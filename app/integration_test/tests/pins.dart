import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/pins/pages/pin_page.dart';
import 'package:acter/features/pins/sheets/create_pin_sheet.dart';
import 'package:acter/features/pins/widgets/pin_item.dart';
import 'package:acter/features/profile/pages/my_profile_page.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/pages/labs_page.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/login.dart';
import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/super_invites.dart';
import '../support/util.dart';

extension ActerNews on ConvenientTest {
  Future<void> gotoPin(String pinId, {Key? appTab}) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await navigateTo([
      MainNavKeys.dashboardHome,
      MainNavKeys.dashboardHome,
      MainNavKeys.quickJump,
      MainNavKeys.quickJump,
      QuickJumpKeys.pins,
    ]);

    final select = find.byKey(Key('pin-list-item-$pinId'));
    await tester.ensureVisible(select);
    await select.should(findsOneWidget);
    await select.longPress();

    if (appTab != null) {
      final selectedApp = find.byKey(appTab);
      await tester.ensureVisible(selectedApp);
      await selectedApp.should(findsOneWidget);
      await selectedApp.tap();
    }
  }

  Future<void> createPin(
    String spaceId,
    String title,
    String content,
    String url,
  ) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final quickJumpKey = find.byKey(MainNavKeys.quickJump);
    await quickJumpKey.should(findsOneWidget);
    await quickJumpKey.tap();

    final spacesKey = find.byKey(QuickJumpKeys.createPinAction);
    await spacesKey.should(findsOneWidget);
    await spacesKey.tap();

    final titleField = find.byKey(CreatePinSheet.titleFieldKey);
    await titleField.should(findsOneWidget);
    await titleField.enterTextWithoutReplace(title);

    final urlField = find.byKey(CreatePinSheet.urlFieldKey);
    await urlField.should(findsOneWidget);
    await urlField.enterTextWithoutReplace(url);

    final contentField = find.byKey(CreatePinSheet.contentFieldKey);
    await contentField.should(findsOneWidget);
    await contentField.enterTextWithoutReplace(content);

    await selectSpace(spaceId, SelectSpaceFormField.openKey);

    final submit = find.byKey(CreatePinSheet.submitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();
  }

  Future<String> editPin(String title, String content, String url) async {
    await find.byKey(PinPage.actionMenuKey).should(findsOneWidget);
    final actionMenuKey = find.byKey(PinPage.actionMenuKey);
    await actionMenuKey.tap();

    await find.byKey(PinPage.editBtnKey).should(findsOneWidget);
    final editBtnKey = find.byKey(PinPage.editBtnKey);
    await editBtnKey.tap();

    final titleField = find.byKey(PinPage.titleFieldKey);
    await titleField.should(findsOneWidget);
    await titleField.replaceText(title);

    final linkField = find.byKey(PinItem.linkFieldKey);
    await linkField.should(findsOneWidget);
    await linkField.replaceText(url);

    final mdEditorKey = find.byKey(PinItem.markdownEditorKey);
    await mdEditorKey.replaceText(content);

    final saveBtnKey = find.byKey(PinItem.saveBtnKey);
    await saveBtnKey.should(findsOneWidget);
    await tester.ensureVisible(saveBtnKey);
    await saveBtnKey.tap();

    final pinPage = find.byKey(PinPage.pinPageKey);
    await pinPage.should(findsOneWidget);
    final page = pinPage.evaluate().first.widget as PinPage;
    return page.pinId;
  }

  Future<void> switchPinLabEditor() async {
    final avatarKey = find.byKey(Keys.avatar);
    await avatarKey.should(findsOneWidget);
    await avatarKey.tap();

    final settingsKey = find.byKey(MyProfilePage.settingsKey);
    await settingsKey.should(findsOneWidget);
    await settingsKey.tap();

    final labsKey = find.byKey(SettingsMenu.labs);
    await tester.ensureVisible(labsKey);
    await labsKey.should(findsOneWidget);
    await labsKey.tap();

    final pinEditorKey = find.byKey(SettingsLabsPage.pinsEditorLabSwitch);
    await tester.ensureVisible(pinEditorKey);
    await pinEditorKey.should(findsOneWidget);
    await pinEditorKey.tap();
  }

  Future<void> ensureLabRichEditorEnabled() async {
    await find.byKey(PinPage.actionMenuKey).should(findsOneWidget);
    final actionMenuKey = find.byKey(PinPage.actionMenuKey);
    await actionMenuKey.tap();

    await find.byKey(PinPage.editBtnKey).should(findsOneWidget);
    final editBtnKey = find.byKey(PinPage.editBtnKey);
    await editBtnKey.tap();

    final richEditorKey = find.byKey(PinItem.richTextEditorKey);
    await richEditorKey.should(findsOneWidget);
  }

  Future<void> ensureMdEditorEnabled() async {
    await find.byKey(PinPage.actionMenuKey).should(findsOneWidget);
    final actionMenuKey = find.byKey(PinPage.actionMenuKey);
    await actionMenuKey.tap();

    await find.byKey(PinPage.editBtnKey).should(findsOneWidget);
    final editBtnKey = find.byKey(PinPage.editBtnKey);
    await editBtnKey.tap();

    final mdEditorKey = find.byKey(PinItem.markdownEditorKey);
    await mdEditorKey.should(findsOneWidget);
  }
}

void pinsTests() {
  acterTestWidget('Create Example Pin with URL can be seen by others',
      (t) async {
    final spaceId = await t.freshAccountWithSpace(
      userDisplayName: 'Alex',
      spaceDisplayName: 'Shared Pins Example',
    );
    await t.createPin(
      spaceId,
      'This is great',
      'This pin contains acter global link',
      'https://acter.global',
    );

    // we expect to be thrown to the pin screen and see our title

    await find.text('This is great').should(findsAtLeast(1));

    final superInviteToken = await t.createSuperInvite([spaceId]);

    await t.logout();
    await t.freshAccount(
      registrationToken: superInviteToken,
      displayName: 'Beatrice',
    );

    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.pins,
    ]);

    await find.text('This is great').should(findsOneWidget);
  });

  acterTestWidget(
      'User sees pins rich content editor based on selection in Acter Labs',
      (t) async {
    final spaceId = await t.freshAccountWithSpace(
      userDisplayName: 'Alex',
      spaceDisplayName: 'Create Pin Example',
    );
    await t.createPin(
      spaceId,
      'Create Pin Example',
      'This pin has Acter Global link',
      'https://acter.global',
    );

    final pinPage = find.byKey(PinPage.pinPageKey);
    await pinPage.should(findsOneWidget);
    final page = pinPage.first.evaluate().first.widget as PinPage;
    final pinId = page.pinId;

    // keyboard showing still and obscuring main nav, do gesture do hide it
    await t.tester.fling(pinPage, const Offset(0.0, -5.0), 50.0);
    await t.pump(const Duration(seconds: 1));

    // can see the main nav now
    await t.navigateTo([
      MainNavKeys.dashboardHome,
      MainNavKeys.dashboardHome,
    ]);

    // enable rich text editor
    await t.switchPinLabEditor();
    // let's check whether pin rich editor is there
    await t.gotoPin(pinId);
    await t.ensureLabRichEditorEnabled();

    await t.navigateTo([
      MainNavKeys.dashboardHome,
      MainNavKeys.dashboardHome,
    ]);

    // switch to default md editor again to ensure disabled
    await t.switchPinLabEditor();
    await t.gotoPin(pinId);
    await t.ensureMdEditorEnabled();
  });
  acterTestWidget(
      'Create Example Pin and Edit it with ensuring reflected changes are shown',
      (t) async {
    final spaceId = await t.freshAccountWithSpace(
      userDisplayName: 'Alex',
      spaceDisplayName: 'Pin Edit Example',
    );
    await t.createPin(
      spaceId,
      'Edit Pin Example',
      'This pin has Acter Global link',
      'https://acter.global',
    );

    // we expect to be thrown to the pin screen and see our title

    final pinId = await t.editPin(
      'Acter Global website',
      'Check out our website',
      'https://acter.global',
    );

    // lets re-route to this edited pin to see if changes reflected
    await t.gotoPin(pinId);

    await find.text('Acter Global website').should(findsOneWidget);
    await find.text('Check out our website').should(findsOneWidget);
    await find.text('https://acter.global').should(findsOneWidget);
  });
}
