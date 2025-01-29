import 'package:acter/common/actions/report_content.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

Future<void> reportMessageAction(
  BuildContext context,
  RoomEventItem item,
  String messageId,
  String roomId,
) async {
  final lang = L10n.of(context);
  final senderId = item.sender();
  await openReportContentDialog(
    context,
    title: lang.reportThisMessage,
    description: lang.reportMessageContent,
    senderId: senderId,
    roomId: roomId,
    eventId: messageId,
  );
}
