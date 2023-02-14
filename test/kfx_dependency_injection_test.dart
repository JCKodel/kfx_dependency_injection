// ignore_for_file: inference_failure_on_function_invocation

import 'package:test/test.dart';

import 'package:kfx_dependency_injection/kfx_dependency_injection.dart';

class _TestClass {
  _TestClass();

  int value = 0;
}

class _MockTestClass extends _TestClass {
  _MockTestClass({required int value}) {
    this.value = value;
  }
}

void _expectException<TException extends Exception>(void Function() method, String expectedMessage) {
  try {
    method();
    fail("Expected ${TException} was not thrown");
  } catch (ex) {
    expect(ex, isA<TException>());
    expect(expectedMessage, (ex as dynamic).message);
  }
}

void main() {
  tearDown(() => ServiceProvider.unregisterAll());

  test("Registered transient services must be transient", () {
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "2");

    final tc1 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "1");
    final tc2 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "2");

    tc1.value = 1;
    tc2.value = 2;

    expect(tc1.value, 1);
    expect(tc2.value, 2);
    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "1").value, 0);
    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "2").value, 0);
  });

  test("Overrides must work", () {
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");

    ServiceProvider.replace<_TestClass>((serviceProvider, platformInfo) => _MockTestClass(value: 11), key: "1");
    ServiceProvider.replace<_TestClass>((serviceProvider, platformInfo) => _MockTestClass(value: 22), key: "2");

    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "2");

    final tc1 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "1");
    final tc2 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "2");

    expect(tc1.value, 11);
    expect(tc2.value, 22);
    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "1").value, 11);

    tc1.value = 33;

    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "2").value, 22);
  });

  test("Registered singleton services must be singleton", () {
    ServiceProvider.registerSingleton((serviceProvider, platformInfo) => _TestClass(), key: "1");
    ServiceProvider.registerSingleton((serviceProvider, platformInfo) => _TestClass(), key: "2");

    final tc1 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "1");
    final tc2 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "2");

    tc1.value = 1;
    tc2.value = 2;

    expect(tc1.value, 1);
    expect(tc2.value, 2);
    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "1").value, 1);
    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "2").value, 2);
    tc2.value = 4;
    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "2").value, 4);
  });

  test("Unallow duplicate registration", () {
    _expectException<ServiceAlreadyRegisteredException>(
      () {
        ServiceProvider.registerTransient<_TestClass>((serviceProvider, platformInfo) => _TestClass());
        ServiceProvider.registerTransient<_TestClass>((serviceProvider, platformInfo) => _TestClass());
      },
      "The service _TestClass was already registered as a transactional service",
    );

    ServiceProvider.unregisterAll();

    _expectException<ServiceAlreadyRegisteredException>(
      () {
        ServiceProvider.registerSingleton<_TestClass>((serviceProvider, platformInfo) => _TestClass());
        ServiceProvider.registerSingleton<_TestClass>((serviceProvider, platformInfo) => _TestClass());
      },
      "The service _TestClass was already registered as a singleton service",
    );

    _expectException<ServiceAlreadyRegisteredException>(
      () {
        ServiceProvider.registerTransient<_TestClass>((serviceProvider, platformInfo) => _TestClass());
      },
      "The service _TestClass was already registered as a singleton service",
    );
  });

  test("Ignore duplicate registration", () {
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass());

    expect(ServiceProvider.instance.getRequiredService<_TestClass>().value, 0);

    ServiceProvider.registerTransientIfNotRegistered((serviceProvider, platformInfo) => _MockTestClass(value: 2));

    expect(ServiceProvider.instance.getRequiredService<_TestClass>().value, 0);
  });

  test("Registration tests", () {
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass());

    expect(ServiceProvider.instance.isRegistered<_TestClass>(key: "1"), true);
    expect(ServiceProvider.instance.isRegistered<_TestClass>(), true);
    expect(ServiceProvider.instance.isRegistered<_TestClass>(key: "2"), false);
  });

  test("Required services validation", () {
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass());

    final tc1 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "1");
    final tc = ServiceProvider.instance.getRequiredService<_TestClass>();

    tc1.value = 1;
    tc.value = 2;

    expect(tc1.value, 1);
    expect(tc.value, 2);

    final tc2 = ServiceProvider.instance.getService<_TestClass>(key: "2");

    expect(tc2, null);

    _expectException<ServiceNotRegisteredException>(
      () {
        final tc3 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "3");

        expect(tc3, null);
      },
      "The service _TestClass:3 was not registered",
    );
  });

  test("Services unregistrations", () {
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass());
    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");

    expect(ServiceProvider.instance.getService<_TestClass>()!.value, 0);
    expect(ServiceProvider.instance.getService<_TestClass>(key: "1")!.value, 0);

    ServiceProvider.unregister<_TestClass>();

    expect(ServiceProvider.instance.getService<_TestClass>(), null);
    expect(ServiceProvider.instance.getService<_TestClass>(key: "1")!.value, 0);

    ServiceProvider.registerTransient((serviceProvider, platformInfo) => _TestClass());
    ServiceProvider.unregister<_TestClass>(key: "1");

    expect(ServiceProvider.instance.getService<_TestClass>()!.value, 0);
    expect(ServiceProvider.instance.getService<_TestClass>(key: "1"), null);

    ServiceProvider.unregisterAll();

    _expectException<ServiceNotRegisteredException>(
      () {
        ServiceProvider.unregister<_TestClass>(throwsExceptionIfNotRegistered: true);
      },
      "The service _TestClass was not registered",
    );
  });

  test("Service without generic argument", () {
    ServiceProvider.registerSingleton((serviceProvider, platformInfo) => _TestClass());
    ServiceProvider.registerSingleton((serviceProvider, platformInfo) => _TestClass(), key: "1");

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.registerSingleton((serviceProvider, platformInfo) => null);
      },
      "The service with key null was used without specifying the TService generic argument, so I don't know what type to return",
    );

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.instance.getService();
      },
      "The service with key null was used without specifying the TService generic argument, so I don't know what type to return",
    );

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.instance.getService(key: "1");
      },
      "The service with key 1 was used without specifying the TService generic argument, so I don't know what type to return",
    );

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.unregister();
      },
      "The service with key null was used without specifying the TService generic argument, so I don't know what type to return",
    );

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.unregister(key: "1");
      },
      "The service with key 1 was used without specifying the TService generic argument, so I don't know what type to return",
    );
  });
}
