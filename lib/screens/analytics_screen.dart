import 'package:flutter/material.dart';
import '../theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Analytics & Reports'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Period Selector
          Row(children: [
            const Text('Overview for:', style: S.body),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: C.surface, border: Border.all(color: C.border)),
              child: const Row(children: [
                Text('Last 30 Days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ]),
            ),
          ]),
          const SizedBox(height: 20),

          // Total Revenue
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [C.orange, C.orangeLight]),
              boxShadow: [BoxShadow(color: C.orange.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Revenue', style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 6),
              const Text('₹1,45,250', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.white.withValues(alpha: 0.2)),
                  child: const Row(children: [
                    Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('+15.4%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text('vs previous 30 days', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // KPI Grid
          Row(children: [
            Expanded(child: _kpiCard('Orders Completed', '142', '+12', C.blue, true)),
            const SizedBox(width: 12),
            Expanded(child: _kpiCard('Return Rate', '1.2%', '-0.5%', C.green, true)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _kpiCard('Average Order Value', '₹1,020', '+₹40', C.yellow, true)),
            const SizedBox(width: 12),
            Expanded(child: _kpiCard('Cancellation Rate', '4.5%', '+1.2%', C.red, false)),
          ]),
          const SizedBox(height: 24),

          // Top Products
          const SectionHeader(title: 'Top Performing Products'),
          _topProduct('Cotton T-Shirt Pack', 54, 18500),
          _topProduct('Basmati Rice 5kg', 42, 12600),
          _topProduct('Natural Soap Pack', 31, 3720),
          
          const SizedBox(height: 24),
          const SectionHeader(title: 'Customer Demographics'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _pieSegment('B2C (Groups)', 65, C.orange),
              Container(width: 1, height: 40, color: C.border),
              _pieSegment('B2C (Singles)', 15, C.yellow),
              Container(width: 1, height: 40, color: C.border),
              _pieSegment('B2B (Bulk)', 20, C.blue),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, String diff, Color color, bool positive) {
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: S.caption),
      const SizedBox(height: 8),
      Text(value, style: S.h2.copyWith(fontSize: 22)),
      const SizedBox(height: 8),
      Row(children: [
        Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: color, size: 14),
        const SizedBox(width: 4),
        Text(diff, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    ]));
  }

  Widget _topProduct(String name, int orders, int revenue) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: C.surfaceAlt, border: Border.all(color: C.border)),
          child: Center(child: Text('${orders}x', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.textSec))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: S.body.copyWith(fontWeight: FontWeight.w600)),
          Text('Revenue: ₹$revenue', style: S.caption),
        ])),
      ]),
    );
  }

  Widget _pieSegment(String label, int pct, Color color) {
    return Column(children: [
      Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text('$pct%', style: S.h3),
      ]),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: C.textTer)),
    ]);
  }
}
