import 'package:flutter/material.dart';
import '../profile/Profile_Page.dart';
import '../widgets/create_post_dialog.dart';
import '../widgets/home_bottom_nav.dart';
import '../../controllers/home_controller.dart';
import '../../models/post.dart';
import '../../views/widgets/Home_widget.dart';
import '../../views/comment_screen.dart';

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
    setState(() => _postsFuture = _homeController.fetchPosts());
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

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);

    if (_homeController.shouldNavigate(index, _userType)) {
      final route = _homeController.getRouteForTab(index);
      if (route != null) {
        Navigator.pushNamed(context, route);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF006C5F),
        foregroundColor: Colors.white,
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
        currentIndex: _currentIndex,
        profileImageUrl: _profileImageUrl,
        isLoadingProfile: _isLoadingProfile,
        userType: _userType,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
