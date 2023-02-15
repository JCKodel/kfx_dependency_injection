part of kfx_dependency_injection;

/// What kind of platform the app is running?
enum PlatformMedia {
  /// App running on a web browser (Flutter Web)
  web,

  /// App running on a native desktop enviroment (Windows, Linux or MacOS)
  desktop,

  /// App running on a mobile device (Android or iOS)
  mobile,

  /// Could not determine the media
  unknown,
}
