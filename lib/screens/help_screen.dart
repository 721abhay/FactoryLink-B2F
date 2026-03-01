import 'package:flutter/material.dart';
import '../theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Help & Support'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact Support Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.blue, C.blueLight]),
              boxShadow: [BoxShadow(color: C.blue.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Need Help?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Our support team is available 24/7 to assist you with your orders and queries.', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _contactBtn(Icons.chat_rounded, 'Chat')),
                const SizedBox(width: 12),
                Expanded(child: _contactBtn(Icons.phone_rounded, 'Call')),
                const SizedBox(width: 12),
                Expanded(child: _contactBtn(Icons.email_rounded, 'Email')),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // Quick Topics
          const SectionHeader(title: 'What do you need help with?'),
          Row(children: [
            _topicCard(Icons.inventory_2_rounded, 'My Orders', C.orange),
            const SizedBox(width: 10),
            _topicCard(Icons.payments_rounded, 'Payments', C.green),
            const SizedBox(width: 10),
            _topicCard(Icons.local_shipping_rounded, 'Delivery', C.blue),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _topicCard(Icons.restart_alt_rounded, 'Returns', C.red),
            const SizedBox(width: 10),
            _topicCard(Icons.groups_rounded, 'Group Buying', C.yellow),
            const SizedBox(width: 10),
            _topicCard(Icons.person_rounded, 'Account', C.textSec),
          ]),
          const SizedBox(height: 24),

          // FAQs
          const SectionHeader(title: 'Frequently Asked Questions'),
          _faqItem('How does group buying work?', 'When you place an order, it joins a zonal pool. Once the group reaches the target quantity (within the timer), the bulk discount is applied and the order is sent to the factory.'),
          _faqItem('Where is the collection point?', 'Collection points are usually local colleges, offices, or large residential complexes in your zone to ensure cost-friendly bulk shipping.'),
          _faqItem('Can I cancel my order?', 'You can cancel an order before the group timer expires. Once the timer is up and the order goes to the factory, cancellations are no longer possible since items are manufactured to order.'),
          _faqItem('How do I track my delivery?', 'Go to the Orders tab and tap on an active order. You will see a 7-step timeline tracking your order from production to the collection point.'),
        ],
      ),
    );
  }

  Widget _contactBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withValues(alpha: 0.2)),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }

  Widget _topicCard(IconData icon, String label, Color color) {
    return Expanded(child: AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: EdgeInsets.zero,
      child: Column(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withValues(alpha: 0.1)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(label, style: S.caption.copyWith(fontWeight: FontWeight.w600, color: C.text)),
      ]),
    ));
  }

  Widget _faqItem(String q, String a) {
    return AppCard(child: Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero, childrenPadding: EdgeInsets.zero,
        title: Text(q, style: S.h4),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(a, style: S.body.copyWith(fontSize: 13, color: C.textSec)),
          ),
        ],
      ),
    ));
  }
}
