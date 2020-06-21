import 'package:shadertoy_client/shadertoy_client.dart';
import 'package:shadertoy_client/src/client_options.dart';

/// Options for the Shadertoy REST API client
///
/// Stores the options used to build a [ShadertoyWSClient]
class ShadertoyWSOptions extends ShadertoyClientOptions {
  /// The default base API path to use for the REST calls
  ///
  /// Currently points to the v1 of the API
  static const String DefaultApiPath = '/api/v1';

  /// The API key that should be appended for each call
  final String apiKey;

  /// The configured API path
  final String apiPath;

  /// Builds a [ShadertoyWSOptions]
  ///
  /// * [apiKey]: The API key
  /// * [apiPath]: The base api path, defaults to [ShadertoyWSOptions.DefaultApiPath]
  /// * [poolMaxAllocatedResources]: The maximum number of resources allocated for parallel calls, defaults to [ShadertoyClientOptions.DefaultPoolMaxAllocatedResources]
  /// * [poolTimeout]: The timeout before giving up on a call, defaults to [ShadertoyClientOptions.DefaultPoolTimeout]
  /// * [retryMaxAttempts]: The maximum number of attempts at a failed request, defaults to [ShadertoyClientOptions.DefaultRetryMaxAttempts]
  /// * [shaderCount]: The number of shaders fetched on a paged call, defaults to [ShadertoyClientOptions.DefaultShaderCount]
  ShadertoyWSOptions(
      {this.apiKey,
      this.apiPath = DefaultApiPath,
      int poolMaxAllocatedResources =
          ShadertoyClientOptions.DefaultPoolMaxAllocatedResources,
      int poolTimeout = ShadertoyClientOptions.DefaultPoolTimeout,
      int retryMaxAttempts = ShadertoyClientOptions.DefaultRetryMaxAttempts,
      int shaderCount = ShadertoyClientOptions.DefaultShaderCount})
      : assert(apiKey != null && apiKey.isNotEmpty),
        assert(apiPath != null && apiPath.isNotEmpty),
        assert(poolMaxAllocatedResources != null &&
            poolMaxAllocatedResources >= 1),
        assert(poolTimeout != null && poolTimeout >= 0),
        assert(retryMaxAttempts != null && retryMaxAttempts >= 0),
        assert(shaderCount != null && shaderCount > 0),
        super(
            supportsCookies: false,
            poolMaxAllocatedResources: poolMaxAllocatedResources,
            poolTimeout: poolTimeout,
            retryMaxAttempts: retryMaxAttempts,
            shaderCount: shaderCount);
}
