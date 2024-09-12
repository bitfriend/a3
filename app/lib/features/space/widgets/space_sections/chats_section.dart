import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/related/chats_helpers.dart';
import 'package:acter/features/space/widgets/related/util.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::sections::chats');

class ChatsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const ChatsSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewLoader = ref.watch(spaceRelationsOverviewProvider(spaceId));
    return overviewLoader.when(
      data: (overview) => buildChatsSectionUI(
        context,
        ref,
        overview.knownChats,
      ),
      error: (e, s) {
        _log.severe('Failed to load the related spaces', e, s);
        return Center(
          child: Text(L10n.of(context).loadingSpacesFailed(e)),
        );
      },
      loading: () => Skeletonizer(
        child: Center(
          child: Text(L10n.of(context).loading),
        ),
      ),
    );
  }

  Widget buildChatsSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> chats,
  ) {
    final relatedChats =
        ref.watch(remoteChatRelationsProvider(spaceId)).valueOrNull ?? [];
    final config = calculateSectionConfig(
      localListLen: chats.length,
      limit: limit,
      remoteListLen: relatedChats.length,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).chats,
          isShowSeeAllButton: config.isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceChats.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        chatsListUI(
          ref,
          spaceId,
          chats,
          config.listingLimit,
          showOptions: false,
        ),
        if (config.renderRemote)
          renderFurther(
            context,
            ref,
            spaceId,
            config.remoteCount,
          ),
      ],
    );
  }
}
