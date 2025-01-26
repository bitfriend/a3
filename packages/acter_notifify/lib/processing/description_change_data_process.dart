
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForObjectDescriptionChange(
    NotificationItem notification) {
  //Generate body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newDescription = notification.title();

  String? body = '$username updated description: "$newDescription"';

  //Generate title
  final parent = notification.parent();
  String title;
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = '$parentInfo changed';
  } else {
    title = '$username updated description: "$newDescription"';
    body = null;
  }

  return (title, body);
}