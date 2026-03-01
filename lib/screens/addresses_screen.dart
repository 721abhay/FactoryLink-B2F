import 'package:flutter/material.dart';
import '../theme.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  int _defaultIdx = 0;

  final _addresses = [
    {
      'type': 'Home',
      'name': 'Abhay Singh',
      'address': 'B-302, Green Valley Apartments, Sector 14, Gurugram, 122001',
      'phone': '+91 98765 43210',
    },
    {
      'type': 'Office',
      'name': 'Abhay Singh',
      'address': 'Level 4, Cyber City Building 10, DLF Phase 2, Gurugram, 122002',
      'phone': '+91 98765 43210',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('My Addresses'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._addresses.asMap().entries.map((e) {
            final i = e.key;
            final a = e.value;
            final isDefault = _defaultIdx == i;
            return AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: C.surfaceAlt),
                    child: Text(a['type']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textSec)),
                  ),
                  const Spacer(),
                  if (isDefault) const StatusChip(label: 'Default', color: C.blue),
                ]),
                const SizedBox(height: 12),
                Text(a['name']!, style: S.h4),
                const SizedBox(height: 4),
                Text(a['address']!, style: S.body.copyWith(fontSize: 13, height: 1.4, color: C.textSec)),
                const SizedBox(height: 8),
                Text('Phone: ${a['phone']}', style: S.caption),
                const Divider(height: 24),
                Row(children: [
                  if (!isDefault) Expanded(child: AppBtn(text: 'Set as Default', onTap: () => setState(() => _defaultIdx = i), outline: true)),
                  if (!isDefault) const SizedBox(width: 12),
                  const Icon(Icons.edit_rounded, color: C.textSec, size: 20),
                  const SizedBox(width: 16),
                  const Icon(Icons.delete_outline_rounded, color: C.red, size: 20),
                ]),
              ]),
            );
          }),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(color: C.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))]),
        child: SafeArea(child: AppBtn(text: 'Add New Address', onTap: () {}, color: C.blue, icon: Icons.add_rounded)),
      ),
    );
  }
}
