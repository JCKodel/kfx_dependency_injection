import 'dart:html' as html show window;

import 'platform_host.dart';
import 'platform_info.dart';
import 'platform_media.dart';

PlatformInfo getCurrentPlatformInfo() {
  final userAgent = html.window.navigator.userAgent;
  final platform = html.window.navigator.platform!.toLowerCase();

  if (["darwin", "macintosh", "macintel"].indexOf(platform) != -1) {
    return PlatformInfo(platformMedia: PlatformMedia.web, platformHost: PlatformHost.macos);
  }

  if (["iphone", "ipad", "ipod"].indexOf(platform) != -1) {
    return PlatformInfo(platformMedia: PlatformMedia.web, platformHost: PlatformHost.ios);
  }

  if (["win64", "win32", "windows"].indexOf(platform) != -1) {
    return PlatformInfo(platformMedia: PlatformMedia.web, platformHost: PlatformHost.windows);
  }

  if (userAgent.contains("Android")) {
    return PlatformInfo(platformMedia: PlatformMedia.web, platformHost: PlatformHost.android);
  }

  if (platform.contains("linux")) {
    return PlatformInfo(platformMedia: PlatformMedia.web, platformHost: PlatformHost.linux);
  }

  return PlatformInfo(platformMedia: PlatformMedia.web, platformHost: PlatformHost.unknown);
}
