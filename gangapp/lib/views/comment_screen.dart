import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../services/api_service.dart';
import '../../services/post_service.dart';
import 'package:intl/intl.dart';
import '../../languages/language.dart';
import 'package:provider/provider.dart';

class CommentScreen extends StatefulWidget {
  final int postId;

  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  dynamic _selectedImage;
  late Future<Map<String, dynamic>> _postFuture;
  late Future<List<dynamic>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _postFuture = _postService.getPost(widget.postId);
    _commentsFuture = _postService.getComments(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          // For web, convert the image to Uint8List
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImage = bytes;
          });
        } else {
          // For mobile, use File
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty && _selectedImage == null)
      return;

    try {
      await _postService.createComment(
        postId: widget.postId,
        content: _commentController.text.trim(),
        image: _selectedImage,
      );

      // Clear the input field and image
      _commentController.clear();
      setState(() {
        _selectedImage = null;
      });

      // Refresh comments
      setState(() {
        _commentsFuture = _postService.getComments(widget.postId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return SizedBox.shrink();

    if (kIsWeb) {
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Stack(
          children: [
            Image.memory(
              _selectedImage as Uint8List,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Stack(
          children: [
            Image.file(
              _selectedImage as File,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCommentContent(Comment comment) {
    String formattedDate;
    try {
      formattedDate = DateFormat('MMM d, y HH:mm').format(comment.createdAt);
    } catch (e) {
      formattedDate = comment.createdAt.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          comment.username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(comment.content),
        if (comment.effectiveImageUrl != null) ...[
          const SizedBox(height: 8),
          Image.network(
            comment.effectiveImageUrl!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          formattedDate,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
        backgroundColor: Color(0xFF006C5F),
      ),
      body: Column(
        children: [
          // Post preview
          FutureBuilder(
            future: _postFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final post =
                  Post.fromJson(snapshot.data! as Map<String, dynamic>);
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(post.content),
                  ],
                ),
              );
            },
          ),
          // Comments list
          Expanded(
            child: FutureBuilder(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final comments = (snapshot.data! as List)
                    .map((json) =>
                        Comment.fromJson(json as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: _buildCommentContent(comment),
                    );
                  },
                );
              },
            ),
          ),
          // Comment input
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              children: [
                _buildImagePreview(),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image),
                      onPressed: _pickImage,
                      color: Color(0xFF006C5F),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: context
                              .read<Language>()
                              .get('Write a comment...'),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send),
                      color: Color(0xFF006C5F),
                      onPressed: _submitComment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
