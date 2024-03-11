import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::attachments');

// ignore_for_file: unused_field

class AttachmentsManagerNotifier
    extends FamilyNotifier<AttachmentsManager, AttachmentsManager> {
  late Stream<void> _listener;
  late StreamSubscription<void> _poller;

  @override
  AttachmentsManager build(AttachmentsManager arg) {
    _listener = arg.subscribeStream(); // keep it resident in memory
    _poller = _listener.listen(
      (e) async {
        _log.info('attempting to reload');
        final newManager = await arg.reload();
        _log.info(
          'manager updated. attachments: ${newManager.attachmentsCount()}',
        );
        state = newManager;
      },
      onError: (e, stack) {
        _log.severe('stream errored.', e, stack);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    return arg;
  }
}
