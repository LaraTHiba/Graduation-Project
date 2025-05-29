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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF23272F) : theme.cardColor,
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
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.textTheme.titleLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${group.createdByUsername}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: group.isMember ? onLeave : onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        group.isMember ? Colors.red : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    group.isMember ? 'Leave' : 'Join',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              group.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${group.createdAt}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
