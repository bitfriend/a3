import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class _MemberListInnerSkeleton extends StatelessWidget {
  const _MemberListInnerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Skeletonizer(
        child: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: const AvatarInfo(
            uniqueId: 'no id given',
          ),
          size: 18,
        ),
      ),
      title: Skeletonizer(
        child: Text(
          'no id',
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: Skeletonizer(
        child: Text(
          'no id',
          style: Theme.of(context)
              .textTheme
              .labelLarge!
              .copyWith(color: Theme.of(context).colorScheme.neutral5),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class MemberListEntry extends ConsumerWidget {
  final String memberId;
  final String roomId;
  final Member? myMembership;

  const MemberListEntry({
    super.key,
    required this.memberId,
    required this.roomId,
    this.myMembership,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileData =
        ref.watch(roomMemberProvider((userId: memberId, roomId: roomId)));
    return profileData.when(
      data: (data) => _MemberListEntryInner(
        userId: memberId,
        roomId: roomId,
        member: data.member,
        profile: data.profile,
      ),
      error: (e, s) => Text('Error loading Profile: $e'),
      loading: () => const _MemberListInnerSkeleton(),
    );
  }
}

class _MemberListEntryInner extends ConsumerWidget {
  final Member member;
  final ProfileData profile;
  final String userId;
  final String roomId;

  const _MemberListEntryInner({
    required this.userId,
    required this.member,
    required this.profile,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberStatus = member.membershipStatusStr();
    Widget? trailing;
    if (memberStatus == 'Admin') {
      trailing = const Tooltip(
        message: 'Admin',
        child: Icon(Atlas.crown_winner_thin),
      );
    } else if (memberStatus == 'Mod') {
      trailing = const Tooltip(
        message: 'Moderator',
        child: Icon(Atlas.shield_star_win_thin),
      );
    }

    return ListTile(
      onTap: () async {
        if (context.mounted) {
          await showMemberInfoDrawer(
            context: context,
            roomId: roomId,
            memberId: userId,
          );
        }
      },
      leading: ActerAvatar(
        mode: DisplayMode.DM,
        avatarInfo: AvatarInfo(
          uniqueId: userId,
          displayName: profile.displayName,
          avatar: profile.getAvatarImage(),
        ),
        size: 18,
      ),
      title: Text(
        profile.displayName ?? userId,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: profile.displayName != null
          ? Text(
              userId,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(color: Theme.of(context).colorScheme.neutral5),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: trailing,
    );
  }
}
