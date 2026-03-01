import 'package:flutter/material.dart';
import '../theme.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _selectedFilter = 0;

  final _filters = ['All', 'Clothing', 'Groceries', 'Home', 'Kitchen', 'Care'];

  final _allProducts = [
    {'name': 'Premium Cotton T-Shirt', 'factory': 'Tirupur Textiles', 'price': 199, 'retail': 499, 'save': 60, 'orders': 18, 'min': 25, 'time': '4h 23m', 'cat': 'Clothing', 'icon': Icons.checkroom_rounded, 'score': 4.3},
    {'name': 'Basmati Rice 5kg', 'factory': 'Pune Rice Mill', 'price': 285, 'retail': 450, 'save': 37, 'orders': 22, 'min': 30, 'time': '2h 11m', 'cat': 'Groceries', 'icon': Icons.rice_bowl_rounded, 'score': 4.6},
    {'name': 'Cold Pressed Oil 1L', 'factory': 'Village Oil Works', 'price': 180, 'retail': 320, 'save': 44, 'orders': 14, 'min': 20, 'time': '8h 45m', 'cat': 'Groceries', 'icon': Icons.water_drop_rounded, 'score': 4.1},
    {'name': 'Handloom Bedsheet Set', 'factory': 'Panipat Weavers', 'price': 450, 'retail': 999, 'save': 55, 'orders': 9, 'min': 15, 'time': '12h 30m', 'cat': 'Home', 'icon': Icons.bed_rounded, 'score': 4.5},
    {'name': 'Natural Soap Pack (6)', 'factory': 'Herbal Factory', 'price': 120, 'retail': 240, 'save': 50, 'orders': 20, 'min': 25, 'time': '1h 05m', 'cat': 'Care', 'icon': Icons.soap_rounded, 'score': 4.2},
    {'name': 'Steel Lunch Box', 'factory': 'Wazirpur Steel', 'price': 350, 'retail': 650, 'save': 46, 'orders': 7, 'min': 20, 'time': '18h 12m', 'cat': 'Kitchen', 'icon': Icons.lunch_dining_rounded, 'score': 4.4},
    {'name': 'Organic Wheat Flour 10kg', 'factory': 'Punjab Grains', 'price': 320, 'retail': 520, 'save': 38, 'orders': 16, 'min': 25, 'time': '6h 30m', 'cat': 'Groceries', 'icon': Icons.bakery_dining_rounded, 'score': 4.3},
    {'name': 'Copper Water Bottle', 'factory': 'Jaipur Crafts', 'price': 280, 'retail': 599, 'save': 53, 'orders': 11, 'min': 15, 'time': '10h 15m', 'cat': 'Kitchen', 'icon': Icons.local_drink_rounded, 'score': 4.7},
  ];

  List<Map<String, dynamic>> get _filtered {
    var list = _allProducts.toList();
    if (_selectedFilter > 0) list = list.where((p) => p['cat'] == _filters[_selectedFilter]).toList();
    if (_query.isNotEmpty) list = list.where((p) => (p['name'] as String).toLowerCase().contains(_query.toLowerCase())).toList();
    return list;
  }

  final _trending = ['Cotton T-Shirts', 'Organic Rice', 'Handloom Sarees', 'Steel Utensils', 'Natural Soaps'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: C.text), onPressed: () => Navigator.pop(context)),
        title: Container(
          height: 44,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.surface, border: Border.all(color: C.border)),
          child: TextField(
            controller: _searchCtrl, autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search products, factories...', hintStyle: TextStyle(fontSize: 14, color: C.textTer),
              prefixIcon: Icon(Icons.search_rounded, color: C.textTer, size: 20),
              border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ),
      body: Column(children: [
        // Filters
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _selectedFilter == i ? C.blue : C.surface,
                    border: Border.all(color: _selectedFilter == i ? C.blue : C.border),
                  ),
                  child: Text(_filters[i], style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: _selectedFilter == i ? Colors.white : C.textSec,
                  )),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Expanded(child: _query.isEmpty && _selectedFilter == 0
          ? _buildSuggestions()
          : _buildResults()),
      ]),
    );
  }

  Widget _buildSuggestions() {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
      const SectionHeader(title: 'Trending Searches'),
      Wrap(spacing: 8, runSpacing: 8, children: _trending.map((t) => GestureDetector(
        onTap: () => setState(() { _query = t; _searchCtrl.text = t; }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: C.surface, border: Border.all(color: C.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.trending_up_rounded, size: 14, color: C.orange),
            const SizedBox(width: 6),
            Text(t, style: S.body.copyWith(fontSize: 13)),
          ]),
        ),
      )).toList()),
      const SizedBox(height: 24),
      const SectionHeader(title: 'Popular Categories'),
      GridView.count(
        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1, crossAxisSpacing: 10, mainAxisSpacing: 10,
        children: [
          _catCard(Icons.checkroom_rounded, 'Clothing', C.blue),
          _catCard(Icons.rice_bowl_rounded, 'Groceries', C.green),
          _catCard(Icons.bed_rounded, 'Home', C.orange),
          _catCard(Icons.soap_rounded, 'Care', C.yellow),
          _catCard(Icons.lunch_dining_rounded, 'Kitchen', C.red),
          _catCard(Icons.hardware_rounded, 'Hardware', C.textSec),
        ],
      ),
    ]);
  }

  Widget _catCard(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = _filters.indexOf(label).clamp(0, _filters.length - 1)),
      child: AppCard(
        padding: const EdgeInsets.all(12), margin: EdgeInsets.zero,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withValues(alpha: 0.1)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: S.caption.copyWith(fontWeight: FontWeight.w600, color: C.text)),
        ]),
      ),
    );
  }

  Widget _buildResults() {
    final results = _filtered;
    if (results.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded, size: 56, color: C.textTer.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        const Text('No products found', style: S.h4),
        Text('Try a different search term', style: S.caption),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final p = results[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.surfaceAlt),
                child: Icon(p['icon'] as IconData, color: C.textTer, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['name'] as String, style: S.h4.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(p['factory'] as String, style: S.caption),
                const SizedBox(height: 4),
                Row(children: [
                  Text('₹${p['price']}', style: S.price.copyWith(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('₹${p['retail']}', style: S.priceCut),
                  const SizedBox(width: 6),
                  StatusChip(label: '${p['save']}% OFF', color: C.green),
                ]),
              ])),
            ]),
          ),
        );
      },
    );
  }
}
