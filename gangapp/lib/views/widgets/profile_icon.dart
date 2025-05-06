import 'package:flutter/material.dart';

/// Widget for displaying a user's profile icon
class ProfileIcon extends StatelessWidget {
  /// URL of the profile image
  final String? imageUrl;

  /// Whether the profile image is currently loading
  final bool isLoading;

  /// Size of the icon
  final double size;

  /// Color of the icon when no image is available
  final Color iconColor;

  const ProfileIcon({
    super.key,
    this.imageUrl,
    this.isLoading = false,
    this.size = 24,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: iconColor,
          strokeWidth: 2,
        ),
      );
    }

    if (imageUrl?.isNotEmpty ?? false) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.person_rounded, size: size, color: iconColor),
        ),
      );
    }

    return Icon(Icons.person_rounded, size: size, color: iconColor);
  }
}
