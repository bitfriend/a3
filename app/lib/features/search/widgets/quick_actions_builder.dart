import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/bug_report/actions/open_bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::search::quick_actions_builder');

class QuickActionsBuilder extends ConsumerWidget {
  final bool popBeforeRoute;

  const QuickActionsBuilder({
    super.key,
    required this.popBeforeRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    bool isActive(f) => ref.watch(isActiveProvider(f));

    final canPostNewsLoader = ref.watch(
      hasSpaceWithPermissionProvider('CanPostNews'),
    );
    final canPostNews = canPostNewsLoader.valueOrNull ?? false;

    final canPostPinLoader = ref.watch(
      hasSpaceWithPermissionProvider('CanPostPin'),
    );
    final canPostPin = canPostPinLoader.valueOrNull ?? false;

    final canPostEventLoader = ref.watch(
      hasSpaceWithPermissionProvider('CanPostEvent'),
    );
    final canPostEvent = canPostEventLoader.valueOrNull ?? false;

    final canPostTasklistLoader = ref.watch(
      hasSpaceWithPermissionProvider('CanPostTaskList'),
    );
    final canPostTasklist = canPostTasklistLoader.valueOrNull ?? false;

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 8,
      runSpacing: 10,
      children: List.from(
        [
          if (canPostNews)
            OutlinedButton.icon(
              key: QuickJumpKeys.createUpdateAction,
              onPressed: () => routeTo(context, Routes.actionAddUpdate),
              icon: const Icon(
                Atlas.plus_circle_thin,
                size: 18,
              ),
              label: Text(
                lang.boost,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (canPostPin)
            OutlinedButton.icon(
              key: QuickJumpKeys.createPinAction,
              onPressed: () => routeTo(context, Routes.createPin),
              icon: const Icon(
                Atlas.plus_circle_thin,
                size: 18,
              ),
              label: Text(
                lang.pin,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (canPostEvent)
            OutlinedButton.icon(
              key: QuickJumpKeys.createEventAction,
              onPressed: () => routeTo(context, Routes.createEvent),
              icon: const Icon(
                Atlas.plus_circle_thin,
                size: 18,
              ),
              label: Text(
                lang.event,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (canPostTasklist)
            OutlinedButton.icon(
              key: QuickJumpKeys.createTaskListAction,
              onPressed: () => showCreateUpdateTaskListBottomSheet(context),
              icon: const Icon(
                Atlas.plus_circle_thin,
                size: 18,
              ),
              label: Text(
                lang.taskList,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (isActive(LabsFeature.polls))
            OutlinedButton.icon(
              onPressed: () {
                _log.info('poll pressed');
              },
              icon: const Icon(
                Atlas.plus_circle_thin,
                size: 18,
              ),
              label: Text(
                lang.poll,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          if (isActive(LabsFeature.discussions))
            OutlinedButton.icon(
              onPressed: () {
                _log.info('Discussion pressed');
              },
              icon: const Icon(
                Atlas.plus_circle_thin,
                size: 18,
              ),
              label: Text(
                lang.discussion,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          OutlinedButton.icon(
            icon: const Icon(Atlas.connection),
            key: SpacesKeys.actionCreate,
            onPressed: () => routeTo(context, Routes.createSpace),
            label: Text(lang.createSpace),
          ),
          if (isBugReportingEnabled)
            OutlinedButton.icon(
              key: QuickJumpKeys.bugReport,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.textHighlight,
                side: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.textHighlight,
                ),
              ),
              icon: const Icon(
                Atlas.bug_clipboard_thin,
                size: 18,
              ),
              label: Text(
                lang.reportBug,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              onPressed: () async {
                if (popBeforeRoute) {
                  Navigator.pop(context);
                }
                await openBugReport(context);
              },
            ),
        ],
      ),
    );
  }

  void routeTo(BuildContext context, Routes route) {
    if (popBeforeRoute) {
      Navigator.pop(context);
    }
    context.pushNamed(route.name);
  }
}
