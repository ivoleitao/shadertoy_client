import 'package:shadertoy_client/shadertoy_client.dart';

void main(List<String> arguments) async {
  var shaders = {'ldcyW4', '3tfGWl', 'lsKSRz', 'MtsXzl', 'MsBXWy'};

  var site = ShadertoySiteClient.build();
  var result = await site.findShadersByIdSet(shaders);
  print('${result?.total} shader(s)');
}
