import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final commentsManagerProvider = AsyncNotifierProvider.autoDispose.family<
    AsyncCommentsManagerNotifier, CommentsManager, Future<CommentsManager>>(
  () => AsyncCommentsManagerNotifier(),
);

class AsyncCommentsManagerNotifier extends AutoDisposeFamilyAsyncNotifier<
    CommentsManager, Future<CommentsManager>> {
  late Stream<bool> _listener;

  @override
  FutureOr<CommentsManager> build(Future<CommentsManager> arg) async {
    final manager = await arg;
    _listener = manager.subscribeStream(); // keep it resident in memory
    _listener.forEach((e) async {
      // reset
      state = await AsyncValue.guard(() => manager.reload());
    });
    return manager;
  }
}

final commentsListProvider = FutureProvider.family
    .autoDispose<List<Comment>, CommentsManager>((ref, manager) async {
  return (await manager.comments()).toList();
});
