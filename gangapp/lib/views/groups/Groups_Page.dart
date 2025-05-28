import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../languages/language.dart';
import '../widgets/home_bottom_nav.dart';
import '../home/Home_Page.dart';
import '../profile/Profile_Page.dart';
import '../../controllers/home_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  bool _isLoading = true;
  String _userType = 'User';
  String? _profileImageUrl;
  bool _isLoadingProfile = true;
  List<Map<String, dynamic>> _groups = [];
  final HomeController _homeController = HomeController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUserTypeAndEmail();
    await _fetchUserProfile();
    // TODO: Implement groups loading logic
    setState(() {
      _isLoading = false;
      _groups = []; // This will be populated with actual groups data
    });
  }

  Future<void> _loadUserTypeAndEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('user_type') ?? 'User';
    });
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profileImageUrl = await _homeController.fetchUserProfile();
      setState(() => _profileImageUrl = profileImageUrl);
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  void _onTabSelected(int index) {
    if (_userType == 'Company') {
      // Company: Home (0), AI (1), Profile (2)
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          break;
        case 1:
          // TODO: Navigate to AI page
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
          break;
      }
    } else {
      // User: Home (0), Groups (1), AI (2), Profile (3)
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          break;
        case 1:
          // Already on groups page
          break;
        case 2:
          // TODO: Navigate to AI page
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<Language>();
    final theme = Theme.of(context);
    final isCompanyUser = _userType == 'Company';

    return Scaffold(
      appBar: AppBar(
        title: Text(language.get('groups')),
        backgroundColor: const Color(0xFF006C5F),
        foregroundColor: Colors.white,
        toolbarHeight: 70,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No groups yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join or create a group to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF006C5F),
                          child: Text(
                            group['name']?[0]?.toUpperCase() ?? 'G',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          group['name'] ?? 'Unnamed Group',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '${group['member_count'] ?? 0} members',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded),
                          onPressed: () {
                            // TODO: Navigate to group details
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show create group dialog
        },
        backgroundColor: const Color(0xFF006C5F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: HomeBottomNav(
          currentIndex: isCompanyUser ? 1 : 1,
          profileImageUrl: _profileImageUrl,
          isLoadingProfile: _isLoadingProfile,
          userType: _userType,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}
