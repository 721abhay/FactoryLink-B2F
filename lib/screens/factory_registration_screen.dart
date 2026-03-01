import 'package:flutter/material.dart';
import '../theme.dart';
import 'factory_dashboard_screen.dart';

class FactoryRegistrationScreen extends StatefulWidget {
  const FactoryRegistrationScreen({super.key});
  @override
  State<FactoryRegistrationScreen> createState() => _FactoryRegistrationScreenState();
}

class _FactoryRegistrationScreenState extends State<FactoryRegistrationScreen> {
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  int _selectedCat = -1;

  final _categories = [
    {'name': 'Textiles & Clothing', 'icon': Icons.checkroom_rounded},
    {'name': 'Food & Groceries', 'icon': Icons.rice_bowl_rounded},
    {'name': 'Personal Care', 'icon': Icons.soap_rounded},
    {'name': 'Home & Kitchen', 'icon': Icons.bed_rounded},
    {'name': 'Steel & Hardware', 'icon': Icons.hardware_rounded},
    {'name': 'Paper & Stationery', 'icon': Icons.note_rounded},
  ];

  void _next() {
    if (_step < 2) setState(() => _step++);
    else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const FactoryDashboardScreen()),
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: C.text),
          onPressed: () => _step > 0 ? setState(() => _step--) : Navigator.pop(context)),
        title: Text('Step ${_step + 1} of 3', style: S.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(children: List.generate(3, (i) => Expanded(
            child: Container(
              height: 4, margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: i <= _step ? C.orange : C.border),
            ),
          ))),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: [_stepBusiness(), _stepCategory(), _stepCapacity()][_step],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: AppBtn(text: _step == 2 ? 'Launch Dashboard' : 'Continue', onTap: _next, color: C.orange,
            icon: _step == 2 ? Icons.rocket_launch_rounded : null),
        ),
      ]),
    );
  }

  Widget _stepBusiness() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: C.orangeSurface),
      child: const Icon(Icons.business_rounded, color: C.orange, size: 28)),
    const SizedBox(height: 20),
    const Text('Business Details', style: S.h1),
    const SizedBox(height: 6),
    Text('Tell us about your factory', style: S.body.copyWith(color: C.textSec)),
    const SizedBox(height: 28),
    _field('Factory / Business Name', _nameCtrl, Icons.factory_rounded),
    const SizedBox(height: 14),
    _field('GST Number', _gstCtrl, Icons.receipt_rounded),
    const SizedBox(height: 14),
    _field('Factory Address', _addrCtrl, Icons.location_on_rounded, lines: 3),
    const SizedBox(height: 20),
    // Document upload
    Container(
      width: double.infinity, height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14), color: C.orangeSurface,
        border: Border.all(color: C.orange.withValues(alpha: 0.3), style: BorderStyle.solid),
      ),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_upload_rounded, color: C.orange, size: 30),
        SizedBox(height: 6),
        Text('Upload Business License', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.orange)),
        Text('PDF, JPG up to 5MB', style: S.caption),
      ]),
    ),
  ]);

  Widget _stepCategory() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: C.orangeSurface),
      child: const Icon(Icons.category_rounded, color: C.orange, size: 28)),
    const SizedBox(height: 20),
    const Text('What do you\nmanufacture?', style: S.h1),
    const SizedBox(height: 6),
    Text('Select your primary category', style: S.body.copyWith(color: C.textSec)),
    const SizedBox(height: 24),
    ...List.generate(_categories.length, (i) {
      final c = _categories[i];
      final sel = _selectedCat == i;
      return GestureDetector(
        onTap: () => setState(() => _selectedCat = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: sel ? C.orangeSurface : C.surface,
            border: Border.all(color: sel ? C.orange : C.border, width: sel ? 2 : 1),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: sel ? C.orange.withValues(alpha: 0.15) : C.surfaceAlt),
              child: Icon(c['icon'] as IconData, color: sel ? C.orange : C.textSec, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(c['name'] as String, style: S.h4.copyWith(color: sel ? C.orange : C.text))),
            if (sel) const Icon(Icons.check_circle_rounded, color: C.orange, size: 22),
          ]),
        ),
      );
    }),
  ]);

  Widget _stepCapacity() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: C.orangeSurface),
      child: const Icon(Icons.speed_rounded, color: C.orange, size: 28)),
    const SizedBox(height: 20),
    const Text('Production\nCapacity', style: S.h1),
    const SizedBox(height: 6),
    Text('Help us match you with the right orders', style: S.body.copyWith(color: C.textSec)),
    const SizedBox(height: 28),
    _field('Monthly Production Capacity', _capCtrl, Icons.inventory_rounded, keyboard: TextInputType.number),
    const SizedBox(height: 20),
    // Benefits summary
    AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('What you get', style: S.h4),
      const SizedBox(height: 14),
      _benefit(Icons.groups_rounded, 'Guaranteed Orders', 'Pre-paid group orders from verified customers'),
      _benefit(Icons.payments_rounded, '48hr Payments', 'Fast payments directly to your bank account'),
      _benefit(Icons.trending_up_rounded, 'Build Trust Score', 'Higher score = more orders & better visibility'),
      _benefit(Icons.support_agent_rounded, 'Dedicated Support', 'Factory success team to help you grow'),
    ])),
  ]);

  Widget _benefit(IconData icon, String title, String sub) {
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(children: [
      Icon(icon, color: C.orange, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: S.h4.copyWith(fontSize: 13)),
        Text(sub, style: S.caption),
      ])),
    ]));
  }

  Widget _field(String hint, TextEditingController ctrl, IconData icon, {int lines = 1, TextInputType? keyboard}) {
    return TextField(
      controller: ctrl, maxLines: lines, keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: C.textTer),
        prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: Icon(icon, color: C.textTer, size: 20)),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true, fillColor: C.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.orange, width: 2)),
      ),
    );
  }
}
