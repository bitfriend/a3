import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/pins/widgets/pin_list_empty_state.dart';
import 'package:acter/features/pins/widgets/pin_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PinsListPage extends ConsumerStatefulWidget {
  final String? spaceId;

  const PinsListPage({
    super.key,
    this.spaceId,
  });

  @override
  ConsumerState<PinsListPage> createState() => _AllPinsPageConsumerState();
}

class _AllPinsPageConsumerState extends ConsumerState<PinsListPage> {
  String get searchValue => ref.watch(searchValueProvider);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    final spaceId = widget.spaceId;
    return AppBar(
      centerTitle: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).pins),
          if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
        ],
      ),
      actions: [
        AddButtonWithCanPermission(
          canString: 'CanPostPin',
          spaceId: widget.spaceId,
          onPressed: () => context.pushNamed(
            Routes.createPin.name,
            queryParameters: {'spaceId': spaceId},
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerSearchWidget(
          onChanged: (value) {
            final notifier = ref.read(searchValueProvider.notifier);
            notifier.state = value;
          },
          onClear: () {
            final notifier = ref.read(searchValueProvider.notifier);
            notifier.state = '';
          },
        ),
        Expanded(
          child: PinListWidget(
            spaceId: widget.spaceId,
            shrinkWrap: false,
            searchValue: searchValue,
            emptyState: PinListEmptyState(
              spaceId: widget.spaceId,
              isSearchApplied: searchValue.isNotEmpty,
            ),
          ),
        ),
      ],
    );
  }
}
