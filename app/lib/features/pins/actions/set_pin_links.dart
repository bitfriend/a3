import 'package:acter/common/models/types.dart';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_link_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

void showAddPinLinkBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required bool isBottomSheetOpen,
}) {
  showPinLinkBottomSheet(
    context: context,
    bottomSheetTitle: L10n.of(context).addLink,
    onSave: (title, link) {
      if (isBottomSheetOpen) Navigator.pop(context);
      Navigator.pop(context);
      final pinAttachment = PinAttachment(
        attachmentType: AttachmentType.link,
        title: title,
        link: link,
      );
      ref.read(createPinStateProvider.notifier).addAttachment(pinAttachment);
    },
  );
}

void showEditPinLinkBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PinAttachment attachmentData,
  required int index,
}) {
  showPinLinkBottomSheet(
    context: context,
    pinTitle: attachmentData.title,
    pinLink: attachmentData.link,
    onSave: (title, link) {
      Navigator.pop(context);
      final pinAttachment = attachmentData.copyWith(
        title: title,
        link: link,
      );
      ref
          .read(createPinStateProvider.notifier)
          .changeAttachmentTitle(pinAttachment, index);
    },
  );
}
