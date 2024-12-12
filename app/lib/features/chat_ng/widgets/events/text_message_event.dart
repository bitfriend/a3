import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat/widgets/pill_builder.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_matrix_html/text_parser.dart';

class TextMessageEvent extends StatelessWidget {
  final String roomId;
  final MsgContent content;
  final Map<String, dynamic> metadata;

  const TextMessageEvent({
    super.key,
    required this.content,
    required this.roomId,
    required this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chatTheme = Theme.of(context).chatTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final body = content.formattedBody() ?? content.body();

    String? msgType = metadata['msgType'];
    bool isUser = metadata['isUser'];
    bool isReply = metadata['isReply'];
    bool isNotice = (msgType == 'm.notice' || msgType == 'm.server_notice');

    // whether text only contains emojis
    final enlargeEmoji = isOnlyEmojis(content.body());

    if (enlargeEmoji) {
      final emojiTextStyle = isUser
          ? chatTheme.sentEmojiMessageTextStyle
          : chatTheme.receivedEmojiMessageTextStyle;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          content.body(),
          style: emojiTextStyle.copyWith(
            fontFamily: emojiFont,
          ),
          maxLines: isReply ? 3 : null,
        ),
      );
    }

    return Html(
      shrinkToFit: true,
      pillBuilder: ({
        required String identifier,
        required String url,
        OnPillTap? onTap,
      }) =>
          ActerPillBuilder(
        identifier: identifier,
        uri: url,
        roomId: roomId,
      ),
      renderNewlines: true,
      maxLines: isReply ? 2 : null,
      defaultTextStyle: textTheme.bodySmall?.copyWith(
        color: isNotice ? colorScheme.onSurface.withOpacity(0.5) : null,
        overflow: isReply ? TextOverflow.ellipsis : null,
      ),
      data: body,
    );
  }
}
