import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monekin/core/presentation/widgets/income_mask.dart';
import 'package:monekin/core/services/income_privacy_service.dart';

void main() {
  testWidgets('IncomeMask blurs until tapped', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    IncomePrivacyService.instance.hide();

    await tester.pumpWidget(
      const MaterialApp(home: IncomeMask(child: Text('1234'))),
    );
    expect(find.byType(ImageFiltered), findsOneWidget);

    await tester.tap(find.text('1234'), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(ImageFiltered), findsNothing);

    IncomePrivacyService.instance.hide();
    await tester.pump();
    await tester.pump();
    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('IncomeMask disabled leaves child untouched', (tester) async {
    IncomePrivacyService.instance.hide();

    await tester.pumpWidget(
      const MaterialApp(
        home: IncomeMask(enabled: false, child: Text('99')),
      ),
    );
    expect(find.byType(ImageFiltered), findsNothing);
  });
}
