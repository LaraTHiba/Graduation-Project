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
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: ThemeConfig.titleTextStyle,
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
              style: ThemeConfig.bodyTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${group.createdAt}',
              style: ThemeConfig.captionTextStyle,
            ),
          ],
        ),
      ),
    );
  }
}
