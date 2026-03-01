import 'package:flutter/material.dart';
import '../theme.dart';
import 'add_product_screen.dart';

class FactoryCatalogScreen extends StatelessWidget {
  const FactoryCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Product Catalog'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            Expanded(child: _summaryCard('Listed', '12', C.blue, Icons.inventory_2_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('Sold Out', '2', C.red, Icons.cancel_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('Pending', '1', C.orange, Icons.hourglass_top_rounded)),
          ]),
          const SizedBox(height: 24),
          
          _productCard('Cotton T-Shirt Pack (3)', 'Clothing', 500, 350, 300, 50, 'Active', C.green, Icons.checkroom_rounded),
          _productCard('Basmati Rice 5kg', 'Groceries', 450, 300, 280, 50, 'Active', C.green, Icons.rice_bowl_rounded),
          _productCard('Natural Soap Pack', 'Personal Care', 240, 150, 120, 25, 'Sold Out', C.red, Icons.soap_rounded),
          _productCard('Winter Blanket', 'Home', 1200, 900, 750, 30, 'Active', C.green, Icons.bed_rounded),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(color: C.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))]),
        child: SafeArea(child: AppBtn(text: 'List New Product', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())), color: C.orange, icon: Icons.add_rounded)),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(value, style: S.h3),
        Text(label, style: S.caption),
      ]),
    );
  }

  Widget _productCard(String name, String cat, int retail, int t1, int t2, int grp, String status, Color color, IconData icon) {
    return AppCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.surfaceAlt, border: Border.all(color: C.border)),
            child: Icon(icon, color: C.textSec, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: S.h4),
            Text(cat, style: S.caption),
          ])),
          StatusChip(label: status, color: color),
        ]),
        const Divider(height: 24),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Retail', style: S.caption),
            const SizedBox(height: 2),
            Text('₹$retail', style: S.priceCut.copyWith(fontSize: 14)),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Text('Single', style: S.caption),
            const SizedBox(height: 2),
            Text('₹$t1', style: S.price.copyWith(fontSize: 16)),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Group (Min $grp)', style: S.caption),
            const SizedBox(height: 2),
            Text('₹$t2', style: S.price.copyWith(color: C.orange, fontSize: 16)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.edit_rounded, color: C.textTer, size: 16),
          const SizedBox(width: 4),
          const Text('Edit Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.textSec)),
          const Spacer(),
          const Icon(Icons.share_rounded, color: C.textTer, size: 16),
          const SizedBox(width: 16),
          const Icon(Icons.delete_outline_rounded, color: C.red, size: 18),
        ]),
      ],
    ));
  }
}
