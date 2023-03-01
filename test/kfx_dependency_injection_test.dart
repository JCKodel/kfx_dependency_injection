// ignore_for_file: inference_failure_on_function_invocation

import 'package:test/test.dart';

import 'package:kfx_dependency_injection/kfx_dependency_injection.dart';

abstract class _ITest implements IInitializable {
  bool get wasInitialized;
  int get value;
  set value(int v);
}

class _TestClass implements _ITest {
  _TestClass();

  int _value = 0;

  @override
  int get value => _value;

  @override
  set value(int v) => _value = v;

  bool _wasInitialized = false;

  static int initializationCount = 0;

  @override
  void initialize() {
    _wasInitialized = true;
    initializationCount++;
  }

  @override
  bool get wasInitialized => _wasInitialized;
}

class _MockTestClass extends _TestClass {
  _MockTestClass({required int value}) {
    this.value = value;
  }
}

abstract class IRequireToBeSingleton implements IMustBeSingleton {}

abstract class IRequireToBeTransient implements IMustBeTransient {}

class MeSingleton implements IRequireToBeSingleton {}

class MeTransient implements IRequireToBeTransient {}

void _expectException<TException extends Exception>(void Function() method, String expectedMessage) {
  try {
    method();
    fail("Expected ${TException} was not thrown");
  } catch (ex) {
    expect(ex, isA<TException>());
    expect(expectedMessage, (ex as dynamic).message);
    expect("${ex.runtimeType}: ${expectedMessage}", ex.toString());
  }
}

void main() {
  tearDown(() => ServiceProvider.unregisterAll());

  test("Registered transient services must be transient", () {
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass(), key: "1");
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass(), key: "2");

    final tc1 = ServiceProvider.required<_ITest>(key: "1");
    final tc2 = ServiceProvider.required<_ITest>(key: "2");

    tc1.value = 1;
    tc2.value = 2;

    expect(tc1.value, 1);
    expect(tc2.value, 2);
    expect(ServiceProvider.required<_ITest>(key: "1").value, 0);
    expect(ServiceProvider.required<_ITest>(key: "2").value, 0);
  });

  test("Transient overrides must work", () {
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass(), key: "1");

    ServiceProvider.override<_ITest>((optional, required, platform) => _MockTestClass(value: 11), key: "1");
    ServiceProvider.override<_ITest>((optional, required, platform) => _MockTestClass(value: 22), key: "2");

    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass(), key: "2");

    final tc1 = ServiceProvider.required<_ITest>(key: "1");
    final tc2 = ServiceProvider.required<_ITest>(key: "2");

    expect(tc1.value, 11);
    expect(tc2.value, 22);
    expect(ServiceProvider.required<_ITest>(key: "1").value, 11);

    tc1.value = 33;

    expect(ServiceProvider.required<_ITest>(key: "2").value, 22);
  });

  test("Singleton overrides must work", () {
    ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass(), key: "1");

    ServiceProvider.override<_ITest>((optional, required, platform) => _MockTestClass(value: 11), key: "1");
    ServiceProvider.override<_ITest>((optional, required, platform) => _MockTestClass(value: 22), key: "2");

    ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass(), key: "2");

    final tc1 = ServiceProvider.required<_ITest>(key: "1");
    final tc2 = ServiceProvider.required<_ITest>(key: "2");

    expect(tc1.value, 11);
    expect(tc2.value, 22);
    expect(ServiceProvider.required<_ITest>(key: "1").value, 11);

    tc1.value = 33;

    expect(ServiceProvider.required<_ITest>(key: "2").value, 22);
  });

  test("Registered singleton services must be singleton", () {
    ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass(), key: "1");
    ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass(), key: "2");

    final tc1 = ServiceProvider.required<_ITest>(key: "1");
    final tc2 = ServiceProvider.required<_ITest>(key: "2");

    tc1.value = 1;
    tc2.value = 2;

    expect(tc1.value, 1);
    expect(tc2.value, 2);
    expect(ServiceProvider.required<_ITest>(key: "1").value, 1);
    expect(ServiceProvider.required<_ITest>(key: "2").value, 2);
    tc2.value = 4;
    expect(ServiceProvider.required<_ITest>(key: "2").value, 4);
  });

  test("IMustBeTransient and IMustBeSingleton must validate the service", () {
    ServiceProvider.registerTransient<IRequireToBeSingleton>((optional, required, platform) => MeSingleton());
    ServiceProvider.registerSingleton<IRequireToBeTransient>((optional, required, platform) => MeTransient());

    _expectException<RegistryMustBeSingletonException>(
      () {
        ServiceProvider.required<IRequireToBeSingleton>();
      },
      "The service IRequireToBeSingleton must be registered with registerSingleton method",
    );

    _expectException<RegistryMustBeTransientException>(
      () {
        ServiceProvider.required<IRequireToBeTransient>();
      },
      "The service IRequireToBeTransient must be registered with registerTransient method",
    );

    ServiceProvider.unregisterAll();
  });

  test("Unallow duplicate registration", () {
    _expectException<ServiceAlreadyRegisteredException>(
      () {
        ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass());
        ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass());
      },
      "The service _ITest was already registered as a transient service",
    );

    ServiceProvider.unregisterAll();

    _expectException<ServiceAlreadyRegisteredException>(
      () {
        ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass());
        ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass());
      },
      "The service _ITest was already registered as a singleton service",
    );

    _expectException<ServiceAlreadyRegisteredException>(
      () {
        ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass());
      },
      "The service _ITest was already registered as a singleton service",
    );
  });

  test("Ignore duplicate transient registration", () {
    ServiceProvider.registerTransientIfNotRegistered<_ITest>((optional, required, platform) => _TestClass());

    expect(ServiceProvider.required<_ITest>().value, 0);

    ServiceProvider.registerTransientIfNotRegistered<_ITest>((optional, required, platform) => _MockTestClass(value: 2));

    expect(ServiceProvider.required<_ITest>().value, 0);
  });

  test("Ignore duplicate singleton registration", () {
    ServiceProvider.registerSingletonIfNotRegistered<_ITest>((optional, required, platform) => _TestClass());

    expect(ServiceProvider.required<_ITest>().value, 0);

    ServiceProvider.registerSingletonIfNotRegistered<_ITest>((optional, required, platform) => _MockTestClass(value: 2));

    expect(ServiceProvider.required<_ITest>().value, 0);
  });

  test("Replaces registrations copying the previous behavior", () {
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass(), key: "T");
    ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass(), key: "S");

    expect(true, ServiceProvider.isRegisteredAsTransient<_ITest>(key: "T"));
    expect(true, ServiceProvider.isRegisteredAsSingleton<_ITest>(key: "S"));

    final t1 = ServiceProvider.required<_ITest>(key: "T");
    final t2 = ServiceProvider.required<_ITest>(key: "S");

    expect(true, t1 is _TestClass);
    expect(false, t1 is _MockTestClass);
    expect(true, t2 is _TestClass);
    expect(false, t2 is _MockTestClass);

    ServiceProvider.replace<_ITest>((optional, required, platform) => _MockTestClass(value: 2), key: "T");
    ServiceProvider.replace<_ITest>((optional, required, platform) => _MockTestClass(value: 2), key: "S");

    expect(true, ServiceProvider.isRegisteredAsTransient<_ITest>(key: "T"));
    expect(true, ServiceProvider.isRegisteredAsSingleton<_ITest>(key: "S"));

    final rt1 = ServiceProvider.required<_ITest>(key: "T");
    final rt2 = ServiceProvider.required<_ITest>(key: "S");

    expect(true, rt1 is _TestClass);
    expect(true, rt1 is _MockTestClass);
    expect(true, rt2 is _TestClass);
    expect(true, rt2 is _MockTestClass);
  });

  test("Replaces non existing registration should throw", () {
    _expectException<ServiceNotRegisteredException>(
      () {
        ServiceProvider.replace<_ITest>((optional, required, platform) => _TestClass(), key: "T");
      },
      "The service _ITest:T was not registered",
    );
  });

  test("Replaces registrations with new behaviour", () {
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass(), key: "T");
    ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass(), key: "S");

    expect(true, ServiceProvider.isRegisteredAsTransient<_ITest>(key: "T"));
    expect(true, ServiceProvider.isRegisteredAsSingleton<_ITest>(key: "S"));

    final t1 = ServiceProvider.required<_ITest>(key: "T");
    final t2 = ServiceProvider.required<_ITest>(key: "S");

    expect(true, t1 is _TestClass);
    expect(false, t1 is _MockTestClass);
    expect(true, t2 is _TestClass);
    expect(false, t2 is _MockTestClass);

    ServiceProvider.registerOrReplaceSingleton<_ITest>((optional, required, platform) => _MockTestClass(value: 2), key: "T");
    ServiceProvider.registerOrReplaceTransient<_ITest>((optional, required, platform) => _MockTestClass(value: 2), key: "S");

    expect(true, ServiceProvider.isRegisteredAsSingleton<_ITest>(key: "T"));
    expect(true, ServiceProvider.isRegisteredAsTransient<_ITest>(key: "S"));

    final rt1 = ServiceProvider.required<_ITest>(key: "T");
    final rt2 = ServiceProvider.required<_ITest>(key: "S");

    expect(true, rt1 is _TestClass);
    expect(true, rt1 is _MockTestClass);
    expect(true, rt2 is _TestClass);
    expect(true, rt2 is _MockTestClass);
  });

  test("Registration tests", () {
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass(), key: "1");
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass());

    expect(ServiceProvider.isRegistered<_ITest>(key: "1"), true);
    expect(ServiceProvider.isRegistered<_ITest>(), true);
    expect(ServiceProvider.isRegistered<_ITest>(key: "2"), false);
  });

  test("Required services validation", () {
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass(), key: "1");
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass());

    final tc1 = ServiceProvider.required<_ITest>(key: "1");
    final tc = ServiceProvider.required<_ITest>();

    tc1.value = 1;
    tc.value = 2;

    expect(tc1.value, 1);
    expect(tc.value, 2);

    final tc2 = ServiceProvider.optional<_ITest>(key: "2");

    expect(tc2, null);

    _expectException<ServiceNotRegisteredException>(
      () {
        final tc3 = ServiceProvider.required<_ITest>(key: "3");

        expect(tc3, null);
      },
      "The service _ITest:3 was not registered",
    );
  });

  test("Services unregistrations", () {
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass());
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass(), key: "1");

    expect(ServiceProvider.optional<_ITest>()!.value, 0);
    expect(ServiceProvider.optional<_ITest>(key: "1")!.value, 0);

    ServiceProvider.unregister<_ITest>();

    expect(ServiceProvider.optional<_ITest>(), null);
    expect(ServiceProvider.optional<_ITest>(key: "1")!.value, 0);

    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass());
    ServiceProvider.unregister<_ITest>(key: "1");

    expect(ServiceProvider.optional<_ITest>()!.value, 0);
    expect(ServiceProvider.optional<_ITest>(key: "1"), null);

    ServiceProvider.unregisterAll();

    _expectException<ServiceNotRegisteredException>(
      () {
        ServiceProvider.unregister<_ITest>(throwsExceptionIfNotRegistered: true);
      },
      "The service _ITest was not registered",
    );
  });

  test("Service without generic argument", () {
    ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass());
    ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass(), key: "1");

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.registerSingleton((optional, required, platform) => null);
      },
      "The service with key null was used without specifying the TService generic argument, so I don't know what type to return",
    );

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.optional();
      },
      "The service with key null was used without specifying the TService generic argument, so I don't know what type to return",
    );

    _expectException<ServiceInvalidInferenceException>(
      () {
        ServiceProvider.optional(key: "1");
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

  test("IInitializable initializes instances every transient instance", () {
    _TestClass.initializationCount = 0;
    ServiceProvider.registerTransient<_ITest>((optional, required, platform) => _TestClass());

    final t0 = ServiceProvider.required<_ITest>();
    final t1 = ServiceProvider.required<_ITest>();

    expect(t0.wasInitialized, true);
    expect(t1.wasInitialized, true);
    expect(_TestClass.initializationCount, 2);
  });

  test("IInitializable initializes instances once for singleton instance", () {
    _TestClass.initializationCount = 0;
    ServiceProvider.registerSingleton<_ITest>((optional, required, platform) => _TestClass());

    final t0 = ServiceProvider.required<_ITest>();
    final t1 = ServiceProvider.required<_ITest>();

    expect(t0.wasInitialized, true);
    expect(t1.wasInitialized, true);
    expect(_TestClass.initializationCount, 1);
  });
}
