import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shadertoy_api/shadertoy_api.dart';

File _fixture(String path) => File('test/fixtures/$path');

Uint8List binaryFixture(String path) => _fixture(path).readAsBytesSync();

String textFixture(String path) => _fixture(path).readAsStringSync();

Map<String, dynamic> jsonFixture(String path) => json.decode(textFixture(path));

Shader shaderFixture(String path) => Shader.fromJson(jsonFixture(path));

List<Shader> shadersFixture(List<String> paths) =>
    paths.map((p) => shaderFixture(p)).toList();

FindShaderResponse findShaderResponseFixture(String path,
        {ResponseError error}) =>
    FindShaderResponse(shader: shaderFixture(path), error: error);

FindShadersResponse findShadersResponseFixture(List<String> paths,
        {ResponseError error}) =>
    FindShadersResponse(
        shaders: paths.map((p) => findShaderResponseFixture(p)).toList(),
        error: error);

String shaderIdFixture(String path) => shaderFixture(path).info.id;

FindShaderIdsResponse findShaderIdsResponsetFixture(List<String> paths,
        {int count, ResponseError error}) =>
    FindShaderIdsResponse(
        count: count,
        ids: paths.map((p) => shaderIdFixture(p)).toList(),
        error: error);

FindShadersRequest findShadersRequestFixture(List<String> paths,
        {ResponseError error}) =>
    FindShadersRequest(paths.map((p) => shaderIdFixture(p)).toSet());

CommentsResponse commentsResponseFixture(String path) =>
    CommentsResponse.fromMap(jsonFixture(path));

DownloadFileResponse downloadFileResponseFixture(String path,
        {ResponseError error}) =>
    DownloadFileResponse(bytes: binaryFixture(path), error: error);
