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
  test("Registered transient services must be transient", () {
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "2");

    final tc1 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "1");
    final tc2 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "2");

    tc1.value = 1;
    tc2.value = 2;

    expect(tc1.value, 1);
    expect(tc2.value, 2);
    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "1").value, 0);
    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "2").value, 0);

    ServiceProvider.instance.unregisterAll();
  });

  test("Overrides must work", () {
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "2");

    ServiceProvider.instance.override<_TestClass>((serviceProvider, platformInfo) => _MockTestClass(value: 11), key: "1");
    ServiceProvider.instance.override<_TestClass>((serviceProvider, platformInfo) => _MockTestClass(value: 22), key: "2");

    final tc1 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "1");
    final tc2 = ServiceProvider.instance.getRequiredService<_TestClass>(key: "2");

    expect(tc1.value, 11);
    expect(tc2.value, 22);
    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "1").value, 11);

    tc1.value = 33;

    expect(ServiceProvider.instance.getRequiredService<_TestClass>(key: "2").value, 22);

    ServiceProvider.instance.unregisterAll();
  });

  test("Registered singleton services must be singleton", () {
    ServiceProvider.instance.registerSingleton((serviceProvider, platformInfo) => _TestClass(), key: "1");
    ServiceProvider.instance.registerSingleton((serviceProvider, platformInfo) => _TestClass(), key: "2");

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

    ServiceProvider.instance.unregisterAll();
  });

  test("Unallow duplicate registration", () {
    _expectException<ServiceAlreadyRegisteredException>(
      () {
        ServiceProvider.instance.registerTransient<_TestClass>((serviceProvider, platformInfo) => _TestClass());
        ServiceProvider.instance.registerTransient<_TestClass>((serviceProvider, platformInfo) => _TestClass());
      },
      "The service _TestClass was already registered as a transactional service",
    );

    ServiceProvider.instance.unregisterAll();

    _expectException<ServiceAlreadyRegisteredException>(
      () {
        ServiceProvider.instance.registerSingleton<_TestClass>((serviceProvider, platformInfo) => _TestClass());
        ServiceProvider.instance.registerSingleton<_TestClass>((serviceProvider, platformInfo) => _TestClass());
      },
      "The service _TestClass was already registered as a singleton service",
    );

    _expectException<ServiceAlreadyRegisteredException>(
      () {
        ServiceProvider.instance.registerTransient<_TestClass>((serviceProvider, platformInfo) => _TestClass());
      },
      "The service _TestClass was already registered as a singleton service",
    );

    ServiceProvider.instance.unregisterAll();
  });

  test("Registration tests", () {
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass());

    expect(ServiceProvider.instance.isRegistered<_TestClass>(key: "1"), true);
    expect(ServiceProvider.instance.isRegistered<_TestClass>(), true);
    expect(ServiceProvider.instance.isRegistered<_TestClass>(key: "2"), false);

    ServiceProvider.instance.unregisterAll();
  });

  test("Required services validation", () {
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass());

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

    ServiceProvider.instance.unregisterAll();
  });

  test("Services unregistrations", () {
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass());
    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass(), key: "1");

    expect(ServiceProvider.instance.getService<_TestClass>()!.value, 0);
    expect(ServiceProvider.instance.getService<_TestClass>(key: "1")!.value, 0);

    ServiceProvider.instance.unregister<_TestClass>();

    expect(ServiceProvider.instance.getService<_TestClass>(), null);
    expect(ServiceProvider.instance.getService<_TestClass>(key: "1")!.value, 0);

    ServiceProvider.instance.registerTransient((serviceProvider, platformInfo) => _TestClass());
    ServiceProvider.instance.unregister<_TestClass>(key: "1");

    expect(ServiceProvider.instance.getService<_TestClass>()!.value, 0);
    expect(ServiceProvider.instance.getService<_TestClass>(key: "1"), null);

    ServiceProvider.instance.unregisterAll();

    _expectException<ServiceNotRegisteredException>(
      () {
        ServiceProvider.instance.unregister<_TestClass>(throwsExceptionIfNotRegistered: true);
      },
      "The service _TestClass was not registered",
    );
  });

  test("Service without generic argument", () {
    ServiceProvider.instance.registerSingleton((serviceProvider, platformInfo) => _TestClass());
    ServiceProvider.instance.registerSingleton((serviceProvider, platformInfo) => _TestClass(), key: "1");

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.instance.registerSingleton((serviceProvider, platformInfo) => null);
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
        ServiceProvider.instance.unregister();
      },
      "The service with key null was used without specifying the TService generic argument, so I don't know what type to return",
    );

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.instance.unregister(key: "1");
      },
      "The service with key 1 was used without specifying the TService generic argument, so I don't know what type to return",
    );

    ServiceProvider.instance.unregisterAll();
  });
}
