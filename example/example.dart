import 'package:dotenv/dotenv.dart';
import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  // Reads environment variables from a .env file.
  // Create .env file at the root of the project and set
  // the apiKey e.g. `apiKey='XXXXXX'`. This project uses the
  // dotenv package to load values at bootstrap
  load();

  // If the api key is not specified in the arguments, try the environment one
  var apiKey = arguments.isEmpty ? env['apiKey'] : arguments[0];

  // if no api key is found abort
  if (apiKey == null || apiKey.isEmpty) {
    print('Invalid API key');
    return;
  }

  var ws = ShadertoyWSClient.build(apiKey);
  var site = ShadertoySiteClient.build();

  // Gets the shader by id
  var shaderId = '3lsSzf';
  var sr = await ws.findShaderById(shaderId);
  if (!sr.hasError()) {
    // If there is no error print the shader contents
    print('${sr?.shader?.info?.id}');
    print('\tName: ${sr?.shader?.info?.name}');
    print('\tUserName: ${sr?.shader?.info?.userId}');
    print('\tDate: ${sr?.shader?.info?.date}');
    print('\tDescription: ${sr?.shader?.info?.description}');
    print('\tViews: ${sr?.shader?.info?.views}');
    print('\tLikes: ${sr?.shader?.info?.likes}');
    print(
        '\tPublish Status: ${sr?.shader?.info?.publishStatus.toString().split('.').last}');
    print('\tTags: ${sr?.shader?.info?.tags?.join(',')}');
    print('\tFlags: ${sr?.shader?.info?.flags}');
    print('\tLiked: ${sr?.shader?.info?.hasLiked}');
    print('\tRender Passes: ${sr?.shader?.renderPasses?.length}');
    sr?.shader?.renderPasses?.forEach((element) => print(
        '\t\t${element?.name} has ${element?.inputs?.length} input(s) and ${element?.outputs?.length} output(s)'));
  } else {
    // In case of error print the error message
    print('Error retrieving the shader: ${sr.error.message}');
  }

  // Gets the firs 5 comments for this shader
  var sc = await site.findCommentsByShaderId(shaderId);
  if (!sc.hasError()) {
    // If there is no error print the shader comments
    sc?.comments?.take(5)?.forEach((c) => print('${c.userId}: ${c.text}'));
  } else {
    // In case of error print the error message
    print('Error retrieving shader ${shaderId} comments: ${sr.error.message}');
  }
}
