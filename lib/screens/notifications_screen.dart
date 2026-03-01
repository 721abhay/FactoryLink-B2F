import 'package:flutter/material.dart';
import '../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = [
      _NotifData(Icons.check_circle_rounded, 'Order Ready!', 'Natural Soap Pack is ready at College Gate', '10 min ago', C.green, true),
      _NotifData(Icons.groups_rounded, 'Zone Almost Full!', 'Basmati Rice group needs 3 more orders', '1h ago', C.blue, true),
      _NotifData(Icons.local_offer_rounded, 'New Deal!', 'Steel Lunch Box — 46% off factory price', '2h ago', C.orange, false),
    ];
    final earlier = [
      _NotifData(Icons.local_shipping_rounded, 'Order Dispatched', 'Cotton T-Shirt Pack is on the way', 'Yesterday', C.yellow, false),
      _NotifData(Icons.payment_rounded, 'Payment Confirmed', '₹570 paid for Basmati Rice 5kg', 'Yesterday', C.green, false),
      _NotifData(Icons.timer_rounded, 'Timer Alert', 'Oil group order closes in 2 hours', '2 days ago', C.red, false),
      _NotifData(Icons.star_rounded, 'Rate Your Order', 'How was the Natural Soap Pack?', '3 days ago', C.yellow, false),
      _NotifData(Icons.celebration_rounded, 'Welcome!', 'Welcome to FactoryLink! Start saving today', '1 week ago', C.blue, false),
    ];

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Notifications'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5,
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all read', style: TextStyle(fontSize: 12, color: C.blue))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('TODAY', style: S.label)),
          ...today.map(_buildNotif),
          const SizedBox(height: 16),
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('EARLIER', style: S.label)),
          ...earlier.map(_buildNotif),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNotif(_NotifData n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: n.unread ? C.blueSurface : C.surface,
        border: Border.all(color: n.unread ? C.blue.withValues(alpha: 0.2) : C.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: n.color.withValues(alpha: 0.1)),
          child: Icon(n.icon, color: n.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(n.title, style: S.h4.copyWith(fontSize: 13))),
            if (n.unread) Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: C.blue)),
          ]),
          const SizedBox(height: 3),
          Text(n.body, style: S.bodySmall),
          const SizedBox(height: 4),
          Text(n.time, style: S.caption),
        ])),
      ]),
    );
  }
}

class _NotifData {
  final IconData icon;
  final String title, body, time;
  final Color color;
  final bool unread;
  const _NotifData(this.icon, this.title, this.body, this.time, this.color, this.unread);
}
