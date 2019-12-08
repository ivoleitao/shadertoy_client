import 'dart:io';

import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  ShadertoySite site = ShadertoySiteClient.build();

  var response = await site.findPlaylistById('week');
  print('${response?.playlist?.name}');
  print('${response?.playlist?.count} shader id(s)');
  response.playlist?.shaders?.forEach((element) => stdout.write('$element '));
}
