// ignore_for_file: invalid_use_of_protected_member

import 'i_platform_info.dart';
import 'platform_info.dart';
import 'service_already_registered_exception.dart';
import 'service_invalid_inference_exception.dart';
import 'service_not_registered_exception.dart';

typedef InjectorDelegate<TService> = TService Function(ServiceProvider serviceProvider, IPlatformInfo platformInfo);

/// Defines a mechanism for retrieving a service object; that is, an object that provides custom support to other objects.
///
/// To use it, register your services using the `registerSingleton` and `registerTransient` methods before your app starts.
/// Those methods accepts a function that receives the `ServiceProvider`, so you can inject the services into those constructors.
///
/// Example:
///
/// ```dart
/// ServiceProvider.instance.registerSingleton<SingletonService>((sp) => SingletonService(sp.getRequiredService<TransientService>()));
/// ServiceProvider.instance.registerTransient<TransientService>((sp) => TransientService());
/// ```
class ServiceProvider {
  ServiceProvider._();

  static ServiceProvider _instance = ServiceProvider._();

  /// Returns the singleton instance of the `ServiceProvider`
  static ServiceProvider get instance => _instance;

  // ignore: strict_raw_type
  final _factoryRegistry = <String, _ServiceFactory>{};

  /// Register a constructor as a singleton service (i.e.: the `TService` will always point to the same instance)
  ///
  /// `constructor` is a function that constructs a new `TService` type and receives an instance of this `ServiceProvider`, so you can get registered dependencies
  /// using the `getService` and `getRequiredService` methods.
  ///
  /// `key` must be provided when a `TService` is ambiguous (for example, when you have two classes with the same name in your project, you need to differentiate
  /// those because Dart has no namesace or library indication on its types, so a clas named User in a package has the same identifier as a class User in another
  /// package) Basically, types are identifier by their single name (`Type.toString()`)
  ///
  /// Throws `ServiceAlreadyRegisteredException` if the service is already registered as singleton or transient
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  void registerSingleton<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    _registerService(constructor, key, true);
  }

  /// Register a constructor as a transient service (i.e.: the `TService` will be created each time the ServiceProvider requires it)
  ///
  /// `constructor` is a function that constructs a new `TService` type and receives an instance of this `ServiceProvider`, so you can get registered dependencies
  /// using the `getService` and `getRequiredService` methods.
  ///
  /// `key` must be provided when a `TService` is ambiguous (for example, when you have two classes with the same name in your project, you need to differentiate
  /// those because Dart has no namesace or library indication on its types, so a clas named User in a package has the same identifier as a class User in another
  /// package) Basically, types are identifier by their single name (`Type.toString()`)
  ///
  /// Throws `ServiceAlreadyRegisteredException` if the service is already registered as singleton or transient
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  void registerTransient<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    _registerService(constructor, key, false);
  }

  void _registerService<TService>(InjectorDelegate<TService> constructor, String? key, bool isSingleton) {
    final serviceKey = _getServiceKey<TService>(key);

    if (_factoryRegistry.containsKey(serviceKey)) {
      throw ServiceAlreadyRegisteredException(serviceKey: serviceKey, asSingleton: _factoryRegistry[serviceKey]!.isSingleton);
    }

    _factoryRegistry[serviceKey] = _ServiceFactory(constructor, isSingleton);
  }

  // Unregister a previous registered service, if it exists.
  ///
  /// `key` must be provided when a `TService` is ambiguous and it was registered with a non null key (see `registerSingleton` and
  /// `registerTransient` methods to know more about the `key` argument)
  ///
  /// `throwsExceptionIfNotRegistered` throws a `ServiceNotRegisteredException` if the service with the specified key was not registered
  /// when `true` or just ignores non registered services if `false` (the default behaviour)
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  void unregister<TService>({String? key, bool throwsExceptionIfNotRegistered = false}) {
    final serviceKey = _getServiceKey<TService>(key);

    if (throwsExceptionIfNotRegistered) {
      if (_factoryRegistry.containsKey(serviceKey) == false) {
        throw ServiceNotRegisteredException(serviceKey: serviceKey);
      }
    }

    _factoryRegistry.remove(serviceKey);
  }

  /// Unregister all registered services (this is usefull, for instance, in test environments)
  void unregisterAll() {
    _factoryRegistry.clear();
  }

  /// Overrides a previous registration (for example, to mock concrete implementations in unit tests)
  ///
  /// The override is registered as singleton or transient depending on the original registration, and that registration must exist
  void override<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    final serviceKey = _getServiceKey<TService>(key);
    final registration = _factoryRegistry[serviceKey];

    if (registration == null) {
      throw ServiceNotRegisteredException(serviceKey: serviceKey);
    }

    unregister<TService>(key: key);

    if (registration.isSingleton) {
      registerSingleton<TService>(constructor, key: key);
    } else {
      registerTransient<TService>(constructor, key: key);
    }
  }

  /// Returns `true` if the service `TService` is registered with the specified `key`.
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  bool isRegistered<TService>({String? key}) {
    final serviceKey = _getServiceKey<TService>(key);

    return _factoryRegistry.containsKey(serviceKey);
  }

  /// Returns a registered `TService`. If `TService` was not registered, returns null.
  ///
  /// `key` must be provided when a `TService` is ambiguous and it was registered with a non null key (see `registerSingleton` and
  /// `registerTransient` methods to know more about the `key` argument)
  ///
  /// The instance of `TService` will be a singleton if it was registered as such (meaning: only the same instance is always returned)
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  TService? getService<TService>({String? key}) {
    final serviceKey = _getServiceKey<TService>(key);
    final serviceFactory = _factoryRegistry[serviceKey];

    if (serviceFactory == null) {
      return null;
    }

    return serviceFactory.instance as TService;
  }

  /// Returns a registered `TService`. If `TService` was not registered, returns a `ServiceNotRegisteredException`.
  ///
  /// `key` must be provided when a `TService` is ambiguous and it was registered with a non null key (see `registerSingleton` and
  /// `registerTransient` methods to know more about the `key` argument)
  ///
  /// The instance of `TService` will be a singleton if it was registered as such (meaning: only the same instance is always returned)
  ///
  /// Throws a `ServiceNotRegisteredException` if the service with the specified key was not registered
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  TService getRequiredService<TService>({String? key}) {
    final service = getService<TService>(key: key);

    if (service == null) {
      throw ServiceNotRegisteredException(serviceKey: _getServiceKey<TService>(key));
    }

    return service;
  }

  static String _getServiceKey<TService>(String? key) {
    final serviceKey = TService.toString();
    final serviceKeyLower = serviceKey.toLowerCase();

    if (serviceKeyLower == "dynamic" || serviceKeyLower == "null" || serviceKeyLower == "void") {
      throw ServiceInvalidInferenceException(key: key);
    }

    return key == null ? TService.toString() : "${TService}:${key}";
  }
}

class _ServiceFactory<TService> {
  _ServiceFactory(this.constructor, this.isSingleton);

  final InjectorDelegate<TService> constructor;
  final bool isSingleton;

  TService? _instance;
  TService get instance {
    if (isSingleton) {
      return _instance ?? (_instance = constructor(ServiceProvider.instance, PlatformInfo.platformInfo));
    }

    return constructor(ServiceProvider.instance, PlatformInfo.platformInfo);
  }
}
