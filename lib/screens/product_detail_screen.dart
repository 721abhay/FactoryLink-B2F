import 'package:flutter/material.dart';
import '../theme.dart';
import 'payment_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  int _selectedTier = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final tiers = [
      {'label': 'Standard', 'min': 1, 'price': p['price']},
      {'label': 'Group (5+)', 'min': 5, 'price': ((p['price'] as int) * 0.92).round()},
      {'label': 'Bulk (20+)', 'min': 20, 'price': ((p['price'] as int) * 0.85).round()},
    ];
    final unitPrice = tiers[_selectedTier]['price'] as int;
    final progress = (p['orders'] as int) / (p['min'] as int);

    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        slivers: [
          // Image Header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: C.surface,
            leading: _backBtn(context),
            actions: [
              _actionBtn(Icons.share_rounded),
              const SizedBox(width: 8),
              _actionBtn(Icons.favorite_border_rounded),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: C.surfaceAlt,
                child: Center(child: Icon(p['icon'] as IconData, size: 80, color: C.textTer.withValues(alpha: 0.3))),
              ),
            ),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Rating
                Row(children: [
                  StatusChip(label: p['cat'] as String, color: C.blue),
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded, size: 16, color: C.yellow),
                  Text(' ${p['score']}', style: S.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  Text(' (128 reviews)', style: S.caption),
                ]),
                const SizedBox(height: 12),

                // Title
                Text(p['name'] as String, style: S.h2),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.factory_rounded, size: 16, color: C.textSec),
                  const SizedBox(width: 6),
                  Text(p['factory'] as String, style: S.body.copyWith(color: C.textSec)),
                  const SizedBox(width: 8),
                  const Icon(Icons.verified_rounded, size: 16, color: C.blue),
                ]),
                const SizedBox(height: 20),

                // Pricing
                Row(children: [
                  Text('₹$unitPrice', style: S.price.copyWith(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text('₹${p['retail']}', style: S.priceCut.copyWith(fontSize: 16)),
                  const SizedBox(width: 10),
                  StatusChip(label: '${p['save']}% OFF', color: C.green),
                ]),
                const SizedBox(height: 6),
                Text('GST inclusive · Free zone delivery', style: S.caption),
                const SizedBox(height: 24),

                // Tiered Pricing
                const SectionHeader(title: 'Pricing Tiers'),
                Row(
                  children: List.generate(tiers.length, (i) {
                    final t = tiers[i];
                    final sel = _selectedTier == i;
                    return Expanded(child: GestureDetector(
                      onTap: () => setState(() { _selectedTier = i; _qty = (t['min'] as int).clamp(1, 999); }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: sel ? C.blueSurface : C.surface,
                          border: Border.all(color: sel ? C.blue : C.border, width: sel ? 2 : 1),
                        ),
                        child: Column(children: [
                          Text(t['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? C.blue : C.textSec)),
                          const SizedBox(height: 4),
                          Text('₹${t['price']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: sel ? C.blue : C.text)),
                          Text('min ${t['min']}', style: S.caption),
                        ]),
                      ),
                    ));
                  }),
                ),
                const SizedBox(height: 24),

                // Zone Progress
                const SectionHeader(title: 'Zone Status'),
                AppCard(child: Column(children: [
                  Row(children: [
                    const Icon(Icons.groups_rounded, color: C.blue, size: 20),
                    const SizedBox(width: 8),
                    Text('${p['orders']} of ${p['min']} orders', style: S.h4.copyWith(fontSize: 14)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: C.yellowLight),
                      child: Row(children: [
                        const Icon(Icons.timer_rounded, color: C.yellow, size: 14),
                        const SizedBox(width: 4),
                        Text(p['time'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.yellow)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress, backgroundColor: C.border,
                      valueColor: AlwaysStoppedAnimation(progress > 0.8 ? C.green : C.blue), minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${(progress * 100).round()}% filled', style: S.caption),
                    Text('${(p['min'] as int) - (p['orders'] as int)} more needed', style: S.caption.copyWith(color: C.blue, fontWeight: FontWeight.w600)),
                  ]),
                ])),
                const SizedBox(height: 24),

                // Factory Info
                const SectionHeader(title: 'Factory Details'),
                AppCard(child: Column(children: [
                  _infoRow(Icons.factory_rounded, 'Factory', p['factory'] as String),
                  const Divider(height: 20),
                  _infoRow(Icons.verified_rounded, 'Trust Score', '4.3 / 5.0 · Verified'),
                  const Divider(height: 20),
                  _infoRow(Icons.local_shipping_rounded, 'Delivery', '3-5 working days'),
                  const Divider(height: 20),
                  _infoRow(Icons.replay_rounded, 'Returns', '7-day easy returns'),
                ])),
                const SizedBox(height: 100),
              ],
            ),
          )),
        ],
      ),
      // Bottom CTA
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: C.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Qty selector
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
                child: Row(children: [
                  _qtyBtn(Icons.remove, () { if (_qty > 1) setState(() => _qty--); }),
                  SizedBox(width: 40, child: Center(child: Text('$_qty', style: S.h4))),
                  _qtyBtn(Icons.add, () => setState(() => _qty++)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PaymentScreen(product: p, qty: _qty, unitPrice: unitPrice),
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.blue, foregroundColor: Colors.white, elevation: 0,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Add to Group · ₹${unitPrice * _qty}', style: S.btnText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 18, color: C.textSec)));
  }

  Widget _backBtn(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Container(
      decoration: BoxDecoration(color: C.surface.withValues(alpha: 0.9), shape: BoxShape.circle),
      child: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: C.text, size: 20), onPressed: () => Navigator.pop(context)),
    ),
  );

  Widget _actionBtn(IconData icon) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(color: C.surface.withValues(alpha: 0.9), shape: BoxShape.circle),
    child: Icon(icon, color: C.textSec, size: 20),
  );

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: C.blue, size: 18),
      const SizedBox(width: 10),
      Text(label, style: S.bodySmall.copyWith(fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(value, style: S.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }
}
