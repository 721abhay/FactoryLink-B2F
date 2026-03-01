import 'package:flutter/material.dart';
import '../theme.dart';
import 'trust_score_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'factory_catalog_screen.dart';
import 'analytics_screen.dart';
import 'chat_screen.dart';

class FactoryProfileScreen extends StatelessWidget {
  const FactoryProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220, pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: C.orange,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.orange, C.orangeLight])),
                child: SafeArea(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.factory_rounded, color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tirupur Textiles Pvt Ltd', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('GST: 33AABCU9603R1ZM', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _headerStat('Orders', '156'),
                      Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.white.withValues(alpha: 0.3)),
                      _headerStat('Rating', '4.3★'),
                      Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.white.withValues(alpha: 0.3)),
                      _headerStat('Trust', 'Verified'),
                    ]),
                  ]),
                )),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
                    child: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Trust Score Card
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrustScoreScreen())),
                child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.shield_rounded, color: C.green, size: 22),
                  const SizedBox(width: 8),
                  const Text('Trust Score', style: S.h4),
                  const Spacer(),
                  const Text('4.3 / 5.0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.green)),
                ]),
                const SizedBox(height: 14),
                _trustBar('Quality', 0.85, C.green),
                _trustBar('Delivery', 0.92, C.blue),
                _trustBar('Communication', 0.78, C.yellow),
                _trustBar('Packaging', 0.88, C.green),
              ])),
              ),
              const SizedBox(height: 12),

              // Menu
              _menuSection('Business', [
                _menuItem(Icons.factory_rounded, 'Factory Details', C.orange),
                _menuItem(Icons.inventory_rounded, 'Product Catalog', C.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FactoryCatalogScreen()))),
                _menuItem(Icons.people_rounded, 'My Team', C.green),
              ]),
              _menuSection('Finance', [
                _menuItem(Icons.account_balance_rounded, 'Bank Account', C.blue),
                _menuItem(Icons.receipt_long_rounded, 'Tax Reports', C.orange),
                _menuItem(Icons.assessment_rounded, 'Analytics', C.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
              ]),
              _menuSection('Support', [
                _menuItem(Icons.help_rounded, 'Help & FAQ', C.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
                _menuItem(Icons.headset_mic_rounded, 'Factory Support', C.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                _menuItem(Icons.info_rounded, 'Terms & Policies', C.textSec),
              ]),
              const SizedBox(height: 12),
              AppBtn(text: 'Log Out', onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                color: C.red, outline: true, icon: Icons.logout_rounded),
              const SizedBox(height: 8),
              Text('FactoryLink v0.1.0 · Factory Edition', style: S.caption),
            ]),
          )),
        ],
      ),
    );
  }

  static Widget _headerStat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
    ]);
  }

  Widget _trustBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: S.bodySmall)),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value, backgroundColor: C.border, valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
        )),
        const SizedBox(width: 10),
        Text('${(value * 100).round()}%', style: S.caption.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _menuSection(String title, List<Widget> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: S.label)),
      AppCard(padding: EdgeInsets.zero, child: Column(children: items)),
      const SizedBox(height: 16),
    ]);
  }

  Widget _menuItem(IconData icon, String label, Color color, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: S.body.copyWith(fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right_rounded, color: C.textTer, size: 20),
        ]),
      ),
    );
  }
}
