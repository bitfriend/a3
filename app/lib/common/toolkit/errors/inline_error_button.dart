import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

/// InlineErrorButton for text inlined actions
///
/// This is a ErrorButton that highlights the given text using the
/// `theme.inlineErrorTheme`. Thus this is super useful if you have some text
/// and want a specific part of it to be highlighted to the user indicating
/// it has an action. See [ErrorButton] for options.
class ActerInlineErrorButton extends StatelessWidget {
  final Object error;
  final StackTrace? stack;
  final VoidCallback? onRetryTap;
  final Icon? icon;

  final String? dialogTitle;
  final String? text;
  final String Function(Object error)? textBuilder;
  final bool includeBugReportButton;

  const ActerInlineErrorButton({
    super.key,
    required this.error,
    this.icon,
    this.stack,
    this.dialogTitle,
    this.text,
    this.textBuilder,
    this.onRetryTap,
    this.includeBugReportButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return _buildWithIcon(context);
    }
    return TextButton(
      onPressed: () async {
        await ActerErrorDialog.show(
          context: context,
          error: error,
          stack: stack,
          title: dialogTitle,
          text: text,
          textBuilder: textBuilder,
          onRetryTap: onRetryTap != null
              ? () {
                  onRetryTap!();
                  Navigator.pop(context);
                }
              : null,
          includeBugReportButton: includeBugReportButton,
        );
      },
      child: Text(L10n.of(context).fatalError),
    );
  }

  const ActerInlineErrorButton.icon({
    super.key,
    required this.error,
    this.stack,
    required this.icon,
    this.dialogTitle,
    this.text,
    this.textBuilder,
    this.onRetryTap,
    this.includeBugReportButton = true,
  });

  Widget _buildWithIcon(BuildContext context) {
    return IconButton(
      icon: icon!,
      onPressed: () async {
        await ActerErrorDialog.show(
          context: context,
          error: error,
          stack: stack,
          title: dialogTitle,
          text: text,
          textBuilder: textBuilder,
          onRetryTap: onRetryTap != null
              ? () {
                  onRetryTap!();
                  Navigator.pop(context);
                }
              : null,
          includeBugReportButton: includeBugReportButton,
        );
      },
    );
  }
}