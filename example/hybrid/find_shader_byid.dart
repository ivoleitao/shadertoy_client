import 'package:dotenv/dotenv.dart';
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

  var hybrid = ShadertoyHybridClient.build(apiKey: apiKey);

  var sr = await hybrid.findShaderById('3lsSzf');
  print('${sr?.shader?.info?.id}');
  print('\tName: ${sr?.shader?.info?.name}');
}
