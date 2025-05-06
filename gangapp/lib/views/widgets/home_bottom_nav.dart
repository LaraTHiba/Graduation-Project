import 'package:flutter/material.dart';
import 'profile_icon.dart';

/// Bottom navigation bar for the home page
class HomeBottomNav extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// URL of the user's profile image
  final String? profileImageUrl;

  /// Whether the profile image is loading
  final bool isLoadingProfile;

  /// User type (Company or User)
  final String userType;

  /// Callback when a tab is selected
  final Function(int) onTabSelected;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.profileImageUrl,
    required this.isLoadingProfile,
    required this.userType,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF006C5F),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        if (userType != 'Company')
          const BottomNavigationBarItem(
            icon: Icon(Icons.group_rounded),
            label: 'Groups',
          ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.explore_rounded),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: ProfileIcon(
            imageUrl: profileImageUrl,
            isLoading: isLoadingProfile,
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
