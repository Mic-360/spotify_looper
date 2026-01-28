// Basic Flutter widget test for Spotify Looper.
//
// This test verifies that the app builds successfully.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_looper/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SpotifyLooperApp()));

    // Verify that the app built without errors.
    expect(find.byType(SpotifyLooperApp), findsOneWidget);
  });
}
