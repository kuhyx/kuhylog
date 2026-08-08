import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/platform/quick_capture.dart';
import 'package:kuhylog/src/state/app_state.dart';
import 'package:kuhylog/src/store/memory_store.dart';

import '../ui/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.kuhy.kuhylog/quick_capture.test');
  late AppState state;
  late QuickCapture bridge;
  late List<MethodCall> outgoing;

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Pretends to be Android calling into Dart.
  ///
  /// A `null` result means "not implemented": Flutter turns a
  /// [MissingPluginException] thrown by a handler, and the absence of a
  /// handler entirely, into an empty reply rather than an error
  /// envelope.
  Future<Object?> callFromPlatform(String method, [Object? arguments]) async {
    Object? decoded;
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (reply) {
        if (reply != null) {
          decoded = const StandardMethodCodec().decodeEnvelope(reply);
        }
      },
    );
    return decoded;
  }

  setUp(() {
    state = AppState(MemoryStore(), now: () => testNow)
      ..saveTracker(
        const Tracker(tag: 'coffee', label: 'Coffee', positivity: -1),
      )
      ..saveTracker(const Tracker(tag: 'gym', label: 'Gym', positivity: 5));
    bridge = QuickCapture(state, channel: channel);
    outgoing = <MethodCall>[];
  });

  tearDown(() {
    bridge.detach();
    messenger.setMockMethodCallHandler(channel, null);
  });

  void mockPlatform() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      outgoing.add(call);
      return null;
    });
  }

  group('QuickCapture summary', () {
    test('reports the score, the count and the top trackers', () {
      state.recordTracker(state.trackers.first);
      final summary = bridge.summary();
      expect(summary['score'], -1);
      expect(summary['entries'], 1);
      final trackers = summary['trackers']! as List<Map<String, Object?>>;
      expect(trackers, hasLength(2));
      expect(trackers.first['tag'], 'coffee');
      expect(trackers.first['display'], '1');
      expect(trackers.first['glyph'], 'C');
      expect(trackers.last['value'], 0.0);
      expect(trackers.last['display'], '0');
    });

    test('caps the tracker list', () {
      for (var i = 0; i < 10; i++) {
        state.saveTracker(Tracker(tag: 't$i', label: 'T$i'));
      }
      final trackers =
          bridge.summary()['trackers']! as List<Map<String, Object?>>;
      expect(trackers, hasLength(QuickCapture.summarySize));
    });
  });

  group('QuickCapture platform to Dart', () {
    setUp(() => bridge.attach());

    test('logTracker records and answers with the new summary', () async {
      final reply =
          await callFromPlatform('logTracker', <String, Object?>{
                'tag': 'gym',
              })
              as Map<Object?, Object?>?;
      expect(state.store.allEntries.single.note, '#gym(1.0)');
      expect(reply!['score'], 5);
    });

    test('logTracker honours an explicit value', () async {
      await callFromPlatform('logTracker', <String, Object?>{
        'tag': 'coffee',
        'value': 3,
      });
      expect(state.store.allEntries.single.note, '#coffee(3.0)');
    });

    test('logTracker accepts a bare string tag', () async {
      await callFromPlatform('logTracker', 'gym');
      expect(state.store.allEntries.single.note, '#gym(1.0)');
    });

    test('logTracker rejects an unknown tag', () async {
      await expectLater(
        callFromPlatform('logTracker', 'ghost'),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'unknown-tracker',
          ),
        ),
      );
      expect(state.store.allEntries, isEmpty);
    });

    test('logTracker rejects arguments of the wrong shape', () async {
      await expectLater(
        callFromPlatform('logTracker', 42),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'bad-arguments',
          ),
        ),
      );
      await expectLater(
        callFromPlatform('logTracker', <String, Object?>{'tag': 7}),
        throwsA(isA<PlatformException>()),
      );
    });

    test('logNote records free text', () async {
      final reply =
          await callFromPlatform('logNote', <String, Object?>{
                'note': 'walked #gym',
              })
              as Map<Object?, Object?>?;
      expect(state.store.allEntries.single.note, 'walked #gym');
      expect(reply!['entries'], 1);
    });

    test('logNote rejects an empty note', () async {
      await expectLater(
        callFromPlatform('logNote', '   '),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'empty-note'),
        ),
      );
    });

    test('summary answers without recording anything', () async {
      final reply = await callFromPlatform('summary') as Map<Object?, Object?>?;
      expect(reply!['entries'], 0);
      expect(state.store.allEntries, isEmpty);
    });

    test('an unknown method reports itself as not implemented', () async {
      expect(await callFromPlatform('teleport'), isNull);
      expect(
        () => bridge.handle(const MethodCall('teleport')),
        throwsA(isA<MissingPluginException>()),
      );
    });
  });

  group('QuickCapture Dart to platform', () {
    test('publish sends the summary', () async {
      mockPlatform();
      await bridge.publish();
      expect(outgoing.single.method, 'render');
      final arguments = outgoing.single.arguments as Map<Object?, Object?>;
      expect(arguments['score'], 0);
    });

    test('publish tolerates no implementation on the other side', () async {
      await expectLater(bridge.publish(), completes);
    });

    test('attaching republishes on every change', () async {
      mockPlatform();
      bridge.attach();
      state.recordTracker(state.trackers.last);
      await Future<void>.delayed(Duration.zero);
      expect(outgoing, hasLength(1));
      expect(
        (outgoing.single.arguments as Map<Object?, Object?>)['score'],
        5,
      );
    });

    test('detaching stops publishing and answering', () async {
      mockPlatform();
      bridge
        ..attach()
        ..detach();
      state.recordTracker(state.trackers.last);
      await Future<void>.delayed(Duration.zero);
      expect(outgoing, isEmpty);
      expect(await callFromPlatform('summary'), isNull);
    });
  });
}
