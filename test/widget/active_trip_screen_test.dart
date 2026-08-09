import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gts_foundingteams/app/gts_app.dart';
import 'package:gts_foundingteams/core/utils/formatters.dart';
import 'package:gts_foundingteams/features/trip/application/trip_providers.dart';
import 'package:gts_foundingteams/features/trip/data/mock_trip_data.dart';

/// Smoke tests for the main flow.
///
/// `pumpAndSettle` is deliberately avoided: the live indicator and the marker
/// halo animate forever by design, so settling would time out. Explicit
/// `pump(duration)` calls advance exactly as far as each assertion needs.
void main() {
  /// A realistic phone viewport. The default 800x600 test surface is shorter
  /// than any device this ships to, which pushes the driver card out of the
  /// lazily-built part of the list.
  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: GtsApp()));
    await tester.pump();
  }

  Future<void> disposeApp(WidgetTester tester) async {
    // Unmounting the ProviderScope disposes the controllers, which cancels the
    // simulation timer and keeps the test from failing on a pending timer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  final routeLengthLabel = Formatters.distance(MockTripData.route.totalMeters);

  testWidgets('shows the child, the school and the live journey', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text(MockTripData.child.name), findsOneWidget);
    expect(find.textContaining(MockTripData.school.name), findsWidgets);
    expect(find.text(MockTripData.dropOff.name), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    // The journey opens at the school gate, before the vehicle has pulled away.
    expect(find.text('Picked up'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('shows the driver, their rating and the vehicle', (tester) async {
    await pumpApp(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pump();

    expect(find.text(MockTripData.driver.name), findsOneWidget);
    expect(find.text(MockTripData.driver.ratingLabel), findsOneWidget);
    expect(find.text(MockTripData.driver.vehiclePlate), findsOneWidget);
    expect(find.text('Call driver'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('the journey advances and the distance covered increases', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('0 m of $routeLengthLabel covered'), findsOneWidget);

    // Twelve ticks of the simulator at 250 ms each.
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('0 m of $routeLengthLabel covered'), findsNothing);
    expect(find.textContaining('of $routeLengthLabel covered'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('an overspeeding alert reaches the parent as a banner', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Driver is going too fast'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    // Reach for the controller the same way the demo menu does.
    container.read(tripControllerProvider.notifier).simulateOverspeeding();

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Driver is going too fast'), findsOneWidget);
    expect(find.textContaining('where the limit is 50 km/h'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('SOS requires a deliberate hold and then reports success', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('SOS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Raise an emergency SOS?'), findsOneWidget);
    expect(find.text('Hold to raise SOS'), findsOneWidget);

    // A plain tap must not dispatch anything: the press starts the timer and
    // the immediate release rewinds it.
    await tester.tap(find.text('Hold to raise SOS'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Raise an emergency SOS?'), findsOneWidget);

    // A sustained press does. The first pump lets the tap recogniser clear its
    // press deadline so `onTapDown` fires; the second advances the animation
    // past its 900 ms completion point.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold to raise SOS')),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 1000));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Raising SOS…'), findsOneWidget);

    // Each channel acknowledges in turn until the alert is fully raised.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('SOS alert raised'), findsOneWidget);
    expect(find.textContaining('SOS-'), findsOneWidget);
    expect(find.text('Call GTS safety line'), findsOneWidget);

    await disposeApp(tester);
  });
}
