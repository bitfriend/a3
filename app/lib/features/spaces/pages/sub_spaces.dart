import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::space::sub_spaces');

class SubSpaces extends ConsumerStatefulWidget {
  static const moreOptionKey = Key('sub-spaces-more-actions');
  static const createSubspaceKey = Key('sub-spaces-more-create-subspace');
  static const linkSubspaceKey = Key('sub-spaces-more-link-subspace');

  final String spaceId;

  const SubSpaces({super.key, required this.spaceId});

  @override
  ConsumerState<SubSpaces> createState() => _SubSpacesState();
}

class _SubSpacesState extends ConsumerState<SubSpaces> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBarUI(),
      body: _buildSubSpacesUI(),
    );
  }

  AppBar _buildAppBarUI() {
    final spaceName =
        ref.watch(roomDisplayNameProvider(widget.spaceId)).valueOrNull;
    final membership = ref.watch(roomMembershipProvider(widget.spaceId));
    bool canLinkSpace =
        membership.valueOrNull?.canString('CanLinkSpaces') == true;
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).spaces),
          Text(
            '($spaceName)',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(PhosphorIcons.arrowsClockwise()),
          onPressed: () {
            ref.read(addDummySpaceCategoriesProvider(widget.spaceId));
          },
        ),
        if (canLinkSpace) _buildMenuOptions(context),
      ],
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(PhosphorIcons.plusCircle()),
      iconSize: 28,
      color: Theme.of(context).colorScheme.surface,
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        PopupMenuItem(
          key: SubSpaces.createSubspaceKey,
          onTap: () => context.pushNamed(
            Routes.createSpace.name,
            queryParameters: {'parentSpaceId': widget.spaceId},
          ),
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.plus()),
              const SizedBox(width: 6),
              Text(L10n.of(context).createSubspace),
            ],
          ),
        ),
        PopupMenuItem(
          key: SubSpaces.linkSubspaceKey,
          onTap: () => context.pushNamed(
            Routes.linkSubspace.name,
            pathParameters: {'spaceId': widget.spaceId},
          ),
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.link()),
              const SizedBox(width: 6),
              Text(L10n.of(context).linkExistingSpace),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => context.pushNamed(
            Routes.linkRecommended.name,
            pathParameters: {'spaceId': widget.spaceId},
          ),
          child: Row(
            children: [
              const Icon(Atlas.link_select, size: 18),
              const SizedBox(width: 8),
              Text(L10n.of(context).recommendedSpaces),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {},
          child: Row(
            children: [
              Icon(PhosphorIcons.dotsSixVertical()),
              const SizedBox(width: 6),
              Text(L10n.of(context).organized),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubSpacesUI() {
    final spaceCategories = ref.watch(spaceCategoriesProvider(widget.spaceId));
    return spaceCategories.when(
      data: (categories) {
        final List<Category> categoryList = categories.categories().toList();
        return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: categoryList.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildCategoriesList(categoryList[index]);
          },
        );
      },
      error: (e, s) {
        _log.severe('Failed to load the space categories', e, s);
        return Center(child: Text(L10n.of(context).loadingFailed(e)));
      },
      loading: () => Center(child: Text(L10n.of(context).loading)),
    );
  }

  Widget _buildCategoriesList(Category category) {
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            ActerIconWidget(
              iconSize: 24,
              color: convertColor(
                category.display()?.color(),
                iconPickerColors[0],
              ),
              icon: ActerIcon.iconForCategories(category.display()?.iconStr()),
            ),
            const SizedBox(width: 6),
            Text(category.title()),
          ],
        ),
        children: List<Widget>.generate(
          category.entries().length,
          (index) => ListTile(
            title: Text(category.entries()[index]),
          ),
        ),
      ),
    );
  }
}
