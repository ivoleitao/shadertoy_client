import 'dart:io';

import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  ShadertoySite site = ShadertoySiteClient.build();

  var sr = await site.findShadersByPlaylistId('week');
  print('${sr?.total} shader id(s)');
  sr?.shaders
      ?.forEach((shader) => stdout.write('${shader?.shader?.info?.id} '));
}
