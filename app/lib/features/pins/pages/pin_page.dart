import 'dart:core';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';

class PinPage extends ConsumerWidget {
  final String pinId;
  const PinPage({
    super.key,
    required this.pinId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final pin = ref.watch(pinProvider(pinId));
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: pin.hasValue ? pin.value!.title() : 'Loading pin',
            sectionColor: Colors.blue.shade200,
            actions: [
              IconButton(
                icon: const Icon(Atlas.pencil_edit_thin),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'Pin edit not yet implemented',
                  );
                },
              ),
            ],
          ),
          pin.when(
            data: (pin) {
              final isLink = pin.isLink();
              final spaceId = pin.roomIdStr();
              final List<Widget> content = [];
              if (isLink) {
                content.add(
                  OutlinedButton.icon(
                    icon: const Icon(Atlas.link_chain_thin),
                    label: Text(pin.url() ?? ''),
                    onPressed: () async {
                      final target = pin.url()!;
                      await openLink(target, context);
                    },
                  ),
                );
              }
              if (pin.hasFormattedText()) {
                content.add(RenderHtml(text: pin.contentFormatted() ?? ''));
              } else {
                final text = pin.contentText();
                if (text != null) {
                  content.add(Text(text));
                }
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          key: Key(
                            pin.eventIdStr(),
                          ), // FIXME: causes crashes in ffigen
                          leading: Icon(
                            isLink
                                ? Atlas.link_chain_thin
                                : Atlas.document_thin,
                          ),
                          title: Text(pin.title()),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              children: [SpaceChip(spaceId: spaceId)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(children: content),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(
                child: Text('Loading failed: $error'),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Text('Loading'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
