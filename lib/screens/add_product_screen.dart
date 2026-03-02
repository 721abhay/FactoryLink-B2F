import 'package:flutter/material.dart';
import '../theme.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Add New Product'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Image Upload
          Container(
            height: 160, width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), color: C.surface,
              border: Border.all(color: C.border, style: BorderStyle.none), // Custom dashed later
            ),
            child: Stack(children: [
              CustomPaint(painter: _DashedRectPainter(), size: Size.infinite),
              const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_photo_alternate_rounded, color: C.textTer, size: 40),
                SizedBox(height: 8),
                Text('Upload Product Images', style: S.h4),
                Text('JPG, PNG (Max 5MB)', style: S.caption),
              ])),
            ]),
          ),
          const SizedBox(height: 24),

          // Details
          const SectionHeader(title: 'Basic Details'),
          _field('Product Name', 'e.g. Cotton T-Shirt Pack of 3'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _field('Category', 'Select...', icon: Icons.keyboard_arrow_down_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _field('Unit', 'e.g. Pack, kg, Litre')),
          ]),
          const SizedBox(height: 24),

          // Capacity & Production
          const SectionHeader(title: 'Capacity & Production (TRD F2)'),
          AppCard(child: Column(children: [
            _field('Maximum Units Per Day', 'e.g. 500', icon: Icons.production_quantity_limits_rounded),
            const SizedBox(height: 16),
            _field('Minimum Order Quantity', 'e.g. 25', icon: Icons.shopping_basket_rounded),
            const SizedBox(height: 16),
            _field('Production Lead Time (Days)', 'e.g. 3', icon: Icons.schedule_rounded),
            const SizedBox(height: 16),
            _field('Slow Season Months', 'e.g. June, July', icon: Icons.calendar_month_rounded),
          ])),
          const SizedBox(height: 24),

          // Pricing structure
          const SectionHeader(title: 'Guaranteed Pricing Model (TRD F3)'),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: C.blueLight.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: C.blue, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Prices are agreed with the FactoryLink team during onboarding and entered by the team.', style: TextStyle(fontSize: 12, color: C.blue))),
            ]),
          ),
          AppCard(child: Column(children: [
            _priceRow('Tier 1 (25-50 units)', 'e.g. 350'),
            const Divider(height: 24),
            _priceRow('Tier 2 (51-150 units)', 'e.g. 300'),
            const Divider(height: 24),
            _priceRow('Tier 3 (151+ units)', 'e.g. 250'),
          ])),
          const SizedBox(height: 24),

          // Description
          const SectionHeader(title: 'Description'),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your product quality, materials, and features...',
              hintStyle: const TextStyle(fontSize: 14, color: C.textTer),
              filled: true, fillColor: C.surface,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.orange, width: 2)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(color: C.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))]),
        child: SafeArea(child: AppBtn(
          text: 'List Product', onTap: () => Navigator.pop(context), color: C.orange, icon: Icons.check_circle_rounded,
        )),
      ),
    );
  }

  Widget _field(String label, String hint, {IconData? icon}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(label, style: S.bodySmall)),
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.surface, border: Border.all(color: C.border)),
        child: TextField(
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(fontSize: 14, color: C.textTer),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            suffixIcon: icon != null ? Icon(icon, color: C.textTer, size: 20) : null,
          ),
        ),
      ),
    ]);
  }

  Widget _priceRow(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: S.bodySmall.copyWith(color: C.text))),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: C.surfaceAlt, border: Border.all(color: C.border)),
            child: TextField(
              keyboardType: TextInputType.number, textAlign: TextAlign.center,
              decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: C.textTer), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = C.border..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    for (double i = 16; i < size.width; i += 12) { canvas.drawLine(Offset(i, 0), Offset(i + 6, 0), paint); canvas.drawLine(Offset(i, size.height), Offset(i + 6, size.height), paint); }
    for (double i = 16; i < size.height; i += 12) { canvas.drawLine(Offset(0, i), Offset(0, i + 6), paint); canvas.drawLine(Offset(size.width, i), Offset(size.width, i + 6), paint); }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20)), Paint()..color = Colors.transparent);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
