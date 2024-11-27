import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_room_messages_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::chat::message_provider');

typedef RoomMsgId = (String roomId, String uniqueId);

final chatStateProvider = StateNotifierProvider.family<ChatRoomMessagesNotifier,
    ChatRoomState, String>(
  (ref, roomId) => ChatRoomMessagesNotifier(ref: ref, roomId: roomId),
);

final chatRoomMessageProvider =
    StateProvider.family<RoomMessage?, RoomMsgId>((ref, roomMsgId) {
  final (roomId, uniqueMsgId) = roomMsgId;
  final chatRoomState = ref.watch(chatStateProvider(roomId));
  return chatRoomState.message(uniqueMsgId);
});

final showHiddenMessages = StateProvider((ref) => false);

const _supportedTypes = ['m.room.message'];

final animatedListChatMessagesProvider =
    StateProvider.family<GlobalKey<AnimatedListState>, String>(
  (ref, roomId) => ref.watch(chatStateProvider(roomId).notifier).animatedList,
);

final renderableChatMessagesProvider =
    StateProvider.autoDispose.family<List<String>, String>((ref, roomId) {
  final msgList =
      ref.watch(chatStateProvider(roomId).select((value) => value.messageList));
  if (ref.watch(showHiddenMessages)) {
    // do not apply filters
    return msgList;
  }
  // do apply some filters

  return msgList.where((id) {
    final msg = ref.watch(chatRoomMessageProvider((roomId, id)));
    if (msg == null) {
      _log.severe('Room Msg $roomId $id not found');
      return false;
    }
    return _supportedTypes.contains(msg.eventItem()?.eventType());
  }).toList();
});

// Provider to check if we should show avatar by comparing with the next message
final shouldShowAvatarProvider = Provider.family<bool, RoomMsgId>(
  (ref, roomMsgId) {
    final roomId = roomMsgId.$1;
    final eventId = roomMsgId.$2;
    final messages = ref.watch(renderableChatMessagesProvider(roomId));
    final currentIndex = messages.indexOf(eventId);

    // Always show avatar for the first message (last in the list)
    if (currentIndex == messages.length - 1) return true;

    // Get current and next message
    final currentMsg = ref.watch(chatRoomMessageProvider(roomMsgId));
    final nextMsg = ref.watch(
      chatRoomMessageProvider((roomId, messages[currentIndex + 1])),
    );

    if (currentMsg == null || nextMsg == null) return true;

    final currentSender = currentMsg.eventItem()?.sender();
    final nextSender = nextMsg.eventItem()?.sender();

    // Show avatar if next message is from a different sender
    return currentSender != nextSender;
  },
);
