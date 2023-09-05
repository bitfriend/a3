import 'dart:io';

import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/notifiers/chat_input_notifier.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/mention_profile_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:mime/mime.dart';

class CustomChatInput extends ConsumerStatefulWidget {
  final Convo convo;
  const CustomChatInput({required this.convo, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CustomChatInputState();
}

class _CustomChatInputState extends ConsumerState<CustomChatInput> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(clientProvider)!.userId().toString();
    final chatInputNotifier = ref.watch(chatInputProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider);
    final chatState = ref.watch(chatStateProvider(widget.convo));
    final repliedToMessage = chatInputState.repliedToMessage;
    final currentMessageId = chatInputState.currentMessageId;
    final accountProfile = ref.watch(accountProfileProvider);
    final showReplyView = ref.watch(
      chatInputProvider.select((ci) => ci.showReplyView),
    );

    bool isAuthor() {
      if (currentMessageId != null) {
        final messages = chatState.messages;
        int index = messages.indexWhere((x) => x.id == currentMessageId);
        if (index != -1) {
          return userId == messages[index].author.id;
        }
      }
      return false;
    }

    void handleEmojiSelected(Category? category, Emoji emoji) {
      final mentionState = ref.read(mentionKeyProvider).currentState!;
      mentionState.controller!.text += emoji.emoji;
      ref.read(chatInputProvider.notifier).showSendBtn(true);
    }

    void handleBackspacePressed() {
      final mentionState = ref.read(mentionKeyProvider).currentState!;
      final newValue =
          mentionState.controller!.text.characters.skipLast(1).string;
      mentionState.controller!.text = newValue;
      if (newValue.isEmpty) {
        ref.read(chatInputProvider.notifier).showSendBtn(false);
      }
    }

    return Column(
      children: [
        Visibility(
          visible: showReplyView,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  repliedToMessage != null
                      ? Consumer(builder: replyBuilder)
                      : const SizedBox.shrink(),
                  if (repliedToMessage != null &&
                      chatInputState.replyWidget != null)
                    _ReplyContentWidget(
                      convo: widget.convo,
                      msg: repliedToMessage,
                      messageWidget: chatInputState.replyWidget!,
                    ),
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: !chatInputState.emojiRowVisible,
          replacement: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Theme.of(context).colorScheme.onPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    if (isAuthor()) {
                      popUpDialog(
                        context: context,
                        title: const Text(
                          'Are you sure you want to delete this message? This action cannot be undone.',
                        ),
                        btnText: 'No',
                        btn2Text: 'Yes',
                        btn2Color: Theme.of(context).colorScheme.onError,
                        onPressedBtn: () => context.pop(),
                        onPressedBtn2: () async {
                          final messageId = chatInputState.currentMessageId;
                          if (messageId != null) {
                            try {
                              await redactRoomMessage(messageId);
                              chatInputNotifier.emojiRowVisible(false);
                              chatInputNotifier.setCurrentMessageId(null);
                              if (context.mounted) {
                                context.pop();
                              }
                            } catch (e) {
                              if (!context.mounted) {
                                return;
                              }
                              context.pop();
                              customMsgSnackbar(
                                context,
                                e.toString(),
                              );
                            }
                          } else {
                            debugPrint(messageId);
                          }
                        },
                      );
                    } else {
                      customMsgSnackbar(
                        context,
                        'Report message isn\'t implemented yet',
                      );
                    }
                  },
                  child: Text(
                    isAuthor() ? 'Unsend' : 'Report',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => customMsgSnackbar(
                    context,
                    'More options not implemented yet',
                  ),
                  child: const Text(
                    'More',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: Theme.of(context).colorScheme.onPrimary,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    accountProfile.when(
                      data: (data) => ActerAvatar(
                        uniqueId: userId,
                        mode: DisplayMode.User,
                        displayName: data.profile.displayName ?? userId,
                        avatar: data.profile.getAvatarImage(),
                        size: data.profile.hasAvatar() ? 18 : 36,
                      ),
                      error: (e, st) {
                        debugPrint('Error loading due to $e');
                        return ActerAvatar(
                          uniqueId: userId,
                          mode: DisplayMode.User,
                          displayName: userId,
                          size: 36,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _TextInputWidget(
                          convo: widget.convo,
                          onSendButtonPressed: () => onSendButtonPressed(ref),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () => handleAttachment(ref, context),
                        child: const Icon(Atlas.paperclip_attachment),
                      ),
                    ),
                    if (chatInputState.sendBtnVisible)
                      InkWell(
                        onTap: () => onSendButtonPressed(ref),
                        child: const Icon(Atlas.paper_airplane),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: ref.watch(chatInputProvider).emojiPickerVisible,
          child: EmojiPickerWidget(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 2,
            ),
            onEmojiSelected: handleEmojiSelected,
            onBackspacePressed: handleBackspacePressed,
          ),
        ),
      ],
    );
  }

// delete message event
  Future<void> redactRoomMessage(String eventId) async {
    await widget.convo.redactMessage(eventId, '', null);
  }

  // file selection
  Future<List<File>?> handleFileSelection(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result != null) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return null;
  }

  void handleAttachment(WidgetRef ref, BuildContext ctx) async {
    var chatInputStateNotifier = ref.read(chatInputProvider.notifier);
    var chatInputState = ref.read(chatInputProvider);
    var newList = await handleFileSelection(ctx);
    chatInputStateNotifier.updateFileList(newList);
    if (ctx.mounted) {
      var selectionList = chatInputState.fileList;
      String fileName = selectionList.first.path.split('/').last;
      final mimeType = lookupMimeType(selectionList.first.path);
      popUpDialog(
        context: ctx,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Upload Files (${selectionList.length})',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        subtitle: Visibility(
          visible: selectionList.length <= 5,
          child: _FileWidget(mimeType, selectionList.first),
        ),
        description: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(fileName, style: Theme.of(ctx).textTheme.bodySmall),
        ),
        btnText: 'Cancel',
        btn2Text: 'Upload',
        btn2Color: Theme.of(ctx).colorScheme.success,
        btnBorderColor: Theme.of(ctx).colorScheme.errorContainer,
        onPressedBtn: () => ctx.pop(),
        onPressedBtn2: () async {
          ctx.pop();
          await handleFileUpload();
        },
      );
    }
  }

  Future<void> handleFileUpload() async {
    final chatInputState = ref.read(chatInputProvider);
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    final convo = widget.convo;

    if (chatInputState.fileList.isNotEmpty) {
      try {
        for (File file in chatInputState.fileList) {
          String fileName = file.path.split('/').last;
          String? mimeType = lookupMimeType(file.path);

          if (mimeType!.startsWith('image/')) {
            var bytes = file.readAsBytesSync();
            var image = await decodeImageFromList(bytes);
            if (chatInputState.repliedToMessage != null) {
              await convo.sendImageReply(
                file.path,
                fileName,
                mimeType,
                file.lengthSync(),
                image.width,
                image.height,
                chatInputState.repliedToMessage!.id,
                null,
              );

              chatInputNotifier.setRepliedToMessage(null);
              chatInputNotifier.toggleReplyView(false);
              chatInputNotifier.setReplyWidget(null);
            } else {
              await convo.sendImageMessage(
                file.path,
                fileName,
                mimeType,
                file.lengthSync(),
                image.height,
                image.width,
                null,
              );
            }
          } else if (mimeType.startsWith('/audio')) {
            if (chatInputState.repliedToMessage != null) {
            } else {}
          } else if (mimeType.startsWith('/video')) {
          } else {
            if (chatInputState.repliedToMessage != null) {
              await convo.sendFileReply(
                file.path,
                fileName,
                mimeType,
                file.lengthSync(),
                chatInputState.repliedToMessage!.id,
                null,
              );
              chatInputNotifier.setRepliedToMessage(null);
              chatInputNotifier.toggleReplyView(false);
              chatInputNotifier.setReplyWidget(null);
            } else {
              await convo.sendFileMessage(
                file.path,
                fileName,
                mimeType,
                file.lengthSync(),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('error occurred: $e');
      }
    }
  }

  Widget replyBuilder(BuildContext context, WidgetRef ref, Widget? child) {
    final chatInputState = ref.watch(chatInputProvider);
    final authorId = chatInputState.repliedToMessage!.author.id;
    final replyProfile = ref.watch(memberProfileProvider(authorId));
    final inputNotifier = ref.watch(chatInputProvider.notifier);
    return Row(
      children: [
        replyProfile.when(
          data: (profile) => ActerAvatar(
            mode: DisplayMode.User,
            uniqueId: authorId,
            displayName: profile.displayName ?? authorId,
            avatar: profile.getAvatarImage(),
            size: profile.hasAvatar() ? 12 : 24,
          ),
          error: (e, st) {
            debugPrint('Error loading avatar due to $e');
            return ActerAvatar(
              mode: DisplayMode.User,
              uniqueId: authorId,
              displayName: authorId,
              size: 24,
            );
          },
          loading: () => const CircularProgressIndicator(),
        ),
        const SizedBox(width: 5),
        Text(
          'Reply to ${toBeginningOfSentenceCase(authorId)}',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            inputNotifier.toggleReplyView(false);
            inputNotifier.setReplyWidget(null);
          },
          child: const Icon(
            Atlas.xmark_circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> onSendButtonPressed(WidgetRef ref) async {
    final inputNotifier = ref.read(chatInputProvider.notifier);
    final mentionState = ref.read(mentionKeyProvider).currentState!;
    final markDownProvider = ref.read(messageMarkDownProvider);
    final markDownNotifier = ref.read(messageMarkDownProvider.notifier);

    inputNotifier.showSendBtn(false);
    String markdownText = mentionState.controller!.text;
    int messageLength = markdownText.length;
    markDownProvider.forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });
    await handleSendPressed(markdownText, messageLength);
    markDownNotifier.update((state) => {});
    mentionState.controller!.clear();
  }

  // // push messages in convo
  Future<void> handleSendPressed(
    String markdownMessage,
    int messageLength,
  ) async {
    final convo = widget.convo;
    final chatInputState = ref.watch(chatInputProvider);
    final chatInputNotifier = ref.watch(chatInputProvider.notifier);
    // image or video is sent automatically
    // user will click "send" button explicitly for text only
    await convo.typingNotice(false);
    if (chatInputState.repliedToMessage != null) {
      await convo.sendTextReply(
        markdownMessage,
        chatInputState.repliedToMessage!.id,
        null,
      );
      chatInputNotifier.setRepliedToMessage(null);
      final inputNotifier = ref.read(chatInputProvider.notifier);
      inputNotifier.toggleReplyView(false);
      inputNotifier.setReplyWidget(null);
    } else {
      await convo.sendFormattedMessage(markdownMessage);
    }
  }
}

class _FileWidget extends ConsumerWidget {
  const _FileWidget(this.mimeType, this.file);
  final String? mimeType;
  final File file;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mimeType!.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(file, height: 200, fit: BoxFit.cover),
      );
    } else if (mimeType!.startsWith('audio/')) {
      return Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Atlas.file_sound_thin)),
      );
    } else if (mimeType!.startsWith('video/')) {
      return Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Atlas.file_video_thin)),
      );
    }
    //FIXME: cover all mime extension cases?
    else {
      return Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Atlas.plus_file_thin)),
      );
    }
  }
}

class _TextInputWidget extends ConsumerWidget {
  final Convo convo;
  final Function onSendButtonPressed;
  const _TextInputWidget({
    required this.convo,
    required this.onSendButtonPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionList = ref.watch(mentionListProvider);
    final mentionKey = ref.watch(mentionKeyProvider);
    final chatInputNotifier = ref.watch(chatInputProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider);
    final width = MediaQuery.of(context).size.width;
    return FlutterMentions(
      key: mentionKey,
      suggestionPosition: SuggestionPosition.Top,
      suggestionListWidth: width >= 770 ? width * 0.6 : width * 0.8,
      onMentionAdd: (Map<String, dynamic> roomMember) {
        _handleMentionAdd(roomMember, ref);
      },
      suggestionListDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.neutral2,
        borderRadius: BorderRadius.circular(6),
      ),
      onChanged: (String value) async {
        final focusNode = ref.read(chatInputFocusProvider);
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }
        if (value.isNotEmpty) {
          chatInputNotifier.showSendBtn(true);
          await typingNotice(true);
        } else {
          chatInputNotifier.showSendBtn(false);
          await typingNotice(false);
        }
      },
      textInputAction: TextInputAction.send,
      onSubmitted: (value) => onSendButtonPressed(ref),
      style: Theme.of(context).textTheme.bodySmall,
      cursorColor: Theme.of(context).colorScheme.tertiary,
      maxLines: 6,
      minLines: 1,
      focusNode: ref.watch(chatInputFocusProvider),
      decoration: InputDecoration(
        isCollapsed: true,
        fillColor: Theme.of(context).colorScheme.primaryContainer,
        suffixIcon: InkWell(
          onTap: () => chatInputState.emojiPickerVisible
              ? chatInputNotifier.emojiPickerVisible(false)
              : chatInputNotifier.emojiPickerVisible(true),
          child: const Icon(Icons.emoji_emotions),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
        filled: true,
        hintText: AppLocalizations.of(context)!.newMessage,
        contentPadding: const EdgeInsets.all(15),
        hintMaxLines: 1,
      ),
      mentions: [
        Mention(
          trigger: '@',
          style: TextStyle(
            height: 0.5,
            background: Paint()
              ..color = Theme.of(context).colorScheme.neutral2
              ..strokeWidth = 13
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke,
          ),
          data: mentionList,
          matchAll: true,
          suggestionBuilder: (Map<String, dynamic> roomMember) {
            final authorId = roomMember['link'];
            final title = roomMember['display'] ?? authorId;
            return ListTile(
              leading: MentionProfileBuilder(
                authorId: authorId,
                title: title,
              ),
              title: Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 15),
                  Text(
                    authorId,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.neutral5,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleMentionAdd(Map<String, dynamic> roomMember, WidgetRef ref) {
    String authorId = roomMember['link'];
    String displayName = roomMember['display'] ?? authorId;
    ref.read(messageMarkDownProvider).addAll({
      '@$displayName': '[$displayName](https://matrix.to/#/$authorId)',
    });
  }

  // send typing event from client
  Future<bool> typingNotice(bool typing) async {
    return await convo.typingNotice(typing);
  }
}

class _ReplyContentWidget extends StatelessWidget {
  const _ReplyContentWidget({
    required this.convo,
    required this.msg,
    required this.messageWidget,
  });

  final Convo convo;
  final Message msg;
  final Widget messageWidget;

  @override
  Widget build(BuildContext context) {
    if (msg is ImageMessage) {
      final imageMsg = msg as ImageMessage;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ImageMessageBuilder(
          convo: convo,
          message: imageMsg,
          messageWidth: imageMsg.size.toInt(),
          isReplyContent: true,
        ),
      );
    } else if (msg is TextMessage) {
      final textMsg = msg as TextMessage;
      return Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
        padding: const EdgeInsets.all(12),
        child: Html(
          data: textMsg.text,
          defaultTextStyle: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(overflow: TextOverflow.ellipsis),
          maxLines: 3,
        ),
      );
    }
    return messageWidget ?? const SizedBox.shrink();
  }
}
