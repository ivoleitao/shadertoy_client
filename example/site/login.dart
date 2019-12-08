import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  var site =
      ShadertoySiteClient.build(user: 'shaderflix', password: 'IcA200Pur');

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
