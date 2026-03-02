import 'package:flutter/material.dart';
import '../theme.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int qty;
  final int unitPrice;
  const PaymentScreen({super.key, required this.product, required this.qty, required this.unitPrice});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _method = 0;
  bool _processing = false;

  final _methods = [
    {'icon': Icons.account_balance_rounded, 'label': 'UPI / Google Pay', 'sub': 'Pay directly from bank'},
    {'icon': Icons.credit_card_rounded, 'label': 'Debit / Credit Card', 'sub': 'Visa, Mastercard, Rupay'},
    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Net Banking', 'sub': 'All major banks'},
    {'icon': Icons.money_rounded, 'label': 'Cash on Delivery', 'sub': 'Pay at collection point'},
  ];

  @override
  Widget build(BuildContext context) {
    final total = widget.unitPrice * widget.qty;
    final gst = (total * 0.18).round();
    final grand = total + gst;
    final advance = (grand * 0.30).round(); // TRD C6 Split Payment
    final remaining = grand - advance;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Payment'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            AppCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Summary', style: S.h3),
                const SizedBox(height: 14),
                _summaryRow(widget.product['name'] as String, '${widget.qty} × ₹${widget.unitPrice}'),
                _summaryRow('Subtotal', '₹$total'),
                _summaryRow('GST (18%)', '₹$gst'),
                _summaryRow('Delivery', 'FREE', valueColor: C.green),
                const Divider(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total Value', style: S.h3),
                  Text('₹$grand', style: S.price),
                ]),
                const Divider(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: C.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('30% Advance (Pay Now)', style: TextStyle(fontWeight: FontWeight.bold, color: C.orange)),
                        Text('₹$advance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: C.orange)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('70% Remaining (Before Delivery)', style: TextStyle(fontSize: 12, color: C.textSec)),
                        Text('₹$remaining', style: const TextStyle(fontSize: 12, color: C.textSec)),
                      ]),
                    ],
                  ),
                ),
              ],
            )),
            const SizedBox(height: 8),

            // Savings badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.greenLight),
              child: Row(children: [
                const Icon(Icons.savings_rounded, color: C.green, size: 20),
                const SizedBox(width: 10),
                Text('You save ₹${(widget.product['retail'] as int) * widget.qty - total} vs retail!',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.green)),
              ]),
            ),
            const SizedBox(height: 24),

            // Delivery info
            const SectionHeader(title: 'Delivery Details'),
            AppCard(child: Column(children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.blueSurface),
                  child: const Icon(Icons.place_rounded, color: C.blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('College Gate - BITS Pilani', style: S.h4),
                    Text('Anchor Point · 0.8 km away', style: S.caption),
                  ],
                )),
                GestureDetector(
                  child: const Text('Change', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.blue)),
                ),
              ]),
              const Divider(height: 20),
              Row(children: [
                const Icon(Icons.schedule_rounded, color: C.textSec, size: 18),
                const SizedBox(width: 8),
                const Text('Estimated: 3-5 working days', style: S.bodySmall),
              ]),
            ])),
            const SizedBox(height: 24),

            // Payment methods
            const SectionHeader(title: 'Payment Method'),
            ...List.generate(_methods.length, (i) {
              final m = _methods[i];
              final sel = _method == i;
              return GestureDetector(
                onTap: () => setState(() => _method = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: sel ? C.blueSurface : C.surface,
                    border: Border.all(color: sel ? C.blue : C.border, width: sel ? 2 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: sel ? C.blue.withValues(alpha: 0.15) : C.surfaceAlt),
                      child: Icon(m['icon'] as IconData, color: sel ? C.blue : C.textSec, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['label'] as String, style: S.h4.copyWith(fontSize: 14, color: sel ? C.blue : C.text)),
                        Text(m['sub'] as String, style: S.caption),
                      ],
                    )),
                    Icon(sel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: sel ? C.blue : C.textTer, size: 22),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: C.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: SafeArea(child: AppBtn(
          text: _processing ? 'Processing...' : 'Pay ₹$advance (30% Advance)',
          onTap: () {
            setState(() => _processing = true);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('🎉 Order placed successfully!'),
                  backgroundColor: C.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              }
            });
          },
          icon: Icons.lock_rounded,
        )),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: S.body.copyWith(color: C.textSec)),
        Text(value, style: S.body.copyWith(fontWeight: FontWeight.w500, color: valueColor ?? C.text)),
      ]),
    );
  }
}
