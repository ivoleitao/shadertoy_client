import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';

class MockAdapter extends HttpClientAdapter {
  static const String mockHost = 'mockserver';
  static const String mockBase = 'http://$mockHost';

  final Map<String, Function> _routes;

  MockAdapter(this._routes);

  final DefaultHttpClientAdapter _adapter = DefaultHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) async {
    var uri = options.uri;
    if (uri.host == mockHost && _routes.containsKey(uri.path)) {
      return _routes[uri.path]();
    }
    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  static Function newRoute(Object object) {
    return () => ResponseBody.fromString(
          jsonEncode(object),
          200,
          headers: {
            HttpHeaders.contentTypeHeader: [ContentType.json.toString()],
          },
        );
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}
