import 'dart:io';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/pins/pin_utils/pin_utils.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';

class CreatePinPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  static const titleFieldKey = Key('create-pin-title-field');
  static const contentFieldKey = Key('create-pin-content-field');
  static const urlFieldKey = Key('create-pin-url-field');
  static const submitBtn = Key('create-pin-submit');

  const CreatePinPage({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<CreatePinPage> createState() => _CreatePinSheetConsumerState();
}

class _CreatePinSheetConsumerState extends ConsumerState<CreatePinPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final spaceNotifier = ref.read(selectedSpaceIdProvider.notifier);
      spaceNotifier.state = widget.initialSelectedSpace;
    });
  }

  @override
  Widget build(BuildContext context) {
    final attachments = ref.watch(selectedAttachmentsProvider);
    return SideSheet(
      header: 'Create new Pin',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTitleField(),
                  const SizedBox(height: 15),
                  _buildLinkField(),
                  const SizedBox(height: 15),
                  _buildAttachmentField(),
                  const SizedBox(height: 15),
                  if (attachments.isNotEmpty)
                    Flexible(child: _buildAttachments(attachments)),
                  const SizedBox(height: 15),
                  _buildDescriptionField(),
                ],
              ),
              const SizedBox(height: 15),
              const SelectSpaceFormField(canCheck: 'CanPostPin'),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          key: CreatePinPage.submitBtn,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _handleCreatePin();
            }
          },
          child: const Text('Create Pin'),
        ),
      ],
      confirmActionOnPressed: () async {},
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text('Title'),
        ),
        InputTextField(
          hintText: 'Pin Name',
          key: CreatePinPage.titleFieldKey,
          textInputType: TextInputType.text,
          controller: _titleController,
          validator: (value) => (value != null && value.trim().isNotEmpty)
              ? null
              : 'Please enter a title',
        ),
      ],
    );
  }

  Widget _buildAttachmentField() {
    return InkWell(
      onTap: () => PinUtils.showAttachmentSelection(context, ref),
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Atlas.file_arrow_up_thin,
              size: 14,
              color: Theme.of(context).colorScheme.neutral5,
            ),
            Text(
              'Upload File',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(color: Theme.of(context).colorScheme.neutral5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments(List<PinAttachment> attachments) {
    return Wrap(
      direction: Axis.horizontal,
      spacing: 5.0,
      children: <Widget>[
        for (var pinAttachment in attachments)
          _AttachmentFileWidget(pinAttachment),
      ],
    );
  }

  Widget _buildLinkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text('Link'),
        ),
        InputTextField(
          hintText: 'https://',
          key: CreatePinPage.urlFieldKey,
          textInputType: TextInputType.url,
          controller: _linkController,
          validator: (value) =>
              hasLinkOrText() ? null : 'Text or URL must be given',
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text('Description'),
        ),
        SizedBox(
          height: 200,
          child: MdEditorWithPreview(
            key: CreatePinPage.contentFieldKey,
            validator: (value) =>
                hasLinkOrText() ? null : 'Text or URL must be given',
            controller: _textController,
          ),
        ),
      ],
    );
  }

  bool hasLinkOrText() {
    return _linkController.text.trim().isNotEmpty ||
        _textController.text.trim().isNotEmpty;
  }

  void _handleCreatePin() async {
    EasyLoading.show(status: 'Creating pin...');
    try {
      final spaceId = ref.read(selectedSpaceIdProvider);
      final space = await ref.read(spaceProvider(spaceId!).future);
      final pinDraft = space.pinDraft();
      final title = _titleController.text;
      final text = _textController.text;
      final url = _linkController.text;

      if (title.trim().isNotEmpty) {
        pinDraft.title(title);
      }

      if (text.isNotEmpty) {
        pinDraft.contentMarkdown(text);
      }
      if (url.isNotEmpty) {
        pinDraft.url(url);
      }
      final pinId = await pinDraft.send();
      // pin sent okay, lets send attachments too.
      EasyLoading.show(status: 'Sending attachments...');
      final pin = await ref.read(pinProvider(pinId.toString()).future);
      final manager = await pin.attachments();
      final List<AttachmentDraft>? drafts =
          await PinUtils.makeAttachmentDrafts(manager, ref as Ref<Object?>);
      if (drafts == null) {
        EasyLoading.showError('Error occured sending attachments');
        return;
      }
      for (var draft in drafts) {
        await draft.send();
      }
      // reset controllers
      _textController.text = '';
      _linkController.text = '';
      EasyLoading.showSuccess('Pin created successfully');
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      // ignore: use_build_context_synchronously
      Navigator.of(context, rootNavigator: true).pop(); // pop the create sheet
      // ignore: use_build_context_synchronously
      context.pushNamed(
        Routes.pin.name,
        pathParameters: {'pinId': pinId.toString()},
      );
    } catch (e) {
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      EasyLoading.showError('An error occured creating pin $e');
    }
  }
}

// Attachment File UI widget
class _AttachmentFileWidget extends ConsumerWidget {
  const _AttachmentFileWidget(this.attachment);

  final PinAttachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentNotifier = ref.watch(selectedAttachmentsProvider.notifier);
    final file = attachment.file;
    String fileName = file.path.split('/').last;

    return Container(
      height: 30,
      width: 100,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: <Widget>[
          _attachmentFile(file),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              fileName,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: () {
              var files = ref.read(selectedAttachmentsProvider);
              files.remove(attachment);
              attachmentNotifier.update((state) => [...files]);
            },
            child: const Icon(Icons.close, size: 12),
          ),
        ],
      ),
    );
  }
}

// handler for mimetype icon
Widget _attachmentFile(File file) {
  final mimeType = lookupMimeType(file.path);
  if (mimeType!.startsWith('image/')) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        height: 20,
        width: 20,
      ),
    );
  } else if (mimeType.startsWith('audio/')) {
    return const Icon(Atlas.file_sound_thin, size: 12);
  } else if (mimeType.startsWith('video/')) {
    return const Icon(Atlas.file_video_thin, size: 12);
  } else {
    return const Icon(Atlas.file_thin, size: 12);
  }
}
