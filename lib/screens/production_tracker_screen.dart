import 'package:flutter/material.dart';
import '../theme.dart';

class ProductionTrackerScreen extends StatefulWidget {
  const ProductionTrackerScreen({super.key});
  @override
  State<ProductionTrackerScreen> createState() => _ProductionTrackerScreenState();
}

class _ProductionTrackerScreenState extends State<ProductionTrackerScreen> {
  final _batches = [
    {'id': 'B-001', 'product': 'Cotton T-Shirt Pack', 'qty': 50, 'done': 32, 'status': 'In Progress', 'color': C.yellow, 'start': 'Mar 1', 'due': 'Mar 4'},
    {'id': 'B-002', 'product': 'Natural Soap Pack', 'qty': 25, 'done': 25, 'status': 'QC Pending', 'color': C.blue, 'start': 'Feb 28', 'due': 'Mar 3'},
    {'id': 'B-003', 'product': 'Handloom Bedsheet', 'qty': 15, 'done': 8, 'status': 'In Progress', 'color': C.yellow, 'start': 'Mar 2', 'due': 'Mar 6'},
    {'id': 'B-004', 'product': 'Basmati Rice 5kg', 'qty': 30, 'done': 30, 'status': 'Completed', 'color': C.green, 'start': 'Feb 25', 'due': 'Mar 1'},
  ];

  @override
  Widget build(BuildContext context) {
    final inProgress = _batches.where((b) => b['status'] == 'In Progress').length;
    final completed = _batches.where((b) => b['status'] == 'Completed' || b['status'] == 'QC Pending').length;
    final totalQty = _batches.fold<int>(0, (s, b) => s + (b['qty'] as int));
    final doneQty = _batches.fold<int>(0, (s, b) => s + (b['done'] as int));

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Production Tracker'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(icon: const Icon(Icons.add_circle_rounded, color: C.orange), onPressed: () {}),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Overview card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [C.orange, C.orangeLight]),
            ),
            child: Column(children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Production Overview', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text('$doneQty / $totalQty units', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                ])),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                  child: Center(child: Text('${(doneQty / totalQty * 100).round()}%',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: doneQty / totalQty,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _miniStat('Active', '$inProgress', Colors.white),
                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.3)),
                _miniStat('Done', '$completed', Colors.white),
                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.3)),
                _miniStat('Batches', '${_batches.length}', Colors.white),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          const SectionHeader(title: 'Active Batches'),
          ..._batches.map((b) => _batchCard(b)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
    ]);
  }

  Widget _batchCard(Map<String, dynamic> b) {
    final progress = (b['done'] as int) / (b['qty'] as int);
    final isDone = progress >= 1.0;
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: (b['color'] as Color).withValues(alpha: 0.1)),
          child: Icon(isDone ? Icons.check_circle_rounded : Icons.precision_manufacturing_rounded,
            color: b['color'] as Color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b['product'] as String, style: S.h4.copyWith(fontSize: 14)),
          Text('Batch ${b['id']} · ${b['start']} → ${b['due']}', style: S.caption),
        ])),
        StatusChip(label: b['status'] as String, color: b['color'] as Color),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: C.border,
            valueColor: AlwaysStoppedAnimation(isDone ? C.green : C.orange),
            minHeight: 6,
          ),
        )),
        const SizedBox(width: 12),
        Text('${b['done']} / ${b['qty']}', style: S.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ]),
      if (!isDone) ...[
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppBtn(text: 'Update Progress', onTap: () {
            setState(() {
              final done = (b['done'] as int) + 5;
              b['done'] = done.clamp(0, b['qty'] as int);
              if (done >= (b['qty'] as int)) { b['status'] = 'Completed'; b['color'] = C.green; }
            });
          }, color: C.orange)),
        ]),
      ],
    ]));
  }
}
