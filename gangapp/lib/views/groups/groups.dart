import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/Profile_Page.dart';
import '../../utils/email_validator.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  String? _userType;
  String? _userEmail;
  bool _accessDenied = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkUserTypeAndRedirect();
  }

  Future<void> _checkUserTypeAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type') ?? 'User';
    final userEmail = prefs.getString('email') ?? '';
    final isCompanyWithCompanyEmail =
        userType == 'Company' && EmailValidator.isCompanyEmail(userEmail);
    if (isCompanyWithCompanyEmail) {
      setState(() {
        _accessDenied = true;
        _checked = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      setState(() {
        _userType = userType;
        _userEmail = userEmail;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_accessDenied) {
      // Show nothing while redirecting
      return const Scaffold();
    }
    bool isCompanyWithCompanyEmail = _userType == 'Company' &&
        EmailValidator.isCompanyEmail(_userEmail ?? '');
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF006C5F), Color(0xFF4CAF93)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006C5F).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.groups_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Groups',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006C5F),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(30),
                child: Icon(
                  Icons.groups_rounded,
                  color: const Color(0xFF006C5F).withOpacity(0.7),
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Groups Yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join or create a group to get started!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement create group functionality
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C5F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            height: 70,
            color: const Color(0xFF006C5F),
            child: BottomNavigationBar(
              currentIndex: 1,
              onTap: (index) {
                if (isCompanyWithCompanyEmail) {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacementNamed(context, '/home');
                      break;
                    case 1:
                      Navigator.pushReplacementNamed(context, '/explore');
                      break;
                    case 2:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()),
                      );
                      break;
                  }
                } else {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacementNamed(context, '/home');
                      break;
                    case 1:
                      break;
                    case 2:
                      Navigator.pushReplacementNamed(context, '/explore');
                      break;
                    case 3:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()),
                      );
                      break;
                  }
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.6),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
              items: isCompanyWithCompanyEmail
                  ? [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home_rounded, size: 24),
                        label: 'Home',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.explore_rounded, size: 24),
                        label: 'Explore',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person_rounded, size: 24),
                        label: 'Profile',
                      ),
                    ]
                  : [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home_rounded, size: 24),
                        label: 'Home',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.groups_rounded, size: 24),
                        label: 'Groups',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.explore_rounded, size: 24),
                        label: 'Explore',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person_rounded, size: 24),
                        label: 'Profile',
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
