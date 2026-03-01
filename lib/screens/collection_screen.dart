import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with SingleTickerProviderStateMixin {
  bool _scanned = false;
  bool _verified = false;
  late AnimationController _scanCtrl;

  final _readyOrders = [
    {'id': 'FL-0340', 'product': 'Natural Soap Pack (6)', 'qty': 1, 'amount': 120, 'anchor': 'College Gate - BITS'},
    {'id': 'FL-0338', 'product': 'Basmati Rice 5kg', 'qty': 2, 'amount': 570, 'anchor': 'College Gate - BITS'},
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() { _scanCtrl.dispose(); super.dispose(); }

  void _simulateScan() {
    setState(() => _scanned = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _verified = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Collect Order'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Scanner
          if (!_scanned) ...[
            GestureDetector(
              onTap: _simulateScan,
              child: Container(
                width: double.infinity, height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20), color: Colors.black,
                  border: Border.all(color: C.border),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  // Scanner frame
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: C.blue.withValues(alpha: 0.6), width: 2),
                    ),
                  ),
                  // Corner accents
                  ...List.generate(4, (i) {
                    final isTop = i < 2;
                    final isLeft = i % 2 == 0;
                    return Positioned(
                      top: isTop ? 40 : null, bottom: isTop ? null : 40,
                      left: isLeft ? 55 : null, right: isLeft ? null : 55,
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            top: isTop ? const BorderSide(color: C.blue, width: 3) : BorderSide.none,
                            bottom: !isTop ? const BorderSide(color: C.blue, width: 3) : BorderSide.none,
                            left: isLeft ? const BorderSide(color: C.blue, width: 3) : BorderSide.none,
                            right: !isLeft ? const BorderSide(color: C.blue, width: 3) : BorderSide.none,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Scanning line
                  AnimatedBuilder(animation: _scanCtrl, builder: (_, __) {
                    return Positioned(
                      top: 40 + _scanCtrl.value * 200,
                      left: 55, right: 55,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.transparent, C.blue, Colors.transparent]),
                          boxShadow: [BoxShadow(color: C.blue.withValues(alpha: 0.5), blurRadius: 8)],
                        ),
                      ),
                    );
                  }),
                  // Text
                  Positioned(
                    bottom: 16,
                    child: Text('Tap to simulate scan', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: Text('Point camera at the QR code at the collection point', style: S.bodySmall, textAlign: TextAlign.center)),
          ] else if (!_verified) ...[
            // Verifying
            Container(
              width: double.infinity, padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: C.blueSurface),
              child: const Column(children: [
                SizedBox(width: 48, height: 48, child: CircularProgressIndicator(color: C.blue, strokeWidth: 3)),
                SizedBox(height: 16),
                Text('Verifying QR Code...', style: S.h4),
                SizedBox(height: 4),
                Text('Matching with your orders', style: S.caption),
              ]),
            ),
          ] else ...[
            // Verified success
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: C.greenLight),
              child: Column(children: [
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: C.green),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text('Order Collected! 🎉', style: S.h2),
                const SizedBox(height: 6),
                Text('Your items are ready for pickup', style: S.body.copyWith(color: C.textSec)),
              ]),
            ),
          ],
          const SizedBox(height: 24),

          // Ready for collection
          const SectionHeader(title: 'Ready for Collection'),
          ..._readyOrders.map((o) => AppCard(child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.greenLight),
              child: const Icon(Icons.inventory_2_rounded, color: C.green, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o['product'] as String, style: S.h4.copyWith(fontSize: 13)),
              Text('#${o['id']} · Qty: ${o['qty']}', style: S.caption),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${o['amount']}', style: S.body.copyWith(fontWeight: FontWeight.w700)),
              StatusChip(label: 'Ready', color: C.green),
            ]),
          ]))),
          const SizedBox(height: 16),

          // Anchor Point info
          const SectionHeader(title: 'Collection Point'),
          AppCard(child: Column(children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.blueSurface),
                child: const Icon(Icons.place_rounded, color: C.blue, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('College Gate - BITS Pilani', style: S.h4),
                Text('0.8 km away · Open until 8 PM', style: S.caption),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: AppBtn(text: 'Get Directions', onTap: () {}, outline: true, icon: Icons.directions_rounded)),
              const SizedBox(width: 12),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.greenLight),
                child: const Icon(Icons.phone_rounded, color: C.green, size: 22),
              ),
            ]),
          ])),
        ]),
      ),
    );
  }
}
