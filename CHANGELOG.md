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
* Breaking change: write methods (i.e.: `registerTransient`) no longer requires `ServiceProvider.instance` (they are now static methods)
* Breaking change: During registration, a `IServiceProvider` is available only with query methods (`isRegistered`, `getService` and `getRequiredService`)
* Breaking change: to avoid conflict with the `@override` attribute, the `override` method was renamed to `replace`
