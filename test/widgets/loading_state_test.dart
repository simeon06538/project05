import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'package:campus_delivery/widgets/status_views.dart';

void main() {
  testWidgets('loading state shows the Lottie dots and its label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LoadingState(label: 'Loading requests…')),
      ),
    );

    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Loading requests…'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  test('loading animation is a valid looping Lottie file', () {
    final json = jsonDecode(
      File('assets/lottie/loading.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(json['fr'], 30);
    expect(json['op'], greaterThan(json['ip'] as int));
    expect(json['layers'] as List, hasLength(3));
  });

  test('loading animation is registered as an app asset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('assets/lottie/'));
  });
}
