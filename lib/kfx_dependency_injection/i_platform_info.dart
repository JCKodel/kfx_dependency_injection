part of kfx_dependency_injection;

abstract class IPlatformInfo {
  const IPlatformInfo({required this.platformMedia, required this.platformHost});

  /// What kind of platform the app is running?
  final PlatformMedia platformMedia;

  /// After considering `platformMedia`, which host is running the app?
  final PlatformHost platformHost;

  /// Which native platform is running the app?
  NativePlatform get nativePlatform;

  /// `true` when the app is running in debug mode, `false` for release
  bool get isDebug;

  /// Returns the most appropriate `PlatformDesignSystem` for the current host
  PlatformDesignSystem get platformDesignSystem;
}
