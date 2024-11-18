import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockAsyncMaybeRoomNotifier extends FamilyAsyncNotifier<Room?, String>
    with Mock
    implements AsyncMaybeRoomNotifier {
  final Room? retVal;

  MockAsyncMaybeRoomNotifier({this.retVal});

  @override
  Future<Room?> build(arg) async => retVal;
}

class MockRoomPreview with Mock implements RoomPreview {}
