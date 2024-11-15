import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::room::join');

Future<String?> joinRoom(
  BuildContext context,
  WidgetRef ref,
  String displayMsg,
  String roomIdOrAlias,
  List<String>? serverNames,
  Function(String)? forward,
) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: displayMsg);
  final client = ref.read(alwaysClientProvider);
  try {
    final sdk = await ref.read(sdkProvider.future);
    VecStringBuilder servers = sdk.api.newVecStringBuilder();
    if (serverNames != null) {
      for (final server in serverNames) {
        servers.add(server);
      }
    }
    final newRoom = await client.joinRoom(roomIdOrAlias, servers);
    final roomId = newRoom.roomIdStr();
    // ensure we re-evaluate the room data on our end. This is necessary
    // if we knew of the room prior (e.g. we had left it), but hadn’t joined
    // this should properly re-evaluate all possible readers
    ref.invalidate(maybeRoomProvider(roomId));
    ref.invalidate(chatProvider(roomId));
    ref.invalidate(spaceProvider(roomId));
    await client.waitForRoom(roomId, 5);
    EasyLoading.dismiss();
    if (forward != null) forward(roomId);
    return roomId;
  } catch (e, s) {
    _log.severe('Failed to join room', e, s);
    EasyLoading.showError(
      lang.joiningFailed(e),
      duration: const Duration(seconds: 3),
    );
    return null;
  }
}
