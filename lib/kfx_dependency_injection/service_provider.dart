part of kfx_dependency_injection;

typedef InjectorDelegate<TService> = TService Function(TConcrete? Function<TConcrete>() optional, TConcrete Function<TConcrete>() required, PlatformInfo platform);

/// Defines a mechanism for retrieving a service object; that is, an object that provides custom support to other objects.
///
/// To use it, register your services using the `registerSingleton` and `registerTransient` methods before your app starts.
/// Those methods accepts a function that receives the `ServiceProvider`, so you can inject the services into those constructors.
///
/// Example:
///
/// ```dart
/// ServiceProvider.registerSingleton<SingletonService>((optional, required, platform) => SingletonService(sp.required<TransientService>()));
/// ServiceProvider.registerTransient<TransientService>((optional, required, platform) => TransientService());
/// ```
abstract class ServiceProvider {
  // ignore: strict_raw_type
  static final _factoryRegistry = <String, _ServiceFactory>{};

  // ignore: strict_raw_type
  static final _overrideFactoryRegistry = <String, Object>{};

  /// Register a constructor as a singleton service (i.e.: the `TService` will always point to the same instance)
  ///
  /// `constructor` is a function that constructs a new `TService` type and receives an instance of this `ServiceProvider`, so you can get registered dependencies
  /// using the `optional` and `required` methods.
  ///
  /// `key` must be provided when a `TService` is ambiguous (for example, when you have two classes with the same name in your project, you need to differentiate
  /// those because Dart has no namesace or library indication on its types, so a clas named User in a package has the same identifier as a class User in another
  /// package) Basically, types are identifier by their single name (`Type.toString()`)
  ///
  /// Throws `ServiceAlreadyRegisteredException` if the service is already registered as singleton or transient
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  static void registerSingleton<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    _registerService(constructor, key, true);
  }

  /// Register a constructor as a singleton service (i.e.: the `TService` will always point to the same instance), if none is registered yet
  ///
  /// `constructor` is a function that constructs a new `TService` type and receives an instance of this `ServiceProvider`, so you can get registered dependencies
  /// using the `optional` and `required` methods.
  ///
  /// `key` must be provided when a `TService` is ambiguous (for example, when you have two classes with the same name in your project, you need to differentiate
  /// those because Dart has no namesace or library indication on its types, so a clas named User in a package has the same identifier as a class User in another
  /// package) Basically, types are identifier by their single name (`Type.toString()`)
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  static void registerSingletonIfNotRegistered<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    if (isRegistered<TService>(key: key)) {
      return;
    }

    registerSingleton(constructor, key: key);
  }

  /// Register a constructor as a transient service (i.e.: the `TService` will be created each time the ServiceProvider requires it)
  ///
  /// `constructor` is a function that constructs a new `TService` type and receives an instance of this `ServiceProvider`, so you can get registered dependencies
  /// using the `optional` and `required` methods.
  ///
  /// `key` must be provided when a `TService` is ambiguous (for example, when you have two classes with the same name in your project, you need to differentiate
  /// those because Dart has no namesace or library indication on its types, so a clas named User in a package has the same identifier as a class User in another
  /// package) Basically, types are identifier by their single name (`Type.toString()`)
  ///
  /// Throws `ServiceAlreadyRegisteredException` if the service is already registered as singleton or transient
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  static void registerTransient<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    _registerService(constructor, key, false);
  }

  static void registerTransientIfNotRegistered<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    if (isRegistered<TService>(key: key)) {
      return;
    }

    registerTransient(constructor, key: key);
  }

  static void _registerService<TService>(InjectorDelegate<TService> constructor, String? key, bool isSingleton) {
    final serviceKey = _getServiceKey<TService>(key);

    if (_factoryRegistry.containsKey(serviceKey)) {
      throw ServiceAlreadyRegisteredException(serviceKey: serviceKey, asSingleton: _factoryRegistry[serviceKey]!.isSingleton);
    }

    final override = _overrideFactoryRegistry[serviceKey];

    if (override == null) {
      _factoryRegistry[serviceKey] = _ServiceFactory(constructor, isSingleton);
    } else {
      _factoryRegistry[serviceKey] = _ServiceFactory<TService>(override as InjectorDelegate<TService>, isSingleton);
    }
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
  static void unregister<TService>({String? key, bool throwsExceptionIfNotRegistered = false}) {
    final serviceKey = _getServiceKey<TService>(key);

    if (throwsExceptionIfNotRegistered) {
      if (_factoryRegistry.containsKey(serviceKey) == false) {
        throw ServiceNotRegisteredException(serviceKey: serviceKey);
      }
    }

    _factoryRegistry.remove(serviceKey);
  }

  /// Unregister all registered services (this is usefull, for instance, in test environments)
  static void unregisterAll() {
    _factoryRegistry.clear();
  }

  /// Replaces a previous registration
  ///
  /// The registration must exist (otherwise, throws a ServiceNotRegisteredException)
  ///
  /// This is different from override because it requires a previous registration and thus will not work in future registrations
  ///
  /// The replacement will be transient/singleton if the previous registration was transient/singleton
  static void replace<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    final serviceKey = _getServiceKey<TService>(key);
    final registration = _factoryRegistry[serviceKey];

    if (registration == null) {
      throw ServiceNotRegisteredException(serviceKey: serviceKey);
    }

    final isSingleton = registration.isSingleton;

    _factoryRegistry.remove(serviceKey);

    if (isSingleton) {
      registerSingleton<TService>(constructor, key: key);
    } else {
      registerTransient<TService>(constructor, key: key);
    }
  }

  /// Register a transient service or replace it if it was already registered
  ///
  /// This is different from override because it requires a previous registration and thus will not work in future registrations
  ///
  /// If the previous registration exists and it was singleton, it will be transient now
  static void registerOrReplaceTransient<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    final serviceKey = _getServiceKey<TService>(key);
    final registration = _factoryRegistry[serviceKey];

    if (registration != null) {
      _factoryRegistry.remove(serviceKey);
    }

    registerTransient<TService>(constructor, key: key);
  }

  /// Register a SINGLETON service or replace it if it was already registered
  ///
  /// This is different from override because it requires a previous registration and thus will not work in future registrations
  ///
  /// If the previous registration exists and it was transient, it will be singleton now
  static void registerOrReplaceSingleton<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    final serviceKey = _getServiceKey<TService>(key);
    final registration = _factoryRegistry[serviceKey];

    if (registration != null) {
      _factoryRegistry.remove(serviceKey);
    }

    registerSingleton<TService>(constructor, key: key);
  }

  /// Overrides a previous or future registration (for example, to mock concrete implementations in unit tests)
  ///
  /// The override is registered as singleton or transient depending on the original registration, and that registration must exist
  static void override<TService>(InjectorDelegate<TService> constructor, {String? key}) {
    final serviceKey = _getServiceKey<TService>(key);
    final registration = _factoryRegistry[serviceKey];

    if (registration == null) {
      _overrideFactoryRegistry[serviceKey] = constructor;
      return;
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
  static bool isRegistered<TService>({String? key}) {
    final serviceKey = _getServiceKey<TService>(key);

    return _factoryRegistry.containsKey(serviceKey);
  }

  /// Returns `true` if the service `TService` is registered with the specified `key` as singleton.
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  static bool isRegisteredAsSingleton<TService>({String? key}) {
    final serviceKey = _getServiceKey<TService>(key);
    final registration = _factoryRegistry[serviceKey];

    return registration != null && registration.isSingleton;
  }

  /// Returns `true` if the service `TService` is registered with the specified `key` as singleton.
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  static bool isRegisteredAsTransient<TService>({String? key}) {
    final serviceKey = _getServiceKey<TService>(key);
    final registration = _factoryRegistry[serviceKey];

    return registration != null && registration.isSingleton == false;
  }

  /// Returns a registered `TService`. If `TService` was not registered, returns null.
  ///
  /// `key` must be provided when a `TService` is ambiguous and it was registered with a non null key (see `registerSingleton` and
  /// `registerTransient` methods to know more about the `key` argument)
  ///
  /// The instance of `TService` will be a singleton if it was registered as such (meaning: only the same instance is always returned)
  ///
  /// Throws `ServiceInvalidInferenceException` if you forget to specify `TService`
  static TService? optional<TService>({String? key}) {
    final serviceKey = _getServiceKey<TService>(key);
    final serviceFactory = _factoryRegistry[serviceKey];

    if (serviceFactory == null) {
      return null;
    }

    final instance = serviceFactory.instance as TService;

    if (instance is IMustBeSingleton && serviceFactory.isSingleton == false) {
      throw RegistryMustBeSingletonException(serviceKey: serviceKey);
    }

    if (instance is IMustBeTransient && serviceFactory.isSingleton == true) {
      throw RegistryMustBeTransientException(serviceKey: serviceKey);
    }

    return instance;
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
  static TService required<TService>({String? key}) {
    final service = optional<TService>(key: key);

    if (service == null) {
      throw ServiceNotRegisteredException(serviceKey: _getServiceKey<TService>(key));
    }

    return service;
  }

  // ignore: invalid_use_of_protected_member
  static PlatformInfo get platformInfo => PlatformInfo.platformInfo;

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
      return _instance ?? (_instance = _buildInstance());
    }

    return _buildInstance();
  }

  TService _buildInstance() {
    // ignore: invalid_use_of_protected_member
    final instance = constructor(ServiceProvider.optional, ServiceProvider.required, PlatformInfo.platformInfo);

    if (instance is IInitializable) {
      instance.initialize();
    }

    return instance;
  }
}
