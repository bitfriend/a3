import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::mention_profile_builder');

class MentionProfileBuilder extends ConsumerWidget {
  final BuildContext context;
  final RoomQuery roomQuery;

  const MentionProfileBuilder({
    super.key,
    required this.context,
    required this.roomQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final userId = client.userId().toString();
    final membersLoader = ref.watch(membersIdsProvider(roomQuery.roomId));
    return membersLoader.when(
      loading: () => Skeletonizer(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Card(child: ListView()),
        ),
      ),
      error: (e, s) {
        _log.severe('Failed to load room members', e, s);
        return ErrorWidget(L10n.of(context).loadingFailed(e));
      },
      data: (members) {
        final users = members.fold<Map<String, String>>({}, (map, uId) {
          if (uId != userId) {
            final displayName = ref.watch(
              memberDisplayNameProvider(
                (roomId: roomQuery.roomId, userId: uId),
              ),
            );

            final normalizedId = uId.toLowerCase();
            final normalizedName = displayName.valueOrNull ?? '';
            final normalizedQuery = roomQuery.query.toLowerCase();

            if (normalizedId.contains(normalizedQuery) ||
                normalizedName.toLowerCase().contains(normalizedQuery)) {
              map[uId] = normalizedName;
            }
          }
          return map;
        });
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            elevation: 2,
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(0),
              itemCount: users.length,
              itemBuilder: (_, index) {
                final id = users.keys.elementAt(index);
                final displayName = users.values.elementAt(index);
                return ListTile(
                  dense: true,
                  onTap: () {
                    final autocomplete = MultiTriggerAutocomplete.of(context);
                    ref
                        .read(chatInputProvider.notifier)
                        .addMention(displayName, id);
                    return autocomplete.acceptAutocompleteOption(
                      displayName.isNotEmpty ? displayName : id.substring(1),
                    );
                  },
                  leading: Consumer(
                    builder: (context, ref, child) {
                      final avatarInfo = ref.watch(
                        memberAvatarInfoProvider(
                          (roomId: roomQuery.roomId, userId: id),
                        ),
                      );
                      return ActerAvatar(
                        options: AvatarOptions.DM(
                          avatarInfo,
                          size: 18,
                        ),
                      );
                    },
                  ),
                  title: Text(displayName),
                  titleTextStyle: Theme.of(context).textTheme.bodyMedium,
                  subtitleTextStyle: Theme.of(context).textTheme.labelMedium,
                  subtitle: displayName.isNotEmpty ? Text(id) : null,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
