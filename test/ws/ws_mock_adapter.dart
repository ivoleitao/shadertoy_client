import 'dart:io';

import 'package:dio/dio.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/src/ws/ws_options.dart';

import '../fixtures/fixtures.dart';
import '../mock_adapter.dart';

extension WSMockAdaptater on MockAdapter {
  MockAdapter addEmptyResponseRoute(String path, ShadertoyWSOptions options,
      [Map<String, List<String>> queryParameters]) {
    return emptyRoute(path, queryParameters: {
      'key': [options.apiKey],
      ...?queryParameters
    });
  }

  MockAdapter addTextResponseRoute(
      String path, String object, ShadertoyWSOptions options,
      [Map<String, List<String>> queryParameters]) {
    return textRoute(path, object, queryParameters: {
      'key': [options.apiKey],
      ...?queryParameters
    });
  }

  MockAdapter addFindShaderRoute(
      String fixturePath, ShadertoyWSOptions options) {
    final response = findShaderResponseFixture(fixturePath);
    return jsonRoute('shaders/${response.shader.info.id}', response,
        queryParameters: {
          'key': [options.apiKey]
        });
  }

  MockAdapter addFindShaderSocketErrorRoute(
      String fixturePath, ShadertoyWSOptions options, String message) {
    final response = findShaderResponseFixture(fixturePath);
    return errorRoute('shaders/${response.shader.info.id}',
        queryParameters: {
          'key': [options.apiKey]
        },
        type: DioErrorType.DEFAULT,
        error: SocketException(message));
  }

  MockAdapter addFindShadersRoute(
      List<String> fixturesPath, ShadertoyWSOptions options) {
    fixturesPath.forEach((fixturePath) {
      addFindShaderRoute(fixturePath, options);
    });

    return this;
  }

  MockAdapter addFindShadersSocketErrorRoute(
      List<String> fixturesPath, ShadertoyWSOptions options, String message) {
    fixturesPath.forEach((fixturePath) {
      addFindShaderSocketErrorRoute(fixturePath, options, message);
    });

    return this;
  }

  String _getShaderQueryPath({String term}) {
    var sb = StringBuffer('shaders/query');

    if (term != null && term.isNotEmpty) {
      sb.write('/$term');
    }

    return sb.toString();
  }

  Map<String, List<String>> _getShaderQueryParameters(
      ShadertoyWSOptions options,
      {Set<String> filters,
      Sort sort,
      int from,
      int num}) {
    var queryParameters = {
      'key': [options.apiKey]
    };

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

  MockAdapter addFindAllShaderIdsRoute(
      List<String> fixturesPath, ShadertoyWSOptions options) {
    return jsonRoute('shaders', findShaderIdsResponsetFixture(fixturesPath),
        queryParameters: _getShaderQueryParameters(options));
  }

  MockAdapter addFindShaderIdsRoute(
      List<String> fixturesPath, ShadertoyWSOptions options,
      {String term, Set<String> filters, Sort sort, int from, int num}) {
    return jsonRoute(_getShaderQueryPath(term: term),
        findShaderIdsResponsetFixture(fixturesPath),
        queryParameters: _getShaderQueryParameters(options,
            filters: filters,
            sort: sort,
            from: from,
            num: num ?? options.shaderCount));
  }

  MockAdapter addFindShaderIdsSocketErrorRoute(
      ShadertoyWSOptions options, String message,
      {String term, Set<String> filters, Sort sort, int from, int num}) {
    return errorRoute(_getShaderQueryPath(term: term),
        queryParameters: _getShaderQueryParameters(options,
            filters: filters,
            sort: sort,
            from: from,
            num: num ?? options.shaderCount),
        type: DioErrorType.DEFAULT,
        error: SocketException(message));
  }
}
