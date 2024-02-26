import 'package:acter/common/providers/room_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::room::notification_settings_tile');

String? notifToText(String curNotifStatus) {
  if (curNotifStatus == 'muted') {
    return 'Muted';
  } else if (curNotifStatus == 'mentions') {
    return 'Only on mentions and keywords';
  } else if (curNotifStatus == 'all') {
    return 'All Messages';
  } else {
    return null;
  }
}

class _NotificationSettingsTile extends ConsumerWidget {
  final String roomId;
  final String? title;
  final String? defaultTitle;
  final bool includeMentions;

  const _NotificationSettingsTile({
    required this.roomId,
    this.title,
    this.defaultTitle,
    this.includeMentions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationStatus =
        ref.watch(roomNotificationStatusProvider(roomId));
    final defaultNotificationStatus =
        ref.watch(roomDefaultNotificationStatusProvider(roomId));
    final curNotifStatus = notificationStatus.valueOrNull;
    final tileTextTheme = Theme.of(context).textTheme.bodySmall;
    // ignore: always_declare_return_types
    return SettingsTile(
      title: Text(
        title ?? 'Notifications',
        style: tileTextTheme,
      ),
      description: Text(
        notifToText(curNotifStatus ?? '') ??
            (defaultTitle ??
                'Default (${notifToText(defaultNotificationStatus.valueOrNull ?? '') ?? 'undefined'})'),
      ),
      leading: curNotifStatus == 'muted'
          ? const Icon(Atlas.bell_dash_bold, size: 18)
          : const Icon(Atlas.bell_thin, size: 18),
      trailing: PopupMenuButton<String>(
        initialValue: curNotifStatus,
        // Callback that sets the selected popup menu item.
        onSelected: (String newMode) async {
          _log.info('new value: $newMode');
          final room = await ref.read(maybeRoomProvider(roomId).future);
          if (room == null) {
            EasyLoading.showError(
              'Room not found',
            );
            return;
          }
          EasyLoading.showProgress(0);
          // '' is a special case resetting to default.
          if (await room.setNotificationMode(
            newMode == '' ? null : newMode,
          )) {
            EasyLoading.showSuccess(
              'Notification status submitted',
            );
            await Future.delayed(const Duration(seconds: 1), () {
              // FIXME: we want to refresh the view but don't know
              //        when the event was confirmed form sync :(
              // let's hope that a second delay is reasonable enough
              ref.invalidate(maybeRoomProvider(roomId));
            });
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'all',
            child: notificationSettingItemUI(
              context,
              curNotifStatus == 'all',
              'All Messages',
            ),
          ),
          if (includeMentions)
            PopupMenuItem<String>(
              value: 'mentions',
              child: notificationSettingItemUI(
                context,
                curNotifStatus == 'mentions',
                'Mentions and Keywords only',
              ),
            ),
          PopupMenuItem<String>(
            value: 'muted',
            child: notificationSettingItemUI(
              context,
              curNotifStatus == 'muted',
              'Muted',
            ),
          ),
          PopupMenuItem<String>(
            value: '',
            child: notificationSettingItemUI(
              context,
              curNotifStatus == '',
              defaultTitle ??
                  'Default (${notifToText(defaultNotificationStatus.valueOrNull ?? '') ?? 'unedefined'})',
            ),
          ),
        ],
      ),
    );
  }

  ListTile notificationSettingItemUI(
    BuildContext context,
    bool isSelected,
    String title,
  ) {
    return ListTile(
      selected: isSelected,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: isSelected
          ? Icon(
              Atlas.check_circle,
              size: 18,
              color: Theme.of(context).colorScheme.onBackground,
            )
          : null,
    );
  }
}

class NotificationsSettingsTile extends AbstractSettingsTile {
  final String roomId;
  final String? title;
  final String? defaultTitle;
  final bool? includeMentions;

  const NotificationsSettingsTile({
    required this.roomId,
    this.title,
    this.defaultTitle,
    this.includeMentions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _NotificationSettingsTile(
      roomId: roomId,
      title: title,
      defaultTitle: defaultTitle,
      includeMentions: includeMentions ?? true,
    );
  }
}
