import 'package:flutter/material.dart';

import 'package:kfx_dependency_injection/kfx_dependency_injection.dart';

void main() {
  // Register a class that receives an injection of a dependency
  ServiceProvider.registerTransient<MainApp>(
    (optional, required, platform) => MainApp(helloWorldProvider: required<IHelloWorldProvider>()),
  );

  // Register a concrete class that will implement a service `IHelloWorldProvider` to be injected when needed
  ServiceProvider.registerSingleton<IHelloWorldProvider>(
    (optional, required, platform) => EnglishHelloWorldProvider(platform: platform),
  );

  // Builds the `MainApp` class with injected dependencies
  final mainApp = ServiceProvider.required<MainApp>();

  runApp(mainApp);
}

class MainApp extends StatelessWidget {
  // Injected in the `registerTransient` method above
  const MainApp({required this.helloWorldProvider, super.key});

  // Abstract version of a service (this widget doesn't know the concrete implementation)
  final IHelloWorldProvider helloWorldProvider;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(helloWorldProvider.helloWorldText),
        ),
      ),
    );
  }
}

/// An interface (contract) of a service (in this case, a "hello world" text provider)
@immutable
abstract class IHelloWorldProvider {
  const IHelloWorldProvider({required this.platform});

  final IPlatformInfo platform;

  String get helloWorldText;
}

/// An example of a concrete implementation of `IHelloWorldProvider`
@immutable
class EnglishHelloWorldProvider extends IHelloWorldProvider {
  const EnglishHelloWorldProvider({required super.platform});

  @override
  String get helloWorldText => "Hello world from ${platform.platformMedia} ${platform.platformHost}!";
}
