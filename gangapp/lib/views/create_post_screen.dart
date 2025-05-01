import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:io' if (dart.library.js) 'dart:ui' as io;
import 'package:gangapp/services/api_service.dart';

class CreatePostScreen extends StatefulWidget {
  final Map<String, dynamic>? post;

  const CreatePostScreen({Key? key, this.post}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _apiService = ApiService();

  dynamic _selectedImage;
  Uint8List? _webImage;
  bool _isLoading = false;
  int? _selectedInterest;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post!['title'];
      _contentController.text = widget.post!['content'];
      _selectedInterest = widget.post!['interest'];
    }
    _loadFirstInterest();
  }

  Future<void> _loadFirstInterest() async {
    try {
      final interestId = await _apiService.getFirstValidInterestId();
      setState(() {
        _selectedInterest = interestId;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading interest: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        if (kIsWeb) {
          // For web platform
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null; // Clear mobile image
          });
        } else {
          // For mobile platforms
          setState(() {
            _selectedImage = File(image.path);
            _webImage = null; // Clear web image
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate() || _selectedInterest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.post != null) {
        // Update existing post
        if (kIsWeb) {
          await _apiService.updatePostWeb(
            postId: widget.post!['id'],
            title: _titleController.text,
            content: _contentController.text,
            interest: _selectedInterest!,
            imageBytes: _webImage,
          );
        } else {
          await _apiService.updatePost(
            postId: widget.post!['id'],
            title: _titleController.text,
            content: _contentController.text,
            interest: _selectedInterest!,
            image: _selectedImage,
          );
        }
      } else {
        // Create new post
        if (kIsWeb) {
          await _apiService.createPostWeb(
            title: _titleController.text,
            content: _contentController.text,
            interest: _selectedInterest!,
            imageBytes: _webImage,
          );
        } else {
          await _apiService.createPost(
            title: _titleController.text,
            content: _contentController.text,
            interest: _selectedInterest!,
            image: _selectedImage,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post != null ? 'Edit Post' : 'Create Post'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick Image'),
              ),
              if (_selectedImage != null || _webImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Image selected',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.post != null ? 'Update Post' : 'Create Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
