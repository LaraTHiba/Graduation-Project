import 'package:flutter/material.dart';
import '../models/group.dart';
import '../config/theme.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const GroupCard({
    Key? key,
    required this.group,
    required this.onJoin,
    required this.onLeave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF232323),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: ThemeConfig.titleTextStyle
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${group.createdByUsername}',
                        style: ThemeConfig.captionTextStyle
                            .copyWith(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: group.isMember ? onLeave : onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: group.isMember
                        ? ThemeConfig.errorColor
                        : ThemeConfig.primaryColor,
                  ),
                  child: Text(
                    group.isMember ? 'Leave' : 'Join',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              group.description,
              style: ThemeConfig.bodyTextStyle.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${group.createdAt}',
              style: ThemeConfig.captionTextStyle
                  .copyWith(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
