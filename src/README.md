# kfx_dependency_injection

A simple dependency injection and service locator inspired by .net service provider.

In software engineering, dependency injection is a design pattern in which an object or function receives other objects or functions that it depends on, so you can pass
some abstract classes (the closest thing as an interface you can get in Dart) and let this package figures out what your class will get when it is instantiated.

It also works as a service locator (when you have an abstract/interface definition and want to choose the concrete implementation on the registration).

## Features

1) Allows registration of transitional and singleton dependencies
2) 100% code coverage on unit tests
3) Covers misconfigurated lint options (such as using generic methods without providing generic types)

## Usage

For example, you can define an authentication system as a set of empty common methods (in an abstract class, which is the closest you can get right now of a true
interface in Dart). Then, you implement the authentication itself on another class, let's say, using Firebase authentication.

Log is important and you also do the same for logging. Perhaps using `dart:developer` to make it so.

So the registration on `main` is something like this:

```dart
ServiceProvider.instance.registerSingleton<IAuthenticationService>((serviceProvider) => FirebaseAuthenticationService(logService: serviceProvider.getService<ILogService>()));

ServiceProvider.instance.registerSingleton<ILogService>((serviceProvider) => DartDeveloperLogService());
```

Notice that the order of registration doesn't matter, as long as you register all dependencies in the same location (a good place is the `main` method, before your app runs).

Now, to get your authentication service, with the injected log stuff defined in the registration, you just need to:

```dart
final authenticationService = ServiceProvider.instance.getRequiredService<IAuthenticationService>();
```

And that's it. You don't need to know the concrete implementation nor know what kind of log is being used (or if it even exist).

### Singleton vs Transitional

The main difference between the registrations are: whenever you call `getService`, `getRequiredService` or something is injected in another constructor, singletons always
returns the same instance of a class, while transitional registrations always returns a new instance of that class (in most cases, you want a singleton).

### getService vs getRequiredService

The difference between those methods is that `getService` can return null if the specified service was not registered, while `getRequiredService` will throw a
`ServiceNotRegisteredException` if the service was not registered. You should use `getRequiredService` to ensure everything was successfully registered.

## Additional information

There are some methods to check if a type is registered (`isRegistered<T>()`) and methods to allow unregistration (this is usefull to release singleton instances or
in unit tests to cleanup the `ServiceProvider` manager).

Since Dart is uncapable of returning unique type names, all methods in `ServiceProvider` accepts a key, which will be used to differentiate types.

For instance: the `firebase_authentication` package contains an `User` class. It's probable that you also have a `User` class in your code, which has nothing to do
with that Firebase implementation. But Dart will return `User` in both cases when we ask the name of the type.

So, if you have two classes with the same name and want to register them (since is not possible to register a type more than once), you can differentiate them using
the `key` argument:

```dart
import 'some_class.dart';
import 'package:some_package:some_class.dart' as SomePackage;

ServiceProvider.instance.registerSingleton<SomeClass>();
ServiceProvider.instance.registerSingleton<SomePackage.SomeClass>(key: "SomePackage");
```

The second registration must use the `key` argument because the `Someclass` exists in multiple locations.

To retrieve each version of the registration, use the same key:

```dart
import 'some_class.dart';

final someClass = ServiceProvider.instance.getRequiredService<SomeClass>();
```

This will return the first registration (because `key` is null in both cases).

```dart
import 'package:some_package:some_class.dart';

final someClass = ServiceProvider.instance.getRequiredService<SomeClass>(key: "SomePackage");
```

Notice that the above code doesn't have an alias anymore, but it still returns the correct `SomeClass` version because the same `key` argument was used.

## Exceptions

There are three available exceptions thrown by this package:

### `ServiceAlreadyRegisteredException`

This exception is thrown when you try to register a type with the same `key` (or lack of it).

### `ServiceNotRegisteredException`

This exception is thrown by `getRequiredService` when it requires a service that was not registered and also by `unregister` method, if `throwsExceptionIfNotRegistered`
argument is `true` (which is `false` by default).

### `ServiceInvalidInferenceException`

Dart by default will not warn you when you don't provide a generic argument and one is expected, so `ServiceProvider.instance.getService()` is valid code,
but it is impossible to know what service we should return (since `TService` is `dynamic` in this case). The correct usage would be
`ServiceProvider.instance.getService<SomeTypeHere>()`.

The same occurs on registration of a null type: `ServiceProvider.instance.registerSingleton((sp) => null)` which is valid code, but the type would be `Null`.

To be warned about those cases, you should turn on the `strict-inference` language analyzer in your `analysis_options.yaml`:

```yaml
analyzer:
  language:
    strict-inference: true
```

That setting will give you a warning like this one:

```dart
ServiceProvider.instance.getService();
```

```text
The type argument(s) of the function 'getService' can't be inferred. 
Use explicit type argument(s) for 'getService'.
```
