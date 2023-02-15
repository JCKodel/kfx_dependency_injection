# kfx_dependency_injection

[![Dart](https://github.com/JCKodel/kfx_dependency_injection/actions/workflows/dart.yml/badge.svg)](https://github.com/JCKodel/kfx_dependency_injection/actions/workflows/dart.yml) | [Versão Português](README.pt.md)

A simple dependency injection and service locator inspired by .net service provider.

In software engineering, dependency injection is a design pattern in which an object or function receives other objects or functions that it depends on, so you can pass
some abstract classes (the closest thing as an interface you can get in Dart) and let this package figures out what your class will get when it is instantiated.

It also works as a service locator (when you have an abstract/interface definition and want to choose the concrete implementation on the registration).

## Features

1) Allows registration of transient and singleton dependencies
2) Covers misconfigured lint options (such as using generic methods without providing generic types)
3) The injector has a `PlatformInfo` available, so you can decide what to inject based on media (web, desktop or mobile) and host (window, linux, macos, android or ios)
4) Flutter web safe, including `PlatformInfo`
5) No external dependencies

## Usage

For example, you can define an authentication system as a set of empty common methods (in an abstract class, which is the closest you can get right now of a true
interface in Dart). Then, you implement the authentication itself on another class, let's say, using Firebase authentication. Wanna use AWS Incognito? Just reimplement
that abstract class using Incognito e change the registration to point to it. Done, without breaking changes.

Log is important and you can also do the same for logging. Perhaps using `dart:developer` to make it so.

When you register the authentication service, you can inject the log service on it (at that point, it is an abstract class that doesn't care how it will be implemented).
Change the log registration to some other type (perhaps some remote logging?) and everything keeps working perfectly, and you don't even need to touch the authentication
service (since all is based on interfaces/abstract classes, which are only contracts to concrete implementation)

So the registration on `main` is something like this:

```dart
ServiceProvider.instance.registerSingleton<IAuthenticationService>(
  (serviceProvider, platformInfo) => FirebaseAuthenticationService(
    logService: serviceProvider.getService<ILogService>()
  )
);

ServiceProvider.instance.registerSingleton<ILogService>(
  (serviceProvider, platformInfo) => DartDeveloperLogService(isWeb: platformInfo.platformMedia == PlatformMedia.web)
);
```

Notice that the order of registration doesn't matter, as long as you register all dependencies before using them (a good place is the `main` method, before your app runs).

The `platformInfo` argument is an instance of the `PlatformInfo`, so you can instantly know what kind of media you are using (Flutter Web, Flutter Desktop or Flutter Mobile)
and the host you are running (Android, iOS, Windows, MacOS or Linux). That info is separated between media and host, so you can know when you are running Flutter Web on an
Android device, for instance (perhaps to choose the appropriate design system (i.e. Material, Apple or Fluent)). In the example above, I could tell my concrete log implementation if we are running Flutter Web or native.

Now, to get your authentication service, with the injected log stuff defined in the registration, you just need to:

```dart
final authenticationService = ServiceProvider.instance.getRequiredService<IAuthenticationService>();
```

And that's it. You don't need to know the concrete implementation nor know what kind of log is being used (or if it even exists).

### Singleton vs Transient

The difference between the registrations are: whenever you call `getService`, `getRequiredService` or something is injected in another constructor, singletons always
returns the same instance of a class, while transient registrations always returns a new instance of that class (in most cases, you want a singleton).

### getService vs getRequiredService

The difference between those methods is that `getService` can return `null` if the specified service was not registered, while `getRequiredService` will throw a
`ServiceNotRegisteredException` if the service was not registered. You should use `getRequiredService` to ensure everything was correctly registered during app's initialization.

## Mocking

After registering a type, you can override it using `ServiceProvider.instance.override<TService>((serviceProvider, platformInfo) => MockClass(), key: "some key")`.

This is useful when you use some remote API service registered on your app, but want to mock that service in unit tests. In this case, the app remains as it is (no change
is required). In your unit test, you override the registration of your api calls to some mock class and you're done.

That override can take place before or after the normal registration (i.e.: you can override before instantiating your app and registering your types or after that, it
doesn't matter)

## Additional information

There are some methods to check if a type is registered (`isRegistered<T>()`) and methods to allow unregistration (this is useful to release singleton instances or
in unit tests to clean up the `ServiceProvider` manager).

Since Dart is uncapable of returning unique type names, all methods in `ServiceProvider` accepts a key, which will be used to differentiate types.

For instance: the `firebase_authentication` package contains an `User` class. It's probable that you also have a `User` class in your code, which has nothing to do
with that Firebase implementation. The problem is that Dart will return `User` in both cases when we ask the name of the type. That's the same reason you have to use
the `as`, `hide` and `show` keywords during `import` to avoid class and functions names conflicts.

So, if you have two classes with the same name and want to register them (since it's not possible to register a type more than once), you can differentiate them using
the `key` argument:

```dart
import 'some_class.dart';
import 'package:some_package:some_class.dart' as SomePackage;

ServiceProvider.instance.registerSingleton<SomeClass>(
  (serviceProvider) => SomeClass()
);

ServiceProvider.instance.registerSingleton<SomePackage.SomeClass>(
  (serviceProvider) => SomePackage.SomeClass(),
  key: "SomePackage"
);
```

The second registration must use the `key` argument because the `SomeClass` exists in multiple locations and it was already registered.

To retrieve each version of the registration, use the same key:

```dart
import 'some_class.dart';

final someClass = ServiceProvider.instance.getRequiredService<SomeClass>();
```

This will return the first registration (because `key` is `null` in both cases).

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
