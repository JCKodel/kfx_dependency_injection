part of kfx_dependency_injection;

/// After considering `PlatformMedia`, which host is running the app?
enum PlatformHost {
  /// Android phone or tablet
  android,

  /// iPhone or iPad
  ios,

  /// Windows machine
  windows,

  /// MacOS machine
  macos,

  /// Linux machine
  linux,

  /// Unable to determine the host
  unknown,
}
