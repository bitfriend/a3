import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:acter/features/search/providers/spaces.dart';
import 'package:acter/router/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::search::spaces_builder');

class SpacesBuilder extends ConsumerWidget {
  final bool popBeforeRoute;

  const SpacesBuilder({
    super.key,
    this.popBeforeRoute = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesLoader = ref.watch(spacesFoundProvider);
    return spacesLoader.when(
      loading: () => renderLoading(context),
      error: (e, s) {
        _log.severe('Failed to search spaces', e, s);
        return inBox(
          context,
          Text(L10n.of(context).searchingFailed(e)),
        );
      },
      data: (spaces) {
        if (spaces.isEmpty) return renderEmpty(context, ref);
        return renderItems(context, ref, spaces);
      },
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
    );
  }

  Widget renderLoading(BuildContext context) {
    return inBox(
      context,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            padding: const EdgeInsets.all(10),
            child: const Column(
              children: [
                Skeletonizer(
                  child: Icon(Icons.abc),
                ),
                SizedBox(height: 3),
                Skeletonizer(
                  child: Text('space name'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget renderItems(
    BuildContext context,
    WidgetRef ref,
    List<SpaceDetails> spaces,
  ) {
    return inBox(
      context,
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: spaces.map((space) {
            return InkWell(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    space.icon,
                    const SizedBox(height: 3),
                    Text(space.name),
                  ],
                ),
              ),
              onTap: () {
                if (popBeforeRoute) Navigator.pop(context);
                goToSpace(context, space.navigationTargetId);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget renderEmpty(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return inBox(
      context,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(lang.noSpacesFound),
          ActerInlineTextButton(
            onPressed: () {
              final query = ref.read(searchValueProvider);
              context.pushNamed(
                Routes.searchPublicDirectory.name,
                queryParameters: {'query': query},
              );
            },
            child: Text(lang.searchPublicDirectory),
          ),
        ],
      ),
    );
  }

  Widget inBox(BuildContext context, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Text(L10n.of(context).spaces),
          const SizedBox(height: 15),
          child,
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
