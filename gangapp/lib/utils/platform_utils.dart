import 'package:flutter/foundation.dart' show kIsWeb;

// Don't use conditional imports as they don't work well with Flutter
class PlatformUtils {
  // Just use the Flutter-provided kIsWeb constant
  static bool get isWeb => kIsWeb;
  
  // We only care about web vs non-web for this application
  static bool get isMobile => !kIsWeb;
  
  static bool get isDesktop => false; // For future implementation if needed
} 