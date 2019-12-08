import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  ShadertoySite site = ShadertoySiteClient.build();

  var response = await site.findUserById('iq');
  print('${response?.user?.id}');
  print('Name: ${response?.user?.picture}');
  print('Member Since: ${response?.user?.memberSince}');
  print('Shaders: ${response?.user?.shaders}');
  print('Comments: ${response?.user?.comments}');
  print('About:');
  print('${response?.user?.about}');
}
