import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../utils/platform_utils.dart';
import 'api_service.dart';

class PostService {
  final ApiService _apiService = ApiService();

  // Post CRUD operations
  Future<List<dynamic>> getPosts() => _apiService.getPosts();
  Future<List<dynamic>> getUserPosts(String username) =>
      _apiService.getUserPosts(username);
  Future<Map<String, dynamic>> getPost(int postId) =>
      _apiService.getPost(postId);
  Future<List<dynamic>> searchPosts(String query) =>
      _apiService.searchPosts(query);
  Future<List<dynamic>> getDeletedPosts() => _apiService.getDeletedPosts();
  Future<Map<String, dynamic>> restorePost(int postId) =>
      _apiService.restorePost(postId);
  Future<void> hardDeletePost(int postId) => _apiService.hardDeletePost(postId);
  Future<void> deletePost(int postId) => _apiService.deletePost(postId);
  Future<void> archivePost(int postId) => _apiService.archivePost(postId);

  // Platform-agnostic post creation
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    required int interest,
    dynamic image,
  }) async {
    if (image != null &&
        !(image.toString().contains('File') || image is Uint8List)) {
      throw Exception(
          'Image must be either a File (mobile) or Uint8List (web)');
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

  // Platform-agnostic post update
  Future<Map<String, dynamic>> updatePost({
    required int postId,
    required String title,
    required String content,
    required int interest,
    dynamic image,
  }) async {
    if (image != null &&
        !(image.toString().contains('File') || image is Uint8List)) {
      throw Exception(
          'Image must be either a File (mobile) or Uint8List (web)');
    }

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

  // Comment operations
  Future<List<dynamic>> getComments(int postId) =>
      _apiService.getComments(postId);
  Future<Map<String, dynamic>> getComment(int commentId) =>
      _apiService.getComment(commentId);
  Future<List<dynamic>> getUserComments(String username) =>
      _apiService.getUserComments(username);
  Future<List<dynamic>> getDeletedComments() =>
      _apiService.getDeletedComments();
  Future<Map<String, dynamic>> restoreComment(int commentId) =>
      _apiService.restoreComment(commentId);
  Future<void> deleteComment(int commentId) =>
      _apiService.deleteComment(commentId);
  Future<void> hardDeleteComment(int commentId) =>
      _apiService.hardDeleteComment(commentId);

  // Platform-agnostic comment creation
  Future<Map<String, dynamic>> createComment({
    required int postId,
    required String content,
    dynamic image,
  }) async {
    if (content.trim().isEmpty) {
      throw Exception('Comment content cannot be empty');
    }

    if (image != null &&
        !(image.toString().contains('File') || image is Uint8List)) {
      throw Exception(
          'Image must be either a File (mobile) or Uint8List (web)');
    }

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

  // Platform-agnostic reply creation
  Future<Map<String, dynamic>> createReply({
    required int postId,
    required int commentId,
    required String content,
    dynamic image,
  }) async {
    if (image != null &&
        !(image.toString().contains('File') || image is Uint8List)) {
      throw Exception(
          'Image must be either a File (mobile) or Uint8List (web)');
    }

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

  // Platform-agnostic comment update
  Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required String content,
    dynamic image,
  }) async {
    if (image != null &&
        !(image.toString().contains('File') || image is Uint8List)) {
      throw Exception(
          'Image must be either a File (mobile) or Uint8List (web)');
    }

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

  // Platform-agnostic file upload
  Future<Map<String, dynamic>> uploadFile(dynamic file,
      {String? fileName, String? contentType}) async {
    if (file == null) throw Exception('File cannot be null');
    if (!(file.toString().contains('File') || file is Uint8List)) {
      throw Exception('File must be either a File (mobile) or Uint8List (web)');
    }

    return kIsWeb
        ? _apiService.uploadFileWeb(
            file,
            fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
            contentType ?? 'image/jpeg',
          )
        : _apiService.uploadFile(file);
  }
}
