import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatBubble extends StatelessWidget {
  final Widget child;
  final int? messageWidth;
  final BoxDecoration decoration;
  final CrossAxisAlignment bubbleAlignment;
  final bool isEdited;
  final Widget? repliedToBuilder;

  // default private constructor
  const ChatBubble._inner({
    super.key,
    required this.child,
    required this.bubbleAlignment,
    required this.decoration,
    this.isEdited = false,
    this.messageWidth,
    this.repliedToBuilder,
  });

  // factory bubble constructor
  factory ChatBubble({
    required Widget child,
    required BuildContext context,
    bool isNextMessageInGroup = false,
    bool isEdited = false,
    Widget? repliedToBuilder,
    int? messageWidth,
  }) {
    final theme = Theme.of(context);
    return ChatBubble._inner(
      messageWidth: messageWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(isNextMessageInGroup ? 16 : 4),
          bottomRight: Radius.circular(16),
        ),
      ),
      bubbleAlignment: CrossAxisAlignment.start,
      isEdited: isEdited,
      repliedToBuilder: repliedToBuilder,
      child: child,
    );
  }

  // for user's own messages
  factory ChatBubble.user({
    Key? key,
    required BuildContext context,
    required Widget child,
    bool isNextMessageInGroup = false,
    bool isEdited = false,
    int? messageWidth,
    Widget? repliedToBuilder,
  }) {
    final theme = Theme.of(context);
    return ChatBubble._inner(
      key: key,
      messageWidth: messageWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(isNextMessageInGroup ? 16 : 4),
        ),
      ),
      bubbleAlignment: CrossAxisAlignment.end,
      repliedToBuilder: repliedToBuilder,
      child: DefaultTextStyle.merge(
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onPrimary),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatTheme = Theme.of(context).chatTheme;
    final size = MediaQuery.sizeOf(context);
    final msgWidth = messageWidth.map((w) => w.toDouble());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: bubbleAlignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: msgWidth ?? size.width,
            ),
            width: msgWidth,
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (repliedToBuilder != null) ...[
                    repliedToBuilder.expect('widget cannot be null'),
                    const SizedBox(height: 10),
                  ],
                  child,
                ],
              ),
            ),
          ),
          if (isEdited)
            Align(
              alignment: Alignment(0.9, 0.0),
              child: Text(
                L10n.of(context).edited,
                style: chatTheme.emptyChatPlaceholderTextStyle
                    .copyWith(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
