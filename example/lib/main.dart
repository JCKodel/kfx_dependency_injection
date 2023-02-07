import 'package:flutter/material.dart';

import 'package:kfx_dependency_injection/kfx_dependency_injection/service_provider.dart';

void main() {
  // Register a class that receives an injection of a dependency
  ServiceProvider.instance.registerTransient<MainApp>(
    (sp) => MainApp(helloWorldProvider: sp.getRequiredService<IHelloWorldProvider>()),
  );

  // Register a concrete class that will implement a service `IHelloWorldProvider` to be injected when needed
  ServiceProvider.instance.registerSingleton<IHelloWorldProvider>(
    (sp) => EnglishHelloWorldProvider(),
  );

  // Builds the `MainApp` class with injected dependencies
  final mainApp = ServiceProvider.instance.getRequiredService<MainApp>();

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
abstract class IHelloWorldProvider {
  String get helloWorldText;
}

/// An example of a concrete implementation of `IHelloWorldProvider`
class EnglishHelloWorldProvider extends IHelloWorldProvider {
  @override
  String get helloWorldText => "Hello world!";
}
