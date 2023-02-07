/// This exception is thrown when you try to get a required service from `ServiceProvider` and the service was not registered.
///
/// To fix, ensure the combination of type and `key` is the same used at registration (using the `registerSingleton` or `registerTransient` methods)
class ServiceNotRegisteredException implements Exception {
  factory ServiceNotRegisteredException({required String serviceKey}) => ServiceNotRegisteredException._(serviceKey);

  ServiceNotRegisteredException._(String serviceKey) : message = "The service ${serviceKey} was not registered";

  final String message;
}
