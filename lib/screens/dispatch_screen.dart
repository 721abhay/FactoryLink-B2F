import 'package:flutter/material.dart';
import '../theme.dart';

class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});
  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  final _readyToDispatch = [
    {'id': 'FL-0340', 'product': 'Natural Soap Pack', 'qty': 25, 'zone': 'Zone A', 'anchor': 'College Gate - BITS', 'dispatched': false},
    {'id': 'FL-0339', 'product': 'Handloom Bedsheet', 'qty': 15, 'zone': 'Zone C', 'anchor': 'Central Market Square', 'dispatched': false},
  ];

  final _dispatched = [
    {'id': 'FL-0338', 'product': 'Basmati Rice 5kg', 'qty': 30, 'zone': 'Zone B', 'anchor': 'TCS Office Tower', 'tracking': 'AWB-99281'},
    {'id': 'FL-0337', 'product': 'Cotton T-Shirt Pack', 'qty': 50, 'zone': 'Zone A', 'anchor': 'College Gate - BITS', 'tracking': 'AWB-99280'},
  ];

  void _dispatch(int i) {
    setState(() {
      _readyToDispatch[i]['dispatched'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('📦 ${_readyToDispatch[i]['product']} dispatched!'),
      backgroundColor: C.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Dispatch'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stats
          Row(children: [
            _stat('Ready', '${_readyToDispatch.where((d) => d['dispatched'] == false).length}', C.orange, Icons.inventory_2_rounded),
            const SizedBox(width: 10),
            _stat('Dispatched', '${_dispatched.length}', C.green, Icons.local_shipping_rounded),
            const SizedBox(width: 10),
            _stat('In Transit', '${_dispatched.length}', C.blue, Icons.route_rounded),
          ]),
          const SizedBox(height: 20),

          // Ready to Dispatch
          const SectionHeader(title: 'Ready to Dispatch'),
          ..._readyToDispatch.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            final done = d['dispatched'] as bool;
            return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: done ? C.greenLight : C.orangeSurface),
                  child: Icon(done ? Icons.check_circle_rounded : Icons.inventory_2_rounded, color: done ? C.green : C.orange, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['product'] as String, style: S.h4.copyWith(fontSize: 14)),
                  Text('#${d['id']} · ${d['zone']} · ${d['qty']} units', style: S.caption),
                ])),
                StatusChip(label: done ? 'Dispatched' : 'Ready', color: done ? C.green : C.orange),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.place_rounded, size: 14, color: C.textSec),
                const SizedBox(width: 6),
                Expanded(child: Text(d['anchor'] as String, style: S.bodySmall)),
              ]),
              if (!done) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: AppBtn(text: 'Generate QR & Dispatch', onTap: () => _dispatch(i), color: C.orange, icon: Icons.qr_code_2_rounded)),
                ]),
              ],
            ]));
          }),
          const SizedBox(height: 16),

          // Already Dispatched
          const SectionHeader(title: 'Dispatched'),
          ..._dispatched.map((d) => AppCard(child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.greenLight),
              child: const Icon(Icons.local_shipping_rounded, color: C.green, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['product'] as String, style: S.h4.copyWith(fontSize: 14)),
              Text('#${d['id']} · ${d['zone']}', style: S.caption),
              Row(children: [
                const Icon(Icons.confirmation_number_rounded, size: 12, color: C.textTer),
                const SizedBox(width: 4),
                Text(d['tracking'] as String, style: S.caption.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ])),
            StatusChip(label: 'In Transit', color: C.blue, icon: Icons.route_rounded),
          ]))),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color, IconData icon) {
    return Expanded(child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: S.h2.copyWith(fontSize: 22)),
        Text(label, style: S.caption),
      ]),
    ));
  }
}
