import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter/features/settings/widgets/options_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::chat_settings');

class ChatSettingsPage extends ConsumerWidget {
  const ChatSettingsPage({super.key});

  AbstractSettingsTile _autoDownload(BuildContext context, WidgetRef ref) {
    return ref.watch(userAppSettingsProvider).when(
          data: (settings) => OptionsSettingsTile<String>(
            selected: settings.autoDownloadChat() ?? 'always',
            title: L10n.of(context).chatSettingsAutoDownload,
            explainer: L10n.of(context).chatSettingsAutoDownloadExplainer,
            options: [
              ('always', L10n.of(context).chatSettingsAutoDownloadAlways),
              ('wifiOnly', L10n.of(context).chatSettingsAutoDownloadWifiOnly),
              ('never', L10n.of(context).chatSettingsAutoDownloadNever),
            ],
            onSelect: (String newVal) async {
              EasyLoading.show(status: L10n.of(context).settingsSubmitting);
              try {
                final updater = settings.updateBuilder();
                updater.autoDownloadChat(newVal);
                await updater.send();
                EasyLoading.showToast(
                  // ignore: use_build_context_synchronously
                  L10n.of(context).settingsSubmittingSuccess,
                  toastPosition: EasyLoadingToastPosition.bottom,
                );
              } catch (error, stackTrace) {
                _log.severe('Failure submitting settings', error, stackTrace);
                EasyLoading.showError(
                  // ignore: use_build_context_synchronously
                  L10n.of(context).settingsSubmittingFailed(error),
                );
              }
            },
          ),
          error: (error, stack) => SettingsTile.navigation(
            title: Text(
              L10n.of(context).failed,
            ),
          ),
          loading: () => SettingsTile.switchTile(
            title: Skeletonizer(child: Text(L10n.of(context).events)),
            enabled: false,
            description: Skeletonizer(
              child: Text(L10n.of(context).sharedCalendarAndEvents),
            ),
            initialValue: false,
            onToggle: (newVal) {},
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(title: Text(L10n.of(context).chat)),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(L10n.of(context).defaultModes),
              tiles: [
                _autoDownload(context, ref),

                // SettingsTile.switchTile(
                //   key: tasksLabSwitch,
                //   title: Text(L10n.of(context).tasks),
                //   description: Text(
                //     L10n.of(context).manageTasksListsAndToDosTogether,
                //   ),
                //   initialValue: ref.watch(isActiveProvider(LabsFeature.tasks)),
                //   onToggle: (newVal) =>
                //       updateFeatureState(ref, LabsFeature.tasks, newVal),
                // ),
                // SettingsTile.switchTile(
                //   title: const Text('Comments'),
                //   description: const Text('Commenting on space objects'),
                //   initialValue:
                //       ref.watch(isActiveProvider(LabsFeature.comments)),
                //   onToggle: (newVal) =>
                //       updateFeatureState(ref, LabsFeature.comments, newVal),
                // ),
                // SettingsTile.switchTile(
                //   title: Text(L10n.of(context).polls),
                //   description: Text(L10n.of(context).pollsAndSurveys),
                //   initialValue: ref.watch(isActiveProvider(LabsFeature.polls)),
                //   onToggle: (newVal) =>
                //       updateFeatureState(ref, LabsFeature.polls, newVal),
                //   enabled: false,
                // ),
                // SettingsTile.switchTile(
                //   title: Text(L10n.of(context).coBudget),
                //   description:
                //       Text(L10n.of(context).manageBudgetsCooperatively),
                //   initialValue: ref.watch(
                //     isActiveProvider(LabsFeature.cobudget),
                //   ),
                //   onToggle: (newVal) =>
                //       updateFeatureState(ref, LabsFeature.cobudget, newVal),
                //   enabled: false,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
