/// This exception is thrown when you try to register a service with the same name twice.
///
/// To fix, ensure the service is unique or use a different key for this one (note that the service name is the service class name, so two classes with the
/// same name but from different packages are considered equal, thus, requiring a non null `serviceKey` argument to differentate them)
class ServiceAlreadyRegisteredException implements Exception {
  factory ServiceAlreadyRegisteredException({required String serviceKey, required bool asSingleton}) => ServiceAlreadyRegisteredException._(serviceKey, asSingleton);

  ServiceAlreadyRegisteredException._(String serviceKey, bool asSingleton)
      : message = "The service ${serviceKey} was already registered as a ${asSingleton ? "singleton" : "transactional"} service";

  final String message;
}
