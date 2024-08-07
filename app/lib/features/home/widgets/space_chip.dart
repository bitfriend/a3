import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceChip extends ConsumerWidget {
  final SpaceItem? space;
  final String? spaceId;
  final bool onTapOpenSpaceDetail;
  final bool isCompactView;
  final VoidCallback? onTapSelectSpace;

  const SpaceChip({
    super.key,
    this.space,
    this.spaceId,
    this.onTapOpenSpaceDetail = true,
    this.isCompactView = false,
    this.onTapSelectSpace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (space == null) {
      if (spaceId == null) {
        throw L10n.of(context).spaceOrSpaceIdMustBeProvided;
      }
      final brief = ref.watch(briefSpaceItemProvider(spaceId!));
      return brief.when(
        data: (space) {
          return renderSpace(context, space);
        },
        error: (error, st) => Chip(
          label: Text(L10n.of(context).loadingFailed(error)),
        ),
        loading: () => renderLoading(spaceId!),
      );
    }
    return renderSpace(context, space!);
  }

  Widget renderLoading(String spaceId) {
    return Skeletonizer(
      child: Chip(
        avatar: ActerAvatar(
          options: AvatarOptions(
            AvatarInfo(
              uniqueId: spaceId,
            ),
            size: 24,
          ),
        ),
        label: Text(spaceId),
      ),
    );
  }

  Widget renderSpace(BuildContext context, SpaceItem space) {
    String spaceName = space.avatarInfo.displayName ?? space.roomId;
    return InkWell(
      onTap:
          onTapOpenSpaceDetail ? () => goToSpace(context, space.roomId) : null,
      child: isCompactView
          ? Row(
              children: [
                const Text('In'),
                ActerInlineTextButton(
                  onPressed: () =>
                      onTapSelectSpace != null ? onTapSelectSpace!() : null,
                  child: Text(spaceName),
                ),
              ],
            )
          : Chip(
              avatar: ActerAvatar(
                options: AvatarOptions(
                  AvatarInfo(
                    uniqueId: space.roomId,
                    displayName: space.avatarInfo.displayName,
                    avatar: space.avatarInfo.avatar,
                  ),
                  size: 24,
                ),
              ),
              label: Text(spaceName),
            ),
    );
  }
}
