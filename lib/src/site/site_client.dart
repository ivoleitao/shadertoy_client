import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:html/dom.dart' show Document, Element, Node;
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import 'package:pool/pool.dart';
import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/src/base_client.dart';
import 'package:shadertoy_client/src/site/site_options.dart';

/// A Shadertoy site API client
///
/// Provides an implementation of the [ShadertoySite] thus allowing the creation
/// of a client to access all the methods provided by the shadertoy site API
/// Please note that most of the implementations provided rely on some stability on
/// the website design since data extraction is in some cases performed with web scrapping
class ShadertoySiteClient extends ShadertoyHttpClient<ShadertoySiteOptions>
    implements ShadertoySite {
  /// Parses the number of results out of the Shadertoy browse
  /// [page](https://www.shadertoy.com/browse)
  static final RegExp NumResultsTopRegExp =
      RegExp(r'\s*Results\s\((\d*)\):\s*');

  /// Parses the number of results out of the Shadertoy playlist page,
  /// for example this week playlist [page](https://www.shadertoy.com/playlist/week)
  static final RegExp NumResultsBottomRegExp =
      RegExp(r'\((\d*)\s(results|shaders)\)');

  /// Parses the id's from the Shadertoy results, for example on
  /// a search for "elevated" this regular expression parses the
  /// id's from this [page](https://www.shadertoy.com/results?query=elevated)
  static final RegExp IdArrayRegExp = RegExp(r'\[(\s*\"(\w{6})\"\s*,?)+\]');

  /// Parses a Shadertoy id after sucessfully aplying the regex [IdArrayRegExp]
  static final RegExp ShaderIdRegExp = RegExp(r'\"(\w{6})\"');

  /// Creates a [ShadertoySiteClient]
  ///
  /// * [options]: The [ShadertoySiteOptions] used to configure this client
  /// * [client]: A pre-initialized [Dio] client
  ShadertoySiteClient(ShadertoySiteOptions options, {Dio client})
      : super(options, client: client);

  /// Builds a [ShadertoySiteClient] out of the most common set of configurations
  ///
  /// * [user]: The Shadertoy site user
  /// * [password]: The Shadertoy site password
  ///
  /// The [user] and [password] are optional and when not present
  /// the site API is acessed anonymously like a normal browsing session
  ShadertoySiteClient.build({String user, String password})
      : super(ShadertoySiteOptions(user: user, password: password));

  @override
  Future<LoginResponse> login() {
    var data =
        FormData.fromMap({'user': options.user, 'password': options.password});
    var clientOptions = Options(
        contentType:
            ContentType.parse('application/x-www-form-urlencoded').toString(),
        headers: {HttpHeaders.refererHeader: '${context.signInUrl}'},
        followRedirects: false,
        validateStatus: (int status) => status == 302);

    return catchDioError<LoginResponse>(
        client
            .post('/${ShadertoyContext.SignInPath}',
                data: data, options: clientOptions)
            .then((Response<dynamic> response) => LoginResponse()), (de) {
      return LoginResponse(error: toResponseError(de));
    });
  }

  @override
  Future<LogoutResponse> logout() {
    return catchDioError<LogoutResponse>(
        client
            .get('/${ShadertoyContext.SignOutPath}')
            .then((Response<dynamic> response) {
          clearCookies();
          return LogoutResponse();
        }),
        (de) => LogoutResponse(error: toResponseError(de)));
  }

  /// Finds shaders by ids
  ///
  /// * [ids]: The list of shaders
  ///
  /// Returns a [FindShadersResponse] with the list of [Shader] obtained or a [ResponseError]
  /// This call posts a list of of shader ids to the shadertoy [path](https://www.shadertoy.com/shadertoy)
  /// obtaining a list of [Shader] objects as the response
  Future<FindShadersResponse> _getShadersByIdSet(Set<String> ids) {
    var data = FormData.fromMap(
        {'s': jsonEncode(FindShadersRequest(ids)), 'nt': 1, 'nl': 1});
    var options = Options(
        contentType:
            ContentType.parse('application/x-www-form-urlencoded').toString(),
        headers: {HttpHeaders.refererHeader: '${context.shaderBrowseUrl}'});

    return client.post('/shadertoy', data: data, options: options).then(
        (Response<dynamic> response) => jsonResponse<FindShadersResponse>(
            response,
            (data) => FindShadersResponse(
                shaders: List<dynamic>.from(data)
                    .map((shader) =>
                        FindShaderResponse(shader: Shader.fromJson(shader)))
                    .toList())));
  }

  /// Finds a [Shader] by Id
  ///
  /// [shaderId]: The id of the shader
  ///
  /// Returns a [FindShaderResponse] with the [Shader] or a [ResponseError]
  Future<FindShaderResponse> _getShaderById(String shaderId) {
    return _getShadersByIdSet({shaderId}).then((response) => response.total > 0
        ? response.shaders[0]
        : FindShaderResponse(
            error: ResponseError.notFound(
                message: 'Shader not found',
                context: CONTEXT_SHADER,
                target: shaderId)));
  }

  @override
  Future<FindShaderResponse> findShaderById(String shaderId) {
    return catchDioError<FindShaderResponse>(
        _getShaderById(shaderId),
        (de) => FindShaderResponse(
            error: toResponseError(de,
                context: CONTEXT_SHADER, target: shaderId)));
  }

  @override
  Future<FindShadersResponse> findShadersByIdSet(Set<String> ids) {
    return catchDioError<FindShadersResponse>(
        _getShadersByIdSet(ids),
        (de) => FindShadersResponse(
            error: toResponseError(de, context: CONTEXT_SHADER)));
  }

  /// Parses the number of returned shader's from the html
  /// returned in the Shadertoy browse [page](https://www.shadertoy.com/browse)
  /// the results [page](https://www.shadertoy.com/results) or the user page,
  /// [iq](https://www.shadertoy.com/user/iq) user page for example
  ///
  /// [doc]: The [Document] with the page DOM
  ///
  /// Returns null in case of a unsucessful match
  int _parseShaderPagerTop(Document doc) {
    var elements = doc.querySelectorAll('#content>#controls>*>div');
    if (elements.isNotEmpty) {
      for (var element in elements) {
        Match numResultsMatch = NumResultsTopRegExp.firstMatch(element.text);
        if (numResultsMatch != null) {
          return int.tryParse(numResultsMatch.group(1));
        }
      }
    }

    return null;
  }

  /// Parses the number of returned shader's from the html
  /// returned in the Shadertoy playlist [week](https://www.shadertoy.com/playlist/week)
  /// playlist for example
  ///
  /// [doc]: The [Document] with the page DOM
  ///
  /// Returns null in case of a unsucessful match
  int _parseShaderPagerBottom(Document doc) {
    var element = doc.querySelector('#numResults');

    if (element != null) {
      Match numResultsMatch = NumResultsBottomRegExp.firstMatch(element.text);
      if (numResultsMatch != null) {
        return int.tryParse(numResultsMatch.group(1));
      }
    }

    return null;
  }

  /// Parses the list of shader id's returned
  ///
  /// * [doc]: The [Document] with the page DOM
  ///
  /// It should be used to parse the html of
  /// browse, results, user and playlist pages
  FindShaderIdsResponse _parseShaderIds(Document doc) {
    int count;
    var results = <String>[];

    count = _parseShaderPagerBottom(doc) ?? _parseShaderPagerTop(doc);
    if (count == null) {
      return FindShaderIdsResponse(
          error: ResponseError.backendResponse(
              message: 'Unable to parse the number of results'));
    } else if (count <= 0) {
      return FindShaderIdsResponse(
          error: ResponseError.backendResponse(
              message: 'Obtained an invalid number of results: $count'));
    }

    var elements = doc.querySelectorAll('script');
    if (elements.isNotEmpty) {
      for (var element in elements) {
        Match elementMatch = IdArrayRegExp.firstMatch(element.text);

        if (elementMatch != null) {
          var shaderListText = elementMatch.group(0);
          Iterable<Match> shaderIdMatches =
              ShaderIdRegExp.allMatches(shaderListText);

          if (shaderIdMatches.isNotEmpty) {
            for (var i = 0; i < shaderIdMatches.length; i++) {
              var shaderIdMatch = shaderIdMatches.elementAt(i);

              results.add(shaderIdMatch.group(1));
            }
          } else {
            return FindShaderIdsResponse(
                error: ResponseError.backendResponse(
                    message:
                        'Unable to obtain the list of shader ids while matching "${shaderListText}" with "${ShaderIdRegExp.pattern}" pattern'));
          }
        }
      }

      if (results.isEmpty) {
        return FindShaderIdsResponse(
            error: ResponseError.backendResponse(
                message:
                    'No script block matches with "${IdArrayRegExp.pattern}" pattern'));
      }
    } else {
      return FindShaderIdsResponse(
          error: ResponseError.backendResponse(
              message: 'Unable to get the script blocks from the document'));
    }

    return FindShaderIdsResponse(count: count, ids: results);
  }

  /// Finds shader ids
  ///
  /// * [term]: Shaders that have [term] in the name or in description
  /// * [filters]: A set of tag filters
  /// * [sort]: The sort order of the shaders
  /// * [page]: A page number. Each page returns a fixed set of shader ids as configured in [ShadertoySiteOptions.pageResultsShaderCount]
  ///
  /// Returns a [FindShaderIdsResponse] with a list of ids or a [ResponseError]
  Future<FindShaderIdsResponse> _getShaderIdsPage(
      {String term, Set<String> filters, Sort sort, int page = 1}) {
    var from = max((page - 1), 0) * options.pageResultsShaderCount;
    var num = options.pageResultsShaderCount;

    var queryParameters = [];
    if (term != null && term.isNotEmpty) {
      queryParameters.add('query=$term');
    }

    if (filters != null) {
      for (var filter in filters) {
        queryParameters.add('filter=$filter');
      }
    }

    if (sort != null) {
      queryParameters.add('sort=${EnumToString.parse(sort)}');
    }

    if (from != null) {
      queryParameters.add('from=$from');
    }

    if (num != null) {
      queryParameters.add('num=$num');
    }

    var sb = StringBuffer('/results');
    for (var i = 0; i < queryParameters.length; i++) {
      sb.write(i == 0 ? '?' : '&');
      sb.write(queryParameters[i]);
    }

    return client.get(sb.toString()).then(
        (Response<dynamic> response) => _parseShaderIds(parse(response.data)));
  }

  /// Finds shader ids
  ///
  /// * [term]: Shaders that have [term] in the name or in description
  /// * [filters]: A set of tag filters
  /// * [sort]: The sort order of the shaders
  /// * [from]: A 0 based index for results returned
  /// * [num]: The total number of results
  ///
  /// Returns a [FindShaderIdsResponse] with a list of ids or a [ResponseError]
  /// According with [from] and [num] parameters the number of calls to the Shadertoy
  /// site API s calculated. Note that the site returns a fixed number of shaders
  /// (configured in [ShadertoySiteOptions.pageResultsShaderCount])
  Future<FindShaderIdsResponse> _getShaderIds(
      {String term, Set<String> filters, Sort sort, int from, int num}) {
    return _getShaderIdsPage(term: term, filters: filters, sort: sort)
        .then((FindShaderIdsResponse firstPage) {
      if (firstPage.error != null) {
        return firstPage;
      }

      var pages = (min(num ?? firstPage.total, firstPage.total) /
              options.pageResultsShaderCount)
          .ceil();
      if (pages > 1) {
        var shaderTaskPool = Pool(options.poolMaxAllocatedResources,
            timeout: Duration(seconds: options.poolTimeout));

        var tasks = [Future.value(firstPage)];
        for (var page = 2; page <= pages; page++) {
          tasks.add(pooledRetry(
              shaderTaskPool,
              () => _getShaderIdsPage(
                  term: term, filters: filters, sort: sort, page: page)));
        }

        return Future.wait(tasks).then((List<FindShaderIdsResponse> responses) {
          var results = <String>[];

          for (var i = 0; i < responses.length; i++) {
            var response = responses[i];

            if (response.error != null) {
              return FindShaderIdsResponse(
                  error: ResponseError.backendResponse(
                      message:
                          'Page ${i + 1} of $pages page(s) was not successfully fetched: ${response.error.message}'));
            }

            results.addAll(response.ids);
          }

          return FindShaderIdsResponse(count: results.length, ids: results);
        });
      }

      return firstPage;
    });
  }

  @override
  Future<FindShadersResponse> findShaders(
      {String term, Set<String> filters, Sort sort, int from, int num}) {
    return catchDioError<FindShadersResponse>(
        _getShaderIds(
                term: term,
                filters: filters,
                sort: sort,
                from: from,
                num: num ?? options.shaderCount)
            .then((FindShaderIdsResponse response) {
          if (response.error != null) {
            return FindShadersResponse(
                error: ResponseError.backendResponse(
                    message:
                        'Unable to get the list of shader ids: ${response.error.message}'));
          }

          return _getShadersByIdSet(response.ids.toSet());
        }),
        (de) => FindShadersResponse(
            error: toResponseError(de, context: CONTEXT_SHADER)));
  }

  @override
  Future<FindShaderIdsResponse> findAllShaderIds() {
    return catchDioError<FindShaderIdsResponse>(
        _getShaderIds(),
        (de) => FindShaderIdsResponse(
            error: toResponseError(de, context: CONTEXT_SHADER)));
  }

  @override
  Future<FindShaderIdsResponse> findShaderIds(
      {String term, Set<String> filters, Sort sort, int from, int num}) {
    return catchDioError<FindShaderIdsResponse>(
        _getShaderIds(
            term: term,
            filters: filters,
            sort: sort,
            from: from,
            num: options.shaderCount),
        (de) => FindShaderIdsResponse(
            error: toResponseError(de, context: CONTEXT_SHADER)));
  }

  /// Builds the user url used in the call to Shadertoy user page.
  ///
  /// * [userId]: The user Id
  /// * [filters]: A set of tag filters
  /// * [sort]: The sort order of the shaders
  /// * [page]: A page number. Each page returns a fixed set of shader ids as configured in [ShadertoySiteOptions.pageResultsShaderCount]
  ///
  /// The call is performed to a user page identified by it's id, for example user
  /// iq [page](https://www.shadertoy.com/user/iq)
  String _getUserUrl(String userId,
      {Set<String> filters, Sort sort, int page}) {
    var from = max((page ?? 1 - 1), 0) * options.pageUserShaderCount;
    var num = options.pageUserShaderCount;

    var queryParameters = [];

    if (filters != null) {
      for (var filter in filters) {
        queryParameters.add('filter=$filter');
      }
    }

    if (sort != null) {
      queryParameters.add('sort=${EnumToString.parse(sort)}');
    }

    if (from != null) {
      queryParameters.add('from=$from');
    }

    if (num != null) {
      queryParameters.add('num=$num');
    }

    var sb = StringBuffer('/user/$userId');
    for (var i = 0; i < queryParameters.length; i++) {
      sb.write(i == 0 ? '/' : '&');
      sb.write(queryParameters[i]);
    }

    return sb.toString();
  }

  /// Get the shader id's of a user
  ///
  /// * [userId]: The user Id
  /// * [filters]: A set of tag filters
  /// * [sort]: The sort order of the shaders
  /// * [page]: A page number. Each page returns a fixed set of shader ids as configured in [ShadertoySiteOptions.pageResultsShaderCount]
  ///
  /// Returns a [FindShaderIdsResponse] with a list of ids or a [ResponseError]
  Future<FindShaderIdsResponse> _getShaderIdsPageByUserId(String userId,
      {Set<String> filters, Sort sort, int page}) {
    return client
        .get(_getUserUrl(userId, filters: filters, sort: sort, page: page))
        .then((Response<dynamic> response) =>
            _parseShaderIds(parse(response.data)));
  }

  /// Gets the shader ids of a user
  ///
  /// * [userId]: The user Id
  /// * [filters]: A set of tag filters
  /// * [sort]: The sort order of the shaders
  /// * [from]: A 0 based index for results returned
  /// * [num]: The total number of results
  ///
  /// Returns a [FindShaderIdsResponse] with a list of ids or a [ResponseError]
  /// According with [from] and [num] parameters the number of calls to the Shadertoy
  /// site API s calculated. Note that the site returns a fixed number of shaders
  /// (configured in [ShadertoySiteOptions.pageUserShaderCount])
  Future<FindShaderIdsResponse> _getShaderIdsByUserId(String userId,
      {Set<String> filters, Sort sort, int from, int num}) {
    return _getShaderIdsPageByUserId(userId, filters: filters, sort: sort)
        .then((FindShaderIdsResponse userResponse) {
      if (userResponse.error != null) {
        userResponse.error..target = userId;
        return userResponse;
      }

      var firstPageIds = userResponse.ids;
      var firstPageResponse =
          FindShaderIdsResponse(count: firstPageIds.length, ids: firstPageIds);

      var pages = (min(num ?? userResponse.total, userResponse.total) /
              options.pageUserShaderCount)
          .ceil();
      if (pages > 1) {
        var shaderTaskPool = Pool(options.poolMaxAllocatedResources,
            timeout: Duration(seconds: options.poolTimeout));

        var tasks = [Future.value(firstPageResponse)];
        for (var page = 2; page <= pages; page++) {
          tasks.add(pooledRetry(
              shaderTaskPool,
              () => _getShaderIdsPageByUserId(userId,
                  filters: filters, sort: sort, page: page)));
        }

        return Future.wait(tasks)
            .then((List<FindShaderIdsResponse> findShaderIdsResponses) {
          var results = <String>[];

          for (var i = 0; i < findShaderIdsResponses.length; i++) {
            var findShaderIdsResponse = findShaderIdsResponses[i];

            if (findShaderIdsResponse.error != null) {
              return FindShaderIdsResponse(
                  error: ResponseError.backendResponse(
                      message:
                          'Page ${i + 1} of $pages page(s) was not successfully fetched: ${findShaderIdsResponse.error.message}',
                      target: userId));
            }

            results.addAll(findShaderIdsResponse.ids);
          }

          return FindShaderIdsResponse(count: userResponse.total, ids: results);
        });
      }

      return userResponse;
    });
  }

  /// Helper methods which parses a [String] out of a [Node]
  String _userString(Node node) {
    return node.text.substring(1).trim();
  }

  /// Helper methods which parses a [int] out of a [Node]
  int _userInt(Node node) {
    return int.tryParse(_userString(node));
  }

  /// Helper methods which parses a [DateTime] out of a [Node]
  DateTime _userDate(Node node) {
    return DateFormat('MMMM d, y').parse(_userString(node));
  }

  /// Parses a user out of the DOM representation
  ///
  /// * [userId]: The user id
  /// * [doc]: The [Document] with the page DOM
  ///
  /// Return a [FindUserResponse] with a [User] or a [ResponseError]
  FindUserResponse _parseUser(String userId, Document doc) {
    String picture;
    DateTime memberSince;
    int shaders;
    int comments;
    var aboutBuffer = StringBuffer();

    var elements = doc.querySelectorAll('#content>#divUser>table>tbody>tr>td');
    if (elements.length < 3) {
      return FindUserResponse(
          error: ResponseError.backendResponse(
              message:
                  'Obtained an invalid number of user sections: ${elements.length}'));
    }

    var pictureSection = elements[0];
    picture = pictureSection?.querySelector('#userPicture')?.attributes['src'];
    var fieldsSection = elements[1];
    List<Node> nodes = fieldsSection.nodes;
    for (var i = 0; i < nodes.length; i++) {
      var text = nodes[i].text;

      if ('Member since'.compareTo(text) == 0 && i < nodes.length - 1) {
        memberSince = _userDate(nodes[i + 1]);
      }

      if ('Shaders'.compareTo(text) == 0 && i < nodes.length - 1) {
        shaders = _userInt(nodes[i + 1]);
      }

      if ('Comments'.compareTo(text) == 0 && i < nodes.length - 1) {
        comments = _userInt(nodes[i + 1]);
      }
    }
    var aboutSection = elements[2];
    nodes = aboutSection.nodes;
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      var text = node.text.trim();

      if (node.nodeType == Node.ELEMENT_NODE) {
        var element = node as Element;
        var tag = element.localName;

        if (tag == 'br') {
          aboutBuffer.write('\n');
        } else if (tag == 'strong') {
          aboutBuffer.write('[b]$text[/b]');
        } else if (tag == 'em') {
          aboutBuffer.write('[i]$text[/i]');
        } else if (tag == 'a') {
          var href = element.attributes['href'];
          if (href != null) {
            if (href == text) {
              aboutBuffer.write('[url]$href[/url]');
            } else {
              aboutBuffer.write('[url=$href]$text[/url]');
            }
          }
        } else if (tag == 'pre') {
          aboutBuffer.write('[code]$text[/code]');
        } else if (tag == 'img') {
          var src = element.attributes['src'];
          if (src.endsWith('emoticonHappy.png')) {
            aboutBuffer.write(':)');
          } else if (src.endsWith('emoticonSad.png')) {
            aboutBuffer.write(':(');
          } else if (src.endsWith('emoticonLaugh.png')) {
            aboutBuffer.write(':D');
          } else if (src.endsWith('emoticonLove.png')) {
            aboutBuffer.write(':love:');
          } else if (src.endsWith('emoticonOctopus.png')) {
            aboutBuffer.write(':octopus:');
          } else if (src.endsWith('emoticonOctopusBalloon.png')) {
            aboutBuffer.write(':octopusballoon:');
          }
        }
      } else if (node.nodeType == Node.TEXT_NODE) {
        if (text == 'α') {
          aboutBuffer.write(':alpha:');
        } else if (text == 'β') {
          aboutBuffer.write(':beta:');
        } else if (text == '⏑') {
          aboutBuffer.write(':delta');
        } else if (text == 'ε') {
          aboutBuffer.write(':epsilon:');
        } else if (text == '∇') {
          aboutBuffer.write(':nabla:');
        } else if (text == '²') {
          aboutBuffer.write(':square:');
        } else if (text == '≐') {
          aboutBuffer.write(':limit:');
        } else {
          aboutBuffer.write(text);
        }
      }
    }

    return FindUserResponse(
        user: User(
            id: userId,
            picture: picture,
            memberSince: memberSince,
            shaders: shaders,
            comments: comments,
            about: aboutBuffer.toString()));
  }

  @override
  Future<FindUserResponse> findUserById(String userId) {
    return catchDioError<FindUserResponse>(
        client.get(_getUserUrl(userId)).then((Response<dynamic> response) =>
            _parseUser(userId, parse(response.data))),
        (de) => FindUserResponse(
            error: toResponseError(de, context: CONTEXT_USER, target: userId)));
  }

  @override
  Future<FindShadersResponse> findShadersByUserId(String userId,
      {Set<String> filters, Sort sort, int from, int num}) {
    return catchDioError<FindShadersResponse>(
        _getShaderIdsByUserId(userId,
                filters: filters,
                sort: sort,
                from: from,
                num: num ?? options.shaderCount)
            .then((FindShaderIdsResponse response) {
          if (response.error != null) {
            return FindShadersResponse(
                error: ResponseError.backendResponse(
                    message:
                        'Unable to get the list of shader ids: ${response.error.message}',
                    target: userId));
          }

          return findShadersByIdSet(response.ids.toSet());
        }),
        (de) => FindShadersResponse(
            error: toResponseError(de, context: CONTEXT_USER, target: userId)));
  }

  @override
  Future<FindShaderIdsResponse> findShaderIdsByUserId(String userId,
      {Set<String> filters, Sort sort, int from, int num}) {
    return catchDioError<FindShaderIdsResponse>(
        _getShaderIdsByUserId(userId,
                from: from, num: num ?? options.shaderCount)
            .then((userResponse) => FindShaderIdsResponse(
                count: userResponse.ids.length, ids: userResponse.ids)),
        (de) => FindShaderIdsResponse(
            error: toResponseError(de, context: CONTEXT_USER, target: userId)));
  }

  @override
  Future<FindCommentsResponse> findCommentsByShaderId(String shaderId) {
    var data = FormData.fromMap({'s': shaderId});
    var options = Options(
        contentType: 'application/x-www-form-urlencoded',
        headers: {
          HttpHeaders.refererHeader: '${context.getShaderViewUrl(shaderId)}'
        });

    return catchDioError<FindCommentsResponse>(
        client
            .post('/comment', data: data, options: options)
            .then((Response<dynamic> response) =>
                jsonResponse<CommentsResponse>(
                    response, (data) => CommentsResponse.from(data),
                    context: CONTEXT_SHADER, target: shaderId))
            .then((c) {
          var userIds = c?.userIds;
          var dates = c?.dates;
          var texts = c?.texts;

          var comments = List<Comment>(max(
              max(texts?.length ?? 0, dates?.length ?? 0),
              userIds?.length ?? 0));

          for (var i = 0; i < comments.length; i++) {
            String userId;
            DateTime date;
            String text;

            if (userIds != null && userIds.length > i) {
              userId = userIds[i];
            }

            if (dates != null && dates.length > i) {
              date = DateTime.fromMillisecondsSinceEpoch(
                  int.parse(dates[i]) * 1000);
            }

            if (texts != null && texts.length > i) {
              text = texts[i];
            }

            comments[i] = Comment(
                shaderId: shaderId, userId: userId, date: date, text: text);
          }

          return FindCommentsResponse(
              total: comments.length, comments: comments);
        }),
        (de) => FindCommentsResponse(
            error: toResponseError(de,
                context: CONTEXT_COMMENT, target: shaderId)));
  }

  /// Builds the playlist url used in the call to Shadertoy playlist page.
  ///
  /// * [playlistId]: The playlist id
  /// * [page]: A page number. Each page returns a fixed set of playlist shader ids as configured in [ShadertoySiteOptions.pagePlaylistShaderCount]
  ///
  /// The call is performed to a playlist page identified by it's id, for example week
  /// [playlist](https://www.shadertoy.com/playlist/week)
  String _getPlaylistUrl(String playlistId, int page) {
    var from = max((page - 1), 0) * options.pagePlaylistShaderCount;
    var num = options.pagePlaylistShaderCount;

    var queryParameters = [];
    if (from != null) {
      queryParameters.add('from=$from');
    }

    if (num != null) {
      queryParameters.add('num=$num');
    }

    var sb = StringBuffer('/playlist/$playlistId');
    for (var i = 0; i < queryParameters.length; i++) {
      sb.write(i == 0 ? '?' : '&');
      sb.write(queryParameters[i]);
    }

    return sb.toString();
  }

  /// Parses the list of shader id's returned
  ///
  /// * [playlistId]: The id of the playlist
  /// * [doc]: The [Document] with the page DOM
  ///
  /// It should be used to parse the html of
  /// the playlist pages
  FindPlaylistResponse _parsePlaylist(String playlistId, Document doc) {
    String name;

    var element = doc.querySelector('#content>#info>span>span');
    if (element != null) {
      name = element.text;
    } else {
      return FindPlaylistResponse(
          error: ResponseError.backendResponse(
              message: 'Unable to get the playlist name from the document'));
    }

    var shaderIdsResponse = _parseShaderIds(doc);
    if (shaderIdsResponse.error != null) {
      return FindPlaylistResponse(error: shaderIdsResponse.error);
    }

    return FindPlaylistResponse(
        playlist: Playlist(
            id: playlistId,
            name: name,
            count: shaderIdsResponse.total,
            shaders: shaderIdsResponse.ids));
  }

  /// Get's a playlist with it's associated shaders
  ///
  /// * [playlistId]: The playlist Id
  /// * [page]: A page number. Each page returns a fixed set of playlist shader ids as configured in [ShadertoySiteOptions.pagePlaylistShaderCount]
  ///
  /// Returns a [FindPlaylistResponse] with a list of shader id's or a [ResponseError]
  Future<FindPlaylistResponse> _getPlaylistPageByPlayListId(String playlistId,
      {int page = 1}) {
    return client.get(_getPlaylistUrl(playlistId, page)).then(
        (Response<dynamic> response) =>
            _parsePlaylist(playlistId, parse(response.data)));
  }

  /// Get's the sahders id's of a playlist
  ///
  /// * [playlistId]: The playlist Id
  /// * [page]: A page number. Each page returns a fixed set of shader ids as configured in [ShadertoySiteOptions.pagePlaylistShaderCount]
  ///
  /// Returns a [FindShaderIdsResponse] with a list of shader id's or a [ResponseError]
  Future<FindShaderIdsResponse> _getShaderIdsPageByPlayListId(String playlistId,
      {int page = 1}) {
    return client.get(_getPlaylistUrl(playlistId, page)).then(
        (Response<dynamic> response) => _parseShaderIds(parse(response.data)));
  }

  /// Gets the shader ids of a playlist
  ///
  /// * [playlistId]: The playlist Id
  /// * [from]: A 0 based index for results returned
  /// * [num]: The total number of results
  ///
  /// Returns a [FindPlaylistResponse] with a list of shader id's or a [ResponseError]
  /// According with [from] and [num] parameters the number of calls to the Shadertoy
  /// site API s calculated. Note that the site returns a fixed number of shaders
  /// (configured in [ShadertoySiteOptions.pagePlaylistShaderCount])
  Future<FindPlaylistResponse> _getPlaylistByPlaylistId(String playlistId,
      {int from, int num}) {
    return _getPlaylistPageByPlayListId(playlistId)
        .then((FindPlaylistResponse playlistResponse) {
      if (playlistResponse.error != null) {
        playlistResponse.error..target = playlistId;
        return playlistResponse;
      }

      var playlist = playlistResponse.playlist;
      var firstPageIds = playlist.shaders;
      var firstPageResponse =
          FindShaderIdsResponse(count: firstPageIds.length, ids: firstPageIds);

      var pages = (min(num ?? playlist.count, playlist.count) /
              options.pagePlaylistShaderCount)
          .ceil();
      if (pages > 1) {
        var shaderTaskPool = Pool(options.poolMaxAllocatedResources,
            timeout: Duration(seconds: options.poolTimeout));

        var tasks = [Future.value(firstPageResponse)];
        for (var page = 2; page <= pages; page++) {
          tasks.add(pooledRetry(shaderTaskPool,
              () => _getShaderIdsPageByPlayListId(playlistId, page: page)));
        }

        return Future.wait(tasks)
            .then((List<FindShaderIdsResponse> findShaderIdsResponses) {
          var shaders = <String>[];

          for (var i = 0; i < findShaderIdsResponses.length; i++) {
            var findShaderIdsResponse = findShaderIdsResponses[i];

            if (findShaderIdsResponse.error != null) {
              return FindPlaylistResponse(
                  error: ResponseError.backendResponse(
                      message:
                          'Page ${i + 1} of $pages page(s) was not successfully fetched: ${findShaderIdsResponse.error.message}',
                      target: playlistId));
            }

            shaders.addAll(findShaderIdsResponse.ids);
          }

          return FindPlaylistResponse(
              playlist: Playlist(
                  id: playlist.id,
                  name: playlist.name,
                  count: playlist.count,
                  shaders: shaders));
        });
      }

      return playlistResponse;
    });
  }

  @override
  Future<FindPlaylistResponse> findPlaylistById(String playlistId) {
    return catchDioError<FindPlaylistResponse>(
        _getPlaylistByPlaylistId(playlistId),
        (de) => FindPlaylistResponse(
            error: toResponseError(de,
                context: CONTEXT_PLAYLIST, target: playlistId)));
  }

  @override
  Future<FindShadersResponse> findShadersByPlaylistId(String playlistId,
      {int from, int num}) {
    return catchDioError<FindShadersResponse>(
        _getPlaylistByPlaylistId(playlistId,
                from: from, num: num ?? options.shaderCount)
            .then((FindPlaylistResponse response) {
          if (response.error != null) {
            return FindShadersResponse(
                error: ResponseError.backendResponse(
                    message:
                        'Unable to get the list of shader ids: ${response.error.message}'));
          }

          return findShadersByIdSet(response.playlist.shaders.toSet());
        }),
        (de) => FindShadersResponse(
            error: toResponseError(de,
                context: CONTEXT_PLAYLIST, target: playlistId)));
  }

  @override
  Future<FindShaderIdsResponse> findShaderIdsByPlaylistId(String playlistId,
      {int from, int num}) {
    return catchDioError<FindShaderIdsResponse>(
        _getPlaylistByPlaylistId(playlistId,
                from: from, num: num ?? options.shaderCount)
            .then((playlistResponse) => FindShaderIdsResponse(
                count: playlistResponse.playlist.shaders.length,
                ids: playlistResponse.playlist.shaders)),
        (de) => FindShaderIdsResponse(
            error: toResponseError(de,
                context: CONTEXT_PLAYLIST, target: playlistId)));
  }

  @override
  Future<DownloadFileResponse> downloadShaderPicture(String shaderId) {
    return catchDioError<DownloadFileResponse>(
        client
            .get<List<int>>('/${context.getShaderPicturePath(shaderId)}',
                options: Options(responseType: ResponseType.bytes))
            .then((response) => DownloadFileResponse(bytes: response.data)),
        (de) => DownloadFileResponse(
            error: toResponseError(de,
                context: CONTEXT_SHADER, target: shaderId)));
  }

  @override
  Future<DownloadFileResponse> downloadMedia(String inputPath) {
    return catchDioError<DownloadFileResponse>(
        client
            .get<List<int>>('$inputPath',
                options: Options(responseType: ResponseType.bytes))
            .then((response) => DownloadFileResponse(bytes: response.data)),
        (de) => DownloadFileResponse(
            error: toResponseError(de, context: CONTEXT_SHADER)));
  }
}
