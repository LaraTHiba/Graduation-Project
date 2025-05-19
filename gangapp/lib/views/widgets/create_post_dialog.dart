import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../languages/language.dart';
import '../../models/post.dart';

/// Dialog widget for creating new posts
class CreatePostDialog extends StatefulWidget {
  /// Callback function when a post is created
  final Function(Post, {dynamic image}) onPostCreated;
  final Post? postToEdit;

  const CreatePostDialog({
    Key? key,
    required this.onPostCreated,
    this.postToEdit,
  }) : super(key: key);

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Uint8List? _webImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.postToEdit != null) {
      _titleController.text = widget.postToEdit!.title;
      _contentController.text = widget.postToEdit!.content;
      if (widget.postToEdit!.imageUrl != null) {
        // Handle existing image
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          // For web, convert the image to Uint8List
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null; // Clear mobile image
          });
        } else {
          // For mobile, use File
          setState(() {
            _selectedImage = File(image.path);
            _webImage = null; // Clear web image
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
                    height: 200,
                    width: double.infinity,
                  )
                : Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    height: 200,
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

  void _showSnackBar(String message, {bool isError = false}) {
    final language = context.read<Language>();
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
        backgroundColor: isError ? Colors.red[400] : const Color(0xFF006C5F),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create the post with the image data
      final post = Post(
        id: widget.postToEdit?.id ?? 0,
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: null, // Will be set after upload
        username: 'Current User', // Replace with actual username
        createdAt: DateTime.now(),
        comments: widget.postToEdit?.comments ?? [],
        user: widget.postToEdit?.user ?? 0,
        interest: widget.postToEdit?.interest ?? 0,
        updatedAt: DateTime.now(),
      );

      // Call onPostCreated with the image data
      final image = kIsWeb ? _webImage : _selectedImage;
      widget.onPostCreated(post, image: image);

      Navigator.pop(context);
      _showSnackBar(
        widget.postToEdit != null
            ? context.read<Language>().get('Post updated')
            : context.read<Language>().get('Post created'),
      );
    } catch (e) {
      _showSnackBar(
        context.read<Language>().get('failed_to_create_post') + e.toString(),
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<Language>();
    final isEditing = widget.postToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing
                    ? language.get('Edit post title')
                    : language.get('Create post title'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: language.get('Post title'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: language.get('Post content'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedImage != null || _webImage != null) ...[
                _buildImagePreview(),
                const SizedBox(height: 16),
              ],
              OutlinedButton.icon(
                onPressed: _handleImageUpload,
                icon: const Icon(Icons.image_rounded),
                label: Text(language.get('Add image')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleSubmit,
                      icon: const Icon(Icons.post_add_rounded),
                      label: Text(
                        isEditing
                            ? language.get('Edit post')
                            : language.get('Post'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
