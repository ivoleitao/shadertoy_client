import 'dart:io';

import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  final site = newShadertoySiteClient();

  final response = await site.downloadMedia('/media/users/TDM/profile.jpeg');
  File('.dart_tool/TDM.jpg').writeAsBytesSync(response.bytes);
}
