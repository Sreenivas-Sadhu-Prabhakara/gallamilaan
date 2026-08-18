import 'package:flutter_test/flutter_test.dart';

import 'package:gallamilaan_app/main.dart';

void main() {
  test('reconcile: cash-only expected and short gap', () {
    final r = reconcile(opening: 2000, cashSales: 5000, expenses: 300, payouts: 500, counted: 6100);
    expect(r.expected, closeTo(6200, 1e-6));
    expect(r.status, 'short');
  });

  testWidgets('renders reconcile button', (tester) async {
    await tester.pumpWidget(const GallamilaanApp());
    expect(find.text('Reconcile'), findsOneWidget);
  });
}
