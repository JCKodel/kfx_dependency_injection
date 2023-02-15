import 'package:flutter/foundation.dart';

import '../kfx_dependency_injection.dart';

import 'web_current_platform_info.dart' if (dart.library.io) "io_get_current_platform_info.dart";

/// Holds information about the current platform and host.
class PlatformInfo implements IPlatformInfo {
  const PlatformInfo({required this.platformMedia, required this.platformHost});

  /// What kind of platform the app is running?
  @override
  final PlatformMedia platformMedia;

  /// After considering `platformMedia`, which host is running the app?
  @override
  final PlatformHost platformHost;

  static PlatformInfo? _platformInfo;

  /// Returns the cached instance of current platform info or fetch that info for the first time
  @protected
  static PlatformInfo get platformInfo => _platformInfo ?? (_platformInfo = getCurrentPlatformInfo());

  /// Shortcut to test if app is running on an Android phone or tablet
  @override
  bool get isAndroidDevice => platformMedia == PlatformMedia.mobile && platformHost == PlatformHost.android;

  /// Shortcut to test if app is running on an iPhone or iPad
  @override
  bool get isIOSDevice => platformMedia == PlatformMedia.mobile && platformHost == PlatformHost.ios;

  /// `true` when the app is running in debug mode, `false` for release
  @override
  bool get isDebug => kDebugMode;
}
