import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:scrollable_list_tab_scroller/scrollable_list_tab_scroller.dart';

class SpaceDetailsPage extends ConsumerStatefulWidget {
  final String spaceId;

  const SpaceDetailsPage({
    super.key,
    required this.spaceId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SpaceDetailsPageState();
}

class _SpaceDetailsPageState extends ConsumerState<SpaceDetailsPage> {
  ValueNotifier<bool> showHeader = ValueNotifier<bool>(true);
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    menuScrollingListeners();
  }

  void menuScrollingListeners() {
    itemPositionsListener.itemPositions.addListener(() {
      var value = itemPositionsListener.itemPositions;
      if (value.value.first.index == 0 &&
          value.value.first.itemLeadingEdge == 0) {
        showHeader.value = true;
      } else {
        showHeader.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: spaceBodyUI(),
      ),
    );
  }

  Widget spaceBodyUI() {
    final spaceMenus = ref.watch(tabsProvider(widget.spaceId));
    return spaceMenus.when(
      skipLoadingOnReload: true,
      data: (tabsList) {
        return ScrollableListTabScroller(
          itemCount: tabsList.length,
          itemPositionsListener: itemPositionsListener,
          headerContainerBuilder: (BuildContext context, Widget menuBarWidget) {
            return spaceHeaderUI(menuBarWidget);
          },
          tabBuilder: (BuildContext context, int index, bool active) =>
              spaceTabMenuUI(tabsList[index], active),
          itemBuilder: (BuildContext context, int index) =>
              spacePageUI(tabsList, index),
        );
      },
      error: (error, stack) => Container(),
      loading: () => Container(),
    );
  }

  Widget spaceHeaderUI(Widget menuBarWidget) {
    final displayName =
        ref.watch(roomDisplayNameProvider(widget.spaceId)).valueOrNull;
    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: showHeader,
          builder: (context, showHeader, child) {
            return Stack(
              children: [
                AnimatedSizeAndFade(
                  sizeDuration: const Duration(milliseconds: 500),
                  child: showHeader ? spaceAvatar() : const SizedBox.shrink(),
                ),
                AppBar(
                  title: showHeader ? null : Text(displayName ?? ''),
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Theme.of(context).colorScheme.surface,
                ),
              ],
            );
          },
        ),
        menuBarWidget,
      ],
    );
  }

  Widget spaceAvatar() {
    final avatarData =
        ref.watch(roomAvatarProvider(widget.spaceId)).valueOrNull;
    if (avatarData != null) {
      return Image.memory(
        avatarData.bytes,
        height: 300,
        width: MediaQuery.of(context).size.width,
        fit: BoxFit.cover,
      );
    } else {
      return Container(height: 200, color: Colors.red);
    }
  }

  Widget spaceTabMenuUI(TabEntry tabItem, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: active ? Theme.of(context).colorScheme.primary : null,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        tabItem.label,
        style: !active
            ? null
            : TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: active ? Theme.of(context).colorScheme.onSurface : null,
              ),
      ),
    );
  }

  Widget spacePageUI(List<TabEntry> tabsList, int index) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tabsList[index].label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            color: Colors.blueGrey,
          ),
        ],
      ),
    );
  }
}
