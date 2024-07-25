import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

void showEditTitleBottomSheet({
  required BuildContext context,
  String? bottomSheetTitle,
  required String titleValue,
  required Function(String) onSave,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    constraints: const BoxConstraints(maxHeight: 300),
    builder: (context) {
      return EditTitleSheet(
        bottomSheetTitle: bottomSheetTitle,
        titleValue: titleValue,
        onSave: onSave,
      );
    },
  );
}

class EditTitleSheet extends ConsumerStatefulWidget {
  final String? bottomSheetTitle;
  final String titleValue;
  final Function(String) onSave;

  const EditTitleSheet({
    super.key,
    this.bottomSheetTitle,
    required this.titleValue,
    required this.onSave,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EditTitleSheetState();
}

class _EditTitleSheetState extends ConsumerState<EditTitleSheet> {
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.titleValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          Text(
            widget.bottomSheetTitle ?? L10n.of(context).editTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 40),
          TextFormField(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            controller: _titleController,
            autofocus: true,
            minLines: 1,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: L10n.of(context).name,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => context.closeDialog(),
                child: Text(L10n.of(context).cancel),
              ),
              const SizedBox(width: 20),
              ActerPrimaryActionButton(
                onPressed: () {
                  // no changes to submit
                  if (_titleController.text.trim() ==
                      widget.titleValue.trim()) {
                    context.closeDialog();
                    return;
                  }

                  // Need to update change of tile
                  widget.onSave(_titleController.text.trim());
                },
                child: Text(L10n.of(context).save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
