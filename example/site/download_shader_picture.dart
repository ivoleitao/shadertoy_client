import 'dart:io';

import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  final site = newShadertoySiteClient();

  final response = await site.downloadShaderPicture('3lsSzf');
  File('.dart_tool/3lsSzf.jpg').writeAsBytesSync(response.bytes);
}
