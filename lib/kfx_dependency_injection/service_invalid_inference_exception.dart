/// This exception is thrown when you try to use a service provider method without specifying the `TService` generic argument, so the Service Provider
/// cannot know what type to return
///
/// To fix, ensure you always call the `ServiceProvider` methods with its generic arguments (ex.: `serviceProvider.getService<TGenericType>())
///
/// To avoid it during development, use the following lint options:
///
/// ```yaml
/// analyzer:
///   exclude:
///     - '**/*.g.dart'
///   language:
///     strict-casts: true
///     strict-raw-types: true
///     strict-inference: true # This will show you when type inference cannot be determinated because you forgot to specify a generic type argument
/// ```
class ServiceInvalidInferenceException implements Exception {
  factory ServiceInvalidInferenceException({required String? key}) => ServiceInvalidInferenceException._(key);

  ServiceInvalidInferenceException._(String? key)
      : message = "The service with key ${key ?? "null"} was used without specifying the TService "
            "generic argument, so I don't know what type to return";

  final String message;
}
