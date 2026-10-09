// Drives the real app on a device against the local Firebase emulators (see seed.mjs).
import 'dart:async';
import 'dart:typed_data';

import 'package:art_platform/firebase_options.dart';
import 'package:art_platform/main.dart' show MyApp;
import 'package:art_platform/models/group.dart';
import 'package:art_platform/screens/upload_screen.dart';
import 'package:art_platform/services/content_filter_service.dart';
import 'package:art_platform/services/firestore_service.dart';
import 'package:art_platform/services/id_set_store.dart';
import 'package:art_platform/services/session_service.dart';
import 'package:art_platform/widgets/board_painter.dart';
import 'package:art_platform/widgets/feed_post_card.dart';
import 'package:art_platform/widgets/post_feed_list.dart';
import 'package:art_platform/widgets/profile_body.dart';
import 'package:art_platform/widgets/whiteboard_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _host = '10.0.2.2';

Future<void> _pumpFor(WidgetTester t, [int ms = 600]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(WidgetTester t, Finder finder, {int seconds = 25}) async {
  for (var i = 0; i < seconds * 5; i++) {
    await t.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  if (const bool.fromEnvironment('PAUSE_ON_FAIL')) {
    debugPrint('WAITING_FOR_SCREENSHOT');
    await Future<void>.delayed(const Duration(seconds: 20));
  }
  final texts = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '')
      .where((x) => x.isNotEmpty)
      .join(' | ');
  throw TestFailure('Timed out waiting for: $finder\nOn screen: $texts');
}

/// Taps visible text. [scroll] scrolls it into view first; only use that on form pages,
/// because it would also scroll the app's horizontal page view.
Future<void> _tapText(WidgetTester t, String text,
    {bool first = false, bool scroll = false, int seconds = 25}) async {
  final f = first ? find.text(text).first : find.text(text);
  await _pumpUntil(t, find.text(text), seconds: seconds);
  if (scroll) await t.ensureVisible(f);
  await t.tap(f);
  await _pumpFor(t, 400);
}

/// Dismisses the floating snack bar so it cannot cover the bottom of the screen.
void _hideSnack(WidgetTester t) {
  final scaffolds = find.byType(Scaffold);
  if (scaffolds.evaluate().isEmpty) return;
  ScaffoldMessenger.of(t.element(scaffolds.last)).hideCurrentSnackBar();
}

/// Scrolls the top-most page's list to its end (so bottom buttons sit above any composer bar).
Future<void> _scrollToEnd(WidgetTester t) async {
  _hideSnack(t);
  final list = find.descendant(of: find.byType(Scaffold).last, matching: find.byType(ListView)).first;
  await t.drag(list, const Offset(0, -2000));
  await _pumpFor(t, 600);
}

Future<void> _signIn(String uid) async {
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInWithEmailAndPassword(email: '$uid@test.com', password: 'password');
}

Future<void> _launch(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(const MyApp());
  await _pumpFor(t, 600);
}

FirebaseFirestore get _db => appFirestore;

Future<Uint8List> _png() => renderBoardPng(
      [
        Stroke(id: 's', userId: 'x', color: 0xFFC9402F, width: 12, points: const [0.1, 0.1, 0.9, 0.8], createdAt: null),
      ],
      width: 300,
      height: 400,
    );

Future<void> _openNav(WidgetTester t, String label) => _tapText(t, label);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
    appFirestore.settings = const Settings(persistenceEnabled: false);
    appFirestore.useFirestoreEmulator(_host, 8085);
    await FirebaseStorage.instance.useStorageEmulator(_host, 9199);
    ContentFilterService.instance.init();
    UserStores.init();
    SessionService.init();
  });

  testWidgets('1 guest can browse everything but is asked to sign in to interact', (t) async {
    await FirebaseAuth.instance.signOut();
    await _launch(t);

    await _pumpUntil(t, find.text('窗邊的靜物'));
    expect(find.text('NSFW 習作'), findsNothing, reason: 'adult posts are hidden by default');
    expect(find.text('AI 試驗圖'), findsNothing, reason: 'AI posts are hidden by default');
    expect(find.byType(FeedPostCard), findsWidgets);

    await _tapText(t, '追蹤', first: true);
    expect(find.text('使用 Google 登入'), findsOneWidget);
    await _tapText(t, '取消');
    expect(find.text('窗邊的靜物'), findsWidgets);

    await _tapText(t, '讚 3');
    expect(find.text('使用 Google 登入'), findsOneWidget);
    await _tapText(t, '取消');

    await _openNav(t, '探索');
    await _tapText(t, '委託');
    await _pumpUntil(t, find.text('徵 VTuber 立繪'));
    expect(find.text('頭像接單中'), findsOneWidget);
    expect(find.text('可疑的高價委託'), findsNothing, reason: 'commissions with 3+ reports are hidden');

    await _tapText(t, '創作者');
    await _pumpUntil(t, find.text('Bob 陳'));
    expect(find.text('Carol 王'), findsWidgets);

    await _tapText(t, '改圖');
    await _pumpUntil(t, find.text('手的比例總是怪怪的'));

    await _openNav(t, '群組');
    expect(find.textContaining('登入後就能加入群組'), findsOneWidget);
  });

  testWidgets('2 hashtag search finds the right posts', (t) async {
    await FirebaseAuth.instance.signOut();
    await _launch(t);
    await _openNav(t, '探索');
    await t.enterText(find.byType(TextField).first, '#鉛筆素描');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntil(t, find.text('窗邊的靜物'));
    expect(find.text('原創角色設定'), findsNothing);
  });

  testWidgets('3 alice: profile is created, follow, following feed, like, comment, bio, level', (t) async {
    await _signIn('alice');
    await _launch(t);
    await _pumpUntil(t, find.text('窗邊的靜物'));

    // The first sign-in creates her public profile.
    for (var i = 0; i < 50; i++) {
      final snap = await _db.doc('profiles/alice').get();
      if (snap.exists) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    final profile = await _db.doc('profiles/alice').get();
    expect(profile.exists, isTrue);
    expect(profile.data()!['displayName'], 'Alice 林');

    // Open Bob's page from the feed and follow him.
    await _tapText(t, 'Bob 陳', first: true);
    await _pumpUntil(t, find.text('作品'));
    expect(find.text('素描與水彩，每天一張'), findsWidgets);
    expect(find.textContaining('Lv.'), findsOneWidget);
    await _tapText(t, '追蹤');
    await _pumpUntil(t, find.text('追蹤中'));
    final follows = await _db.collection('profiles/alice/following').get();
    expect(follows.docs.map((d) => d.id), ['bob']);
    final followers = await _db.collection('profiles/bob/followers').get();
    expect(followers.docs.map((d) => d.id), ['alice']);
    await t.pageBack();
    await _pumpFor(t, 800);

    // Following feed only has Bob's posts.
    await t.fling(find.byType(FeedPostCard).first, const Offset(260, 0), 1500);
    await _pumpFor(t, 1500);
    await _pumpUntil(t, find.text('窗邊的靜物'));
    expect(find.text('原創角色設定'), findsNothing);
    await t.fling(find.byType(FeedPostCard).first, const Offset(-260, 0), 1500);
    await _pumpFor(t, 1000);

    // Like straight from the card; the count and the pill update at once and persist.
    await _tapText(t, '讚 3');
    await _pumpUntil(t, find.text('已讚 4'));
    await _pumpFor(t, 1500);
    expect((await _db.doc('posts/p1').get()).data()!['likesCount'], 4);
    expect((await _db.doc('posts/p1/likes/alice').get()).exists, isTrue);
    expect((await _db.doc('profiles/alice').get()).data()!['likedCount'], 1);

    // Comment on the post.
    await _tapText(t, '窗邊的靜物');
    await _pumpUntil(t, find.text('寫下你的留言…'));
    await t.enterText(find.byType(TextField).last, '整合測試留言');
    await _tapText(t, '送出');
    await _pumpUntil(t, find.text('整合測試留言'));
    expect((await _db.doc('posts/p1').get()).data()!['commentsCount'], 1);
    expect((await _db.doc('profiles/alice').get()).data()!['commentCount'], 1);
    await t.pageBack();
    await _pumpFor(t, 600);

    // Own page: edit the bio, see level and stats.
    await _openNav(t, '個人');
    await _pumpUntil(t, find.text('Alice 林'));
    expect(find.textContaining('Lv.'), findsOneWidget);
    await _tapText(t, '編輯');
    await t.enterText(find.byType(TextField).last, '整合測試簡介');
    await _tapText(t, '儲存');
    await _pumpUntil(t, find.text('整合測試簡介'));
    expect((await _db.doc('profiles/alice').get()).data()!['bio'], '整合測試簡介');
  });

  testWidgets('4 alice: commission lifecycle with report and hide', (t) async {
    await _signIn('alice');
    await _launch(t);
    await _openNav(t, '探索');
    await _tapText(t, '委託');
    await _pumpUntil(t, find.text('發布委託'));
    await _tapText(t, '發布委託');
    await _pumpUntil(t, find.text('標題'));

    await t.enterText(find.widgetWithText(TextField, '標題'), '整合測試委託');
    final contact = find.widgetWithText(TextField, '站外聯絡方式（必填）');
    await t.scrollUntilVisible(contact, 300, scrollable: find.byType(Scrollable).first);
    await t.enterText(contact, 'LINE: alice-test');
    await t.pump();
    final nsfwNo = find.descendant(of: find.byType(SegmentedButton<bool>), matching: find.text('否'));
    await t.scrollUntilVisible(nsfwNo, 300, scrollable: find.byType(Scrollable).first);
    await t.tap(nsfwNo);
    await t.pump();
    final agree = find.byType(CheckboxListTile);
    await t.scrollUntilVisible(agree, 300, scrollable: find.byType(Scrollable).first);
    await t.tap(agree);
    await t.pump();

    // Without the checkbox it would be refused; with everything filled it publishes.
    await t.tap(find.text('發布').first);
    await _pumpUntil(t, find.text('整合測試委託'));
    final created = await _db.collection('commissions').where('title', isEqualTo: '整合測試委託').get();
    expect(created.docs.length, 1);
    expect(created.docs.first.data()['userId'], 'alice');
    expect(created.docs.first.data()['isNsfw'], false);
    expect(created.docs.first.data()['reportCount'], 0);

    // Report someone else's commission twice: the second one is refused.
    await _tapText(t, '徵 VTuber 立繪');
    await _pumpUntil(t, find.text('IG: @seed'));
    expect(find.text('LINE: alice-test'), findsNothing);
    await _scrollToEnd(t);
    await _tapText(t, '檢舉這則委託');
    await _tapText(t, '詐騙或可疑');
    await _pumpUntil(t, find.text('已收到檢舉，謝謝你'));
    expect((await _db.doc('commissions/m1').get()).data()!['reportCount'], 1);
    _hideSnack(t);
    await _pumpFor(t, 800);
    await _tapText(t, '檢舉這則委託');
    await _tapText(t, '詐騙或可疑');
    await _pumpUntil(t, find.textContaining('送出失敗'));
    expect((await _db.doc('commissions/m1').get()).data()!['reportCount'], 1);

    // Closing and deleting your own commission.
    await t.pageBack();
    await _pumpFor(t, 600);
    await _tapText(t, '整合測試委託');
    await _pumpUntil(t, find.text('LINE: alice-test'));
    await _scrollToEnd(t);
    await _tapText(t, '標示為已結案');
    await _pumpUntil(t, find.text('重新開放'));
    expect((await _db.doc('commissions/${created.docs.first.id}').get()).data()!['status'], 'closed');
    await _scrollToEnd(t);
    await _tapText(t, '刪除委託');
    await _tapText(t, '刪除');
    await _pumpFor(t, 1200);
    expect((await _db.doc('commissions/${created.docs.first.id}').get()).exists, isFalse);
  });

  testWidgets('5 alice: stack a floor on a consult', (t) async {
    await _signIn('alice');
    await _launch(t);
    await _openNav(t, '探索');
    await _tapText(t, '改圖');
    await _tapText(t, '手的比例總是怪怪的');
    await _pumpUntil(t, find.text('回覆 1'));
    expect(find.text('手掌長度大約等於中指長度，可以先用方塊概括。'), findsOneWidget);

    await t.enterText(find.byType(TextField).last, '蓋樓測試內容');
    await _tapText(t, '蓋樓', first: true);
    await _pumpUntil(t, find.text('蓋樓測試內容'));
    expect(find.text('2 樓'), findsOneWidget);
    final c = await _db.doc('consults/k1').get();
    expect(c.data()!['floorsCount'], 2);
    final floor = await _db.doc('consults/k1/floors/f2').get();
    expect(floor.data()!['floor'], 2);
    expect(floor.data()!['userId'], 'alice');

    // She can remove her own floor but the number stays.
    await _scrollToEnd(t);
    await _tapText(t, '刪除', first: true);
    await _tapText(t, '確定');
    await _pumpUntil(t, find.text('此樓已刪除'));
    expect((await _db.doc('consults/k1/floors/f2').get()).data()!['deleted'], true);
  });

  testWidgets('6 alice: join a group, chat, draw, undo', (t) async {
    await _signIn('alice');
    await _launch(t);
    await _openNav(t, '群組');
    await _pumpUntil(t, find.text('我的群組'));
    expect(find.text('速寫小聚'), findsNothing);
    await _tapText(t, '探索群組');
    await _pumpUntil(t, find.text('速寫小聚'));
    await _tapText(t, '加入');
    await _pumpUntil(t, find.text('聊天'));
    expect((await _db.doc('groups/g1').get()).data()!['memberIds'], containsAll(['bob', 'carol', 'alice']));

    await _pumpUntil(t, find.text('歡迎新朋友'));
    await t.enterText(find.byType(TextField).last, '大家好，我是新成員');
    await _tapText(t, '送出');
    await _pumpUntil(t, find.text('大家好，我是新成員'));
    expect((await _db.doc('groups/g1').get()).data()!['lastMessage'], '大家好，我是新成員');

    await _tapText(t, '白板');
    await _pumpUntil(t, find.byType(WhiteboardView));
    expect(find.text('清空'), findsNothing, reason: 'only the owner can clear');
    expect(find.text('鎖定白板'), findsNothing);
    final before = (await _db.collection('groups/g1/strokes').get()).docs.length;
    await t.drag(find.byType(WhiteboardView), const Offset(120, 140));
    await _pumpFor(t, 1500);
    final after = await _db.collection('groups/g1/strokes').get();
    expect(after.docs.length, before + 1);
    final mine = after.docs.firstWhere((d) => d.data()['userId'] == 'alice');
    expect((mine.data()['points'] as List).length, greaterThanOrEqualTo(4));

    await _tapText(t, '復原');
    await _pumpFor(t, 1500);
    expect((await _db.collection('groups/g1/strokes').get()).docs.length, before);

    await _tapText(t, '成員');
    await _pumpUntil(t, find.text('房主'));
    expect(find.text('移出'), findsNothing, reason: 'members cannot remove others');
    await _tapText(t, '退出群組');
    await _tapText(t, '確定');
    await _pumpFor(t, 1500);
    expect((await _db.doc('groups/g1').get()).data()!['memberIds'], isNot(contains('alice')));
  });

  testWidgets('7 bob: owner controls on the whiteboard and publishing it', (t) async {
    await _signIn('bob');
    await _launch(t);
    await _openNav(t, '群組');
    await _pumpUntil(t, find.text('速寫小聚'));
    await _tapText(t, '速寫小聚');
    await _tapText(t, '白板');
    await _pumpUntil(t, find.text('鎖定白板'));
    await _tapText(t, '鎖定白板');
    await _pumpUntil(t, find.text('解除鎖定'));
    expect((await _db.doc('groups/g1').get()).data()!['locked'], true);
    await _tapText(t, '解除鎖定');
    await _pumpUntil(t, find.text('鎖定白板'));

    // Publish the board as a post: the publish screen opens pre-filled.
    await _tapText(t, '發布為作品');
    await _pumpUntil(t, find.text('速寫小聚 共同創作'));
    expect(find.text('#共同創作'), findsOneWidget);
    await _tapText(t, '數位繪圖', scroll: true);
    final no = find.descendant(of: find.byType(SegmentedButton<bool>), matching: find.text('否'));
    await t.scrollUntilVisible(no.last, 300, scrollable: find.byType(Scrollable).first);
    await t.tap(no.first);
    await t.tap(no.last);
    await t.pump();
    await t.tap(find.text('發布').first);
    await _pumpFor(t, 6000);
    final posts = await _db.collection('posts').where('title', isEqualTo: '速寫小聚 共同創作').get();
    expect(posts.docs.length, 1);
    final data = posts.docs.first.data();
    expect(data['userId'], 'bob');
    expect(data['isNsfw'], false);
    expect(data['isAiGenerated'], false);
    expect(data['tags'], contains('共同創作'));
    expect((data['imageUrls'] as List).length, 1);
    expect((await _db.doc('profiles/bob').get()).data()!['postCount'], 5);

    // Clear the board.
    await _pumpUntil(t, find.text('清空'));
    await _tapText(t, '清空');
    await _tapText(t, '確定');
    await _pumpFor(t, 1500);
    expect((await _db.collection('groups/g1/strokes').get()).docs, isEmpty);
  });

  testWidgets('8 alice: publish with labels, edit, delete', (t) async {
    await _signIn('alice');
    await _launch(t);

    final bytes = await _png();
    unawaited(t.state<NavigatorState>(find.byType(Navigator).first).push(MaterialPageRoute<bool>(
      builder: (_) => UploadScreen(seed: UploadSeed(
        imageName: 'test.png',
        imageBytes: bytes,
        title: '整合測試作品',
        tags: const ['整合測試'],
      )),
    )));
    await _pumpFor(t, 800);

    // Labels are mandatory: publishing without answering is refused.
    await _tapText(t, '傳統手繪', scroll: true);
    await t.tap(find.text('發布').first);
    await _pumpFor(t, 800);
    _hideSnack(t);
    await t.scrollUntilVisible(find.text('兩項都需要回答才能發布'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('兩項都需要回答才能發布'), findsOneWidget);
    expect((await _db.collection('posts').where('title', isEqualTo: '整合測試作品').get()).docs, isEmpty);

    final no = find.descendant(of: find.byType(SegmentedButton<bool>), matching: find.text('否'));
    final yes = find.descendant(of: find.byType(SegmentedButton<bool>), matching: find.text('是'));
    _hideSnack(t);
    await t.scrollUntilVisible(yes.last, 300, scrollable: find.byType(Scrollable).first);
    await _pumpFor(t, 600);
    await t.tap(no.first);
    await t.tap(yes.last);
    await t.pump();
    await t.tap(find.text('發布').first);
    for (var i = 0; i < 60; i++) {
      final q = await _db.collection('posts').where('title', isEqualTo: '整合測試作品').get();
      if (q.docs.isNotEmpty) break;
      await _pumpFor(t, 300);
    }
    final q = await _db.collection('posts').where('title', isEqualTo: '整合測試作品').get();
    expect(q.docs.length, 1);
    final post = q.docs.first;
    expect(post.data()['isNsfw'], false);
    expect(post.data()['isAiGenerated'], true);
    expect(post.data()['tags'], ['整合測試']);
    expect(post.data()['category'], '傳統手繪');
    expect((await _db.doc('profiles/alice').get()).data()!['postCount'], 1);
    final url = (post.data()['imageUrls'] as List).first as String;
    final ref = FirebaseStorage.instance.refFromURL(url);
    expect((await ref.getMetadata()).contentType, 'image/png');

    // AI content is hidden from others by default but alice always sees her own.
    await _launch(t);
    await _pumpUntil(t, find.text('窗邊的靜物'));
    expect(find.text('AI 試驗圖'), findsNothing);
    await _openNav(t, '個人');
    await _pumpUntil(t, find.text('Alice 林'));
    await t.scrollUntilVisible(
      find.text('整合測試作品'),
      300,
      scrollable: find.descendant(of: find.byType(ProfileBody), matching: find.byType(Scrollable)).first,
    );

    await _tapText(t, '整合測試作品');
    await _pumpUntil(t, find.text('更多'));
    await _tapText(t, '更多');
    await _tapText(t, '編輯作品');
    await _pumpUntil(t, find.text('儲存'));
    await t.enterText(find.widgetWithText(TextField, '標題'), '整合測試作品（已編輯）');
    await _tapText(t, '儲存');
    await _pumpUntil(t, find.text('整合測試作品（已編輯）'));
    expect((await _db.doc('posts/${post.id}').get()).data()!['title'], '整合測試作品（已編輯）');

    await _tapText(t, '更多');
    await _tapText(t, '刪除作品');
    await _tapText(t, '刪除');
    await _pumpFor(t, 2500);
    expect((await _db.doc('posts/${post.id}').get()).exists, isFalse);
    expect((await _db.doc('profiles/alice').get()).data()!['postCount'], 0);
  });

  testWidgets('9 content filter: turning AI on reveals AI posts and persists', (t) async {
    await _signIn('alice');
    await _launch(t);
    await _pumpUntil(t, find.text('窗邊的靜物'));
    expect(find.text('AI 試驗圖'), findsNothing);

    await _openNav(t, '個人');
    await _tapText(t, '設定');
    await _pumpUntil(t, find.text('顯示 AI 生成內容'));
    await _tapText(t, '顯示 AI 生成內容');
    await _pumpFor(t, 1500);
    expect((await _db.doc('users/alice').get()).data()!['showAi'], true);
    await t.pageBack();
    await _openNav(t, '主頁');
    await t.scrollUntilVisible(
      find.text('AI 試驗圖'),
      400,
      scrollable: find.descendant(of: find.byType(PostFeedList), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('NSFW 習作'), findsNothing);
  });
}
