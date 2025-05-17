import 'package:flutter/material.dart';
import '../profile/Profile_Page.dart';
import '../widgets/create_post_dialog.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/pro_company_request_dialog.dart';
import '../../controllers/home_controller.dart';
import '../../models/post.dart';
import '../../views/widgets/Home_widget.dart';
import '../../views/comment_screen.dart';
import '../../utils/email_validator.dart';

/// Main home page of the application
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _homeController = HomeController();
  late Future<List<Post>> _postsFuture;
  String? _profileImageUrl;
  bool _isLoadingProfile = true;
  int _currentIndex = 0;
  String _userType = 'User';
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _postsFuture = _homeController.fetchPosts();
    await _fetchUserProfile();
    await _loadUserTypeAndEmail();
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
    final future = _homeController.fetchPosts();
    setState(() => _postsFuture = future);
  }

  Future<void> _createPost(String title, String content, dynamic image) async {
    try {
      await _homeController.createPost(
        title: title,
        content: content,
        image: image,
      );
      await _refreshPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create post: $e"),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'DISMISS',
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
      // Company: Home (0), Explore (1), Profile (2)
      if (index == 0) {
        // Home: do nothing or refresh
      } else if (index == 1) {
        Navigator.pushNamed(context, '/explore');
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        ).then((_) => _fetchUserProfile());
      }
    } else {
      // User: Home (0), Groups (1), Explore (2), Profile (3)
      if (index == 0) {
        // Home: do nothing or refresh
      } else if (index == 1) {
        // Groups: (if you have a groups page, otherwise do nothing)
      } else if (index == 2) {
        Navigator.pushNamed(context, '/explore');
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
      (postId) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CommentScreen(postId: postId)),
      ),
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
            color: const Color(0xFF006C5F), // App primary color
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
            icon: const Icon(Icons.business_rounded, color: Colors.white),
            label: const Text(
              'Pro-Company',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: _showProCompanyRequestDialog,
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent, // Use container color
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide.none, // No border
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF006C5F),
        foregroundColor: Colors.white,
        actions: _buildAppBarActions(),
        toolbarHeight: 70,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading posts: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshPosts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final posts = snapshot.data!;
            if (posts.isEmpty) {
              return const Center(
                child: Text('No posts yet. Be the first to post!'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: posts.length,
              itemBuilder: (context, index) => _buildPostCard(posts[index]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: const Color(0xFF006C5F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _userType == 'Company' ? 2 : 3,
        profileImageUrl: _profileImageUrl,
        isLoadingProfile: _isLoadingProfile,
        userType: _userType,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
