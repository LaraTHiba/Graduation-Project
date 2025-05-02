class Comment {
  final int id;
  final int user;
  final String username;
  final String content;
  final String? image;
  final String? imageUrl;
  final String? profileImageUrl;
  final int? parentComment;
  final DateTime createdAt;
  final DateTime updatedAt;
  List<Comment>? replies;
  final bool isDeleted;

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

  String? get effectiveImageUrl {
    if (imageUrl == null) return null;
    return imageUrl!.startsWith('http')
        ? imageUrl
        : 'http://127.0.0.1:8000$imageUrl';
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      user: json['user'],
      username: json['username'],
      content: json['content'],
      image: json['image'],
      imageUrl: json['image_url'],
      profileImageUrl: json['user_details']?['profile_picture_url'],
      parentComment: json['parent_comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((reply) => Comment.fromJson(reply))
              .toList()
          : null,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

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
}
