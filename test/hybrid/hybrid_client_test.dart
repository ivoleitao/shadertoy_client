import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/shadertoy_client.dart';
import 'package:test/test.dart';

import '../fixtures/fixtures.dart';
import '../mock_adapter.dart';
import '../site/site_mock_adapter.dart';
import '../ws/ws_mock_adapter.dart';

void main() {
  MockAdapter newAdapter([ShadertoyWSOptions options]) {
    return MockAdapter(basePath: options?.apiPath);
  }

  ShadertoyWSOptions newWSOptions([ShadertoyWSOptions options]) {
    return options != null
        ? options.copyWith(baseUrl: MockAdapter.mockBase)
        : ShadertoyWSOptions(apiKey: 'xx', baseUrl: MockAdapter.mockBase);
  }

  ShadertoySiteOptions newSiteOptions([ShadertoySiteOptions options]) {
    return options != null
        ? options.copyWith(baseUrl: MockAdapter.mockBase)
        : ShadertoySiteOptions(baseUrl: MockAdapter.mockBase);
  }

  ShadertoyHybrid newClient(HttpClientAdapter adapter,
      {ShadertoySiteOptions siteOptions, ShadertoyWSOptions wsOptions}) {
    final client = Dio(BaseOptions(baseUrl: MockAdapter.mockBase))
      ..httpClientAdapter = adapter;

    return ShadertoyHybridClient(siteOptions ?? ShadertoySiteOptions(),
        wsOptions: wsOptions, client: client);
  }

  group('Authentication', () {
    test('Login with correct credentials', () async {
      // prepare
      final user = 'user';
      final password = 'password';
      final siteOptions =
          newSiteOptions(ShadertoySiteOptions(user: user, password: password));
      final nowPlusOneDay = DateTime.now().add(Duration(days: 1));
      final formatter = DateFormat('EEE, dd-MMM-yyyy HH:mm:ss');
      final expires = formatter.format(nowPlusOneDay);
      final adapter = newAdapter()
        ..addLoginRoute(siteOptions, 302, {
          HttpHeaders.setCookieHeader: [
            'sdtd=4e9dcd95663b58540ac7aa1dc3f0b914; expires=$expires GMT; Max-Age=1209600; path=/; secure; HttpOnly',
          ],
          HttpHeaders.locationHeader: ['/']
        });
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.login();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(api.loggedIn, isTrue);
    });

    test('Logout without login', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final adapter = newAdapter();
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.logout();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(api.loggedIn, isFalse);
    });

    test('Logout with login', () async {
      // prepare
      final user = 'user';
      final password = 'password';
      final siteOptions =
          newSiteOptions(ShadertoySiteOptions(user: user, password: password));
      final nowPlusOneDay = DateTime.now().add(Duration(days: 1));
      final formatter = DateFormat('EEE, dd-MMM-yyyy HH:mm:ss');
      final expires = formatter.format(nowPlusOneDay);
      final adapter = newAdapter()
        ..addLoginRoute(siteOptions, 302, {
          HttpHeaders.setCookieHeader: [
            'sdtd=4e9dcd95663b58540ac7aa1dc3f0b914; expires=$expires GMT; Max-Age=1209600; path=/; secure; HttpOnly',
          ],
          HttpHeaders.locationHeader: ['/']
        })
        ..addLogoutRoute(siteOptions, 302, {
          HttpHeaders.setCookieHeader: [
            'sdtd=deleted; expires=Thu, 01-Jan-1970 00:00:01 GMT; Max-Age=0; path=/; secure; httponly',
          ],
          HttpHeaders.locationHeader: ['/']
        });
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var lir = await api.login();
      // assert
      expect(lir, isNotNull);
      expect(lir.error, isNull);
      expect(api.loggedIn, isTrue);
      // act
      var lor = await api.logout();
      // assert
      expect(lor, isNotNull);
      expect(lor.error, isNull);
      expect(api.loggedIn, isFalse);
    });
  });

  group('Shaders', () {
    test('Find shader by id with WS client', () async {
      // prepare
      final wsOptions = newWSOptions();
      final shader = 'shaders/seascape.json';
      final adapter = newAdapter(wsOptions)
        ..addFindShaderRoute(shader, wsOptions);
      final api = newClient(adapter, wsOptions: wsOptions);
      // act
      var sr = await api.findShaderById('Ms2SD1');
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.shader, isNotNull);
      expect(sr, findShaderResponseFixture(shader));
    });

    test('Find shader by id with site client', () async {
      // prepare
      final siteOptions = ShadertoySiteOptions();
      final shaders = ['shaders/seascape.json'];
      final adapter = newAdapter()..addShadersRoute(shaders, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findShaderById('Ms2SD1');
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.shader, isNotNull);
      expect(sr, findShaderResponseFixture('shaders/seascape.json'));
    });

    test('Find shaders by id set with WS client', () async {
      // prepare
      final wsOptions = newWSOptions();
      final shaders = ['shaders/seascape.json', 'shaders/happy_jumping.json'];
      final adapter = newAdapter(wsOptions)
        ..addFindShadersRoute(shaders, wsOptions);
      final api = newClient(adapter, wsOptions: wsOptions);
      // act
      var sr = await api.findShadersByIdSet({'Ms2SD1', '3lsSzf'});
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by id set with site client', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final shaders = ['shaders/seascape.json', 'shaders/happy_jumping.json'];
      final adapter = newAdapter()..addShadersRoute(shaders, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findShadersByIdSet({'Ms2SD1', '3lsSzf'});
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders with site WS client', () async {
      // prepare
      final wsOptions = newWSOptions();
      final term = 'prince';
      final shaders = [
        'shaders/lovely_stars.json',
        'shaders/scaleable_homeworlds.json',
        'shaders/prince_necklace.json'
      ];
      final adapter = newAdapter(wsOptions)
        ..addFindShaderIdsRoute(shaders, wsOptions, term: term)
        ..addFindShadersRoute(shaders, wsOptions);
      final api = newClient(adapter, wsOptions: wsOptions);
      // act
      var sr = await api.findShaders(term: term);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders with site client', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final query = 'raymarch';
      final sort = Sort.love;
      final filters = {'multipass'};
      final from = 0;
      final shaders = [
        'shaders/elevated.json',
        'shaders/rainforest.json',
        'shaders/volcanic.json',
        'shaders/sirenian_dawn.json',
        'shaders/goo.json',
        'shaders/cloudy_terrain.json',
        'shaders/raymarching_tutorial.json',
        'shaders/greek_temple.json',
        'shaders/gargantua_with_hdr_bloom.json',
        'shaders/selfie_girl.json',
        'shaders/ladybug.json',
        'shaders/precalculated_voronoi_heightmap.json',
      ];
      final adapter = newAdapter()
        ..addResultsRoute('results/filtered_page_1.html', siteOptions,
            query: query, sort: sort, filters: filters, from: from)
        ..addShadersRoute(shaders, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findShaders(
          term: query, sort: sort, filters: filters, from: from);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find all shader ids with WS client', () async {
      // prepare
      final wsOptions = newWSOptions();
      final shaders = [
        'shaders/after.json',
        'shaders/happy_jumping.json',
        'shaders/homeward.json',
        'shaders/lovely_stars.json',
        'shaders/prince_necklace.json',
        'shaders/scaleable_homeworlds.json',
        'shaders/seascape.json'
      ];
      final adapter = newAdapter(wsOptions)
        ..addFindAllShaderIdsRoute(shaders, wsOptions);
      ;
      final api = newClient(adapter, wsOptions: wsOptions);
      // act
      var sr = await api.findAllShaderIds();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShaderIdsResponsetFixture(shaders));
    });

    test('Find all shader ids with site client', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final shaders = [
        'shaders/fractal_explorer_multi_res.json',
        'shaders/rave_fractal.json',
        'shaders/rhodium_fractalscape.json',
        'shaders/fractal_explorer_dof.json',
        'shaders/kleinian_variations.json',
        'shaders/simplex_noise_fire_milkdrop_beat.json',
        'shaders/fight_them_all_fractal.json',
        'shaders/trilobyte_julia_fractal_smasher.json',
        'shaders/rapping_fractal.json',
        'shaders/trilobyte_bipolar_daisy_complex.json',
        'shaders/smashing_fractals.json',
        'shaders/trilobyte_multi_turing_pattern.json',
        'shaders/surfer_boy.json',
        'shaders/alien_corridor.json',
        'shaders/turn_burn.json',
        'shaders/ice_primitives.json',
        'shaders/basic_montecarlo.json',
        'shaders/crossy_penguin.json',
        'shaders/full_scene_radial_blur.json',
        'shaders/gargantua_with_hdr_bloom.json',
        'shaders/blueprint_of_architekt.json',
        'shaders/three_pass_dof.json',
        'shaders/elephant.json',
        'shaders/multiple_transparency.json'
      ];
      final adapter = newAdapter()
        ..addResultsRoute('results/24_page_1.html', siteOptions)
        ..addResultsRoute('results/24_page_2.html', siteOptions,
            from: 12, num: 12);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findAllShaderIds();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShaderIdsResponsetFixture(shaders, count: 24));
    });

    test('Find shader ids with WS client', () async {
      // prepare
      final wsOptions = newWSOptions();
      final term = 'prince';
      final shaders = [
        'shaders/lovely_stars.json',
        'shaders/scaleable_homeworlds.json',
        'shaders/prince_necklace.json'
      ];
      final adapter = newAdapter(wsOptions)
        ..addFindShaderIdsRoute(shaders, wsOptions, term: term);
      ;
      final api = newClient(adapter, wsOptions: wsOptions);
      // act
      var sr = await api.findShaderIds(term: term);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShaderIdsResponsetFixture(shaders));
    });

    test('Find shader ids with site client', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final shaders = [
        'shaders/seascape.json',
        'shaders/raymarching_primitives.json',
        'shaders/creation.json',
        'shaders/clouds.json',
        'shaders/raymarching_part_6.json',
        'shaders/elevated.json',
        'shaders/volcanic.json',
        'shaders/raymarching_part_1.json',
        'shaders/rainforest.json',
        'shaders/raymarching_part_2.json',
        'shaders/raymarching_part_3.json',
        'shaders/very_fast_procedural_ocean.json',
      ];
      final adapter = newAdapter()
        ..addResultsRoute('results/normal.html', siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findShaderIds();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShaderIdsResponsetFixture(shaders, count: 43698));
    });
  });

  group('Users', () {
    test('Find user by id', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final userId = 'iq';
      final fixture = 'user/$userId.html';
      final adapter = newAdapter()..addUserRoute(fixture, userId, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findUserById(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.user, isNotNull);
      expect(
          sr,
          FindUserResponse(
              user: User(
                  id: userId,
                  picture: '/media/users/$userId/profile.png',
                  memberSince: DateTime(2013, 1, 11),
                  following: 53,
                  followers: 353,
                  about:
                      '\n\n*[url]http://www.iquilezles.org[/url]\n*[url]https://www.patreon.com/inigoquilez[/url]\n*[url]https://www.youtube.com/c/InigoQuilez[/url]\n*[url]https://www.facebook.com/inigo.quilez.art[/url]\n*[url]https://twitter.com/iquilezles[/url]')));
    });

    test('Find shaders by user id', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final userId = 'iq';
      final shaders = [
        'shaders/raymarching_primitives.json',
        'shaders/clouds.json',
        'shaders/elevated.json',
        'shaders/volcanic.json',
        'shaders/rainforest.json',
        'shaders/snail.json',
        'shaders/voxel_edges.json',
        'shaders/mike.json'
      ];
      final adapter = newAdapter()
        ..addUserShadersRoute('user/iq_page_1.html', userId, siteOptions)
        ..addShadersRoute(shaders, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findShadersByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shader ids by user id, first page', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final userId = 'iq';
      final shaders = [
        'shaders/raymarching_primitives.json',
        'shaders/clouds.json',
        'shaders/elevated.json',
        'shaders/volcanic.json',
        'shaders/rainforest.json',
        'shaders/snail.json',
        'shaders/voxel_edges.json',
        'shaders/mike.json'
      ];
      final adapter = newAdapter()
        ..addUserShadersRoute('user/iq_page_1.html', userId, siteOptions)
        ..addShadersRoute(shaders, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findShaderIdsByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(
          sr,
          findShaderIdsResponsetFixture(shaders,
              count: siteOptions.pageUserShaderCount));
    });
  });

  group('Comments', () {
    test('Find comments by shader id', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final shaderId = 'ldB3Dt';
      final fixture = 'comment/$shaderId.json';
      final adapter = newAdapter()
        ..addCommentRoute(fixture, shaderId, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findCommentsByShaderId(shaderId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.comments, isNotNull);
      expect(sr.comments, isNotEmpty);
      expect(
          sr,
          FindCommentsResponse(comments: [
            Comment(
                id: 'XlGcRK',
                userId: 'wosztal15',
                picture: '/media/users/wosztal15/profile.jpeg',
                date: DateTime.fromMillisecondsSinceEpoch(1599820652 * 1000),
                text: '\nI have to admit that it makes an amazing impression!',
                hidden: false),
            Comment(
                id: '4lGyzG',
                userId: 'Cubex',
                picture: '/media/users/Cubex/profile.png',
                date: DateTime.fromMillisecondsSinceEpoch(1599493658 * 1000),
                text: 'Woobly moobly, it\'s amazing!',
                hidden: false),
            Comment(
                id: 'Xd2GW1',
                userId: 'iq',
                picture: '/media/users/iq/profile.png',
                date: DateTime.fromMillisecondsSinceEpoch(1395074155 * 1000),
                text: 'Oh, I love it!',
                hidden: false),
          ]));
    });
  });

  group('Playlist', () {
    test('Find playlist by id', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final playlistId = 'week';
      final fixture = 'playlist/$playlistId.html';
      final adapter = newAdapter()
        ..addPlaylistRoute(fixture, playlistId, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.playlist, isNotNull);
      expect(
          sr,
          FindPlaylistResponse(
              playlist: Playlist(
                  id: playlistId,
                  userId: 'shadertoy',
                  name: 'Shaders of the Week',
                  description:
                      'Playlist with every single shader of the week ever.',
                  privacy: PlaylistPrivacy.public)));
    });

    test('Find shaders by playlist id', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final playlistId = 'week';
      final shaders = [
        'shaders/cables2.json',
        'shaders/ray_marching_experiment_43.json',
        'shaders/impulse_glass.json',
        'shaders/3d_cellular_tiling.json',
        'shaders/phyllotaxes.json',
        'shaders/geometric_cellular_surfaces.json',
        'shaders/ed_209.json',
        'shaders/hexpacked_sphere_bass_shader.json',
        'shaders/puma_clyde_concept.json',
        'shaders/asymmetric_hexagon_landscape.json',
        'shaders/worms.json',
        'shaders/primitive_portrait.json',
        'shaders/neon_tunnel.json',
        'shaders/hutger_rauer.json',
        'shaders/mushroom.json'
      ];
      final adapter = newAdapter()
        ..addPlaylistShadersRoute(
            'playlist/week_page_1.html', playlistId, siteOptions)
        ..addShadersRoute(shaders, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findShadersByPlaylistId(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shader ids by playlist id', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final playlistId = 'week';
      final shaders = [
        'shaders/cables2.json',
        'shaders/ray_marching_experiment_43.json',
        'shaders/impulse_glass.json',
        'shaders/3d_cellular_tiling.json',
        'shaders/phyllotaxes.json',
        'shaders/geometric_cellular_surfaces.json',
        'shaders/ed_209.json',
        'shaders/hexpacked_sphere_bass_shader.json',
        'shaders/puma_clyde_concept.json',
        'shaders/asymmetric_hexagon_landscape.json',
        'shaders/worms.json',
        'shaders/primitive_portrait.json',
        'shaders/neon_tunnel.json',
        'shaders/hutger_rauer.json',
        'shaders/mushroom.json'
      ];
      final adapter = newAdapter()
        ..addPlaylistShadersRoute(
            'playlist/week_page_1.html', playlistId, siteOptions)
        ..addShadersRoute(shaders, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.findShaderIdsByPlaylistId(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(
          sr,
          findShaderIdsResponsetFixture(shaders,
              count: siteOptions.pagePlaylistShaderCount));
    });
  });

  group('Downloads', () {
    test('Download shader picture', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final shaderId = 'XsX3RB';
      final media = 'media/shaders/$shaderId.jpg';
      final adapter = newAdapter()
        ..addDownloadShaderMedia(media, shaderId, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.downloadShaderPicture(shaderId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.bytes, isNotNull);
      expect(sr, downloadFileResponseFixture(media));
    });

    test('Download media', () async {
      // prepare
      final siteOptions = newSiteOptions();
      final media = 'img/profile.jpg';
      final adapter = newAdapter()..addDownloadFile(media, media, siteOptions);
      final api = newClient(adapter, siteOptions: siteOptions);
      // act
      var sr = await api.downloadMedia('/$media');
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.bytes, isNotNull);
      expect(sr, downloadFileResponseFixture(media));
    });
  });
}
