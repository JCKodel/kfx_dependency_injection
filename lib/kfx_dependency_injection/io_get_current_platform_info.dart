import 'dart:io';

import 'platform_host.dart';
import 'platform_info.dart';
import 'platform_media.dart';

PlatformInfo getCurrentPlatformInfo() {
  if (Platform.isAndroid) {
    return PlatformInfo(platformMedia: PlatformMedia.mobile, platformHost: PlatformHost.android);
  }

  if (Platform.isIOS) {
    return PlatformInfo(platformMedia: PlatformMedia.mobile, platformHost: PlatformHost.ios);
  }

  if (Platform.isWindows) {
    return PlatformInfo(platformMedia: PlatformMedia.desktop, platformHost: PlatformHost.windows);
  }

  if (Platform.isMacOS) {
    return PlatformInfo(platformMedia: PlatformMedia.desktop, platformHost: PlatformHost.macos);
  }

  if (Platform.isLinux) {
    return PlatformInfo(platformMedia: PlatformMedia.desktop, platformHost: PlatformHost.linux);
  }

  return PlatformInfo(platformMedia: PlatformMedia.unknown, platformHost: PlatformHost.unknown);
}
