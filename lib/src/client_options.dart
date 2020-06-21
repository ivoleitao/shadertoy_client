/// Base class for the client options
///
/// It provides a number of options that can be configured regardless the specific implementation of the client
abstract class ShadertoyClientOptions {
  /// The default maximum number of resources that may be allocated at once in the pool
  static const int DefaultPoolMaxAllocatedResources = 5;

  /// The default timeout for a request
  static const int DefaultPoolTimeout = 30;

  /// The default maximum number of attempts before giving up
  static const int DefaultRetryMaxAttempts = 3;

  /// The default number of shaders fetched for a paged call.
  static const int DefaultShaderCount = 10;

  /// If the http client supports cookies
  final bool supportsCookies;

  /// The maximum number of resources that may be allocated at once in the pool
  ///
  /// It is used to constrain the number of parallel calls that are made to the
  /// Shadertoy endpoints
  final int poolMaxAllocatedResources;

  /// Constrains the maximum time a call to the Shadertoy API can last. If this
  /// value is exceed an exception is thrown for the offending request and for all
  /// the others in the queue
  final int poolTimeout;

  /// The maximum number of atempts before giving up.
  final int retryMaxAttempts;

  /// The number of shaders fetched for paged call
  final int shaderCount;

  /// Builds a [ShadertoyClientOptions]
  ///
  /// * [supportsCookies]: If the http client should support cookies
  /// * [poolMaxAllocatedResources]: Max number of parallel calls supported
  /// * [poolTimeout]: The maximum time a call can last
  /// * [retryMaxAttempts]: The maximum number of attempts before giving up
  /// * [shaderCount]: The number of shaders fetched in a paged call
  ShadertoyClientOptions(
      {this.supportsCookies,
      this.poolMaxAllocatedResources,
      this.poolTimeout,
      this.retryMaxAttempts,
      this.shaderCount})
      : assert(supportsCookies != null),
        assert(poolMaxAllocatedResources != null),
        assert(poolTimeout != null),
        assert(retryMaxAttempts != null),
        assert(shaderCount != null);
}
