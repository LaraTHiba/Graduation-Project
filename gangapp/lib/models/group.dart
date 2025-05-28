class Group {
  final int id;
  final String name;
  final String description;
  final int memberCount;
  final int createdBy;
  final String createdByUsername;
  final String createdAt;
  final String updatedAt;
  final bool isMember;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.createdBy,
    required this.createdByUsername,
    required this.createdAt,
    required this.updatedAt,
    this.isMember = false,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      memberCount: json['member_count'] ?? 0,
      createdBy: json['created_by'],
      createdByUsername: json['created_by_username'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isMember: json['is_member'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'member_count': memberCount,
      'created_by': createdBy,
      'created_by_username': createdByUsername,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_member': isMember,
    };
  }
}
