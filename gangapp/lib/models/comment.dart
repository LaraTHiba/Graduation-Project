/// Model class representing a comment in the application
class Comment {
  /// Unique identifier for the comment
  final int id;

  /// ID of the user who created the comment
  final int user;

  /// Username of the comment creator
  final String username;

  /// Content of the comment
  final String content;

  /// URL of the comment's image (new field)
  final String? image;

  /// URL of the comment's image (legacy field)
  final String? imageUrl;

  /// URL of the comment creator's profile picture
  final String? profileImageUrl;

  /// ID of the parent comment if this is a reply
  final int? parentComment;

  /// When the comment was created
  final DateTime createdAt;

  /// When the comment was last updated
  final DateTime updatedAt;

  /// List of replies to this comment
  List<Comment>? replies;

  /// Whether the comment has been deleted
  final bool isDeleted;

  /// Creates a new Comment instance
  Comment({
    required this.id,
    required this.user,
    required this.username,
    required this.content,
    this.image,
    this.imageUrl,
    this.profileImageUrl,
    this.parentComment,
    required this.createdAt,
    required this.updatedAt,
    this.replies,
    this.isDeleted = false,
  });

  /// Gets the effective image URL, handling both local and remote URLs
  String? get effectiveImageUrl {
    if (imageUrl == null) return null;
    return imageUrl!.startsWith('http')
        ? imageUrl
        : 'http://127.0.0.1:8000$imageUrl';
  }

  /// Creates a Comment instance from a JSON map
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      user: json['user'] as int,
      username: json['username'] as String,
      content: json['content'] as String,
      image: json['image'] as String?,
      imageUrl: json['image_url'] as String?,
      profileImageUrl: json['user_details']?['profile_picture_url'] as String?,
      parentComment: json['parent_comment'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((reply) => Comment.fromJson(reply as Map<String, dynamic>))
              .toList()
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  /// Converts the Comment instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'username': username,
      'content': content,
      'image': image,
      'image_url': imageUrl,
      'profile_image_url': profileImageUrl,
      'parent_comment': parentComment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'replies': replies?.map((reply) => reply.toJson()).toList(),
      'is_deleted': isDeleted,
    };
  }

  /// Creates a copy of this Comment with the given fields replaced with new values
  Comment copyWith({
    int? id,
    int? user,
    String? username,
    String? content,
    String? image,
    String? imageUrl,
    String? profileImageUrl,
    int? parentComment,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Comment>? replies,
    bool? isDeleted,
  }) {
    return Comment(
      id: id ?? this.id,
      user: user ?? this.user,
      username: username ?? this.username,
      content: content ?? this.content,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      parentComment: parentComment ?? this.parentComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
