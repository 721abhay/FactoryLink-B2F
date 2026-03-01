import 'package:flutter/material.dart';
import '../theme.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'title': 'Order Placed', 'sub': 'Mar 1, 2026 · 10:30 AM', 'done': true},
      {'title': 'Factory Accepted', 'sub': 'Mar 1, 2026 · 11:00 AM', 'done': true},
      {'title': 'In Production', 'sub': 'Started Mar 2, 2026', 'done': true},
      {'title': 'Quality Check', 'sub': 'Pending', 'done': false},
      {'title': 'Out for Dispatch', 'sub': 'Expected Mar 4', 'done': false},
      {'title': 'At Anchor Point', 'sub': 'Expected Mar 5', 'done': false},
      {'title': 'Collected', 'sub': 'Scan QR to complete', 'done': false},
    ];
    final currentStep = steps.indexWhere((s) => !(s['done'] as bool));

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Track Order'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Order Info
          AppCard(child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: C.surfaceAlt),
              child: const Icon(Icons.inventory_2_rounded, color: C.textSec, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['name'] as String, style: S.h3),
                const SizedBox(height: 4),
                Text('Order #FL-2026-0342', style: S.caption),
                Text('Qty: ${order['qty']}', style: S.bodySmall),
              ],
            )),
            StatusChip(label: order['status'] as String, color: order['color'] as Color),
          ])),
          const SizedBox(height: 8),

          // Estimated delivery
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [C.blue, C.blueLight]),
            ),
            child: Row(children: [
              const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimated Delivery', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  const Text('March 5, 2026', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white.withValues(alpha: 0.2)),
                child: const Text('3 days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Timeline
          const Text('Order Timeline', style: S.h3),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final s = steps[i];
            final done = s['done'] as bool;
            final current = i == currentStep;
            final isLast = i == steps.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  SizedBox(
                    width: 36,
                    child: Column(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? C.blue : current ? C.blueSurface : C.surfaceAlt,
                          border: Border.all(color: done ? C.blue : current ? C.blue : C.border, width: current ? 2 : 1),
                        ),
                        child: done
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                            : current
                                ? Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: C.blue))
                                : null,
                      ),
                      if (!isLast) Expanded(child: Container(
                        width: 2, margin: const EdgeInsets.symmetric(vertical: 4),
                        color: done ? C.blue : C.border,
                      )),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'] as String, style: S.h4.copyWith(
                          fontSize: 14,
                          color: done || current ? C.text : C.textTer,
                        )),
                        const SizedBox(height: 2),
                        Text(s['sub'] as String, style: S.caption),
                      ],
                    ),
                  )),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // Factory contact
          AppCard(child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.blueSurface),
              child: const Icon(Icons.factory_rounded, color: C.blue, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tirupur Textiles', style: S.h4),
                Text('Verified Factory · 4.3★', style: S.caption),
              ],
            )),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.greenLight),
              child: const Icon(Icons.chat_rounded, color: C.green, size: 20),
            ),
          ])),
        ],
      ),
    );
  }
}
