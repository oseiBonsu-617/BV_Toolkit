import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bv_toolkit/theme.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('appRoute is a CupertinoPageRoute on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(appRoute<void>(const SizedBox()), isA<CupertinoPageRoute<void>>());
  });

  test('appRoute keeps the slide+fade route on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final route = appRoute<void>(const SizedBox());
    expect(route, isNot(isA<CupertinoPageRoute<void>>()));
    expect(route, isA<PageRouteBuilder<void>>());
  });
}
