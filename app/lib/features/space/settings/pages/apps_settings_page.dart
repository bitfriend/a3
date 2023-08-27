import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsAndMembership {
  final Space space;
  final ActerAppSettings settings;
  final Member? member;

  const SettingsAndMembership(this.space, this.settings, this.member);
}

final spaceAppSettingsProvider = FutureProvider.autoDispose
    .family<SettingsAndMembership, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);
  return SettingsAndMembership(
    space,
    await space.appSettings(),
    await ref.watch(spaceMembershipProvider(spaceId).future),
  );
});

class SpaceAppsSettingsPage extends ConsumerWidget {
  final String spaceId;
  const SpaceAppsSettingsPage({Key? key, required this.spaceId})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceSettingsWatcher = ref.watch(spaceAppSettingsProvider(spaceId));

    return WithSidebar(
      sidebar: SpaceSettingsMenu(
        spaceId: spaceId,
      ),
      child: spaceSettingsWatcher.when(
        data: (appSettingsAndMembership) {
          final appSettings = appSettingsAndMembership.settings;
          final space = appSettingsAndMembership.space;
          final canEdit = appSettingsAndMembership.member != null
              ? appSettingsAndMembership.member!
                  .canString('CanChangeAppSettings')
              : false;

          final news = appSettings.news();
          final events = appSettings.events();
          final pins = appSettings.pins();

          final moreSections = [];
          if (news.active()) {
            moreSections.add(
              SettingsSection(
                title: const Text('Updates'),
                tiles: [
                  SettingsTile(
                    enabled: false,
                    title: const Text('Required PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post news updates',
                    ),
                    trailing: const Text('not yet implemented'),
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Comments on Updates'),
                    description: const Text('not yet supported'),
                    enabled: false,
                    initialValue: false,
                    onToggle: (newVal) {},
                  ),
                ],
              ),
            );
          }
          if (pins.active()) {
            moreSections.add(
              SettingsSection(
                title: const Text('Pin'),
                tiles: [
                  SettingsTile(
                    enabled: false,
                    title: const Text('Required PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post and edit pins',
                    ),
                    trailing: const Text('not yet implemented'),
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Comments on Pins'),
                    description: const Text('not yet supported'),
                    enabled: false,
                    initialValue: false,
                    onToggle: (newVal) {},
                  ),
                ],
              ),
            );
          }
          if (events.active()) {
            moreSections.add(
              SettingsSection(
                title: const Text('Calendar Events'),
                tiles: [
                  SettingsTile(
                    enabled: false,
                    title: const Text('Admin PowerLevel'),
                    description: const Text(
                      'Minimum power level required to post calendar events',
                    ),
                    trailing: const Text('not yet implemented'),
                  ),
                  SettingsTile(
                    enabled: false,
                    title: const Text('RSVP PowerLevel'),
                    description: const Text(
                      'Minimum power level to RSVP to calendar events',
                    ),
                    trailing: const Text('not yet implemented'),
                  ),
                  SettingsTile.switchTile(
                    title: const Text('Comments'),
                    description: const Text('not yet supported'),
                    enabled: false,
                    initialValue: false,
                    onToggle: (newVal) {},
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Apps Settings')),
            body: SettingsList(
              sections: [
                SettingsSection(
                  title: const Text('Active Apps'),
                  tiles: [
                    SettingsTile.switchTile(
                      title: const Text('Updates'),
                      enabled: canEdit,
                      description: const Text(
                        'Post space-wide updates',
                      ),
                      initialValue: news.active(),
                      onToggle: (newVal) async {
                        final updated = news.updater();
                        updated.active(newVal);
                        final builder = appSettings.updateBuilder();
                        builder.news(updated.build());
                        await space.updateAppSettings(builder);
                      },
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Pins'),
                      enabled: canEdit,
                      description: const Text(
                        'Pin important information',
                      ),
                      initialValue: pins.active(),
                      onToggle: (newVal) async {
                        final updated = pins.updater();
                        updated.active(newVal);
                        final builder = appSettings.updateBuilder();
                        builder.pins(updated.build());
                        await space.updateAppSettings(builder);
                      },
                    ),
                    SettingsTile.switchTile(
                      title: const Text('Events Calendar'),
                      enabled: canEdit,
                      description: const Text(
                        'Calender with Events',
                      ),
                      initialValue: events.active(),
                      onToggle: (newVal) async {
                        final updated = events.updater();
                        updated.active(newVal);
                        final builder = appSettings.updateBuilder();
                        builder.events(updated.build());
                        await space.updateAppSettings(builder);
                      },
                    ),
                  ],
                ),
                ...moreSections,
              ],
            ),
          );
        },
        loading: () => const Center(child: Text('loading')),
        error: (e, s) => Center(
          child: Text('Error loading app settings: $e'),
        ),
      ),
    );
  }
}
