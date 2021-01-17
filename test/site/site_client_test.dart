import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/shadertoy_client.dart';
import 'package:test/test.dart';

import '../fixtures/fixtures.dart';
import '../mock_adapter.dart';
import 'site_mock_adapter.dart';

void main() {
  MockAdapter newAdapter(ShadertoySiteOptions options) {
    return MockAdapter();
  }

  ShadertoySiteOptions newOptions([ShadertoySiteOptions options]) {
    return options != null
        ? options.copyWith(baseUrl: MockAdapter.mockBase)
        : ShadertoySiteOptions(baseUrl: MockAdapter.mockBase);
  }

  ShadertoySiteClient newClient(
      ShadertoySiteOptions options, HttpClientAdapter adapter) {
    final client = Dio(BaseOptions(baseUrl: MockAdapter.mockBase))
      ..httpClientAdapter = adapter;

    return ShadertoySiteClient(options, client: client);
  }

  group('Authentication', () {
    test('Login with correct credentials', () async {
      // prepare
      final user = 'user';
      final password = 'password';
      final options =
          newOptions(ShadertoySiteOptions(user: user, password: password));
      final nowPlusOneDay = DateTime.now().add(Duration(days: 1));
      final formatter = DateFormat('EEE, dd-MMM-yyyy HH:mm:ss');
      final expires = formatter.format(nowPlusOneDay);
      final adapter = newAdapter(options)
        ..addLoginRoute(options, 302, {
          HttpHeaders.setCookieHeader: [
            'sdtd=4e9dcd95663b58540ac7aa1dc3f0b914; expires=$expires GMT; Max-Age=1209600; path=/; secure; HttpOnly',
          ],
          HttpHeaders.locationHeader: ['/']
        });
      final api = newClient(options, adapter);
      // act
      var sr = await api.login();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(api.loggedIn, isTrue);
    });

    test('Login with wrong credentials', () async {
      // prepare
      final user = 'user';
      final password = 'password';
      final options =
          newOptions(ShadertoySiteOptions(user: user, password: password));
      final adapter = newAdapter(options)
        ..addLoginRoute(options, 302, {
          HttpHeaders.locationHeader: [
            '/${ShadertoyContext.SignInPath}?error=1'
          ]
        });
      final api = newClient(options, adapter);
      // act
      var sr = await api.login();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(api.loggedIn, isFalse);
      expect(
          sr.error,
          ResponseError.authentication(
              message: 'Login error',
              context: CONTEXT_USER,
              target: options.user));
    });

    test('Login with missing location header', () async {
      // prepare
      final user = 'user';
      final password = 'password';
      final options =
          newOptions(ShadertoySiteOptions(user: user, password: password));
      final adapter = newAdapter(options)..addLoginRoute(options, 302, {});
      final api = newClient(options, adapter);
      // act
      var sr = await api.login();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(api.loggedIn, isFalse);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'Invalid location header',
              context: CONTEXT_USER,
              target: options.user));
    });

    test('Login with Dio error', () async {
      // prepare
      final user = 'user';
      final password = 'password';
      final options =
          newOptions(ShadertoySiteOptions(user: user, password: password));
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addLoginSocketErrorRoute(options, message);
      final api = newClient(options, adapter);
      // act
      var lr = await api.login();
      // assert
      expect(lr, isNotNull);
      expect(lr.error, isNotNull);
      expect(
          lr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_USER,
              target: user));
    });

    test('Logout without login', () async {
      // prepare
      final options = newOptions(ShadertoySiteOptions());
      final adapter = newAdapter(options);
      final api = newClient(options, adapter);
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
      final options =
          newOptions(ShadertoySiteOptions(user: user, password: password));
      final nowPlusOneDay = DateTime.now().add(Duration(days: 1));
      final formatter = DateFormat('EEE, dd-MMM-yyyy HH:mm:ss');
      final expires = formatter.format(nowPlusOneDay);
      final adapter = newAdapter(options)
        ..addLoginRoute(options, 302, {
          HttpHeaders.setCookieHeader: [
            'sdtd=4e9dcd95663b58540ac7aa1dc3f0b914; expires=$expires GMT; Max-Age=1209600; path=/; secure; HttpOnly',
          ],
          HttpHeaders.locationHeader: ['/']
        })
        ..addLogoutRoute(options, 302, {
          HttpHeaders.setCookieHeader: [
            'sdtd=deleted; expires=Thu, 01-Jan-1970 00:00:01 GMT; Max-Age=0; path=/; secure; httponly',
          ],
          HttpHeaders.locationHeader: ['/']
        });
      final api = newClient(options, adapter);
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

    test('Dio logout error with login', () async {
      // prepare
      final user = 'user';
      final password = 'password';
      final options =
          newOptions(ShadertoySiteOptions(user: user, password: password));
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final nowPlusOneDay = DateTime.now().add(Duration(days: 1));
      final formatter = DateFormat('EEE, dd-MMM-yyyy HH:mm:ss');
      final expires = formatter.format(nowPlusOneDay);
      final adapter = newAdapter(options)
        ..addLoginRoute(options, 302, {
          HttpHeaders.setCookieHeader: [
            'sdtd=4e9dcd95663b58540ac7aa1dc3f0b914; expires=$expires GMT; Max-Age=1209600; path=/; secure; HttpOnly',
          ],
          HttpHeaders.locationHeader: ['/']
        })
        ..addLogoutSocketErrorRoute(options, message);
      final api = newClient(options, adapter);
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
      expect(lor.error, isNotNull);
      expect(
          lor.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_USER,
              target: user));
    });
  });

  group('Shaders', () {
    test('Find shader by id', () async {
      // prepare
      final options = ShadertoySiteOptions();
      final shaders = ['shaders/seascape.json'];
      final adapter = newAdapter(options)..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaderById('Ms2SD1');
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.shader, isNotNull);
      expect(sr, findShaderResponseFixture('shaders/seascape.json'));
    });

    test('Find shader by id with not found response', () async {
      // prepare
      final options = newOptions();
      final shaders = ['shaders/seascape.json'];
      final adapter = newAdapter(options)
        ..addShadersRoute(shaders, options, responseFixturePath: <String>[]);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaderById('Ms2SD1');
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.shader, isNull);
      expect(
          sr.error,
          ResponseError.notFound(
              message: 'Shader not found',
              context: CONTEXT_SHADER,
              target: 'Ms2SD1'));
    });

    test('Find shader by id with Dio error', () async {
      // prepare
      final options = newOptions();
      final shaders = ['shaders/seascape.json'];
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addShadersSocketErrorRoute(shaders, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaderById('Ms2SD1');
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.shader, isNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_SHADER,
              target: 'Ms2SD1'));
    });

    test('Find shaders by id set with one result', () async {
      // prepare
      final options = newOptions();
      final shaders = ['shaders/seascape.json'];
      final adapter = newAdapter(options)..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByIdSet({'Ms2SD1'});
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by id set with two results', () async {
      // prepare
      final options = newOptions();
      final shaders = ['shaders/seascape.json', 'shaders/happy_jumping.json'];
      final adapter = newAdapter(options)..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByIdSet({'Ms2SD1', '3lsSzf'});
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by id set with Dio error', () async {
      // prepare
      final options = newOptions();
      final shaders = ['shaders/seascape.json', 'shaders/happy_jumping.json'];
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addShadersSocketErrorRoute(shaders, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByIdSet({'Ms2SD1', '3lsSzf'});
      // assert
      expect(sr, isNotNull);
      expect(sr.shaders, isNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message', context: CONTEXT_SHADER));
    });

    test('Find shaders', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addResultsRoute('results/normal.html', options)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders with no html body', () async {
      // prepare
      final options = newOptions();
      final adapter = newAdapter(options)
        ..addResultsRoute('error/no_body.html', options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Unexpected HTML response body: '));
    });

    test('Find shaders with an unparsable number of results', () async {
      // prepare
      final options = newOptions();
      final adapter = newAdapter(options)
        ..addResultsRoute('results/unparsable_number_of_results.html', options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Unable to parse the number of results'));
    });

    test('Find shaders with an invalid number of results', () async {
      // prepare
      final options = newOptions();
      final adapter = newAdapter(options)
        ..addResultsRoute('results/invalid_number_of_results.html', options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Obtained an invalid number of results: -1'));
    });

    test('Find shaders with no script blocks', () async {
      // prepare
      final options = newOptions();
      final adapter = newAdapter(options)
        ..addResultsRoute('results/no_script_blocks.html', options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Unable to get the script blocks from the document'));
    });

    test('Find shaders with no script block match', () async {
      // prepare
      final options = newOptions();
      final adapter = newAdapter(options)
        ..addResultsRoute('results/no_script_block_match.html', options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message:
                  'No script block matches with "${ShadertoySiteClient.IdArrayRegExp.pattern}" pattern'));
    });

    test('Find shaders with Dio error', () async {
      // prepare
      final options = newOptions();
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addResultsSocketErrorRoute(options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders();
      // assert
      expect(sr, isNotNull);
      expect(sr.shaders, isNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message', context: CONTEXT_SHADER));
    });

    test('Find shaders with query, one result', () async {
      // prepare
      final options = newOptions();
      final query = 'raymarch';
      final sort = Sort.love;
      final filters = {'vr', 'soundoutput', 'multipass'};
      final shaders = ['shaders/kurogane.json'];
      final adapter = newAdapter(options)
        ..addResultsRoute('results/filtered_1_result.html', options,
            query: query, sort: sort, filters: filters)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders(term: query, sort: sort, filters: filters);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders with query, first page', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addResultsRoute('results/filtered_page_1.html', options,
            query: query, sort: sort, filters: filters, from: from)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders(
          term: query, sort: sort, filters: filters, from: from);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders with query, second page', () async {
      // prepare
      final options = newOptions();
      final query = 'raymarch';
      final sort = Sort.love;
      final filters = {'multipass'};
      final from = options.pageResultsShaderCount;
      final num = options.pageResultsShaderCount;
      final shaders = [
        'shaders/homeward.json',
        'shaders/surfer_boy.json',
        'shaders/alien_corridor.json',
        'shaders/turn_burn.json',
        'shaders/ice_primitives.json',
        'shaders/basic_montecarlo.json',
        'shaders/crossy_penguin.json',
        'shaders/full_scene_radial_blur.json',
        'shaders/fractal_explorer_multi_res.json',
        'shaders/blueprint_of_architekt.json',
        'shaders/three_pass_dof.json',
        'shaders/multiple_transparency.json',
      ];
      final adapter = newAdapter(options)
        ..addResultsRoute('results/filtered_page_2.html', options,
            query: query, sort: sort, filters: filters, from: from, num: num)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders(
          term: query, sort: sort, filters: filters, from: from);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders with query, second and third page', () async {
      // prepare
      final options = newOptions();
      final query = 'raymarch';
      final sort = Sort.love;
      final filters = {'multipass'};
      final from = options.pageResultsShaderCount;
      final num = options.pageResultsShaderCount;
      final shaders = [
        'shaders/homeward.json',
        'shaders/surfer_boy.json',
        'shaders/alien_corridor.json',
        'shaders/turn_burn.json',
        'shaders/ice_primitives.json',
        'shaders/basic_montecarlo.json',
        'shaders/crossy_penguin.json',
        'shaders/full_scene_radial_blur.json',
        'shaders/fractal_explorer_multi_res.json',
        'shaders/blueprint_of_architekt.json',
        'shaders/three_pass_dof.json',
        'shaders/multiple_transparency.json',
        'shaders/sunset_drive_unlimited.json',
        'shaders/80s_raymarching.json',
        'shaders/veach_1997_fig_9_4.json',
        'shaders/raymarching_reaction_diffusion.json',
        'shaders/castaway.json',
        'shaders/julia_quaternion_3.json',
        'shaders/lets_make_a_raymarcher.json',
        'shaders/aurora_explorer.json',
        'shaders/frozen_barrens.json',
        'shaders/go_go_legoman.json',
        'shaders/post_processing_toon_shading.json'
      ];
      final adapter = newAdapter(options)
        ..addResultsRoute('results/filtered_page_2.html', options,
            query: query, sort: sort, filters: filters, from: from, num: num)
        ..addResultsRoute('results/filtered_page_3.html', options,
            query: query,
            sort: sort,
            filters: filters,
            from: from * 2,
            num: num)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaders(
          term: query, sort: sort, filters: filters, from: from, num: num * 2);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find all shader ids', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addResultsRoute('results/24_page_1.html', options)
        ..addResultsRoute('results/24_page_2.html', options, from: 12, num: 12);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findAllShaderIds();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShaderIdsResponsetFixture(shaders, count: 24));
    });

    test('Find all shader ids with Dio error on the first page', () async {
      // prepare
      final options = newOptions();
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addResultsSocketErrorRoute(options, message)
        ..addResultsRoute('results/24_page_2.html', options, from: 12, num: 12);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findAllShaderIds();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message', context: CONTEXT_SHADER));
    });

    test('Find all shader ids with Dio error on the second page', () async {
      // prepare
      final options = newOptions();
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addResultsRoute('results/24_page_1.html', options)
        ..addResultsSocketErrorRoute(options, message, from: 12, num: 12);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findAllShaderIds();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message', context: CONTEXT_SHADER));
    });

    test(
        'Find all shader ids with an unparsable number of results on the second page',
        () async {
      // prepare
      final options = newOptions();
      final adapter = newAdapter(options)
        ..addResultsRoute('results/24_page_1.html', options)
        ..addResultsRoute(
            'results/24_page_2_invalid_number_of_results.html', options,
            from: 12, num: 12);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findAllShaderIds();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message:
                  'Page 2 of 2 page(s) was not successfully fetched: Obtained an invalid number of results: -1'));
    });

    test('Find shader ids', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addResultsRoute('results/normal.html', options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaderIds();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShaderIdsResponsetFixture(shaders, count: 43698));
    });

    test('Find shader ids with Dio error', () async {
      // prepare
      final options = newOptions();
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addResultsSocketErrorRoute(options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaderIds();
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message', context: CONTEXT_SHADER));
    });
  });

  group('Users', () {
    test('Find user iq by id', () async {
      // prepare
      final options = newOptions();
      final userId = 'iq';
      final fixture = 'user/$userId.html';
      final adapter = newAdapter(options)
        ..addUserRoute(fixture, userId, options);
      final api = newClient(options, adapter);
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

    test('Find user shaderflix by id', () async {
      // prepare
      final options = newOptions();
      final userId = 'shaderflix';
      final fixture = 'user/$userId.html';
      final adapter = newAdapter(options)
        ..addUserRoute(fixture, userId, options);
      final api = newClient(options, adapter);
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
                  memberSince: DateTime(2019, 7, 20),
                  following: 0,
                  followers: 0,
                  about:
                      '\n\n[b]b[/b]\n[i]i[/i]\n[url]http://www.url.com[/url]\n[url=http://www.url.com]My Url[/url]\n[code]c[/code]\n:)\n:(\n:D\n:love:\n:octopus:\n:octopusballoon:\n:alpha:\n:beta:\n:delta\n:epsilon:\n:nabla:\n:square:\n:limit:\nplain')));
    });

    test('Find user by id with not found response', () async {
      // prepare
      final options = newOptions();
      final userId = 'XXXX';
      final user = 'user/$userId';
      final error = 'Http status error [404]';
      final adapter = newAdapter(options)
        ..addResponseErrorRoute(user, error, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findUserById(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.user, isNull);
      expect(
          sr.error,
          ResponseError.notFound(
              message: error, context: CONTEXT_USER, target: userId));
    });

    test('Find user by id with empty response', () async {
      // prepare
      final options = newOptions();
      final userId = 'XXXX';
      final adapter = newAdapter(options)
        ..addUserRoute('error/no_body.html', userId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findUserById(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.user, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Unexpected HTML response body: ',
              context: CONTEXT_USER,
              target: userId));
    });

    test('Find user by id with an invalid number of sections', () async {
      // prepare
      final options = newOptions();
      final userId = 'XXXX';
      final adapter = newAdapter(options)
        ..addUserRoute('user/invalid_no_sections.html', userId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findUserById(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.user, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Obtained an invalid number of user sections: 2',
              context: CONTEXT_USER,
              target: userId));
    });

    test('Find user by id with Dio error', () async {
      // prepare
      final options = newOptions();
      final userId = 'shaderflix';
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addUserSocketErrorRoute(userId, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findUserById(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_USER,
              target: userId));
    });

    test('Find shaders by user id with Dio error', () async {
      // prepare
      final options = newOptions();
      final userId = 'shaderflix';
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addUserShadersSocketErrorRoute(userId, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_USER,
              target: userId));
    });

    test('Find shaders by user id with no body', () async {
      // prepare
      final options = newOptions();
      final userId = 'shaderflix';
      final adapter = newAdapter(options)
        ..addUserShadersRoute('error/no_body.html', userId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.shaders, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Unexpected HTML response body: ',
              context: CONTEXT_USER,
              target: userId));
    });

    test('Find shaders by user id with no results', () async {
      // prepare
      final options = newOptions();
      final userId = 'shaderflix';
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/no_shaders.html', userId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture([]));
    });

    test('Find shaders by user id with one result', () async {
      // prepare
      final options = newOptions();
      final userId = 'bonzaj';
      final shaders = ['shaders/julia_bonzaj_mod1.json'];
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/one_shader_1.html', userId, options)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by user id with query, one result', () async {
      // prepare
      final options = newOptions();
      final userId = 'iq';
      final sort = Sort.popular;
      final filters = {'multipass', 'musicstream'};
      final shaders = ['shaders/bricks_game.json'];
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/one_shader_2.html', userId, options,
            sort: sort, filters: filters)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr =
          await api.findShadersByUserId(userId, sort: sort, filters: filters);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by user id, first page', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/iq_page_1.html', userId, options)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by user id, second page', () async {
      // prepare
      final options = newOptions();
      final userId = 'iq';
      final from = 8;
      final num = options.pageUserShaderCount;
      final shaders = [
        'shaders/warping_procedural_2.json',
        'shaders/happy_jumping.json',
        'shaders/cubescape.json',
        'shaders/cloudy_terrain.json',
        'shaders/voronoi_distances.json',
        'shaders/music_pirates.json',
        'shaders/voronoise.json',
        'shaders/palletes.json'
      ];
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/iq_page_2.html', userId, options,
            from: from, num: num)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByUserId(userId, from: from, num: num);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by user id, first and second page', () async {
      // prepare
      final options = newOptions();
      final userId = 'iq';
      final from = 0;
      final num = options.pageUserShaderCount;
      final shaders = [
        'shaders/raymarching_primitives.json',
        'shaders/clouds.json',
        'shaders/elevated.json',
        'shaders/volcanic.json',
        'shaders/rainforest.json',
        'shaders/snail.json',
        'shaders/voxel_edges.json',
        'shaders/mike.json',
        'shaders/warping_procedural_2.json',
        'shaders/happy_jumping.json',
        'shaders/cubescape.json',
        'shaders/cloudy_terrain.json',
        'shaders/voronoi_distances.json',
        'shaders/music_pirates.json',
        'shaders/voronoise.json',
        'shaders/palletes.json'
      ];
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/iq_page_1.html', userId, options,
            from: from, num: num)
        ..addUserShadersRoute('user/iq_page_2.html', userId, options,
            from: options.pageUserShaderCount, num: num)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByUserId(userId, from: from, num: num * 2);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test(
        'Find shaders by user id with an unparsable number of results on the second page',
        () async {
      // prepare
      final options = newOptions();
      final userId = 'iq';
      final from = 0;
      final num = options.pageUserShaderCount;
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/iq_page_1.html', userId, options,
            from: from, num: num)
        ..addUserShadersRoute(
            'user/iq_page_2_invalid_number_of_results.html', userId, options,
            from: options.pageUserShaderCount, num: num);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByUserId(userId, from: from, num: num * 2);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message:
                  'Page 2 of 2 page(s) was not successfully fetched: Obtained an invalid number of results: -1',
              context: CONTEXT_USER,
              target: userId));
    });

    test('Find shaders by user id, second and third page', () async {
      // prepare
      final options = newOptions();
      final userId = 'iq';
      final from = 8;
      final num = options.pageUserShaderCount;
      final shaders = [
        'shaders/warping_procedural_2.json',
        'shaders/happy_jumping.json',
        'shaders/cubescape.json',
        'shaders/cloudy_terrain.json',
        'shaders/voronoi_distances.json',
        'shaders/music_pirates.json',
        'shaders/voronoise.json',
        'shaders/palletes.json',
        'shaders/sphere_projection.json',
        'shaders/bricks_game.json',
        'shaders/dolphin.json',
        'shaders/nv15_space_curvature.json',
        'shaders/menger_sponge.json',
        'shaders/monster.json',
        'shaders/canyon.json',
        'shaders/ladybug.json'
      ];
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/iq_page_2.html', userId, options,
            from: from, num: num)
        ..addUserShadersRoute('user/iq_page_3.html', userId, options,
            from: from * 2, num: num)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByUserId(userId, from: from, num: num * 2);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shader ids by user id, first page', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/iq_page_1.html', userId, options)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaderIdsByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(
          sr,
          findShaderIdsResponsetFixture(shaders,
              count: options.pageUserShaderCount));
    });

    test('Find shader ids by user id with Dio error', () async {
      // prepare
      final options = newOptions();
      final userId = 'iq';
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addUserShadersSocketErrorRoute(userId, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaderIdsByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_USER,
              target: userId));
    });

    test('Find all shader ids by user id', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addUserShadersRoute('user/iq_all.html', userId, options)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findAllShaderIdsByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(
          sr,
          findShaderIdsResponsetFixture(shaders,
              count: options.pageUserShaderCount));
    });

    test('Find all shader ids by user id with Dio error', () async {
      // prepare
      final options = newOptions();
      final userId = 'iq';
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addUserShadersSocketErrorRoute(userId, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findAllShaderIdsByUserId(userId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_USER,
              target: userId));
    });
  });

  group('Comments', () {
    test('Find comments by shader id', () async {
      // prepare
      final options = newOptions();
      final shaderId = 'ldB3Dt';
      final fixture = 'comment/$shaderId.json';
      final adapter = newAdapter(options)
        ..addCommentRoute(fixture, shaderId, options);
      final api = newClient(options, adapter);
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

    test('Find comments by shader id with Dio error', () async {
      // prepare
      final options = newOptions();
      final shaderId = 'ldB3Dt';
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addCommentSocketErrorRoute(shaderId, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findCommentsByShaderId(shaderId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.comments, isNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_COMMENT,
              target: shaderId));
    });
  });

  group('Playlist', () {
    test('Find playlist by id', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final fixture = 'playlist/$playlistId.html';
      final adapter = newAdapter(options)
        ..addPlaylistRoute(fixture, playlistId, options);
      final api = newClient(options, adapter);
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

    test('Find playlist by id with not found response', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'XXXX';
      final playlist = 'playlist/$playlistId';
      final error = 'Http status error [404]';
      final adapter = newAdapter(options)
        ..addResponseErrorRoute(playlist, error, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.playlist, isNull);
      expect(
          sr.error,
          ResponseError.notFound(
              message: error, context: CONTEXT_PLAYLIST, target: playlistId));
    });

    test('Find playlist by id with empty response', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'XXXX';
      final adapter = newAdapter(options)
        ..addPlaylistRoute('error/no_body.html', playlistId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.playlist, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Unexpected HTML response body: ',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find playlist by id with Dio error', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addPlaylistSocketErrorRoute(playlistId, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find playlist by id with an invalid name', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'XXXX';
      final adapter = newAdapter(options)
        ..addPlaylistRoute('playlist/invalid_name.html', playlistId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.playlist, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Unable to get the playlist name from the document',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find playlist by id with an invalid description', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'XXXX';
      final adapter = newAdapter(options)
        ..addPlaylistRoute(
            'playlist/invalid_description.html', playlistId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.playlist, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message:
                  'Unable to get the playlist description from the document',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find playlist by id with an invalid user id', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'XXXX';
      final adapter = newAdapter(options)
        ..addPlaylistRoute(
            'playlist/invalid_user_id.html', playlistId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.playlist, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Unable to get the playlist user id from the document',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find playlist by id with an invalid privacy section', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'XXXX';
      final adapter = newAdapter(options)
        ..addPlaylistRoute(
            'playlist/invalid_privacy_section.html', playlistId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.playlist, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message:
                  'Unable to get the playlist publish status and shader count from the document',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find playlist by id with an invalid publish status', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'XXXX';
      final adapter = newAdapter(options)
        ..addPlaylistRoute(
            'playlist/invalid_publish_status.html', playlistId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.playlist, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message:
                  'Unable to parse playlist publish status and shader count from the document',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find playlist by id with an invalid shader count', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'XXXX';
      final adapter = newAdapter(options)
        ..addPlaylistRoute(
            'playlist/invalid_shader_count.html', playlistId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findPlaylistById(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(sr.playlist, isNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message:
                  'Unable to parse playlist publish status and shader count from the document',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find shaders by playlist id, first page', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addPlaylistShadersRoute(
            'playlist/week_page_1.html', playlistId, options)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByPlaylistId(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by playlist id, second page', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final from = options.pagePlaylistShaderCount;
      final num = options.pagePlaylistShaderCount;
      final shaders = [
        'shaders/not_day_79.json',
        'shaders/molten_bismuth.json',
        'shaders/snaliens.json',
        'shaders/warped_extruded_skewed_grid.json',
        'shaders/atari_pong.json',
        'shaders/surfer_boy.json',
        'shaders/enterprise.json',
        'shaders/underground_passageway.json',
        'shaders/octahydra.json',
        'shaders/tree_in_the_wind.json',
        'shaders/piranha_plant.json',
        'shaders/echeveria.json',
        'shaders/fractal_explorer.json',
        'shaders/fly_on_buckaroo.json',
        'shaders/re_entry.json'
      ];
      final adapter = newAdapter(options)
        ..addPlaylistShadersRoute(
            'playlist/week_page_2.html', playlistId, options,
            from: from, num: num)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr =
          await api.findShadersByPlaylistId(playlistId, from: from, num: num);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by playlist id, first and second page', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final from = 0;
      final num = options.pagePlaylistShaderCount;
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
        'shaders/mushroom.json',
        'shaders/not_day_79.json',
        'shaders/molten_bismuth.json',
        'shaders/snaliens.json',
        'shaders/warped_extruded_skewed_grid.json',
        'shaders/atari_pong.json',
        'shaders/surfer_boy.json',
        'shaders/enterprise.json',
        'shaders/underground_passageway.json',
        'shaders/octahydra.json',
        'shaders/tree_in_the_wind.json',
        'shaders/piranha_plant.json',
        'shaders/echeveria.json',
        'shaders/fractal_explorer.json',
        'shaders/fly_on_buckaroo.json',
        'shaders/re_entry.json'
      ];
      final adapter = newAdapter(options)
        ..addPlaylistShadersRoute(
            'playlist/week_page_1.html', playlistId, options,
            from: from, num: num)
        ..addPlaylistShadersRoute(
            'playlist/week_page_2.html', playlistId, options,
            from: options.pagePlaylistShaderCount, num: num)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByPlaylistId(playlistId,
          from: from, num: num * 2);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test(
        'Find shaders by playlist id with an unparsable number of results on the first page',
        () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final from = 0;
      final num = options.pagePlaylistShaderCount;
      final adapter = newAdapter(options)
        ..addPlaylistShadersRoute(
            'playlist/week_page_1_invalid_number_of_results.html',
            playlistId,
            options,
            from: from,
            num: num);
      final api = newClient(options, adapter);
      // act
      var sr =
          await api.findShadersByPlaylistId(playlistId, from: from, num: num);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message: 'Obtained an invalid number of results: -1',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test(
        'Find shaders by playlist id with an unparsable number of results on the second page',
        () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final from = 0;
      final num = options.pagePlaylistShaderCount;
      final adapter = newAdapter(options)
        ..addPlaylistShadersRoute(
            'playlist/week_page_1.html', playlistId, options,
            from: from, num: num)
        ..addPlaylistShadersRoute(
            'playlist/week_page_2_invalid_number_of_results.html',
            playlistId,
            options,
            from: options.pagePlaylistShaderCount,
            num: num);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByPlaylistId(playlistId,
          from: from, num: num * 2);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.backendResponse(
              message:
                  'Page 2 of 2 page(s) was not successfully fetched: Obtained an invalid number of results: -1',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find shaders by playlist id, second and third page', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final from = options.pagePlaylistShaderCount;
      final num = options.pagePlaylistShaderCount;
      final shaders = [
        'shaders/not_day_79.json',
        'shaders/molten_bismuth.json',
        'shaders/snaliens.json',
        'shaders/warped_extruded_skewed_grid.json',
        'shaders/atari_pong.json',
        'shaders/surfer_boy.json',
        'shaders/enterprise.json',
        'shaders/underground_passageway.json',
        'shaders/octahydra.json',
        'shaders/tree_in_the_wind.json',
        'shaders/piranha_plant.json',
        'shaders/echeveria.json',
        'shaders/fractal_explorer.json',
        'shaders/fly_on_buckaroo.json',
        'shaders/re_entry.json',
        'shaders/shine_on_you_crazy_ball.json',
        'shaders/descent_3d.json',
        'shaders/waterfall_procedural_gfx.json',
        'shaders/abandoned_construction.json',
        'shaders/voxel_game_evolution.json',
        'shaders/sync_cord_revision_2020.json',
        'shaders/psx_rendering.json',
        'shaders/corridor_travel.json',
        'shaders/tempting_the_mariner.json',
        'shaders/day_74.json',
        'shaders/blurry_spheres.json',
        'shaders/echeveria_2.json',
        'shaders/triangulated_heightfield_trick_2.json',
        'shaders/ball_room_dance.json',
        'shaders/day_43.json'
      ];
      final adapter = newAdapter(options)
        ..addPlaylistShadersRoute(
            'playlist/week_page_2.html', playlistId, options,
            from: from, num: num)
        ..addPlaylistShadersRoute(
            'playlist/week_page_3.html', playlistId, options,
            from: from * 2, num: num)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByPlaylistId(playlistId,
          from: from, num: num * 2);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr, findShadersResponseFixture(shaders));
    });

    test('Find shaders by playlist id with Dio error', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addPlaylistShadersSocketErrorRoute(playlistId, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShadersByPlaylistId(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find shader ids by playlist id, first page', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addPlaylistShadersRoute(
            'playlist/week_page_1.html', playlistId, options)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaderIdsByPlaylistId(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(
          sr,
          findShaderIdsResponsetFixture(shaders,
              count: options.pagePlaylistShaderCount));
    });

    test('Find shader ids by playlist id with Dio error', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addPlaylistShadersSocketErrorRoute(playlistId, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findShaderIdsByPlaylistId(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });

    test('Find all shader ids by playlist id', () async {
      // prepare
      final options = newOptions();
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
      final adapter = newAdapter(options)
        ..addPlaylistShadersRoute('playlist/week_all.html', playlistId, options)
        ..addShadersRoute(shaders, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findAllShaderIdsByPlaylistId(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(
          sr,
          findShaderIdsResponsetFixture(shaders,
              count: options.pagePlaylistShaderCount));
    });

    test('Find all shader ids by playlist id with Dio error', () async {
      // prepare
      final options = newOptions();
      final playlistId = 'week';
      final message = 'Failed host lookup: \'www.shadertoy.com\'';
      final adapter = newAdapter(options)
        ..addPlaylistShadersSocketErrorRoute(playlistId, options, message);
      final api = newClient(options, adapter);
      // act
      var sr = await api.findAllShaderIdsByPlaylistId(playlistId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.unknown(
              message: 'SocketException: $message',
              context: CONTEXT_PLAYLIST,
              target: playlistId));
    });
  });

  group('Downloads', () {
    test('Download shader picture', () async {
      // prepare
      final options = newOptions();
      final shaderId = 'XsX3RB';
      final media = 'media/shaders/$shaderId.jpg';
      final adapter = newAdapter(options)
        ..addDownloadShaderMedia(media, shaderId, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.downloadShaderPicture(shaderId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.bytes, isNotNull);
      expect(sr, downloadFileResponseFixture(media));
    });

    test('Download non existing shader picture', () async {
      // prepare
      final options = newOptions();
      final shaderId = 'XsXxXxX';
      final media = 'media/shaders/$shaderId.jpg';
      final error = 'Http status error [404]';
      final adapter = newAdapter(options)
        ..addResponseErrorRoute(media, error, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.downloadShaderPicture(shaderId);
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error,
          ResponseError.notFound(
              message: error, context: CONTEXT_SHADER, target: shaderId));
    });

    test('Download media', () async {
      // prepare
      final options = newOptions();
      final media = 'img/profile.jpg';
      final adapter = newAdapter(options)
        ..addDownloadFile(media, media, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.downloadMedia('/$media');
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNull);
      expect(sr.bytes, isNotNull);
      expect(sr, downloadFileResponseFixture(media));
    });

    test('Download non existing media', () async {
      // prepare
      final options = newOptions();
      final media = 'img/profile.jpg';
      final error = 'Http status error [404]';
      final adapter = newAdapter(options)
        ..addResponseErrorRoute(media, error, options);
      final api = newClient(options, adapter);
      // act
      var sr = await api.downloadMedia('/$media');
      // assert
      expect(sr, isNotNull);
      expect(sr.error, isNotNull);
      expect(
          sr.error, ResponseError.notFound(message: error, target: '/$media'));
    });
  });
}
