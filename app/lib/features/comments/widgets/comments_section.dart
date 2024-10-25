import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/add_comment_widget.dart';
import 'package:acter/features/comments/widgets/comment_list_skeleton_widget.dart';
import 'package:acter/features/comments/widgets/comment_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::comments::section');

class CommentsSection extends ConsumerWidget {
  final Future<CommentsManager> manager;

  const CommentsSection({
    super.key,
    required this.manager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerLoader = ref.watch(commentsManagerProvider(manager));
    return managerLoader.when(
      data: (commentManager) => buildCommentSectionUI(context, commentManager),
      error: (error, stack) =>
          commentManagerErrorWidget(context, ref, error, stack),
      loading: () => const CommentListSkeletonWidget(),
    );
  }

  Widget buildCommentSectionUI(
    BuildContext context,
    CommentsManager commentManager,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(L10n.of(context).comments),
          CommentListWidget(manager: commentManager),
          AddCommentWidget(manager: commentManager),
        ],
      ),
    );
  }

  Widget commentManagerErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace stack,
  ) {
    _log.severe('Failed to load comment manager', error, stack);
    return ErrorPage(
      background: const CommentListSkeletonWidget(),
      error: error,
      stack: stack,
      textBuilder: L10n.of(context).loadingFailed,
      onRetryTap: () => ref.invalidate(commentsManagerProvider(manager)),
    );
  }
}
