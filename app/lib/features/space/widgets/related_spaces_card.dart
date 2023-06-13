import 'dart:core';

import 'package:acter/features/space/providers/space_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class RelatedSpacesCard extends ConsumerWidget {
  final String spaceId;

  const RelatedSpacesCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceItems = ref.watch(relatedSpacesProvider(spaceId));

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Related Spaces',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...spaceItems.when(
              data: (items) => items.map(
                (item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () => context.go('/${item.roomId}'),
                          title: Text(
                            item.spaceProfileData.displayName ?? item.roomId,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          leading: item.spaceProfileData.hasAvatar()
                              ? CircleAvatar(
                                  foregroundImage:
                                      item.spaceProfileData.getAvatarImage(),
                                  radius: 24,
                                )
                              : SvgPicture.asset(
                                  'assets/icon/acter.svg',
                                  height: 24,
                                  width: 24,
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              error: (error, stack) => [Text('Loading spaces failed: $error')],
              loading: () => [const Text('Loading')],
            ),
          ],
        ),
      ),
    );
  }
}
