import 'package:flutter/material.dart';

void main() => runApp(const GallamilaanApp());

/// Gallamilaan — end-of-day till reconciliation. Only cash flows feed the gap;
/// UPI/card are kept separate. Mirrors the Go engine.
class GallamilaanApp extends StatelessWidget {
  const GallamilaanApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Gallamilaan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF2F6E6E), useMaterial3: true),
        home: const HomePage(),
      );
}

class Result {
  final double expected, gap;
  final String status;
  const Result(this.expected, this.gap, this.status);
}

/// reconcile mirrors backend/cost.go.
Result reconcile({
  required double opening, required double cashSales,
  required double expenses, required double payouts, required double counted,
}) {
  final expected = opening + cashSales - expenses - payouts;
  final gap = counted - expected;
  final status = gap < -1e-9 ? 'short' : (gap > 1e-9 ? 'over' : 'exact');
  return Result(expected, gap, status);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _open = TextEditingController(text: '2000');
  final _cash = TextEditingController(text: '5000');
  final _upi = TextEditingController(text: '9000');
  final _exp = TextEditingController(text: '300');
  final _pay = TextEditingController(text: '500');
  final _counted = TextEditingController(text: '6100');
  Result? _r;

  double _n(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  void _calc() => setState(() => _r = reconcile(
        opening: _n(_open), cashSales: _n(_cash),
        expenses: _n(_exp), payouts: _n(_pay), counted: _n(_counted),
      ));

  @override
  Widget build(BuildContext context) {
    String m(double v) => '₹${v.toStringAsFixed(2)}';
    final r = _r;
    final color = r == null
        ? null
        : (r.status == 'short' ? Colors.red : (r.status == 'over' ? Colors.orange : Colors.green));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallamilaan · till tally'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _f(_open, 'Opening cash ₹'),
        _f(_cash, 'Cash sales ₹ (cash tender only)'),
        _f(_upi, 'UPI/card sales ₹ (not reconciled)'),
        Row(children: [Expanded(child: _f(_exp, 'Expenses ₹')), const SizedBox(width: 12), Expanded(child: _f(_pay, 'Payouts ₹'))]),
        _f(_counted, 'Counted closing cash ₹'),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _calc, icon: const Icon(Icons.account_balance_wallet), label: const Text('Reconcile')),
        const SizedBox(height: 20),
        if (r != null)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.status.toUpperCase(), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
                Text('Gap ${m(r.gap)}', style: const TextStyle(fontSize: 20)),
                const Divider(),
                Text('Expected cash ${m(r.expected)}'),
                const Text('UPI/card excluded — only cash reconciles.', style: TextStyle(fontSize: 12)),
              ])),
          ),
      ]),
    );
  }

  Widget _f(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          onChanged: (_) => _calc()),
      );
}
