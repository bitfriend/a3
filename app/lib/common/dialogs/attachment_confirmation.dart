import 'dart:io';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/attachments/post_attachment_selection.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentsManager;
import 'package:flutter/material.dart';

// reusable attachment confirmation dialog
void attachmentConfirmationDialog(
  BuildContext ctx,
  AttachmentsManager manager,
  List<File>? selectedFiles,
) {
  Navigator.of(ctx).pop();
  final size = MediaQuery.of(ctx).size;
  if (selectedFiles != null && selectedFiles.isNotEmpty) {
    isLargeScreen(ctx)
        ? showAdaptiveDialog(
            context: ctx,
            builder: (ctx) => Dialog(
              insetPadding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.5,
                  maxHeight: size.height * 0.5,
                ),
                child: PostAttachmentSelection(
                  files: selectedFiles,
                  manager: manager,
                ),
              ),
            ),
          )
        : showModalBottomSheet(
            context: ctx,
            builder: (ctx) => PostAttachmentSelection(
              files: selectedFiles,
              manager: manager,
            ),
          );
  }
}
