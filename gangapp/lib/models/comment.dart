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
  final List<Comment>? replies;
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

  String? get effectiveImageUrl => image ?? imageUrl;

  factory Comment.fromJson(Map<String, dynamic> json) {
    List<Comment>? repliesList;
    if (json['replies'] != null) {
      repliesList = List<Comment>.from(
          json['replies'].map((reply) => Comment.fromJson(reply)));
    }

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
      replies: repliesList,
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
