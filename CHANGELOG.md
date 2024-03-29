## 1.0.0

* Initial fully functional release

## 1.0.0+1

* Fix issues with pub.dev publishing

## 1.0.0+2

* Downgrading Dart requirements to match pub.dev and refactoring project structure

## 1.0.0+3

* Added portuguese documentation as well as some fixes in the English README.md version

## 1.0.0+4

* Add platform info to `ServiceProvider` so injected classes can be chosen by platform as well

## 1.0.0+5

* Allows override of registrations (for unit test mocking purposes, for instance)

## 1.2.0

* Allows override of registrations even before the registrations take place

## 1.3.0

* Refactoring to separate write/query methods from `ServiceProvider`
* BREAKING CHANGE: write methods (i.e.: `registerTransient`) no longer requires `ServiceProvider.instance` (they are now static methods)
* BREAKING CHANGE: During registration, a `IServiceProvider` is available only with query methods (`isRegistered`, `optional` and `required`)
* BREAKING CHANGE: to avoid conflict with the `@override` attribute, the `override` method was renamed to `replace`

## 1.3.1

* Added `registerSingletonIfNotRegistered` and `registerTransientIfNotRegistered` to avoid throwing exceptions and making registration idempotent

## 1.3.1+1

* Fixed some grammar errors and refactored the barrel file to make import easier

## 1.4.0

* BREAKING CHANGE: now `registerTransient` and `registerSingleton` have the following signature: `(optional, required, platform)`, so you can inject optional
and required services in a easier way:

```dart
ServiceProvider.registerTransient<SomeAbstractClass>(
  (optional, required, platform) => SomeConcreteClassWithDependencies(
    dependencyA: optional<DependencyA>(), 
    dependencyB: required<DependencyB>(),
    platform: platform, 
  ),
);

class SomeConcreteClassWithDependencies {
  SomeConcreteClassWithDependencies({
    this.dependencyA, 
    this.dependencyB,
    this.platform,
  });

  final DependencyA dependencyA;
  final DependencyB dependencyB;
  final IPlatformInfo platform;
}
```

* Also, `getService<T>()` was renamed to `optional<T>()` and `getRequiredService<T>()` was renamed to `required<T>()`.

* Now you can implement `IMustBeTransient` or `IMustBeSingleton` in your services to validate the required type of registration (i.e.: a class that implements
`IMustBeTransient` will throw a `InvalidRegistrationModalForTypeException`, if you try to register it with
`ServiceProvider.registerTransient<ClassThatImplementsIMustBeTransient>((optional, required, platform) => SomeClass())`)

## 1.4.1

* Added the `PlatformDesignSystem platformDesignSystem` property in `IPlatformInfo`, so you can quickly determine what kind of design system the host platform
uses (Material Design for Linux and Android, Apple Human Interface for MacOS or iOS, Fluent Design for Windows)

## 1.5.0

* More methods added, such as `registerOrReplaceTransient`, `override`, `isRegisteredAsSingleton`, etc.

* New interface `IInitializable` that will run `Service.initialize()` every time an instance of `Service` is created.

* BREAKING CHANGE: The `replace` method was renamed to `override`. The new `replace` method will replace an existing registration (or throws an error if the
service isn't registered)

## 1.5.1

* Add `toString` overrides to all exceptions

## 1.5.1+1

* Fixing some dependencies export

## 1.5.1+2

* Changing the license from GPL3 to BSD3

## 1.5.2

* `PlatformInfo` is now publicly available through `ServiceProvider`

## 1.6.0

* BREAKING CHANGE: `PlatformInfo` now has a `nativePlatform` to get info about where is the app running (regarding a native Flutter app (android, ios, windows, etc.) or Flutter web)
