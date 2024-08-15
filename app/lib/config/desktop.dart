import 'dart:io';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/router/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::desktop');

class DesktopSupport extends StatefulWidget {
  final Widget child;

  const DesktopSupport({super.key, required this.child});

  @override
  State<DesktopSupport> createState() => _DesktopSupportState();
}

class _DesktopSupportState extends State<DesktopSupport>
    with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initDesktop();
  }

  Future<void> _initDesktop() async {
    // Must add this line.
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      title: 'Acter',
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });

    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/icon/tray_icon.ico'
          : 'assets/icon/tray_icon.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'home',
          label: 'Home',
        ),
        MenuItem(
          key: 'chat',
          label: 'Chat',
        ),
        MenuItem(
          key: 'activities',
          label: 'Activities',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
          onClick: (item) {
            windowManager.destroy();
          },
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    try {
      trayManager.setToolTip('Acter');
    } on MissingPluginException {
      _log.warning('Setting Tray tooltip not supported on this platform');
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      print('prevent close');
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    // toggle visiblity
    print("toggled");
    if (await windowManager.isVisible()) {
      print('hiding');
      await windowManager.hide();
    } else {
      print('showing');
      await windowManager.show();
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    // do something
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'exit_app') {
      await windowManager.destroy();
      return;
    }

    // we want to show the window on all other clicks
    windowManager.show();
    if (menuItem.key == 'home') {
      rootNavKey.currentContext!.pushNamed(Routes.main.name);
    } else if (menuItem.key == 'chat') {
      rootNavKey.currentContext!.pushNamed(Routes.chat.name);
    } else if (menuItem.key == 'activities') {
      rootNavKey.currentContext!.pushNamed(Routes.activities.name);
    }
  }
}
