import 'package:acter/common/models/attachment_media_state/attachment_media_state.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/download_button.dart';
import 'package:acter/features/attachments/providers/attachment_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Attachment;
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class FileView extends ConsumerWidget {
  final Attachment attachment;
  final bool? openView;
  const FileView({
    super.key,
    required this.attachment,
    this.openView = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(attachmentMediaStateProvider(attachment));
    if (mediaState.mediaLoadingState.isLoading || mediaState.isDownloading) {
      return loadingIndication(context);
    } else if (mediaState.mediaFile == null) {
      return filePlaceholder(context, attachment, mediaState, ref);
    } else {
      return fileUI(context, mediaState);
    }
  }

  Widget loadingIndication(BuildContext context) {
    return const SizedBox(
      width: 150,
      height: 150,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget filePlaceholder(
    BuildContext context,
    Attachment attachment,
    AttachmentMediaState mediaState,
    WidgetRef ref,
  ) {
    final msgContent = attachment.msgContent();
    return InkWell(
      onTap: () async {
        if (mediaState.mediaFile != null) {
          if (isDesktop) {
            downloadFile(context, mediaState.mediaFile!);
          } else {
            Share.shareXFiles([XFile(mediaState.mediaFile!.path)]);
          }
        } else {
          ref
              .read(attachmentMediaStateProvider(attachment).notifier)
              .downloadMedia();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.download,
            size: 24,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.description,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  formatBytes(msgContent.size()!.truncate()),
                  style: Theme.of(context).textTheme.labelSmall!,
                  textScaler: const TextScaler.linear(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget fileUI(BuildContext context, AttachmentMediaState mediaState) {
    return InkWell(
      onTap: openView!
          ? () async {
              if (isDesktop) {
                downloadFile(context, mediaState.mediaFile!);
              } else {
                Share.shareXFiles([XFile(mediaState.mediaFile!.path)]);
              }
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: const Icon(Icons.description, size: 22),
      ),
    );
  }
}
