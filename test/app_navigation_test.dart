import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/app/app.dart';

void main() {
  testWidgets('splash → intro → welcome on a small phone', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(720, 1280); // 360×640 @2x
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SellerApp()));
    expect(find.text('লোড হচ্ছে…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('এড়িয়ে যান'), findsOneWidget);

    await tester.tap(find.text('এড়িয়ে যান'));
    await tester.pumpAndSettle();
    expect(find.text('স্ট্রিট সেলসে স্বাগতম'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
