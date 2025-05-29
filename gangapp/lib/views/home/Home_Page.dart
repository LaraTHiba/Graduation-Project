import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../languages/language.dart';
import '../profile/Profile_Page.dart';
import '../widgets/create_post_dialog.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/pro_company_request_dialog.dart';
import '../../controllers/home_controller.dart';
import '../../models/post.dart';
import '../../views/widgets/Home_widget.dart';
import '../../views/comment_screen.dart';
import '../../utils/email_validator.dart';
import '../../screens/groups_screen.dart';
import '../ai/AI_Page.dart';

/// Main home page of the application
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _homeController = HomeController();
  late Future<List<Post>> _postsFuture;
  String? _profileImageUrl;
  bool _isLoadingProfile = true;
  int _currentIndex = 0;
  String _userType = 'User';
  String? _userEmail;
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _postsFuture = _homeController.fetchPosts();
    await _fetchUserProfile();
    await _loadUserTypeAndEmail();
    await _refreshPosts();
  }

  Future<void> _loadUserTypeAndEmail() async {
    final userData = await _homeController.loadUserTypeAndEmail();
    setState(() {
      _userType = userData['userType']!;
      _userEmail = userData['email'];
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

  Future<void> _refreshPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await _homeController.fetchPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${context.read<Language>().get('error_loading_posts')} $e"),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: context.read<Language>().get('dismiss'),
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPost(Post post, {dynamic image}) async {
    try {
      await _homeController.createPost(
        title: post.title,
        content: post.content,
        image: image,
      );
      await _refreshPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${context.read<Language>().get('failed_to_create_post')} $e"),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: context.read<Language>().get('dismiss'),
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    }
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => CreatePostDialog(
        onPostCreated: _createPost,
      ),
    );
  }

  void _showProCompanyRequestDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const ProCompanyRequestDialog(),
    );
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);

    final isCompanyUser = _userType == 'Company';

    // Map the index to the correct action
    if (isCompanyUser) {
      // Company: Home (0), AI (1), Profile (2)
      if (index == 0) {
        // Home: do nothing or refresh
      } else if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIPage()),
        );
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        ).then((_) => _fetchUserProfile());
      }
    } else {
      // User: Home (0), Groups (1), AI (2), Profile (3)
      if (index == 0) {
        // Home: do nothing or refresh
      } else if (index == 1) {
        // Groups: Navigate to groups page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GroupsScreen()),
        );
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIPage()),
        );
      } else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        ).then((_) => _fetchUserProfile());
      }
    }
  }

  Widget _buildPostCard(Post post) {
    return HomeWidget.buildPostCard(
      post,
      (postId) {
        // No longer navigate to comment screen
      },
      onPostArchived: _refreshPosts,
    );
  }

  List<Widget> _buildAppBarActions() {
    final isCompanyUser = _userType == 'Company';

    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.notifications_rounded),
        onPressed: () {
          // TODO: Implement notifications
        },
      ),
    ];

    if (isCompanyUser) {
      actions.insert(
        0,
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF006C5F),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextButton.icon(
            icon: const Icon(Icons.business_rounded,
                color: Colors.white, size: 20),
            label: const Text(
              'Pro',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: _showProCompanyRequestDialog,
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide.none,
              ),
            ),
          ),
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<Language>();

    return Scaffold(
      appBar: AppBar(
        title: Text(language.get('home')),
        backgroundColor: const Color(0xFF006C5F),
        foregroundColor: Colors.white,
        actions: _buildAppBarActions(),
        toolbarHeight: 70,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Text(
                    language.get('no_posts'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) =>
                        _buildPostCard(_posts[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: const Color(0xFF006C5F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: HomeBottomNav(
          currentIndex: _userType == 'Company' ? 2 : 3,
          profileImageUrl: _profileImageUrl,
          isLoadingProfile: _isLoadingProfile,
          userType: _userType,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}
