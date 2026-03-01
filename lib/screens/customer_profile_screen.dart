import 'package:flutter/material.dart';
import '../theme.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'chat_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: C.blue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.blue, C.blueLight])),
                child: SafeArea(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Center(child: Text('AS', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white))),
                    ),
                    const SizedBox(height: 12),
                    const Text('Abhay Singh', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('+91 98765 43210', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                  ],
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
                    child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Stats
                Row(children: [
                  _stat('Total Orders', '24'),
                  const SizedBox(width: 12),
                  _stat('Total Savings', '₹4,850'),
                  const SizedBox(width: 12),
                  _stat('Zone', 'B'),
                ]),
                const SizedBox(height: 24),

                // Menu items
                _menuSection('Account', [
                  _menuItem(Icons.person_rounded, 'Edit Profile', C.blue),
                  _menuItem(Icons.location_on_rounded, 'My Addresses', C.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()))),
                  _menuItem(Icons.place_rounded, 'Anchor Points', C.green),
                ]),
                _menuSection('Orders & Payments', [
                  _menuItem(Icons.inventory_2_rounded, 'Order History', C.blue),
                  _menuItem(Icons.payment_rounded, 'Payment Methods', C.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
                  _menuItem(Icons.receipt_long_rounded, 'Invoices', C.textSec),
                ]),
                _menuSection('Preferences', [
                  _menuItem(Icons.notifications_rounded, 'Notifications', C.yellow),
                  _menuItem(Icons.language_rounded, 'Language', C.blue),
                  _menuItem(Icons.dark_mode_rounded, 'Dark Mode', C.dark2),
                ]),
                _menuSection('Support', [
                  _menuItem(Icons.help_rounded, 'Help & FAQ', C.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
                  _menuItem(Icons.chat_rounded, 'Contact Support', C.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                  _menuItem(Icons.info_rounded, 'About FactoryLink', C.textSec),
                ]),
                const SizedBox(height: 12),
                AppBtn(text: 'Log Out', onTap: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }, color: C.red, outline: true, icon: Icons.logout_rounded),
                const SizedBox(height: 8),
                Text('FactoryLink v0.1.0', style: S.caption),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Text(value, style: S.h2.copyWith(fontSize: 20, color: C.blue)),
        const SizedBox(height: 2),
        Text(label, style: S.caption),
      ]),
    ));
  }

  Widget _menuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: S.label)),
        AppCard(padding: EdgeInsets.zero, child: Column(children: items)),
        const SizedBox(height: 16),
      ],
    );
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
