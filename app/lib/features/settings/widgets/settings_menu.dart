import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/super_invites/providers/super_invites_providers.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const defaultSettingsMenuKey = Key('settings-menu');

class SettingsMenu extends ConsumerWidget {
  static Key deactivateAccount = const Key('settings-auth-deactivate-account');
  static Key logoutAccount = const Key('settings-auth-logout-account');
  static Key superInvitations = const Key('settings-super-invitations');
  static Key chat = const Key('settings-chat');
  static Key labs = const Key('settings-labs');

  const SettingsMenu({super.key = defaultSettingsMenuKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRoutingLocation);
    final size = MediaQuery.of(context).size;

    Color? colorSelected(Routes route) => currentRoute == route.route
        ? AppTheme.brandColorScheme.secondary
        : null;

    TextStyle titleStylesSelected(Routes route) {
      return TextStyle(color: colorSelected(route));
    }

    final shouldGoNotNamed = size.width > 770;

    final isSuperInviteEnable =
        ref.watch(hasSuperTokensAccess).valueOrNull == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).account,
          children: [
            MenuItemWidget(
              iconData: Atlas.bell_mobile_thin,
              iconColor: colorSelected(Routes.settingNotifications),
              title: L10n.of(context).notifications,
              subTitle: L10n.of(context).notificationsSettingsAndTargets,
              titleStyles: titleStylesSelected(Routes.settingNotifications),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.settingNotifications.name)
                  : context.pushNamed(Routes.settingNotifications.name),
            ),
            MenuItemWidget(
              iconData: Atlas.envelope_paper_email_thin,
              iconColor: colorSelected(Routes.emailAddresses),
              title: L10n.of(context).emailAddresses,
              subTitle: L10n.of(context).connectedToYourAccount,
              titleStyles: titleStylesSelected(Routes.emailAddresses),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.emailAddresses.name)
                  : context.pushNamed(Routes.emailAddresses.name),
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).securityAndPrivacy,
          children: [
            MenuItemWidget(
              iconData: Atlas.key_monitor_thin,
              iconColor: colorSelected(Routes.settingSessions),
              title: L10n.of(context).sessions,
              subTitle: L10n.of(context).yourActiveDevices,
              titleStyles: titleStylesSelected(Routes.settingSessions),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.settingSessions.name)
                  : context.pushNamed(Routes.settingSessions.name),
            ),
            if (ref
                .watch(featuresProvider)
                .isActive(LabsFeature.encryptionBackup))
              MenuItemWidget(
                iconData: Atlas.key_website_thin,
                iconColor: colorSelected(Routes.settingBackup),
                title: L10n.of(context).settingsKeyBackUpTitle,
                subTitle: L10n.of(context).settingsKeyBackUpDesc,
                titleStyles: titleStylesSelected(Routes.settingBackup),
                onTap: () => shouldGoNotNamed
                    ? context.goNamed(Routes.settingBackup.name)
                    : context.pushNamed(Routes.settingBackup.name),
              ),
            MenuItemWidget(
              iconData: Atlas.users_thin,
              iconColor: colorSelected(Routes.blockedUsers),
              title: L10n.of(context).blockedUsers,
              subTitle: L10n.of(context).usersYouBlocked,
              titleStyles: titleStylesSelected(Routes.blockedUsers),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.blockedUsers.name)
                  : context.pushNamed(Routes.blockedUsers.name),
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).community,
          children: [
            MenuItemWidget(
              key: SettingsMenu.superInvitations,
              iconData: Atlas.plus_envelope_thin,
              enabled: isSuperInviteEnable,
              iconColor: colorSelected(Routes.settingsSuperInvites),
              title: L10n.of(context).superInvitations,
              subTitle: L10n.of(context).manageYourInvitationCodes,
              titleStyles: titleStylesSelected(Routes.settingsSuperInvites),
              onTap: isSuperInviteEnable
                  ? () => shouldGoNotNamed
                      ? context.goNamed(Routes.settingsSuperInvites.name)
                      : context.pushNamed(Routes.settingsSuperInvites.name)
                  : null,
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).acterApp,
          children: [
            MenuItemWidget(
              key: SettingsMenu.chat,
              iconData: Atlas.chat_conversation_thin,
              iconColor: colorSelected(Routes.settingsChat),
              title: L10n.of(context).chat,
              subTitle: L10n.of(context).chatSettingsExplainer,
              titleStyles: titleStylesSelected(Routes.settingsChat),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.settingsChat.name)
                  : context.pushNamed(Routes.settingsChat.name),
            ),
            MenuItemWidget(
              iconData: Atlas.language_translation,
              iconColor: colorSelected(Routes.settingLanguage),
              title: L10n.of(context).language,
              subTitle: L10n.of(context).changeAppLanguage,
              titleStyles: titleStylesSelected(Routes.settingLanguage),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.settingLanguage.name)
                  : context.pushNamed(Routes.settingLanguage.name),
            ),
            MenuItemWidget(
              key: SettingsMenu.labs,
              iconData: Atlas.lab_appliance_thin,
              iconColor: colorSelected(Routes.settingsLabs),
              title: L10n.of(context).labs,
              subTitle: L10n.of(context).experimentalActerFeatures,
              titleStyles: titleStylesSelected(Routes.settingsLabs),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.settingsLabs.name)
                  : context.pushNamed(Routes.settingsLabs.name),
            ),
            MenuItemWidget(
              iconData: Atlas.info_circle_thin,
              iconColor: colorSelected(Routes.info),
              title: L10n.of(context).info,
              titleStyles: titleStylesSelected(Routes.info),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.info.name)
                  : context.pushNamed(Routes.info.name),
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).dangerZone,
          isDanderZone: true,
          children: [
            MenuItemWidget(
              key: SettingsMenu.logoutAccount,
              iconData: Atlas.exit_thin,
              iconColor: Theme.of(context).colorScheme.error,
              title: L10n.of(context).logOut,
              subTitle: L10n.of(context).closeSessionAndDeleteData,
              titleStyles: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => logoutConfirmationDialog(context, ref),
            ),
            MenuItemWidget(
              key: SettingsMenu.deactivateAccount,
              iconData: Atlas.trash_can_thin,
              iconColor: Theme.of(context).colorScheme.error,
              title: L10n.of(context).deactivateAccount,
              subTitle: L10n.of(context).irreversiblyDeactivateAccount,
              titleStyles: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => deactivationConfirmationDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _settingMenuSection({
    required BuildContext context,
    required String sectionTitle,
    bool isDanderZone = false,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 10.0),
            child: Text(
              sectionTitle,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: isDanderZone
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
            ),
          ),
          Column(
            children: children,
          ),
        ],
      ),
    );
  }
}
