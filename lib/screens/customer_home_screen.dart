import 'package:flutter/material.dart';
import '../theme.dart';
import 'product_detail_screen.dart';
import 'order_tracking_screen.dart';
import 'customer_profile_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});
  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _tab = 0;

  final _products = [
    {'name': 'Premium Cotton T-Shirt', 'factory': 'Tirupur Textiles', 'price': 199, 'retail': 499, 'save': 60, 'orders': 18, 'min': 25, 'time': '4h 23m', 'cat': 'Clothing', 'icon': Icons.checkroom_rounded, 'score': 4.3},
    {'name': 'Basmati Rice 5kg', 'factory': 'Pune Rice Mill', 'price': 285, 'retail': 450, 'save': 37, 'orders': 22, 'min': 30, 'time': '2h 11m', 'cat': 'Groceries', 'icon': Icons.rice_bowl_rounded, 'score': 4.6},
    {'name': 'Cold Pressed Oil 1L', 'factory': 'Village Oil Works', 'price': 180, 'retail': 320, 'save': 44, 'orders': 14, 'min': 20, 'time': '8h 45m', 'cat': 'Groceries', 'icon': Icons.water_drop_rounded, 'score': 4.1},
    {'name': 'Handloom Bedsheet Set', 'factory': 'Panipat Weavers', 'price': 450, 'retail': 999, 'save': 55, 'orders': 9, 'min': 15, 'time': '12h 30m', 'cat': 'Home', 'icon': Icons.bed_rounded, 'score': 4.5},
    {'name': 'Natural Soap Pack (6)', 'factory': 'Herbal Factory', 'price': 120, 'retail': 240, 'save': 50, 'orders': 20, 'min': 25, 'time': '1h 05m', 'cat': 'Personal Care', 'icon': Icons.soap_rounded, 'score': 4.2},
    {'name': 'Steel Lunch Box', 'factory': 'Wazirpur Steel', 'price': 350, 'retail': 650, 'save': 46, 'orders': 7, 'min': 20, 'time': '18h 12m', 'cat': 'Kitchen', 'icon': Icons.lunch_dining_rounded, 'score': 4.4},
  ];

  final _orders = [
    {'name': 'Cotton T-Shirt Pack', 'status': 'In Production', 'color': C.yellow, 'date': 'Arriving Mar 5', 'qty': 2},
    {'name': 'Basmati Rice 5kg', 'status': 'At Anchor Point', 'color': C.green, 'date': 'Ready to collect', 'qty': 1},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: [_buildHome(), _buildOrders(), _buildSubscriptions(), _buildProfile()][_tab],
      bottomNavigationBar: _buildNav(),
    );
  }

  // ── HOME TAB ──
  Widget _buildHome() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true, backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('FactoryLink', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.blue)),
                  const Spacer(),
                  _iconBtn(Icons.search_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
                  const SizedBox(width: 8),
                  _iconBtn(Icons.notifications_none_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                ],
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(32),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, color: C.blue, size: 16),
                const SizedBox(width: 4),
                Text('Sector 14, Gurugram', style: S.bodySmall.copyWith(color: C.textSec)),
                const Icon(Icons.keyboard_arrow_down_rounded, color: C.textSec, size: 18),
                const Spacer(),
                StatusChip(label: 'Zone B · Healthy', color: C.green, icon: Icons.circle),
              ]),
            ),
          ),
        ),

        SliverToBoxAdapter(child: _buildZoneBanner()),
        SliverToBoxAdapter(child: _buildCategories()),

        // Active Orders
        if (_orders.isNotEmpty) ...[
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SectionHeader(title: 'Active Orders', action: 'View All', onAction: () => setState(() => _tab = 1)),
          )),
          SliverToBoxAdapter(child: SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _orders.length,
              itemBuilder: (_, i) => _buildActiveOrder(_orders[i]),
            ),
          )),
        ],

        // Products
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: SectionHeader(title: 'Group Orders Near You', action: 'Filter'),
        )),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _buildProductCard(_products[i], i),
            childCount: _products.length,
          )),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildZoneBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [C.blue, C.blueLight]),
        boxShadow: [BoxShadow(color: C.blue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎉  Your zone is filling up!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 6),
              Text('3 orders close to unlocking. Join now!', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.72,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text('18 of 25 orders filled', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
            ],
          )),
          const SizedBox(width: 12),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
            child: const Center(child: Text('72%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final cats = [
      {'icon': Icons.checkroom_rounded, 'label': 'Clothing'},
      {'icon': Icons.rice_bowl_rounded, 'label': 'Groceries'},
      {'icon': Icons.bed_rounded, 'label': 'Home'},
      {'icon': Icons.soap_rounded, 'label': 'Care'},
      {'icon': Icons.lunch_dining_rounded, 'label': 'Kitchen'},
    ];
    return SizedBox(
      height: 82,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: i == 0 ? C.blueSurface : C.surfaceAlt, border: Border.all(color: i == 0 ? C.blue.withValues(alpha: 0.3) : C.border)),
                child: Icon(cats[i]['icon'] as IconData, color: i == 0 ? C.blue : C.textSec, size: 24),
              ),
              const SizedBox(height: 6),
              Text(cats[i]['label'] as String, style: TextStyle(fontSize: 11, fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400, color: i == 0 ? C.blue : C.textSec)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrder(Map<String, dynamic> o) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14), color: C.surface,
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Expanded(child: Text(o['name'] as String, style: S.h4.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            StatusChip(label: o['status'] as String, color: o['color'] as Color),
          ]),
          const SizedBox(height: 8),
          Text(o['date'] as String, style: S.caption),
          Text('Qty: ${o['qty']}', style: S.bodySmall),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p, int i) {
    final progress = (p['orders'] as int) / (p['min'] as int);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Product image placeholder
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14), color: C.surfaceAlt,
                    border: Border.all(color: C.border),
                  ),
                  child: Icon(p['icon'] as IconData, color: C.textTer, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] as String, style: S.h4.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.factory_rounded, size: 12, color: C.textTer),
                      const SizedBox(width: 4),
                      Text(p['factory'] as String, style: S.caption),
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded, size: 12, color: C.yellow),
                      Text(' ${p['score']}', style: S.caption.copyWith(fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('₹${p['price']}', style: S.price.copyWith(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('₹${p['retail']}', style: S.priceCut),
                      const SizedBox(width: 8),
                      StatusChip(label: '${p['save']}% OFF', color: C.green),
                    ]),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 12),
            // Zone progress + Timer
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: C.border,
                        valueColor: AlwaysStoppedAnimation(progress > 0.8 ? C.green : C.blue),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${p['orders']} of ${p['min']} orders', style: S.caption),
                  ],
                )),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: C.yellowLight),
                  child: Row(children: [
                    const Icon(Icons.timer_rounded, size: 14, color: C.yellow),
                    const SizedBox(width: 4),
                    Text(p['time'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.yellow)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── ORDERS TAB ──
  Widget _buildOrders() {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('My Orders'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._orders.map((o) => GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: o))),
            child: AppCard(child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: (o['color'] as Color).withValues(alpha: 0.1)),
                child: Icon(Icons.inventory_2_rounded, color: o['color'] as Color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o['name'] as String, style: S.h4.copyWith(fontSize: 14)),
                  Text(o['date'] as String, style: S.caption),
                ],
              )),
              StatusChip(label: o['status'] as String, color: o['color'] as Color),
            ])),
          )),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Past Orders'),
          _pastOrder('Natural Soap Pack', 'Delivered · Feb 22', 5),
          _pastOrder('Wheat Flour 10kg', 'Delivered · Feb 18', 4),
          _pastOrder('Cotton Kurta Set', 'Delivered · Feb 10', 5),
        ],
      ),
    );
  }

  Widget _pastOrder(String name, String date, int stars) {
    return AppCard(child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.greenLight),
        child: const Icon(Icons.check_circle_rounded, color: C.green, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: S.h4.copyWith(fontSize: 14)),
          Text(date, style: S.caption),
        ],
      )),
      Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 16, color: i < stars ? C.yellow : C.border))),
    ]));
  }

  // ── SUBSCRIPTIONS TAB ──
  Widget _buildSubscriptions() {
    final items = [
      {'name': 'Basmati Rice 5kg', 'freq': 'Monthly', 'price': 285, 'next': 'Mar 5'},
      {'name': 'Wheat Flour 10kg', 'freq': 'Monthly', 'price': 320, 'next': 'Mar 5'},
      {'name': 'Mustard Oil 1L', 'freq': 'Monthly', 'price': 145, 'next': 'Mar 5'},
    ];
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Grocery Subscription'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Savings card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [C.green, Color(0xFF16A34A)]),
            ),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly Savings', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 4),
                  const Text('₹485', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('vs retail prices', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                ],
              )),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                child: const Icon(Icons.savings_rounded, color: Colors.white, size: 24),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Your Monthly Basket', action: 'Edit'),
          ...items.map((item) => AppCard(child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.surfaceAlt),
                child: const Icon(Icons.rice_bowl_rounded, color: C.textSec, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] as String, style: S.h4.copyWith(fontSize: 13)),
                  Text('${item['freq']} · Next: ${item['next']}', style: S.caption),
                ],
              )),
              Text('₹${item['price']}', style: S.price.copyWith(fontSize: 16)),
            ],
          ))),
          const SizedBox(height: 12),
          AppBtn(text: 'Add Item to Basket', onTap: () {}, outline: true, icon: Icons.add_rounded),
        ],
      ),
    );
  }

  Widget _buildProfile() => const CustomerProfileScreen();

  // ── BOTTOM NAV ──
  Widget _buildNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Orders'},
      {'icon': Icons.repeat_rounded, 'label': 'Subscribe'},
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
                    color: sel ? C.blueSurface : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i]['icon'] as IconData, color: sel ? C.blue : C.textTer, size: 24),
                      const SizedBox(height: 3),
                      Text(items[i]['label'] as String, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? C.blue : C.textTer)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.surfaceAlt, border: Border.all(color: C.border)),
        child: Icon(icon, color: C.textSec, size: 20),
      ),
    );
  }
}
