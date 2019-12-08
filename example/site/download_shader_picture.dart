import 'dart:io';

import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  ShadertoySite site = ShadertoySiteClient.build();

  var response = await site.downloadShaderPicture('3lsSzf');
  File('.dart_tool/3lsSzf.jpg').writeAsBytesSync(response.bytes);
}
