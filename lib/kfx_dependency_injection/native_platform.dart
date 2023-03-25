part of kfx_dependency_injection;

/// The app is running as a native app in one of these OSes or is Flutter Web?
enum NativePlatform {
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

  /// Flutter web
  web,

  /// Unable to determine the native platform
  unknown,
}
