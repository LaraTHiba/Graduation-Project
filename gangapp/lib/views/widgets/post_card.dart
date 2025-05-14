import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../../services/api_service.dart';
import '../../views/create_post_screen.dart';
import 'dart:typed_data';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../controllers/profile_controller.dart';
import 'package:provider/provider.dart';
import '../../languages/language.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final Function(int) onCommentPressed;
  final Function? onPostArchived;

  const PostCard({
    Key? key,
    required this.post,
    required this.onCommentPressed,
    this.onPostArchived,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  final Map<String, String?> _profileImageCache = {};

  bool _isCommentsVisible = false;
  bool _isSubmitting = false;
  File? _selectedImage;
  Uint8List? _webImage;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Constants for styling
  final Color _primaryColor = const Color(0xFF006C5F);
  final Color _secondaryColor = const Color(0xFF4CAF93);
  final BorderRadius _borderRadius = BorderRadius.circular(20);
  final BoxShadow _boxShadow = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    _profileImageCache.clear();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      _showSnackBar("Please write a comment", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Map<String, dynamic> response;
      if (kIsWeb) {
        response = await _apiService.createCommentWeb(
          postId: widget.post.id,
          content: _commentController.text,
          imageBytes: _webImage,
        );
      } else {
        response = await _apiService.createComment(
          postId: widget.post.id,
          content: _commentController.text,
          image: _selectedImage,
        );
      }

      // Create a new Comment object from the response
      final newComment = Comment(
        id: response['id'],
        user: response['user'],
        username: response['username'],
        content: response['content'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        imageUrl: response['image_url'],
      );

      // Update the post's comments list
      if (mounted) {
        setState(() {
          widget.post.comments.add(newComment);
          _commentController.clear();
          _selectedImage = null;
          _webImage = null;
        });
      }

      _showSnackBar("Comment posted successfully");
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final language = Provider.of<Language>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[400] : _primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null && _webImage == null) return SizedBox.shrink();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: kIsWeb
                ? Image.memory(
                    _webImage!,
                    fit: BoxFit.cover,
                    height: 120,
                    width: double.infinity,
                  )
                : Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    height: 120,
                    width: double.infinity,
                  ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() {
                if (kIsWeb) {
                  _webImage = null;
                } else {
                  _selectedImage = null;
                }
              }),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return FutureBuilder<String?>(
      future: ProfileController().getCurrentUsername(),
      builder: (context, snapshot) {
        final currentUsername = snapshot.data;
        final isCurrentUser = currentUsername == comment.username;

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(comment.username, isReply: false),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      comment.username,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatDate(comment.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (isCurrentUser) ...[
                                        SizedBox(width: 8),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            color: Colors.grey[500],
                                            size: 18,
                                          ),
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_rounded,
                                                      color: Colors.grey[700]),
                                                  SizedBox(width: 8),
                                                  Text('Edit Comment'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_rounded,
                                                      color: Colors.red[400]),
                                                  SizedBox(width: 8),
                                                  Text('Delete Comment',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.red[400])),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) async {
                                            if (value == 'delete') {
                                              await _showDeleteCommentConfirmationDialog(
                                                  comment.id);
                                            } else if (value == 'edit') {
                                              await _showEditCommentDialog(
                                                  comment);
                                            }
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                comment.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.black.withOpacity(0.8),
                                ),
                              ),
                              if (comment.effectiveImageUrl != null) ...[
                                SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    comment.effectiveImageUrl!,
                                    fit: BoxFit.cover,
                                    height: 180,
                                    width: double.infinity,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 16, top: 8),
                          child: TextButton.icon(
                            onPressed: () => _showReplyDialog(comment),
                            icon: Icon(Icons.reply_rounded,
                                size: 16, color: Colors.grey[600]),
                            label: Text(
                              context.read<Language>().get('reply'),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (comment.replies != null && comment.replies!.isNotEmpty) ...[
                SizedBox(height: 8),
                ...comment.replies!.map((reply) => _buildReplyItem(reply)),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showReplyDialog(Comment parentComment) async {
    final TextEditingController replyController = TextEditingController();
    File? selectedImage;
    Uint8List? webImage;

    final language = Provider.of<Language>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${language.get('Reply to')} ${parentComment.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: replyController,
              decoration: InputDecoration(
                hintText: language.get('Write your reply...'),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final picked =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  if (kIsWeb) {
                    final bytes = await picked.readAsBytes();
                    setState(() => webImage = bytes);
                  } else {
                    setState(() => selectedImage = File(picked.path));
                  }
                }
              },
              icon: Icon(Icons.image),
              label: Text(language.get('Add Image')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(language.get('Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isEmpty) {
                _showSnackBar(language.get('Please write a reply'),
                    isError: true);
                return;
              }

              try {
                Map<String, dynamic> response;
                if (kIsWeb) {
                  response = await _apiService.createReplyWeb(
                    postId: widget.post.id,
                    commentId: parentComment.id,
                    content: replyController.text,
                    imageBytes: webImage,
                  );
                } else {
                  response = await _apiService.createReply(
                    postId: widget.post.id,
                    commentId: parentComment.id,
                    content: replyController.text,
                    image: selectedImage,
                  );
                }

                // Create a new Comment object for the reply
                final newReply = Comment(
                  id: response['id'],
                  user: response['user'],
                  username: response['username'],
                  content: response['content'],
                  createdAt: DateTime.parse(response['created_at']),
                  updatedAt: DateTime.parse(response['updated_at']),
                  imageUrl: response['image_url'],
                );

                // Update the parent comment's replies list
                if (mounted) {
                  setState(() {
                    if (parentComment.replies == null) {
                      parentComment.replies = [];
                    }
                    parentComment.replies!.add(newReply);
                  });
                }

                Navigator.pop(context);
                _showSnackBar("Reply posted successfully");
              } catch (e) {
                _showSnackBar("Error: $e", isError: true);
              }
            },
            child: Text(language.get('Post Reply')),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Comment reply) {
    return FutureBuilder<String?>(
      future: ProfileController().getCurrentUsername(),
      builder: (context, snapshot) {
        final currentUsername = snapshot.data;
        final isCurrentUser = currentUsername == reply.username;

        return Container(
          margin: EdgeInsets.only(left: 30, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(reply.username, isReply: true),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              reply.username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatDate(reply.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    color: Colors.grey[500],
                                    size: 16,
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_rounded,
                                              color: Colors.grey[700]),
                                          SizedBox(width: 8),
                                          Text(context
                                              .read<Language>()
                                              .get('Edit Reply')),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_rounded,
                                              color: Colors.red[400]),
                                          SizedBox(width: 8),
                                          Text(
                                            context
                                                .read<Language>()
                                                .get('Delete Reply'),
                                            style: TextStyle(
                                                color: Colors.red[400]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      await _showDeleteCommentConfirmationDialog(
                                          reply.id);
                                    } else if (value == 'edit') {
                                      await _showEditCommentDialog(reply);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        reply.content,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                      if (reply.effectiveImageUrl != null) ...[
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            reply.effectiveImageUrl!,
                            fit: BoxFit.cover,
                            height: 120,
                            width: double.infinity,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _getUserProfileImage(String username) async {
    // Return cached image if available
    if (_profileImageCache.containsKey(username)) {
      return _profileImageCache[username];
    }

    try {
      final profile = await _apiService.getPublicProfile(username);
      final profileImage = profile['profile_picture'];
      // Cache the profile image
      _profileImageCache[username] = profileImage;
      return profileImage;
    } catch (e) {
      print('Error fetching profile image: $e');
      return null;
    }
  }

  Widget _buildAvatar(String username, {required bool isReply}) {
    return FutureBuilder<String?>(
      future: _getUserProfileImage(username),
      builder: (context, snapshot) {
        final profileImage = snapshot.data;

        return Container(
          decoration: BoxDecoration(
            gradient: isReply
                ? null
                : LinearGradient(
                    colors: [_secondaryColor, _primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isReply ? _secondaryColor.withOpacity(0.9) : null,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(isReply ? 0.15 : 0.2),
                blurRadius: isReply ? 4 : 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: isReply ? 14 : 18,
            backgroundImage:
                profileImage != null ? NetworkImage(profileImage) : null,
            child: profileImage == null
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: isReply ? 12 : 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _borderRadius,
        boxShadow: [_boxShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(),
          _buildPostContent(),
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    final language = Provider.of<Language>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: _borderRadius.topLeft),
      ),
      child: Row(
        children: [
          _buildAvatar(widget.post.username, isReply: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(widget.post.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildPostActions(),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            widget.post.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            widget.post.content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ),
        if (widget.post.effectiveImageUrl != null) ...[
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: 500,
              minHeight: 200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.post.effectiveImageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.red[300], size: 40),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: _primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Divider(
            color: Colors.grey.withOpacity(0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPostActions() {
    return FutureBuilder<String?>(
      future: ProfileController().getCurrentUsername(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final currentUsername = snapshot.data;
        if (currentUsername == null ||
            currentUsername != widget.post.username) {
          return const SizedBox.shrink();
        }

        return IconButton(
          icon: Icon(Icons.post_add_rounded, color: _primaryColor),
          onPressed: () {
            final RenderBox button = context.findRenderObject() as RenderBox;
            final RenderBox overlay = Navigator.of(context)
                .overlay!
                .context
                .findRenderObject() as RenderBox;
            final Offset buttonPosition =
                button.localToGlobal(Offset.zero, ancestor: overlay);
            final RelativeRect position = RelativeRect.fromLTRB(
              buttonPosition.dx + button.size.width - 150,
              buttonPosition.dy + 65,
              buttonPosition.dx + button.size.width + 10,
              buttonPosition.dy + button.size.height,
            );
            showMenu(
              context: context,
              position: position,
              items: [
                PopupMenuItem(
                  value: 'update',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text('Update Post'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_rounded, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text('Archive Post'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.red[400]),
                      SizedBox(width: 8),
                      Text('Delete Post',
                          style: TextStyle(color: Colors.red[400])),
                    ],
                  ),
                ),
              ],
            ).then((value) async {
              if (value != null) {
                switch (value) {
                  case 'delete':
                    await _showDeleteConfirmationDialog();
                    break;
                  case 'update':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatePostScreen(
                          post: widget.post.toJson(),
                        ),
                      ),
                    );
                    break;
                  case 'archive':
                    await _handleArchivePost();
                    break;
                }
              }
            });
          },
        );
      },
    );
  }

  Widget _buildCommentsSection() {
    final language = Provider.of<Language>(context, listen: false);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: _borderRadius.bottomLeft,
          bottomRight: _borderRadius.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      language.get('comments'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.post.comments.length}',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        if (_isCommentsVisible) {
                          _animationController.reverse();
                        } else {
                          _animationController.forward();
                        }
                        _isCommentsVisible = !_isCommentsVisible;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _isCommentsVisible
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Column(
              children: [
                if (widget.post.comments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: widget.post.comments
                          .map((comment) => _buildCommentItem(comment))
                          .toList(),
                    ),
                  ),
                _buildCommentInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImage != null || _webImage != null) ...[
            _buildImagePreview(),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: context
                                .read<Language>()
                                .get('Write a comment...'),
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            final picked = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              if (kIsWeb) {
                                final bytes = await picked.readAsBytes();
                                setState(() => _webImage = bytes);
                              } else {
                                setState(
                                    () => _selectedImage = File(picked.path));
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.photo_library_rounded,
                              color: Colors.grey[700],
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isSubmitting ? null : _submitComment,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSubmitting ? Colors.grey[300] : _primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final language = Provider.of<Language>(context, listen: false);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(language.get('delete_post')),
        content: Text(language.get('delete_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(language.get('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(language.get('yes')),
          ),
        ],
      ),
    );

    if (result == true) {
      // Handle post deletion
      if (widget.onPostArchived != null) {
        widget.onPostArchived!();
      }
    }
  }

  Future<void> _handleArchivePost() async {
    // Handle post archiving
    if (widget.onPostArchived != null) {
      widget.onPostArchived!();
    }
  }

  Future<void> _showDeleteCommentConfirmationDialog(int commentId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            SizedBox(width: 8),
            Text('Delete Comment'),
          ],
        ),
        content: Text(
            'Are you sure you want to delete this comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _postService.deleteComment(commentId);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    // Remove the comment from the post's comments list
                    widget.post.comments
                        .removeWhere((comment) => comment.id == commentId);
                    // Also remove from any replies
                    for (var comment in widget.post.comments) {
                      if (comment.replies != null) {
                        comment.replies!
                            .removeWhere((reply) => reply.id == commentId);
                      }
                    }
                  });
                  if (widget.onPostArchived != null) {
                    widget.onPostArchived!();
                  }
                  _showSnackBar('Comment deleted successfully');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Failed to delete comment: $e', isError: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCommentDialog(Comment comment) async {
    final TextEditingController contentController =
        TextEditingController(text: comment.content);
    File? selectedImage;
    Uint8List? webImage;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                hintText: 'Edit your comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final picked =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  if (kIsWeb) {
                    final bytes = await picked.readAsBytes();
                    setState(() => webImage = bytes);
                  } else {
                    setState(() => selectedImage = File(picked.path));
                  }
                }
              },
              icon: Icon(Icons.image),
              label: Text('Change Image'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (kIsWeb) {
                  await _apiService.updateCommentWeb(
                    commentId: comment.id,
                    content: contentController.text,
                    imageBytes: webImage,
                  );
                } else {
                  await _apiService.updateComment(
                    commentId: comment.id,
                    content: contentController.text,
                    image: selectedImage,
                  );
                }
                Navigator.pop(context);
                _showSnackBar('Comment updated successfully');
                if (widget.onPostArchived != null) {
                  widget.onPostArchived!();
                }
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Failed to update comment: $e', isError: true);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
