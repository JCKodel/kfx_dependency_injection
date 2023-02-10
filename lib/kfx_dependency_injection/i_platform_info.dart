import 'platform_host.dart';
import 'platform_media.dart';

abstract class IPlatformInfo {
  const IPlatformInfo({required this.platformMedia, required this.platformHost});

  /// What kind of platform the app is running?
  final PlatformMedia platformMedia;

  /// After considering `platformMedia`, which host is running the app?
  final PlatformHost platformHost;

  /// Shortcut to test if app is running on an Android phone or tablet
  bool get isAndroidDevice;

  /// Shortcut to test if app is running on an iPhone or iPad
  bool get isIOSDevice;

  /// `true` when the app is running in debug mode, `false` for release
  bool get isDebug;
}
