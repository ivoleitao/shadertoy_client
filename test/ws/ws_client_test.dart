import 'package:dio/dio.dart';
import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/shadertoy_client.dart';
import 'package:test/test.dart';

import '../mock_adapter.dart';

void main() {
  group('Shaders', () {
    Dio client;
    ShadertoyClient api;

    setUp(() {
      client = Dio();
      client.options.baseUrl = MockAdapter.mockBase;
      client.httpClientAdapter = MockAdapter({
        '${ShadertoyWSOptions.DefaultApiPath}/shaders/query':
            MockAdapter.newRoute(
                FindShaderIdsResponse(ids: ['Xds3zN']).toJson()),
        '${ShadertoyWSOptions.DefaultApiPath}/shaders/ZzZ0Zz':
            MockAdapter.newRoute(FindShaderResponse(
                shader: Shader(
                    version: '0.1',
                    info: Info(
                        id: 'ZzZ0Zz',
                        date: DateTime.fromMillisecondsSinceEpoch(1360495251),
                        views: 131083,
                        name: 'Example',
                        userId: 'example',
                        description: 'A shader example',
                        likes: 570,
                        publishStatus: PublishStatus.public_api,
                        flags: 32,
                        tags: [
                          'procedural',
                          '3d',
                          'raymarching',
                          'distancefield',
                          'terrain',
                          'motionblur',
                          'vr'
                        ],
                        hasLiked: false),
                    renderPasses: [
              RenderPass(
                  name: 'Image',
                  type: RenderPassType.image,
                  description: '',
                  code: 'code 0',
                  inputs: [
                    Input(
                        id: '257',
                        src: '/media/previz/buffer00.png',
                        type: InputType.texture,
                        channel: 0,
                        sampler: Sampler(
                            filter: FilterType.linear,
                            wrap: WrapType.clamp,
                            vflip: true,
                            srgb: true,
                            internal: 'byte'),
                        published: 1)
                  ],
                  outputs: [
                    Output(id: '37', channel: 0)
                  ]),
              RenderPass(
                  name: 'Buffer A',
                  type: RenderPassType.buffer,
                  description: '',
                  code: 'code 1',
                  inputs: [
                    Input(
                        id: '17',
                        src: '/media/a/zs098rere0323u85534ukj4.png',
                        type: InputType.texture,
                        channel: 0,
                        sampler: Sampler(
                            filter: FilterType.mipmap,
                            wrap: WrapType.repeat,
                            vflip: false,
                            srgb: false,
                            internal: 'byte'),
                        published: 1)
                  ],
                  outputs: [
                    Output(id: '257', channel: 0)
                  ])
            ])))
      });
      api =
          ShadertoyWSClient(ShadertoyWSOptions(apiKey: 'xxx'), client: client);
    });

    test('Find Shader By Id', () async {
      var sr = await api.findShaderById('ZzZ0Zz');
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.shader, isNotNull);
    });

    test('Find Shader Ids', () async {
      var qr = await api.findShaderIds();
      expect(qr, isNotNull);
      expect(qr.error, isNull);
      expect(qr.total, 1);
      expect(qr.total, isNotNull);
      expect(qr.ids, hasLength(1));
      expect(qr.ids.single, 'Xds3zN');
    });
  });
}
