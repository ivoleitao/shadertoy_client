import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  final site = newShadertoySiteClient();

  final response = await site.findPlaylistById('featured');
  print('${response?.playlist?.id}');
  print('${response?.playlist?.userId}');
  print('${response?.playlist?.name}');
  print('${response?.playlist?.description}');
  print('${EnumToString.convertToString(response?.playlist?.privacy)}');

  print(jsonEncode(response.playlist.toJson()));
}
