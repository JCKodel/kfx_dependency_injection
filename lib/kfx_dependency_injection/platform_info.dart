import 'package:flutter/foundation.dart';

import 'platform_host.dart';
import 'platform_media.dart';
import 'web_current_platform_info.dart' if (dart.library.io) "io_get_current_platform_info.dart";

/// Holds information about the current platform and host.
class PlatformInfo {
  const PlatformInfo({required this.platformMedia, required this.platformHost});

  /// What kind of platform the app is running?
  final PlatformMedia platformMedia;

  /// After considering `platformMedia`, which host is running the app?
  final PlatformHost platformHost;

  static PlatformInfo? _platformInfo;

  /// Returns the cached instance of current platform info or fetch that info for the first time
  @protected
  static PlatformInfo get platformInfo => _platformInfo ?? (_platformInfo = getCurrentPlatformInfo());

  /// Shortcut to test if app is running on an Android phone or tablet
  bool get isAndroidDevice => platformMedia == PlatformMedia.mobile && platformHost == PlatformHost.android;

  /// Shortcut to test if app is running on an iPhone or iPad
  bool get isIOSDevice => platformMedia == PlatformMedia.mobile && platformHost == PlatformHost.ios;

  /// `true` when the app is running in debug mode, `false` for release
  bool get isDebug => kDebugMode;
}
