import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigya_native_screensets_engine/models/main.dart';
import 'package:gigya_native_screensets_engine/models/spark.dart';
import 'package:gigya_native_screensets_engine/nss_ignition.dart';
import 'package:gigya_native_screensets_engine/nss_registry.dart';
import 'package:gigya_native_screensets_engine/utils/assets.dart';
import 'package:mockito/mockito.dart';

class MockWorker extends Mock implements IgnitionWorker {}

void main() {
  group('IgnitionWorker tests', () {
    var worker = IgnitionWorker();

    test('IgnitionWorker with using mock from assets file', () async {
      registry.isMock = true;

      var spark = await worker.spark();

      expect(spark.platformAware, false);
      expect(spark.markup.screens['register'].id, 'register');
    });

    test('IgnitionWorker with mocking method channel response', () async {
      registry.isMock = false;

      registry.channels.mainChannel.setMockMethodCallHandler((call) {
        print(call.method);
        return Future<Map<dynamic, dynamic>>.value({
          'platformAware': true,
          'markup': {
            'initialRoute': 'login',
            'screens': {
              'login': {
                'id': 'login',
                'appbar': {'textKey': 'login'}
              }
            }
          }
        });
      });

      var spark = await worker.spark();
      expect(spark.platformAware, true);
      expect(spark.markup.initialRoute, 'login');
      expect(spark.markup.screens['login'].id, 'login');
    });
  });

  group('NssIgnitionWidget tests', () {
    // Mock the ignition worker.
    var worker = MockWorker();

    testWidgets('Testing engine initialization with "useMockData" true & mocked worker Json asset',
        (WidgetTester tester) async {
      var mockMarkup = await AssetUtils.jsonMapFromAssets('assets/mock_1.json');
      when(worker.spark()).thenAnswer((_) => Future<Spark>(() {
            return Spark.fromJson(mockMarkup);
          }));

      await tester.pumpWidget(
        NssIgnitionWidget(
          layoutScreenSet: (Main main, String initialRoute) {
            return Container(
              child: Center(
                child: Column(
                  children: <Widget>[
                    Text(main.screens['login'].id),
                    Text(main.screens['register'].id),
                  ],
                ),
              ),
            );
          },
          worker: worker,
          useMockData: true,
        ),
      );

      // Making sure the EngineInitializationWidget FutureBuilder has snapped.
      await tester.pump(Duration(seconds: 2), EnginePhase.build);

      final id1TextFinder = find.text('login');
      final id2TextFinder = find.text('register');

      expect(id1TextFinder, findsOneWidget);
      expect(id2TextFinder, findsOneWidget);
    });

    testWidgets('Testing engine initialization with "useMockData" false & mocked worker response',
        (WidgetTester tester) async {
      final mockResponse = {
        'platformAware': false,
        'markup': {
          'initialRoute': 'register',
          'screens': {
            'register': {
              'id': 'register',
              'appbar': {'textKey': 'register'}
            }
          }
        }
      };

      when(worker.spark()).thenAnswer((_) => Future<Spark>(() {
            return Spark.fromJson(mockResponse);
          }));

      await tester.pumpWidget(NssIgnitionWidget(
        layoutScreenSet: (Main main, String initialRoute) {
          return Container(
            child: Text(main.screens[initialRoute].id),
          );
        },
        worker: worker,
      ));

      // Making sure the EngineInitializationWidget FutureBuilder has snapped.
      await tester.pump(Duration(seconds: 2), EnginePhase.build);

      final textFinder = find.text('register');

      expect(textFinder, findsOneWidget);
    });

    testWidgets('Testing engine initialization with "useMockData" false & mocked worker response without initial route',
        (WidgetTester tester) async {
      final mockResponse = {
        'platformAware': false,
        'markup': {
          'screens': {
            'login': {
              'id': 'login',
              'appbar': {'textKey': 'login'}
            },
            'register': {
              'id': 'register',
              'appbar': {'textKey': 'register'}
            }
          }
        }
      };

      when(worker.spark()).thenAnswer((_) => Future<Spark>(() {
            return Spark.fromJson(mockResponse);
          }));

      await tester.pumpWidget(NssIgnitionWidget(
        layoutScreenSet: (Main main, String initialRoute) {
          return Container(
            child: Text(main.screens[initialRoute].id),
          );
        },
        worker: worker,
      ));

      // Making sure the EngineInitializationWidget FutureBuilder has snapped.
      await tester.pump(Duration(seconds: 2), EnginePhase.build);

      final textFinder = find.text('login');

      expect(textFinder, findsOneWidget);
    });
  });
}
