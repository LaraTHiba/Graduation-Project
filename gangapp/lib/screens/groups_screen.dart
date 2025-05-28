import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/groups_controller.dart';
import '../controllers/home_controller.dart';
import '../models/group.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import '../widgets/group_card.dart';
import '../widgets/create_group_dialog.dart';
import '../config/theme.dart';
import '../config/language.dart';
import '../views/widgets/home_bottom_nav.dart';
import '../views/home/Home_Page.dart';
import '../views/profile/Profile_Page.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  final GroupsController _controller = GroupsController();
  final HomeController _homeController = HomeController();
  List<Group> _myGroups = [];
  List<Group> _availableGroups = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  // For HomeBottomNav
  String _userType = 'User';
  String? _profileImageUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadGroups();
    });
    _loadUserTypeAndProfile();
    _loadGroups();
  }

  Future<void> _loadUserTypeAndProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('user_type') ?? 'User';
    });
    setState(() => _isLoadingProfile = true);
    final profileImageUrl = await _homeController.fetchUserProfile();
    setState(() {
      _profileImageUrl = profileImageUrl;
      _isLoadingProfile = false;
    });
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final myGroupsData = await _controller.getMyGroups();
      final availableGroupsData = await _controller.getAvailableGroups();
      setState(() {
        _myGroups = myGroupsData.map((data) => Group.fromJson(data)).toList();
        _availableGroups =
            availableGroupsData.map((data) => Group.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createGroup(String name, String description) async {
    try {
      await _controller.createGroup(name: name, description: description);
      _loadGroups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _joinGroup(int groupId) async {
    try {
      await _controller.joinGroup(groupId);
      _loadGroups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _leaveGroup(int groupId) async {
    try {
      await _controller.leaveGroup(groupId);
      _loadGroups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _onTabSelected(int index) {
    final isCompanyUser = _userType == 'Company';
    if (isCompanyUser) {
      // Company: Home (0), AI (1), Profile (2)
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          break;
        case 1:
          // AI page
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
          // AI page
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: ThemeConfig.bodyTextStyle.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            Language.translate('no_groups_hint'),
            style: ThemeConfig.captionTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompanyUser = _userType == 'Company';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Language.translate('groups')),
          backgroundColor: const Color(0xFF006C5F),
          foregroundColor: Colors.white,
          toolbarHeight: 70,
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color.fromARGB(255, 255, 255, 255),
            unselectedLabelColor: const Color.fromARGB(255, 255, 255, 255),
            indicatorColor: const Color.fromARGB(255, 255, 255, 255),
            tabs: [
              Tab(text: Language.translate('my_groups')),
              Tab(text: Language.translate('available_groups')),
            ],
          ),
        ),
        body: _isLoading
            ? const LoadingIndicator()
            : _error != null
                ? ErrorMessage(message: _error!)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _myGroups.isEmpty
                          ? _buildEmptyState(Language.translate('no_my_groups'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _myGroups.length,
                              itemBuilder: (context, index) {
                                final group = _myGroups[index];
                                return GroupCard(
                                  group: group,
                                  onJoin: () => _joinGroup(group.id),
                                  onLeave: () => _leaveGroup(group.id),
                                );
                              },
                            ),
                      _availableGroups.isEmpty
                          ? _buildEmptyState(
                              Language.translate('no_available_groups'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _availableGroups.length,
                              itemBuilder: (context, index) {
                                final group = _availableGroups[index];
                                return GroupCard(
                                  group: group,
                                  onJoin: () => _joinGroup(group.id),
                                  onLeave: () => _leaveGroup(group.id),
                                );
                              },
                            ),
                    ],
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => CreateGroupDialog(
                onCreateGroup: _createGroup,
              ),
            );
          },
          backgroundColor: const Color(0xFF006C5F),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: HomeBottomNav(
            currentIndex: isCompanyUser ? 1 : 1, // Adjust if needed
            profileImageUrl: _profileImageUrl,
            isLoadingProfile: _isLoadingProfile,
            userType: _userType,
            onTabSelected: _onTabSelected,
          ),
        ),
      ),
    );
  }
}
