import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AboutCard extends ConsumerWidget {
  final String spaceId;

  const AboutCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceId));
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    final invited =
        ref.watch(spaceInvitedMembersProvider(spaceId)).valueOrNull ?? [];
    final showInviteBtn = membership?.canString('CanInvite') == true;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                showInviteBtn && invited.length <= 100
                    ? OutlinedButton(
                        onPressed: () => context.pushNamed(
                          Routes.spaceInvite.name,
                          pathParameters: {'spaceId': spaceId},
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.success,
                          ),
                        ),
                        child: const Text('Invite'),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            space.when(
              data: (space) {
                final topic = space.topic();
                return Text(
                  topic ?? 'no topic found',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
              error: (error, stack) => Text('Loading failed: $error'),
              loading: () => const Text('Loading'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
