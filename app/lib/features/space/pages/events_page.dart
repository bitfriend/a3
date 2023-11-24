import 'dart:math';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/events_item.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/space/widgets/space_header.dart';

class SpaceEventsPage extends ConsumerWidget {
  final String spaceIdOrAlias;

  const SpaceEventsPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceRelationsOverview =
        ref.watch(spaceRelationsOverviewProvider(spaceIdOrAlias));
    final spaceEvents = ref.watch(spaceEventsProvider(spaceIdOrAlias));

    return spaceRelationsOverview.when(
      data: (spaceData) {
        bool checkPermission(String permission) {
          if (spaceData.membership != null) {
            return spaceData.membership!.canString(permission);
          }
          return false;
        }

        final canPostEvent = checkPermission('CanPostEvent');
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        'Events',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Visibility(
                        visible: canPostEvent,
                        child: IconButton(
                          icon: Icon(
                            Atlas.plus_circle_thin,
                            color: Theme.of(context).colorScheme.neutral5,
                          ),
                          iconSize: 28,
                          color: Theme.of(context).colorScheme.surface,
                          onPressed: () => context.pushNamed(
                            Routes.createEvent.name,
                            queryParameters: {'spaceId': spaceIdOrAlias},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              spaceEvents.when(
                data: (events) {
                  final widthCount =
                      (MediaQuery.of(context).size.width ~/ 600).toInt();
                  const int minCount = 2;
                  if (events.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          'Currently there are no events planned for this space',
                        ),
                      ),
                    );
                  }
                  return SliverGrid.builder(
                    itemCount: events.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: max(1, min(widthCount, minCount)),
                      childAspectRatio: 4.0,
                    ),
                    itemBuilder: (context, index) =>
                        EventItem(event: events[index]),
                  );
                },
                error: (error, stackTrace) => SliverToBoxAdapter(
                  child: Center(
                    child: Text('Failed to load events due to $error'),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        );
      },
      error: (error, stack) => Center(
        child: Text('Loading failed: $error'),
      ),
      loading: () => const Center(
        child: Text('Loading'),
      ),
    );
  }
}
