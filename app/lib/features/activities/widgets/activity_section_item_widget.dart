import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivitySectionItemWidget extends ConsumerWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const ActivitySectionItemWidget({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildLeadingIconUI(context),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTitleSubtitleUI(context),
                  if (actions != null && actions!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(children: actions!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLeadingIconUI(BuildContext context) {
    return Icon(
      icon,
      size: 26,
      color: iconColor ?? Theme.of(context).colorScheme.error,
    );
  }

  Widget buildTitleSubtitleUI(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          ConstrainedBox(
            key: Key('subtitle-key'),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 100,
            ),
            child: Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ],
    );
  }
}
