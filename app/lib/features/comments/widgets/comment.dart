import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'skeletons/comment_item_skeleton_widget.dart';

class CommentWidget extends ConsumerWidget {
  final Comment comment;
  final CommentsManager manager;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.manager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msgContent = comment.msgContent();
    final formatted = msgContent.formattedBody();
    var commentTime =
        DateTime.fromMillisecondsSinceEpoch(comment.originServerTs());
    final time = commentTime.timeago();
    final memberInfo = ref.watch(
      roomMemberProvider(
        (roomId: manager.roomIdStr(), userId: comment.sender().toString()),
      ),
    );

    return memberInfo.when(
      data: (data) {
        final profileData = data.profile;
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: ActerAvatar(
                  mode: DisplayMode.DM,
                  avatarInfo: AvatarInfo(
                    uniqueId: manager.roomIdStr(),
                    displayName: profileData.displayName ?? manager.roomIdStr(),
                    avatar: profileData.getAvatarImage(),
                  ),
                  size: 18,
                ),
                title: Text(
                  profileData.displayName ?? manager.roomIdStr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(comment.sender().toString()),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: formatted != null
                    ? RenderHtml(
                        text: formatted,
                      )
                    : Text(msgContent.body()),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  time.toString(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      error: (err, stackTrace) => const CommentItemSkeleton(),
      loading: () => const CommentItemSkeleton(),
    );
  }
}
