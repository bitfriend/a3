import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:acter_notifify/acter_notifify.dart';
import 'package:acter_notifify/android.dart';
import 'package:acter_notifify/local.dart';
import 'package:acter_notifify/util.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:push/push.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger('a3::notifify');
int id = 0;

const bool isProduction = bool.fromEnvironment('dart.vm.product');

Future<void> initializePush({
  required HandleMessageTap handleMessageTap,
  IsEnabledCheck? isEnabledCheck,
  ShouldShowCheck? shouldShowCheck,
  CurrentClientsGen? currentClientsGen,
  required String appName,
  required String appIdPrefix,
  required String pushServerUrl,
}) async {
  try {
    // Handle notification launching app from terminated state
    Push.instance.notificationTapWhichLaunchedAppFromTerminated.then((data) {
      if (data != null) {
        _log.info('Notification tap launched app from terminated state:\n'
            'RemoteMessage: $data \n');
        handleMessageTap(data);
      }
    });

    // Handle notification taps
    Push.instance.onNotificationTap.listen((data) {
      handleMessageTap(data);
    });

    // Handle push notifications
    Push.instance.addOnMessage((message) async {
      if (isEnabledCheck != null && !await isEnabledCheck()) {
        return;
      }
      await _handlePushMessage(
        message,
        background: false,
        shouldShowCheck: shouldShowCheck,
      );
    });

    // Handle push notifications on background - in iOS we are doing that in
    // the other instance.
    if (!Platform.isIOS) {
      Push.instance.addOnBackgroundMessage((message) async {
        if (isEnabledCheck != null && !await isEnabledCheck()) {
          return;
        }
        await _handlePushMessage(
          message,
          background: true,
          shouldShowCheck: shouldShowCheck,
        );
      });
    }

    // To be informed that the device's token has been updated by the operating system
    // You should update your servers with this token
    Push.instance.onNewToken.listen((token) async {
      // FIXME: how to identify which clients are connected to this?
      _log.info('Just got a new FCM registration token: $token');
      final clients =
          currentClientsGen == null ? [] : await currentClientsGen();
      for (final client in clients) {
        final deviceId = client.deviceId().toString();
        try {
          await _addToken(client, token,
              appIdPrefix: appIdPrefix,
              appName: appName,
              pushServerUrl: pushServerUrl);
        } catch (error, st) {
          _log.severe('Setting token for $deviceId failed', error, st);
        }
      }
    });
  } catch (e, s) {
    // this fails on hot-reload and in integration tests... if so, ignore for now
    _log.severe('Push initialization error', e, s);
  }
}

Future<bool> _handlePushMessage(
  RemoteMessage message, {
  bool background = false,
  ShouldShowCheck? shouldShowCheck,
}) async {
  if (message.data == null) {
    _log.info('non-matrix push: $message');
    return false;
  }
  return await _handleMatrixMessage(message.data!,
      background: background, shouldShowCheck: shouldShowCheck);
}

Future<bool> _handleMatrixMessage(
  Map<String?, Object?> message, {
  bool background = false,
  ShouldShowCheck? shouldShowCheck,
}) async {
  final deviceId = message['device_id'] as String;
  final roomId = message['room_id'] as String;
  final eventId = message['event_id'] as String;
  _log.info('Received msg $roomId: $eventId');
  try {
    final instance = await ActerSdk.instance;
    final notification =
        await instance.getNotificationFor(deviceId, roomId, eventId);
    _log.info('got a notification');

    if (shouldShowCheck != null &&
        !await shouldShowCheck(notification.targetUrl())) {
      _log.info(
        'Ignoring notification: user is looking at this screen already',
      );
      return false;
    }

    await _showNotification(notification);
    return true;
  } catch (e, s) {
    _log.severe('Parsing Notification failed', e, s);
  }
  return false;
}

Future<void> _showNotification(
  NotificationItem notification,
) async {
  if (Platform.isAndroid) {
    return await showNotificationOnAndroid(notification);
  }
  // fallback for non-android
  String? body;
  String title = notification.title();
  List<DarwinNotificationAttachment> attachments = [];

  final msg = notification.body();
  if (msg != null) {
    body = msg.body();
  }
  // FIXME: currently failing with
  // Parsing Notification failed: PlatformException(Error 101, Unrecognized attachment file type, UNErrorDomain, null)
  if (notification.hasImage()) {
    final tempDir = await getTemporaryDirectory();
    final filePath = await notification.imagePath(tempDir.path);
    _log.info('attachment at $filePath');
    attachments.add(DarwinNotificationAttachment(filePath));
  }

  final darwinDetails = DarwinNotificationDetails(
    threadIdentifier: notification.threadId(),
    attachments: attachments,
  );
  final notificationDetails = NotificationDetails(
    macOS: darwinDetails,
    iOS: darwinDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    id++,
    title,
    body,
    notificationDetails,
    payload: notification.targetUrl(),
  );
}

Future<bool?> setupPushNotificationsForDevice(
  Client client, {
  required String appName,
  required String appIdPrefix,
  required String pushServerUrl,
}) async {
  // this show some extra dialog here on devices where necessary
  final requested = await Push.instance.requestPermission(
    badge: true,
    alert: true, // we request loud notifications now.
  );
  if (!requested) {
    // we were bluntly rejected, save and don't them bother again:
    return false;
  }

  // let's get the token
  final token = await Push.instance.token;

  if (token == null) {
    _log.info('No token given');
    return null;
  }

  return await _addToken(client, token,
      appIdPrefix: appIdPrefix, appName: appName, pushServerUrl: pushServerUrl);
}

Map<String, StreamSubscription<String>> _subscriptions = {};

Future<bool?> setupNtfyNotificationsForDevice(
  Client client, {
  required String appName,
  required String appIdPrefix,
  required String ntfyServer,
  ShouldShowCheck? shouldShowCheck,
}) async {
  // let's get the token
  final deviceId = client.deviceId().toString();

  final token = 'up$deviceId';

  // submit to server
  await _addToken(
    client,
    'https://$ntfyServer/$token',
    appIdPrefix: appIdPrefix,
    appName: appName,
    pushServerUrl: 'https://$ntfyServer/_matrix/push/v1/notify',
  );

  if (_subscriptions.containsKey(token)) {
    // clear any pending streams
    await _subscriptions[token]?.cancel();
    _subscriptions.remove(token);
  }

  // and start listening to the server
  Response<ResponseBody> rs = await Dio().get<ResponseBody>(
    'https://$ntfyServer/$token/json',
    options: Options(headers: {
      // "Authorization":
      //     'vhdrjb token"',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    }, responseType: ResponseType.stream), // set responseType to `stream`
  );
  StreamTransformer<Uint8List, List<int>> unit8Transformer =
      StreamTransformer.fromHandlers(
    handleData: (data, sink) {
      sink.add(List<int>.from(data));
    },
  );
  if (rs.data == null) {
    _log.severe('Connecting to ntfy server failed: $rs');
    return false;
  }
  _subscriptions[token] = rs.data!.stream
      .transform(unit8Transformer)
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((event) {
    try {
      final eventJson = json.decode(event);
      if (eventJson['event'] != 'message') {
        // not anything we care about
        return;
      }
      final message = json
          .decode(eventJson['message']); // we have to decode the content again
      final notification = message['notification'];
      // we plug our device ID as it is needed for the inner workings
      notification['device_id'] = deviceId;
      _log.info('Message received: $notification');
      _handleMatrixMessage(
        notification as Map<String?, Object?>,
        shouldShowCheck: shouldShowCheck,
      );
    } catch (error, stack) {
      _log.severe('Failed to show push notification $event', error, stack);
    }
  });
  return true;
}

Future<bool> _addToken(
  Client client,
  String token, {
  required String appName,
  required String appIdPrefix,
  required String pushServerUrl,
}) async {
  final String name = await deviceName();
  late String appId;
  if (Platform.isIOS) {
    // sygnal expects token as a base64 encoded string, but we have a HEX from the plugin
    token = base64.encode(hex.decode(token));
    if (isProduction) {
      appId = '$appIdPrefix.ios';
    } else {
      appId = '$appIdPrefix.ios.dev';
    }
  } else {
    appId = '$appIdPrefix.${Platform.operatingSystem}';
  }

  await client.addPusher(
    appId,
    token,
    name,
    appName,
    pushServerUrl,
    Platform.isIOS,
    null,
  );

  _log.info(
    'notification pusher set: $appName ($appId) on $name ($token) to $pushServerUrl',
  );

  await client.installDefaultActerPushRules();

  _log.info('default push rules submitted');
  return true;
}
