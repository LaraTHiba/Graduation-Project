import 'package:flutter/material.dart';
import '../../models/post.dart';
import 'post_card.dart';

class HomeWidget {
  static Widget buildPostCard(Post post, Function(int) onCommentPressed,
      {Function? onPostArchived}) {
    return PostCard(
      post: post,
      onCommentPressed: onCommentPressed,
      onPostArchived: onPostArchived,
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
