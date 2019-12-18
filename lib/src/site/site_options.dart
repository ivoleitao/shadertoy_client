import 'package:shadertoy_client/src/client_options.dart';

/// Options for the Shadertoy site client
///
/// Stores the options used to build a [ShadertoySiteClient]
class ShadertoySiteOptions extends ShadertoyClientOptions {
  /// The default number of shaders presented in the Shadertoy
  /// results [page](https://www.shadertoy.com/browse)
  static const int DefaultPageResultsShaderCount = 12;

  /// The default number of shaders presented in the Shadertoy
  /// user, for example iq user page as seen in
  /// [here](https://www.shadertoy.com/user/iq)
  static const int DefaultPageUserShaderCount = 8;

  /// The default number of shaders presented in a Shadertoy
  /// playlist page, for example the playlist of the week as seen in
  /// [here](https://www.shadertoy.com/playlist/week)
  static const int DefaultPagePlaylistShaderCount = 15;

  /// The Shadertoy user login
  final String user;

  /// The Shadertoy user password
  final String password;

  /// The number of shaders presented in the Shadertoy
  /// results [page](https://www.shadertoy.com/browse)
  final int pageResultsShaderCount;

  /// The number of shaders presented in the Shadertoy
  /// user, for example iq user page as seen in
  /// [here](https://www.shadertoy.com/user/iq)
  final int pageUserShaderCount;

  /// The number of shaders presented in a Shadertoy playlist
  /// page, for example the playlist of the week as seen in
  /// [here](https://www.shadertoy.com/playlist/week)
  final int pagePlaylistShaderCount;

  /// Builds a [ShadertoySiteOptions]
  ///
  /// * [user]: The Shadertoy user
  /// * [password]: The Shadertoy password
  /// * [pageResultsShaderCount]: The number of shaders presented in the Shadertoy results page
  /// * [pageUserShaderCount]: The number of shaders presented in the Shadertoy user page
  /// * [pagePlaylistShaderCount]: The number of shaders presented in the Shadertoy playlist page
  /// * [poolMaxAllocatedResources]: The maximum number of resources allocated for parallel calls, defaults to [ShadertoyClientOptions.DefaultPoolMaxAllocatedResources]
  /// * [poolTimeout]: The timeout before giving up on a call, defaults to [ShadertoyClientOptions.DefaultPoolTimeout]
  /// * [retryMaxAttempts]: The maximum number of attempts at a failed request, defaults to [ShadertoyClientOptions.DefaultRetryMaxAttempts]
  /// * [shaderCount]: The number of shaders fetched on a paged call, defaults to [ShadertoyClientOptions.DefaultShaderCount]
  ShadertoySiteOptions(
      {this.user,
      this.password,
      this.pageResultsShaderCount = DefaultPageResultsShaderCount,
      this.pageUserShaderCount = DefaultPageUserShaderCount,
      this.pagePlaylistShaderCount = DefaultPagePlaylistShaderCount,
      int poolMaxAlocatedResources =
          ShadertoyClientOptions.DefaultPoolMaxAllocatedResources,
      int poolTimeout = ShadertoyClientOptions.DefaultPoolTimeout,
      int retryMaxAttempts = ShadertoyClientOptions.DefaultRetryMaxAttempts,
      int shaderCount = ShadertoyClientOptions.DefaultShaderCount})
      : assert(pageResultsShaderCount != null && pageResultsShaderCount >= 1),
        assert(pageUserShaderCount != null && pageUserShaderCount >= 1),
        assert(pagePlaylistShaderCount != null && pagePlaylistShaderCount >= 1),
        super(
            supportsCookies: true,
            poolMaxAllocatedResources: poolMaxAlocatedResources,
            poolTimeout: poolTimeout,
            retryMaxAttempts: retryMaxAttempts,
            shaderCount: shaderCount);
}
