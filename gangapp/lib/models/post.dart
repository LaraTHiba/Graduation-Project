import 'comment.dart';

/// Model class representing a post in the application
class Post {
  /// Unique identifier for the post
  final int id;

  /// ID of the user who created the post
  final int user;

  /// Username of the post creator
  final String username;

  /// Title of the post
  final String title;

  /// Main content of the post
  final String content;

  /// URL of the post's image (legacy field)
  final String? imageUrl;

  /// URL of the post's image (new field)
  final String? image;

  /// URL of the post creator's profile picture
  final String? profileImageUrl;

  /// Interest level or category of the post
  final int interest;

  /// When the post was created
  final DateTime createdAt;

  /// When the post was last updated
  final DateTime updatedAt;

  /// List of comments on the post
  final List<Comment> comments;

  /// Whether the post has been deleted
  final bool isDeleted;

  /// Creates a new Post instance
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

  /// Gets the effective image URL, preferring the new image field over the legacy imageUrl
  String? get effectiveImageUrl => image ?? imageUrl;

  /// Creates a Post instance from a JSON map
  factory Post.fromJson(Map<String, dynamic> json) {
    final commentsList = json['comments'] != null
        ? List<Comment>.from(
            json['comments'].map((comment) => Comment.fromJson(comment)))
        : <Comment>[];

    return Post(
      id: json['id'] as int,
      user: json['user'] as int,
      username: json['username'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      image: json['image'] as String?,
      profileImageUrl: json['user_details']?['profile_picture_url'] as String?,
      interest: json['interest'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      comments: commentsList,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  /// Converts the Post instance to a JSON map
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

  /// Creates a copy of this Post with the given fields replaced with new values
  Post copyWith({
    int? id,
    int? user,
    String? username,
    String? title,
    String? content,
    String? imageUrl,
    String? image,
    String? profileImageUrl,
    int? interest,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Comment>? comments,
    bool? isDeleted,
  }) {
    return Post(
      id: id ?? this.id,
      user: user ?? this.user,
      username: username ?? this.username,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      image: image ?? this.image,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      interest: interest ?? this.interest,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      comments: comments ?? this.comments,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
