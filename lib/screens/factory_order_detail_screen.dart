import 'package:flutter/material.dart';
import '../theme.dart';

class FactoryOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const FactoryOrderDetailScreen({super.key, required this.order});
  @override
  State<FactoryOrderDetailScreen> createState() => _FactoryOrderDetailScreenState();
}

class _FactoryOrderDetailScreenState extends State<FactoryOrderDetailScreen> {
  int _currentStatus = 1;
  final _statuses = ['Received', 'Accepted', 'In Production', 'Quality Check', 'Ready', 'Dispatched', 'Delivered'];

  @override
  void initState() {
    super.initState();
    final s = widget.order['status'] as String;
    if (s == 'New') _currentStatus = 0;
    if (s == 'In Production') _currentStatus = 2;
    if (s == 'Ready') _currentStatus = 4;
    if (s == 'Dispatched') _currentStatus = 5;
  }

  void _advance() {
    if (_currentStatus < _statuses.length - 1) {
      setState(() => _currentStatus++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text('#${o['id']}'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatusChip(label: _statuses[_currentStatus], color: o['color'] as Color),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Order overview
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.inventory_2_rounded, color: C.orange, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(o['product'] as String, style: S.h3)),
            ]),
            const Divider(height: 20),
            _detailRow('Quantity', '${o['qty']} units'),
            _detailRow('Amount', '₹${o['amount']}'),
            _detailRow('Zone', o['zone'] as String),
            _detailRow('Ordered', o['date'] as String),
          ])),
          const SizedBox(height: 16),

          // Production Status
          const SectionHeader(title: 'Production Pipeline'),
          AppCard(child: Column(
            children: List.generate(_statuses.length, (i) {
              final done = i <= _currentStatus;
              final current = i == _currentStatus;
              final isLast = i == _statuses.length - 1;
              return IntrinsicHeight(child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 32, child: Column(children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? C.orange : C.surfaceAlt,
                        border: Border.all(color: done ? C.orange : C.border, width: current ? 2 : 1),
                      ),
                      child: done ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                    ),
                    if (!isLast) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: done ? C.orange : C.border)),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                    child: Text(_statuses[i], style: TextStyle(
                      fontSize: 13, fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                      color: done ? C.text : C.textTer,
                    )),
                  )),
                ],
              ));
            }),
          )),
          const SizedBox(height: 16),

          // Customer Info
          const SectionHeader(title: 'Delivery Info'),
          AppCard(child: Column(children: [
            _detailRow('Anchor Point', 'College Gate - BITS'),
            _detailRow('Zone', o['zone'] as String),
            _detailRow('Expected By', 'Mar 5, 2026'),
          ])),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: _currentStatus < _statuses.length - 1 ? Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: C.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: SafeArea(child: AppBtn(
          text: 'Mark as "${_statuses[_currentStatus + 1]}"',
          onTap: _advance, color: C.orange,
          icon: Icons.arrow_forward_rounded,
        )),
      ) : null,
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: S.bodySmall),
        Text(value, style: S.body.copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
      ]),
    );
  }
}
