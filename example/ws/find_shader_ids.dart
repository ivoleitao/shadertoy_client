import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  // Reads environment variables from a .env file
  load();

  // If the api key is not specified in the arguments, try the environment one
  var apiKey = arguments.isEmpty ? env['apiKey'] : arguments[0];

  // if no api key is found abort
  if (apiKey == null || apiKey.isEmpty) {
    print('Invalid API key');
    return;
  }

  ShadertoyWS ws = ShadertoyWSClient.build(apiKey);

  var sr = await ws.findShaderIds(term: 'elevated');
  print('${sr?.total} shader id(s)');
  sr?.ids?.forEach((shaderId) => stdout.write('$shaderId '));
}
