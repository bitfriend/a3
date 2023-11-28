import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/settings/super_invites/widgets/redeem_token.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SuperInvitesPage extends ConsumerWidget {
  static Key createNewToken = const Key('super-invites-create');
  const SuperInvitesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(superInvitesTokensProvider);
    return WithSidebar(
      sidebar: const SettingsMenu(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: const Text('Super Invites'),
          centerTitle: true,
          actions: [
            IconButton(
              key: createNewToken,
              icon: Icon(
                Atlas.plus_circle_thin,
                color: Theme.of(context).colorScheme.neutral5,
              ),
              iconSize: 28,
              color: Theme.of(context).colorScheme.surface,
              onPressed: () async {
                context.pushNamed(Routes.actionCreateSuperInvite.name);
              },
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: RedeemToken()),
            tokens.when(
              data: (tokens) => tokens.isNotEmpty
                  ? SliverList.builder(
                      itemBuilder: (BuildContext context, int index) {
                        final token = tokens[index];
                        final tokenStr = token.token().toString();
                        return Card(
                          key: Key('edit-token-$tokenStr'),
                          margin: const EdgeInsets.all(5),
                          child: ListTile(
                            title: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(tokenStr),
                            ),
                            subtitle:
                                Text('Used ${token.acceptedCount()} times'),
                            onTap: () {
                              context.pushNamed(
                                Routes.actionCreateSuperInvite.name,
                                extra: token,
                              );
                            },
                          ),
                        );
                      },
                      itemCount: tokens.length,
                    )
                  : const SliverToBoxAdapter(
                      child: Center(
                        child:
                            Text('You have not yet created any invite tokens'),
                      ),
                    ),
              error: (error, stack) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text('Failed to load Invite tokens: $error'),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}