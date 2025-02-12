import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/plus_icon_widget.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/widgets/invite_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class InviteListPage extends ConsumerStatefulWidget {
  const InviteListPage({super.key});

  @override
  ConsumerState<InviteListPage> createState() => _InviteListPageState();
}

class _InviteListPageState extends ConsumerState<InviteListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      ref.read(inviteListSearchTermProvider.notifier).state = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final lang = L10n.of(context);
    return AppBar(
      title: Text(lang.superInvites),
      actions: [
        PlusIconWidget(
          onPressed: () => context.pushNamed(Routes.createSuperInvite.name),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        ActerSearchWidget(
          onChanged: (value) {
            final notifier = ref.read(inviteListSearchTermProvider.notifier);
            notifier.state = value;
          },
          onClear: () {
            final notifier = ref.read(inviteListSearchTermProvider.notifier);
            notifier.state = '';
          },
        ),
        Expanded(child: InviteListWidget()),
      ],
    );
  }
}
