import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  ShadertoySite site = ShadertoySiteClient.build();

  var r1 = await site.findCommentsByShaderId('MdX3Rr');
  print('${r1?.total} comment(s)');
  var r2 = await site.findCommentsByShaderId('XdyyDd');
  print('${r2?.total} comment(s)');
  var r3 = await site.findCommentsByShaderId('4scBRs');
  print('${r3?.total} comment(s)');
}
