import 'comment.dart';

class Post {
  final int id;
  final int user;
  final String username;
  final String title;
  final String content;
  final String? imageUrl;
  final String? image;
  final String? profileImageUrl;
  final int interest;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Comment> comments;
  final bool isDeleted;

  Post({
    required this.id,
    required this.user,
    required this.username,
    required this.title,
    required this.content,
    this.imageUrl,
    this.image,
    this.profileImageUrl,
    required this.interest,
    required this.createdAt,
    required this.updatedAt,
    required this.comments,
    this.isDeleted = false,
  });

  String? get effectiveImageUrl => image ?? imageUrl;

  factory Post.fromJson(Map<String, dynamic> json) {
    List<Comment> commentsList = [];
    if (json['comments'] != null) {
      commentsList = List<Comment>.from(
          json['comments'].map((comment) => Comment.fromJson(comment)));
    }

    return Post(
      id: json['id'],
      user: json['user'],
      username: json['username'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['image_url'],
      image: json['image'],
      profileImageUrl: json['user_details']?['profile_picture_url'],
      interest: json['interest'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      comments: commentsList,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'username': username,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'image': image,
      'profile_image_url': profileImageUrl,
      'interest': interest,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'is_deleted': isDeleted,
    };
  }
}
