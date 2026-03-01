import 'package:flutter/material.dart';
import '../theme.dart';
import 'customer_home_screen.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});
  @override
  State<CustomerRegistrationScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends State<CustomerRegistrationScreen> {
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  int _selectedAnchor = -1;

  final _anchors = [
    {'name': 'College Gate - BITS Pilani', 'type': 'College', 'icon': Icons.school_rounded, 'dist': '0.8 km'},
    {'name': 'TCS Office Tower', 'type': 'Office', 'icon': Icons.business_rounded, 'dist': '1.2 km'},
    {'name': 'Central Market Square', 'type': 'Market', 'icon': Icons.store_rounded, 'dist': '1.5 km'},
    {'name': 'City Mall Entrance', 'type': 'Mall', 'icon': Icons.local_mall_rounded, 'dist': '2.1 km'},
    {'name': 'Railway Station Gate 2', 'type': 'Station', 'icon': Icons.train_rounded, 'dist': '2.8 km'},
  ];

  void _next() {
    if (_step < 2) setState(() => _step++);
    else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: C.text),
          onPressed: () => _step > 0 ? setState(() => _step--) : Navigator.pop(context),
        ),
        title: Text('Step ${_step + 1} of 3', style: S.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i <= _step ? C.blue : C.border,
                  ),
                ),
              )),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: [_buildName(), _buildAddress(), _buildAnchor()][_step],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: AppBtn(text: _step == 2 ? 'Start Exploring' : 'Continue', onTap: _next, icon: _step == 2 ? Icons.rocket_launch_rounded : null),
          ),
        ],
      ),
    );
  }

  Widget _buildName() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: C.blueSurface),
        child: const Icon(Icons.person_rounded, color: C.blue, size: 28),
      ),
      const SizedBox(height: 20),
      const Text('What\'s your name?', style: S.h1),
      const SizedBox(height: 6),
      Text('This helps factories identify your orders', style: S.body.copyWith(color: C.textSec)),
      const SizedBox(height: 28),
      _field('Full Name', _nameCtrl, Icons.badge_rounded),
    ],
  );

  Widget _buildAddress() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: C.blueSurface),
        child: const Icon(Icons.location_on_rounded, color: C.blue, size: 28),
      ),
      const SizedBox(height: 20),
      const Text('Where do you\nlive?', style: S.h1),
      const SizedBox(height: 6),
      Text('We\'ll find the best zone for deliveries', style: S.body.copyWith(color: C.textSec)),
      const SizedBox(height: 28),
      _field('Full Address', _addressCtrl, Icons.home_rounded, lines: 3),
      const SizedBox(height: 14),
      _field('PIN Code', _pincodeCtrl, Icons.pin_drop_rounded, keyboard: TextInputType.number),
    ],
  );

  Widget _buildAnchor() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: C.blueSurface),
        child: const Icon(Icons.place_rounded, color: C.blue, size: 28),
      ),
      const SizedBox(height: 20),
      const Text('Pick your\ncollection point', style: S.h1),
      const SizedBox(height: 6),
      Text('Where you\'ll pick up your group orders', style: S.body.copyWith(color: C.textSec)),
      const SizedBox(height: 24),
      // Map placeholder
      Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), color: C.surfaceAlt,
          border: Border.all(color: C.border),
        ),
        child: const Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 40, color: C.textTer),
            SizedBox(height: 6),
            Text('Map Preview', style: TextStyle(fontSize: 12, color: C.textTer)),
          ],
        )),
      ),
      const SizedBox(height: 20),
      ...List.generate(_anchors.length, (i) {
        final a = _anchors[i];
        final sel = _selectedAnchor == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedAnchor = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: sel ? C.blueSurface : C.surface,
              border: Border.all(color: sel ? C.blue : C.border, width: sel ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: sel ? C.blue.withValues(alpha: 0.15) : C.surfaceAlt),
                  child: Icon(a['icon'] as IconData, color: sel ? C.blue : C.textSec, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['name'] as String, style: S.h4.copyWith(fontSize: 13, color: sel ? C.blue : C.text)),
                    Text(a['type'] as String, style: S.caption),
                  ],
                )),
                StatusChip(label: a['dist'] as String, color: sel ? C.blue : C.textSec),
                if (sel) ...[const SizedBox(width: 8), const Icon(Icons.check_circle_rounded, color: C.blue, size: 20)],
              ],
            ),
          ),
        );
      }),
    ],
  );

  Widget _field(String hint, TextEditingController ctrl, IconData icon, {int lines = 1, TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: C.textTer),
        prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: Icon(icon, color: C.textTer, size: 20)),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true, fillColor: C.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.blue, width: 2)),
      ),
    );
  }
}
