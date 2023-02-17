part of kfx_dependency_injection;

/// The design system used by the platform host
enum PlatformDesignSystem {
  /// Android or Linux
  materialDesign,

  /// MacOS, iPhone or iPad
  appleHumanIntercace,

  /// Windows machine
  fluentDesign,

  /// Unable to determine the host or design system
  unknown,
}
