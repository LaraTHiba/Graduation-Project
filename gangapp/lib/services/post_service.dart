import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../utils/platform_utils.dart';
import 'api_service.dart';

/// Service class for handling post and comment-related operations
class PostService {
  final ApiService _apiService = ApiService();

  /// Post CRUD Operations
  ///-----------------------

  /// Retrieves all posts
  Future<List<dynamic>> getPosts() => _apiService.getPosts();

  /// Retrieves posts for a specific user
  Future<List<dynamic>> getUserPosts(String username) =>
      _apiService.getUserPosts(username);

  /// Retrieves a specific post by ID
  Future<Map<String, dynamic>> getPost(int postId) =>
      _apiService.getPost(postId);

  /// Searches posts based on a query string
  Future<List<dynamic>> searchPosts(String query) =>
      _apiService.searchPosts(query);

  /// Retrieves all soft-deleted posts
  Future<List<dynamic>> getDeletedPosts() => _apiService.getDeletedPosts();

  /// Restores a soft-deleted post
  Future<Map<String, dynamic>> restorePost(int postId) =>
      _apiService.restorePost(postId);

  /// Permanently deletes a post
  Future<void> hardDeletePost(int postId) => _apiService.hardDeletePost(postId);

  /// Soft deletes a post
  Future<void> deletePost(int postId) => _apiService.deletePost(postId);

  /// Archives a post
  Future<void> archivePost(int postId) => _apiService.archivePost(postId);

  /// Creates a new post with platform-specific handling for images
  ///
  /// [title] The post title
  /// [content] The post content
  /// [interest] The interest category ID
  /// [image] Optional image file (File for mobile, Uint8List for web)
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    required int interest,
    dynamic image,
  }) async {
    if (image != null) {
      if (kIsWeb && !(image is Uint8List)) {
        throw Exception("For web, image must be Uint8List");
      }
      if (!kIsWeb && !(image is File)) {
        throw Exception("For mobile, image must be File");
      }
    }

    return kIsWeb
        ? _apiService.createPostWeb(
            title: title,
            content: content,
            interest: interest,
            imageBytes: image is Uint8List ? image : null,
          )
        : _apiService.createPost(
            title: title,
            content: content,
            interest: interest,
            image: image,
          );
  }

  /// Updates an existing post with platform-specific handling for images
  ///
  /// [postId] The ID of the post to update
  /// [title] The new post title
  /// [content] The new post content
  /// [interest] The new interest category ID
  /// [image] Optional new image file (File for mobile, Uint8List for web)
  Future<Map<String, dynamic>> updatePost({
    required int postId,
    required String title,
    required String content,
    required int interest,
    dynamic image,
  }) async {
    _validateImageType(image);

    return kIsWeb
        ? _apiService.updatePostWeb(
            postId: postId,
            title: title,
            content: content,
            interest: interest,
            imageBytes: image is Uint8List ? image : null,
          )
        : _apiService.updatePost(
            postId: postId,
            title: title,
            content: content,
            interest: interest,
            image: image,
          );
  }

  /// Comment Operations
  ///------------------

  /// Retrieves all comments for a post
  Future<List<dynamic>> getComments(int postId) =>
      _apiService.getComments(postId);

  /// Retrieves a specific comment by ID
  Future<Map<String, dynamic>> getComment(int commentId) =>
      _apiService.getComment(commentId);

  /// Retrieves all comments by a specific user
  Future<List<dynamic>> getUserComments(String username) =>
      _apiService.getUserComments(username);

  /// Retrieves all soft-deleted comments
  Future<List<dynamic>> getDeletedComments() =>
      _apiService.getDeletedComments();

  /// Restores a soft-deleted comment
  Future<Map<String, dynamic>> restoreComment(int commentId) =>
      _apiService.restoreComment(commentId);

  /// Soft deletes a comment
  Future<void> deleteComment(int commentId) =>
      _apiService.deleteComment(commentId);

  /// Permanently deletes a comment
  Future<void> hardDeleteComment(int commentId) =>
      _apiService.hardDeleteComment(commentId);

  /// Creates a new comment with platform-specific handling for images
  ///
  /// [postId] The ID of the post to comment on
  /// [content] The comment content
  /// [image] Optional image file (File for mobile, Uint8List for web)
  Future<Map<String, dynamic>> createComment({
    required int postId,
    required String content,
    dynamic image,
  }) async {
    if (content.trim().isEmpty) {
      throw Exception('Comment content cannot be empty');
    }

    _validateImageType(image);

    return kIsWeb
        ? _apiService.createCommentWeb(
            postId: postId,
            content: content.trim(),
            imageBytes: image is Uint8List ? image : null,
          )
        : _apiService.createComment(
            postId: postId,
            content: content.trim(),
            image: image,
          );
  }

  /// Creates a reply to a comment with platform-specific handling for images
  ///
  /// [postId] The ID of the post containing the parent comment
  /// [commentId] The ID of the parent comment
  /// [content] The reply content
  /// [image] Optional image file (File for mobile, Uint8List for web)
  Future<Map<String, dynamic>> createReply({
    required int postId,
    required int commentId,
    required String content,
    dynamic image,
  }) async {
    _validateImageType(image);

    return kIsWeb
        ? _apiService.createReplyWeb(
            postId: postId,
            commentId: commentId,
            content: content,
            imageBytes: image is Uint8List ? image : null,
          )
        : _apiService.createReply(
            postId: postId,
            commentId: commentId,
            content: content,
            image: image,
          );
  }

  /// Updates an existing comment with platform-specific handling for images
  ///
  /// [commentId] The ID of the comment to update
  /// [content] The new comment content
  /// [image] Optional new image file (File for mobile, Uint8List for web)
  Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required String content,
    dynamic image,
  }) async {
    _validateImageType(image);

    return kIsWeb
        ? _apiService.updateCommentWeb(
            commentId: commentId,
            content: content,
            imageBytes: image is Uint8List ? image : null,
          )
        : _apiService.updateComment(
            commentId: commentId,
            content: content,
            image: image,
          );
  }

  /// Uploads a file with platform-specific handling
  ///
  /// [file] The file to upload (File for mobile, Uint8List for web)
  /// [fileName] Optional name for the file (required for web)
  /// [contentType] Optional MIME type (required for web)
  Future<Map<String, dynamic>> uploadFile(
    dynamic file, {
    String? fileName,
    String? contentType,
  }) async {
    if (file == null) throw Exception('File cannot be null');
    _validateImageType(file);

    return kIsWeb
        ? _apiService.uploadFileWeb(
            file,
            fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
            contentType ?? 'image/jpeg',
          )
        : _apiService.uploadFile(file);
  }

  /// Validates that the image is of the correct type for the current platform
  void _validateImageType(dynamic image) {
    if (image != null &&
        !(image.toString().contains('File') || image is Uint8List)) {
      throw Exception(
          'Image must be either a File (mobile) or Uint8List (web)');
    }
  }
}
