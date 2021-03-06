import 'package:shadertoy_client/shadertoy_client.dart';

import '../env.dart';

void main(List<String> arguments) async {
  // If the api key is not specified in the arguments, try the environment one
  var apiKey = arguments.isEmpty ? Env.apiKey : arguments[0];

  // if no api key is found abort
  if (apiKey == null || apiKey.isEmpty) {
    print('Invalid API key');
    return;
  }

  var ws = newShadertoyWSClient(apiKey);

  var sr = await ws.findShaders(term: 'elevated');
  print('${sr?.total} shader id(s)');
  sr?.shaders?.forEach((response) => print('${response?.shader?.info?.id} '));
}
