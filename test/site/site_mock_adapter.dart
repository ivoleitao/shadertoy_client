import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/src/site/site_options.dart';

import '../fixtures/fixtures.dart';
import '../mock_adapter.dart';

extension SiteMockAdaptater on MockAdapter {
  MockAdapter addLoginRoute(ShadertoySiteOptions options, int statusCode,
      Map<String, List<String>> responseHeaders) {
    var formData =
        FormData.fromMap({'user': options.user, 'password': options.password});
    return textRoute('/signin', '',
        requestHeaders: {
          HttpHeaders.refererHeader: '${options.baseUrl}/signin'
        },
        formData: formData,
        statusCode: statusCode,
        responseHeaders: responseHeaders);
  }

  MockAdapter addLoginSocketErrorRoute(
      ShadertoySiteOptions options, String message) {
    var formData =
        FormData.fromMap({'user': options.user, 'password': options.password});

    return errorRoute('/signin',
        headers: {HttpHeaders.refererHeader: '${options.baseUrl}/signin'},
        formData: formData,
        type: DioErrorType.DEFAULT,
        error: SocketException(message));
  }

  MockAdapter addLogoutRoute(ShadertoySiteOptions options, int statusCode,
      Map<String, List<String>> responseHeaders) {
    return textRoute('/signout', '',
        requestHeaders: {HttpHeaders.refererHeader: '${options.baseUrl}'},
        statusCode: statusCode,
        responseHeaders: responseHeaders);
  }

  MockAdapter addLogoutSocketErrorRoute(
      ShadertoySiteOptions options, String message) {
    return errorRoute('/signout',
        headers: {HttpHeaders.refererHeader: '${options.baseUrl}'},
        type: DioErrorType.DEFAULT,
        error: SocketException(message));
  }

  MockAdapter addShadersRoute(
      List<String> requestFixturesPath, ShadertoySiteOptions options,
      {List<String> responseFixturePath}) {
    final data = findShadersRequestFixture(requestFixturesPath);

    final formData =
        FormData.fromMap({'s': jsonEncode(data), 'nt': 1, 'nl': 1});
    final response = shadersFixture(responseFixturePath ?? requestFixturesPath);
    return jsonRoute('/shadertoy', response,
        requestHeaders: {
          HttpHeaders.refererHeader: '${options.baseUrl}/browse'
        },
        formData: formData);
  }

  MockAdapter addShadersSocketErrorRoute(List<String> requestFixturesPath,
      ShadertoySiteOptions options, String message) {
    final data = findShadersRequestFixture(requestFixturesPath);

    final requestBody =
        FormData.fromMap({'s': jsonEncode(data), 'nt': 1, 'nl': 1});
    return errorRoute('/shadertoy',
        headers: {HttpHeaders.refererHeader: '${options.baseUrl}/browse'},
        formData: requestBody,
        type: DioErrorType.DEFAULT,
        error: SocketException(message));
  }

  MockAdapter addResponseErrorRoute(
      String requestPath, String error, ShadertoySiteOptions options) {
    return errorRoute('/$requestPath',
        type: DioErrorType.RESPONSE, error: error);
  }

  Map<String, List<String>> _getResultsQueryParameters(
      ShadertoySiteOptions options,
      {String query,
      Set<String> filters,
      Sort sort,
      int from,
      int num}) {
    var queryParameters = <String, List<String>>{};

    if (query != null) {
      queryParameters['query'] = [query];
    }

    if (filters != null) {
      queryParameters['filter'] = filters.toList();
    }

    if (sort != null) {
      queryParameters['sort'] = [EnumToString.convertToString(sort)];
    }

    if (from != null) {
      queryParameters['from'] = [from.toString()];
    }

    if (num != null) {
      queryParameters['num'] = [num.toString()];
    }

    return queryParameters;
  }

  MockAdapter addResultsRoute(String fixturePath, ShadertoySiteOptions options,
      {String query, Set<String> filters, Sort sort, int from, int num}) {
    final response = textFixture(fixturePath);
    return htmlRoute('/results', response,
        queryParameters: _getResultsQueryParameters(options,
            query: query,
            filters: filters,
            sort: sort,
            from: from ?? 0,
            num: num ?? options.shaderCount));
  }

  MockAdapter addResultsSocketErrorRoute(
      ShadertoySiteOptions options, String message,
      {String query, Set<String> filters, Sort sort, int from, int num}) {
    return errorRoute('/results',
        queryParameters: _getResultsQueryParameters(options,
            query: query,
            filters: filters,
            sort: sort,
            from: from ?? 0,
            num: num ?? options.shaderCount),
        type: DioErrorType.DEFAULT,
        error: SocketException(message));
  }

  MockAdapter addUserRoute(
      String fixturePath, String userId, ShadertoySiteOptions options) {
    final response = textFixture(fixturePath);
    return htmlRoute('/user/$userId', response);
  }

  MockAdapter addUserSocketErrorRoute(
      String userId, ShadertoySiteOptions options, String message) {
    return errorRoute('/user/$userId',
        type: DioErrorType.DEFAULT, error: SocketException(message));
  }

  Map<String, List<String>> _getUserQueryParameters(
      ShadertoySiteOptions options,
      {Set<String> filters,
      Sort sort,
      int from,
      int num}) {
    var queryParameters = <String, List<String>>{};

    if (filters != null) {
      queryParameters['filter'] = filters.toList();
    }

    if (sort != null) {
      queryParameters['sort'] = [EnumToString.convertToString(sort)];
    }

    if (from != null) {
      queryParameters['from'] = [from.toString()];
    }

    if (num != null) {
      queryParameters['num'] = [num.toString()];
    }

    return queryParameters;
  }

  String _getUserShadersUrl(
      String userId, Map<String, List<String>> queryParameters) {
    // This strange behaviour is needed because the filtering on the shadertoy
    // website works wrongly i.e. https://www.shadertoy.com/user/iq&sort=popular&filter=multipass&filter=musicstream
    // and not https://www.shadertoy.com/user/iq?sort=popular&filter=multipass&filter=musicstream as expected
    // (note the & in the former instead of ? in the latter)
    var url = StringBuffer('/user/$userId');
    for (final queryParameter in queryParameters.entries) {
      for (final queryParameterValue in queryParameter.value) {
        url.write('&${queryParameter.key}=$queryParameterValue');
      }
    }

    return url.toString();
  }

  MockAdapter addUserShadersSocketErrorRoute(
      String userId, ShadertoySiteOptions options, String message,
      {Set<String> filters, Sort sort, int from, int num}) {
    final queryParameters = _getUserQueryParameters(options,
        filters: filters,
        sort: sort,
        from: from ?? 0,
        num: num ?? options.pageUserShaderCount);

    return errorRoute(_getUserShadersUrl(userId, queryParameters),
        type: DioErrorType.DEFAULT, error: SocketException(message));
  }

  MockAdapter addUserShadersRoute(
      String fixturePath, String userId, ShadertoySiteOptions options,
      {Set<String> filters, Sort sort, int from, int num}) {
    final response = textFixture(fixturePath);
    final queryParameters = _getUserQueryParameters(options,
        filters: filters,
        sort: sort,
        from: from ?? 0,
        num: num ?? options.pageUserShaderCount);

    return htmlRoute(_getUserShadersUrl(userId, queryParameters), response);
  }

  MockAdapter addPlaylistRoute(
      String fixturePath, String playlistId, ShadertoySiteOptions options) {
    final response = textFixture(fixturePath);
    return htmlRoute('/playlist/$playlistId', response);
  }

  MockAdapter addPlaylistSocketErrorRoute(
      String playlistId, ShadertoySiteOptions options, String message) {
    return errorRoute('/playlist/$playlistId',
        type: DioErrorType.DEFAULT, error: SocketException(message));
  }

  Map<String, List<String>> _getPlaylistQueryParameters(
      ShadertoySiteOptions options,
      {int from,
      int num}) {
    var queryParameters = <String, List<String>>{};

    if (from != null) {
      queryParameters['from'] = [from.toString()];
    }

    if (num != null) {
      queryParameters['num'] = [num.toString()];
    }

    return queryParameters;
  }

  MockAdapter addPlaylistShadersSocketErrorRoute(
      String playlistId, ShadertoySiteOptions options, String message,
      {int from, int num}) {
    final queryParameters = _getPlaylistQueryParameters(options,
        from: from ?? 0, num: num ?? options.pagePlaylistShaderCount);

    return errorRoute('/playlist/$playlistId',
        queryParameters: queryParameters,
        type: DioErrorType.DEFAULT,
        error: SocketException(message));
  }

  MockAdapter addPlaylistShadersRoute(
      String fixturePath, String playlistId, ShadertoySiteOptions options,
      {int from, int num}) {
    final response = textFixture(fixturePath);

    return htmlRoute('/playlist/$playlistId', response,
        queryParameters: _getPlaylistQueryParameters(options,
            from: from ?? 0, num: num ?? options.pagePlaylistShaderCount));
  }

  MockAdapter addCommentRoute(
      String fixturePath, String shaderId, ShadertoySiteOptions options) {
    var formData = FormData.fromMap({'s': shaderId});
    final response = commentsResponseFixture(fixturePath);
    return jsonRoute('/comment', response,
        requestHeaders: {
          HttpHeaders.refererHeader: '${options.baseUrl}/view/$shaderId'
        },
        formData: formData);
  }

  MockAdapter addCommentSocketErrorRoute(
      String shaderId, ShadertoySiteOptions options, String message) {
    var formData = FormData.fromMap({'s': shaderId});
    return errorRoute('/comment',
        headers: {
          HttpHeaders.refererHeader: '${options.baseUrl}/view/$shaderId'
        },
        formData: formData,
        type: DioErrorType.DEFAULT,
        error: SocketException(message));
  }

  MockAdapter addDownloadFile(
      String path, String fixturePath, ShadertoySiteOptions options) {
    return binaryRoute('/$path', binaryFixture(fixturePath));
  }

  MockAdapter addDownloadShaderMedia(
      String fixturePath, String shaderId, ShadertoySiteOptions options) {
    return addDownloadFile('${ShadertoyContext.shaderPicturePath(shaderId)}',
        fixturePath, options);
  }
}
