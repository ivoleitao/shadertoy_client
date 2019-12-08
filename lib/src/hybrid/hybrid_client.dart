import 'package:dio/dio.dart';
import 'package:shadertoy_api/shadertoy_api.dart';
import 'package:shadertoy_client/src/site/site_client.dart';
import 'package:shadertoy_client/src/site/site_options.dart';
import 'package:shadertoy_client/src/ws/ws_client.dart';
import 'package:shadertoy_client/src/ws/ws_options.dart';

/// A Shadertoy hybrid client
///
/// An implementation of the [ShadertoyWS] and [ShadertoySite] APIs
/// providing the full set of methods either through the [ShadertoySite] implementation
/// or through the [ShadertoyWS] implementation first then falling back to the [ShadertoySite]
/// implementation. This provides an implementation that provides the same set of shaders available
/// through the REST API (public+api privacy settings) complementing those with additional methods
/// available through the site implementation
class ShadertoyHybridClient extends ShadertoyBaseClient
    implements ShadertoySite, ShadertoyWS {
  /// The site client
  ShadertoySiteClient _siteClient;

  /// The hybrid client (either an instance of [ShadertoySite] or [ShadertoyWS] if provided)
  ShadertoyClient _hybridClient;

  /// Builds a [ShadertoyHybridClient]
  ///
  /// * [siteOptions]: Options for site client
  /// * [wsOptions]: Options for the REST client
  /// * [client]: A dio client instance
  ShadertoyHybridClient(ShadertoySiteOptions siteOptions,
      {ShadertoyWSOptions wsOptions, Dio client}) {
    client ??= Dio(BaseOptions(baseUrl: context.baseUrl));
    _hybridClient =
        _siteClient = ShadertoySiteClient(siteOptions, client: client);
    if (wsOptions != null) {
      _hybridClient = ShadertoyWSClient(wsOptions, client: client);
    }
  }

  /// Builds a [ShadertoyHybridClient]
  ///
  /// * [user]: The user name
  /// * [password]: The user password
  /// * [apiKey]: The API key
  ShadertoyHybridClient.build({String user, String password, String apiKey})
      : this(ShadertoySiteOptions(user: user, password: password),
            wsOptions:
                apiKey != null ? ShadertoyWSOptions(apiKey: apiKey) : null);

  @override
  Future<FindShaderResponse> findShaderById(String shaderId) {
    return _hybridClient.findShaderById(shaderId);
  }

  @override
  Future<FindShadersResponse> findShadersByIdSet(Set<String> shaderIds) {
    return _hybridClient.findShadersByIdSet(shaderIds);
  }

  @override
  Future<FindShadersResponse> findShaders(
      {String term, Set<String> filters, Sort sort, int from, int num}) {
    return _hybridClient.findShaders(
        term: term, filters: filters, sort: sort, from: from, num: num);
  }

  @override
  Future<FindShaderIdsResponse> findAllShaderIds() {
    return _hybridClient.findAllShaderIds();
  }

  @override
  Future<FindShaderIdsResponse> findShaderIds(
      {String term, Set<String> filters, Sort sort, int from, int num}) {
    return _hybridClient.findShaderIds(
        term: term, filters: filters, sort: sort, from: from, num: num);
  }

  @override
  Future<FindUserResponse> findUserById(String userId) {
    return _siteClient.findUserById(userId);
  }

  @override
  Future<FindShadersResponse> findShadersByUserId(String userId,
      {Set<String> filters, Sort sort, int from, int num}) {
    return _siteClient.findShadersByUserId(userId,
        filters: filters, sort: sort, from: from, num: num);
  }

  @override
  Future<FindShaderIdsResponse> findShaderIdsByUserId(String userId,
      {Set<String> filters, Sort sort, int from, int num}) {
    return _siteClient.findShaderIdsByUserId(userId,
        filters: filters, sort: sort, from: from, num: num);
  }

  @override
  Future<FindCommentsResponse> findCommentsByShaderId(String shaderId) {
    return _siteClient.findCommentsByShaderId(shaderId);
  }

  @override
  Future<FindPlaylistResponse> findPlaylistById(String playlistId) {
    return _siteClient.findPlaylistById(playlistId);
  }

  @override
  Future<FindShadersResponse> findShadersByPlaylistId(String playlistId,
      {int from, int num}) {
    return _siteClient.findShadersByPlaylistId(playlistId,
        from: from, num: num);
  }

  @override
  Future<FindShaderIdsResponse> findShaderIdsByPlaylistId(String playlistId,
      {int from, int num}) {
    return _siteClient.findShaderIdsByPlaylistId(playlistId,
        from: from, num: num);
  }

  @override
  Future<LoginResponse> login() {
    return _siteClient.login();
  }

  @override
  Future<LogoutResponse> logout() {
    return _siteClient.logout();
  }

  @override
  Future<DownloadFileResponse> downloadShaderPicture(String shaderId) {
    return _siteClient.downloadShaderPicture(shaderId);
  }

  @override
  Future<DownloadFileResponse> downloadMedia(String inputPath) {
    return _siteClient.downloadMedia(inputPath);
  }
}
