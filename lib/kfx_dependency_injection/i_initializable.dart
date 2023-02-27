part of kfx_dependency_injection;

/// When a service implements this interface, the method `initialize` will be called when the `ServiceProvider` instantiates a new instance
///
/// If the service is registered as transient, this method will run each time the service is fetched by `optional` or `requires`
///
/// If the service is registered as singleton, this method will only run one time when the service is fetched
abstract class IInitializable {
  void initialize();
}
