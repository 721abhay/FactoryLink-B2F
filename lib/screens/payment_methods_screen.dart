import 'package:flutter/material.dart';
import '../theme.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Payment Methods'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Saved Cards'),
          _cardItem('HDFC Bank', '**** **** **** 4521', 'Expires 12/28', C.blue, Icons.credit_card_rounded),
          _cardItem('ICICI Bank', '**** **** **** 8812', 'Expires 08/25', C.orange, Icons.credit_card_rounded),
          const SizedBox(height: 12),
          AppBtn(text: 'Add New Card', onTap: () {}, outline: true, icon: Icons.add_rounded),
          const SizedBox(height: 24),

          const SectionHeader(title: 'UPI & Wallets'),
          AppCard(padding: EdgeInsets.zero, child: Column(children: [
            _upiItem('PhonePe', 'abhay@ybl', C.dark1),
            const Divider(height: 1, indent: 60),
            _upiItem('Google Pay', 'abhay@okicici', C.blue),
            const Divider(height: 1, indent: 60),
            _upiItem('Add New UPI ID', '', C.textTer, Icons.add_rounded),
          ])),
        ],
      ),
    );
  }

  Widget _cardItem(String bank, String num, String exp, Color color, IconData icon) {
    return AppCard(child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withValues(alpha: 0.1)),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(bank, style: S.h4),
        Text('$num  ·  $exp', style: S.caption),
      ])),
      const Icon(Icons.delete_outline_rounded, color: C.textTer, size: 20),
    ]));
  }

  Widget _upiItem(String name, String id, Color color, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
          child: Icon(icon ?? Icons.account_balance_wallet_rounded, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: S.body.copyWith(fontWeight: FontWeight.w500)),
          if (id.isNotEmpty) Text(id, style: S.caption),
        ])),
      ]),
    );
  }
}
