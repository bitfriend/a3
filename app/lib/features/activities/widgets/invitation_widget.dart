import 'dart:typed_data';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/preview/actions/show_room_preview.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Invitation;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::activities::invitation_widget');

class InvitationWidget extends ConsumerStatefulWidget {
  final Invitation invitation;

  const InvitationWidget({
    super.key,
    required this.invitation,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _InvitationWidgetState();
}

class _InvitationWidgetState extends ConsumerState<InvitationWidget> {
  String? roomTitle;
  late AvatarInfo avatarInfo;

  @override
  void initState() {
    super.initState();
    _initializeAvatarInfo();
    _fetchDetails();
  }

  void _initializeAvatarInfo() {
    setState(() {
      avatarInfo = AvatarInfo(uniqueId: widget.invitation.roomIdStr());
    });
  }

  void _fetchDetails() async {
    final room = widget.invitation.room();
    final title = await room.displayName();
    setState(() {
      roomTitle = title.text();
      avatarInfo = AvatarInfo(
        uniqueId: widget.invitation.roomIdStr(),
        displayName: roomTitle,
      );
    });
    final avatarData = (await room.avatar(null)).data();
    if (avatarData != null) {
      setState(() {
        avatarInfo = AvatarInfo(
          uniqueId: widget.invitation.roomIdStr(),
          displayName: roomTitle,
          avatar: MemoryImage(Uint8List.fromList(avatarData.asTypedList())),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildLeadingImageUI(),
            const SizedBox(width: 8),
            Expanded(
              child: buildContentUI(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLeadingImageUI() {
    final isDM = widget.invitation.isDm();
    final profile =
        ref.watch(invitationUserProfileProvider(widget.invitation)).valueOrNull;
    final roomId = widget.invitation.roomIdStr();

    return ActerAvatar(
      options: isDM
          ? AvatarOptions.DM(
              AvatarInfo(
                uniqueId: roomId,
                displayName: profile?.displayName,
                avatar: profile?.avatar,
              ),
              size: 24,
            )
          : AvatarOptions(
              avatarInfo,
              size: 24,
            ),
    );
  }

  Widget buildContentUI(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle(context),
        const SizedBox(height: 8),
        buildInvitationType(context),
        if (!widget.invitation.isDm()) ...[
          const SizedBox(height: 4),
          buildInviterChip(),
        ],
        const SizedBox(height: 12),
        buildActionButtons(context),
      ],
    );
  }

  Widget buildTitle(BuildContext context) {
    final isDM = widget.invitation.isDm();
    final profile =
        ref.watch(invitationUserProfileProvider(widget.invitation)).valueOrNull;
    final roomId = widget.invitation.roomIdStr();
    final senderId = widget.invitation.senderIdStr();

    return GestureDetector(
      onTap: () => showRoomPreview(context: context, roomIdOrAlias: roomId),
      child: Text(
        isDM ? (profile?.displayName ?? senderId) : (roomTitle ?? roomId),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildInvitationType(BuildContext context) {
    final lang = L10n.of(context);
    final isDM = widget.invitation.isDm();
    final isSpace = widget.invitation.room().isSpace();

    return Text(
      isDM
          ? lang.invitationToDM
          : (isSpace ? lang.invitationToSpace : lang.invitationToChat),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget buildInviterChip() {
    final profile =
        ref.watch(invitationUserProfileProvider(widget.invitation)).valueOrNull;
    final senderId = widget.invitation.senderIdStr();

    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: ActerAvatar(
        options: AvatarOptions.DM(
          AvatarInfo(
            uniqueId: senderId,
            displayName: profile?.displayName,
            avatar: profile?.avatar,
          ),
          size: 24,
        ),
      ),
      label: Text(profile?.displayName ?? senderId),
    );
  }

  Widget buildActionButtons(BuildContext context) {
    final lang = L10n.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => _onTapDeclineInvite(context),
          child: Text(lang.decline),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _onTapAcceptInvite(context),
          child: Text(lang.accept),
        ),
      ],
    );
  }

  void _onTapAcceptInvite(BuildContext context) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.joining);
    final client = await ref.read(alwaysClientProvider.future);
    final roomId = widget.invitation.roomIdStr();
    final isSpace = widget.invitation.room().isSpace();
    try {
      await widget.invitation.accept();
    } catch (e, s) {
      _log.severe('Failure accepting invite', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToAcceptInvite(e),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      // timeout to wait for 10seconds to ensure the room is ready
      await client.waitForRoom(roomId, 10);
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.joinedDelayed);
      // do not forward in this case
      return;
    }
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showToast(lang.joined);
    if (isSpace) {
      goToSpace(context, roomId);
    } else {
      goToChat(context, roomId);
    }
  }

  void _onTapDeclineInvite(BuildContext context) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.rejecting);
    try {
      bool res = await widget.invitation.reject();
      ref.invalidate(invitationListProvider);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      if (res) {
        EasyLoading.showToast(lang.rejected);
      } else {
        _log.severe('Failed to reject invitation');
        EasyLoading.showError(
          lang.failedToReject,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, s) {
      _log.severe('Failure reject invite', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToRejectInvite(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
