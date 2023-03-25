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

  /// Shortcut to test if app is running on an Android phone or tablet (not as a web app)
  @override
  NativePlatform get nativePlatform {
    switch (platformMedia) {
      case PlatformMedia.web:
        return NativePlatform.web;
      case PlatformMedia.desktop:
        switch (platformHost) {
          case PlatformHost.windows:
            return NativePlatform.windows;
          case PlatformHost.macos:
            return NativePlatform.macos;
          case PlatformHost.linux:
            return NativePlatform.linux;
          default:
            return NativePlatform.unknown;
        }
      case PlatformMedia.mobile:
        switch (platformHost) {
          case PlatformHost.android:
            return NativePlatform.android;
          case PlatformHost.ios:
            return NativePlatform.ios;
          default:
            return NativePlatform.unknown;
        }
      case PlatformMedia.unknown:
        return NativePlatform.unknown;
    }
  }

  /// `true` when the app is running in debug mode, `false` for release
  @override
  bool get isDebug => kDebugMode;

  /// Returns the most appropriate `PlatformDesignSystem` for the current host
  @override
  PlatformDesignSystem get platformDesignSystem {
    switch (platformHost) {
      case PlatformHost.android:
      case PlatformHost.linux:
        return PlatformDesignSystem.materialDesign;
      case PlatformHost.ios:
      case PlatformHost.macos:
        return PlatformDesignSystem.appleHumanIntercace;
      case PlatformHost.windows:
        return PlatformDesignSystem.fluentDesign;
      case PlatformHost.unknown:
        return PlatformDesignSystem.unknown;
    }
  }
}
