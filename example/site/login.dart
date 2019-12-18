import 'package:dotenv/dotenv.dart';
import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  // Reads environment variables from a .env file
  load();

  // If the user is not specified in the arguments, try the environment one
  var user = arguments.isEmpty ? env['user'] : arguments[0];

  // if no user is found abort
  if (user == null || user.isEmpty) {
    print('Invalid user');
    return;
  }

  // If the password is not specified in the arguments, try the environment one
  var password = arguments.isEmpty ? env['password'] : arguments[0];

  // if no password is found abort
  if (password == null || password.isEmpty) {
    print('Invalid password');
    return;
  }

  var site = ShadertoySiteClient.build(user: user, password: password);

  print('Anonymous');
  var sr = await site.findShaderById('3lsSzf');
  print('${sr?.shader?.info?.id}');
  print('\tName: ${sr?.shader?.info?.name}');
  print('\tLiked: ${sr?.shader?.info?.hasLiked}');

  await site.login();

  print('Logged In');
  site.cookies.forEach((c) => print('${c.name}=${c.value}'));
  sr = await site.findShaderById('3lsSzf');
  print('${sr?.shader?.info?.id}');
  print('\tName: ${sr?.shader?.info?.name}');
  print('\tLiked: ${sr?.shader?.info?.hasLiked}');
}
