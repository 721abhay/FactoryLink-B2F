import 'package:flutter/material.dart';
import '../theme.dart';
import 'factory_order_detail_screen.dart';
import 'factory_profile_screen.dart';
import 'notifications_screen.dart';
import 'production_tracker_screen.dart';
import 'dispatch_screen.dart';
import 'collection_screen.dart';
import '../services/api_service.dart';

class FactoryDashboardScreen extends StatefulWidget {
  const FactoryDashboardScreen({super.key});
  @override
  State<FactoryDashboardScreen> createState() => _FactoryDashboardScreenState();
}

class _FactoryDashboardScreenState extends State<FactoryDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  double _todayEarnings = 0.0;
  int _pendingAction = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final res = await api.getFactoryPendingOrders();
      if (res['success'] == true && mounted) {
        setState(() {
          _orders = res['orders'];
          _isLoading = false;
          // Simple calculations
          for (var o in _orders) {
            final t = o['total_amount']?.toString() ?? '0';
            _todayEarnings += double.tryParse(t) ?? 0;
            if (o['status'] == 'pending') _pendingAction++;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: [_buildDashboard(), _buildOrdersList(), _buildEarnings(), const FactoryProfileScreen()][_tab],
      bottomNavigationBar: _buildNav(),
    );
  }

  // ── DASHBOARD ──
  Widget _buildDashboard() {
    return CustomScrollView(slivers: [
      SliverAppBar(
        floating: true, backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5,
        automaticallyImplyLeading: false,
        title: Row(children: [
          const Text('FactoryLink', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.orange)),
          const Spacer(),
          StatusChip(label: 'Trust: 4.3', color: C.green, icon: Icons.star_rounded),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.surfaceAlt, border: Border.all(color: C.border)),
              child: const Icon(Icons.notifications_none_rounded, color: C.textSec, size: 20),
            ),
          ),
        ]),
      ),

      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(children: [
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [C.orange, C.orangeLight]),
              boxShadow: [BoxShadow(color: C.orange.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Today\'s Overview', style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                const Text('₹28,250', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('4 orders · 2 pending action', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ])),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Settings row
          Row(children: [
            _statCard('New Orders', '${_orders.where((o) => o['status'] == 'pending').length}', C.blue, Icons.fiber_new_rounded),
            const SizedBox(width: 10),
            _statCard('Production', '${_orders.where((o) => o['status'] == 'accepted').length}', C.yellow, Icons.precision_manufacturing_rounded),
            const SizedBox(width: 10),
            _statCard('Ready', '${_orders.where((o) => o['status'] == 'ready').length}', C.green, Icons.check_circle_rounded),
          ]),
          const SizedBox(height: 20),

          // Recent Orders
          SectionHeader(title: 'Recent Orders', action: 'View All', onAction: () => setState(() => _tab = 1)),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_orders.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('No recent orders'))
          else
            ..._orders.take(3).map((o) => _orderCard(o)),

          const SizedBox(height: 12),

          // Quick Actions
          const SectionHeader(title: 'Quick Actions'),
          Row(children: [
            _quickAction(Icons.precision_manufacturing_rounded, 'Production', C.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductionTrackerScreen()))),
            const SizedBox(width: 10),
            _quickAction(Icons.qr_code_scanner_rounded, 'Scan QR', C.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionScreen()))),
            const SizedBox(width: 10),
            _quickAction(Icons.local_shipping_rounded, 'Dispatch', C.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DispatchScreen()))),
          ]),
        ]),
      )),
    ]);
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: S.h2.copyWith(fontSize: 22)),
        Text(label, style: S.caption),
      ]),
    ));
  }

  Widget _orderCard(dynamic o) {
    final status = (o['status'] as String?) ?? 'pending';
    final color = status == 'collected' ? C.green : (status == 'ready' ? C.orange : C.blue);
    final name = o['product'] != null ? o['product']['name'] : 'Unknown Product';
    final qty = o['qty'] ?? 1;
    final total = o['total_amount'] ?? '0';
    final id = o['id']?.toString().substring(0, 8) ?? 'Unknown';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FactoryOrderDetailScreen(order: o))),
      child: AppCard(child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withValues(alpha: 0.1)),
          child: Icon(Icons.inventory_2_rounded, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: S.h4.copyWith(fontSize: 14), maxLines: 1),
          Row(children: [
            Text('#$id', style: S.caption),
            const SizedBox(width: 8),
            Text('Qty: $qty', style: S.caption.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          StatusChip(label: status.toUpperCase(), color: color),
          const SizedBox(height: 4),
          Text('₹$total', style: S.body.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ])),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, [VoidCallback? onTap]) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AppCard(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: color.withValues(alpha: 0.1)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(label, style: S.caption.copyWith(fontWeight: FontWeight.w600, color: C.text)),
      ]),
    )));
  }

  // ── ORDERS LIST ──
  Widget _buildOrdersList() {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('All Orders'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: DefaultTabController(
        length: 4,
        child: Column(children: [
          TabBar(
            labelColor: C.orange, unselectedLabelColor: C.textTer,
            indicatorColor: C.orange, indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'All'), Tab(text: 'New'), Tab(text: 'Active'), Tab(text: 'Done')],
          ),
          Expanded(child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [
                _orderList(_orders),
                _orderList(_orders.where((o) => o['status'] == 'pending').toList()),
                _orderList(_orders.where((o) => o['status'] == 'accepted' || o['status'] == 'ready').toList()),
                _orderList(_orders.where((o) => o['status'] == 'collected').toList()),
              ]),
          ),
        ]),
      ),
    );
  }

  Widget _orderList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: orders.map((o) => _orderCard(o)).toList(),
    );
  }

  // ── EARNINGS ──
  Widget _buildEarnings() {
    final months = ['Jan', 'Feb', 'Mar'];
    final values = [18500, 24300, 28250];

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Earnings'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Total earnings card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [C.orange, C.orangeLight]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Earnings', style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 4),
              const Text('₹71,050', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('This quarter (Jan-Mar 2026)', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 20),
              // Simple bar chart
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (i) {
                    final pct = values[i] / 30000;
                    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text('₹${(values[i] / 1000).toStringAsFixed(1)}k',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
                      const SizedBox(height: 4),
                      Container(
                        width: 40, height: 70 * pct,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white.withValues(alpha: i == 2 ? 0.9 : 0.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(months[i], style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                    ]);
                  }),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Payment history
          const SectionHeader(title: 'Recent Payments'),
          _paymentItem('Cotton T-Shirt Pack', '₹9,950', 'Pending', C.yellow),
          _paymentItem('Basmati Rice 5kg', '₹8,550', 'Paid', C.green),
          _paymentItem('Natural Soap Pack', '₹3,000', 'Paid', C.green),
          _paymentItem('Handloom Bedsheet', '₹6,750', 'Paid', C.green),

          const SizedBox(height: 16),
          // Bank details
          const SectionHeader(title: 'Bank Account'),
          AppCard(child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.blueSurface),
              child: const Icon(Icons.account_balance_rounded, color: C.blue, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('HDFC Bank', style: S.h4),
              Text('••••  ••••  ••••  4521', style: S.caption),
            ])),
            StatusChip(label: 'Verified', color: C.green, icon: Icons.verified_rounded),
          ])),
        ],
      ),
    );
  }

  Widget _paymentItem(String name, String amount, String status, Color color) {
    return AppCard(child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
        child: Icon(Icons.payment_rounded, color: color, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: S.h4.copyWith(fontSize: 13)),
        Text('48hr processing', style: S.caption),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(amount, style: S.body.copyWith(fontWeight: FontWeight.w700)),
        StatusChip(label: status, color: color),
      ]),
    ]));
  }

  // ── BOTTOM NAV ──
  Widget _buildNav() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Orders'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Earnings'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: C.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final sel = _tab == i;
              return GestureDetector(
                onTap: () => setState(() => _tab = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: sel ? C.orangeSurface : Colors.transparent,
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i]['icon'] as IconData, color: sel ? C.orange : C.textTer, size: 24),
                    const SizedBox(height: 3),
                    Text(items[i]['label'] as String, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? C.orange : C.textTer)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
