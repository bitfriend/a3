import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_full_view.dart';
import 'package:acter/features/news/widgets/news_grid_view.dart';
import 'package:acter/features/news/widgets/news_skeleton_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::list');

enum NewsViewMode { gridView, fullView }

class NewsListPage extends ConsumerStatefulWidget {
  final String? spaceId;
  final String? initialEventId;
  final NewsViewMode newsViewMode;

  const NewsListPage({
    super.key,
    this.spaceId,
    this.initialEventId,
    this.newsViewMode = NewsViewMode.gridView,
  });

  @override
  ConsumerState<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends ConsumerState<NewsListPage> {
  final ValueNotifier<bool> useGridMode = ValueNotifier(true);
  final ValueNotifier<bool> stillLoadingForSelectedItem = ValueNotifier(false);
  final ValueNotifier<int> currentIndex = ValueNotifier(0);
  late ProviderSubscription<AsyncValue<List<NewsEntry>>>? listener;

  @override
  void initState() {
    super.initState();
    useGridMode.value = widget.newsViewMode == NewsViewMode.gridView;
    final targetEventId = widget.initialEventId;
    if (targetEventId != null) {
      stillLoadingForSelectedItem.value = true;
      listener = ref.listenManual(
        newsListProvider(widget.spaceId),
        (prev, next) {
          final items = next.valueOrNull;
          if (items == null) {
            return;
          }
          int? itemIdx;

          items.firstWhereIndexedOrNull((int idx, NewsEntry e) {
            if (e.eventId().toString() == targetEventId) {
              itemIdx = idx;
              return true;
            } else {
              return false;
            }
          });
          if (itemIdx == null) {
            // not found, still loading
            return;
          }
          stillLoadingForSelectedItem.value = false;
          currentIndex.value = itemIdx!;
          listener?.close();
          listener = null;
        },
        fireImmediately: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: useGridMode,
      builder: (context, value, child) {
        return Scaffold(
          extendBodyBehindAppBar: !value,
          appBar: _buildAppBar(value),
          body: ValueListenableBuilder(
            valueListenable: stillLoadingForSelectedItem,
            builder: (context, loading, child) =>
                loading ? const NewsSkeletonWidget() : _buildBody(value),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(bool useGridMode) {
    final spaceId = widget.spaceId;
    final canPop = widget.newsViewMode == NewsViewMode.gridView &&
        this.useGridMode.value == true;
    return AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: false,
      leading: widget.newsViewMode == NewsViewMode.gridView
          ? IconButton(
              onPressed: () {
                if (canPop) {
                  Navigator.pop(context);
                } else {
                  this.useGridMode.value = true;
                }
              },
              icon: const Icon(Icons.arrow_back),
            )
          : const SizedBox.shrink(),
      title: widget.newsViewMode == NewsViewMode.gridView
          ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.of(context).boosts),
                if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
              ],
            )
          : const SizedBox.shrink(),
      actions: [
        AddButtonWithCanPermission(
          canString: 'CanPostNews',
          spaceId: widget.spaceId,
          onPressed: () => context.pushNamed(
            Routes.actionAddUpdate.name,
            queryParameters: {'spaceId': widget.spaceId},
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool useGridMode) {
    final newsListLoader = ref.watch(newsListProvider(widget.spaceId));

    return newsListLoader.when(
      data: (newsList) {
        if (newsList.isEmpty) return newsEmptyStateUI(context);
        return useGridMode
            ? NewsGridView(
                newsList: newsList,
                onTapNewItem: (index) {
                  this.useGridMode.value = false;
                  currentIndex.value = index;
                },
              )
            : NewsFullView(
                newsList: newsList,
                initialPageIndex: currentIndex.value,
              );
      },
      error: (e, s) => newsErrorUI(context, e, s),
      loading: () => const NewsSkeletonWidget(),
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
    );
  }

  Widget newsErrorUI(BuildContext context, error, stack) {
    _log.severe('Failed to load boost list', error, stack);
    return ErrorPage(
      background: const NewsSkeletonWidget(),
      error: error,
      stack: stack,
      textBuilder: L10n.of(context).loadingFailed,
      onRetryTap: () {
        ref.invalidate(newsListProvider(widget.spaceId));
      },
    );
  }

  Widget newsEmptyStateUI(BuildContext context) {
    final lang = L10n.of(context);
    return Center(
      child: EmptyState(
        title: lang.youHaveNoUpdates,
        subtitle: lang.createPostsAndEngageWithinSpace,
        image: 'assets/images/empty_updates.svg',
        primaryButton: ActerPrimaryActionButton(
          onPressed: () => context.pushNamed(Routes.actionAddUpdate.name),
          child: Text(lang.addBoost),
        ),
      ),
    );
  }
}
