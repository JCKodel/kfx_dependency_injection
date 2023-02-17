part of kfx_dependency_injection;

/// This exception is thrown when you try to register a service that implements `IMustBeTransient` as singleton or `IMustBeSingleton` as transient.
///
/// To fix, ensure the service is registered with the required type (transient or singleton)
abstract class InvalidRegistrationModalForTypeException implements Exception {
  InvalidRegistrationModalForTypeException._(String serviceKey, bool shouldBeSingleton)
      : message = "The service ${serviceKey} must be registered with register${shouldBeSingleton ? "Singleton" : "Transient"} method";

  final String message;
}

/// This exception is thrown when you try to register a service that implements `IMustBeTransient` as singleton.
///
/// To fix, ensure the service is registered using `ServiceProvider.registerTransient`.
class RegistryMustBeTransientException extends InvalidRegistrationModalForTypeException {
  factory RegistryMustBeTransientException({required String serviceKey}) => RegistryMustBeTransientException._(serviceKey);

  RegistryMustBeTransientException._(String serviceKey) : super._(serviceKey, false);
}

/// This exception is thrown when you try to register a service that implements `IMustBeTransient` as transient.
///
/// To fix, ensure the service is registered using `ServiceProvider.registerSingleton`.
class RegistryMustBeSingletonException extends InvalidRegistrationModalForTypeException {
  factory RegistryMustBeSingletonException({required String serviceKey}) => RegistryMustBeSingletonException._(serviceKey);

  RegistryMustBeSingletonException._(String serviceKey) : super._(serviceKey, true);
}
