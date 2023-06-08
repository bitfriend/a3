import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Conversation, RoomMessage;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'joined_room.freezed.dart';

@Freezed(makeCollectionsUnmodifiable: false)
class JoinedRoom with _$JoinedRoom {
  const factory JoinedRoom({
    required String id,
    required Conversation conversation,
    @Default(null) RoomMessage? latestMessage,
    @Default(null) String? displayName,
    @Default([]) List<types.User> typingUsers,
  }) = _JoinedRoom;
}
