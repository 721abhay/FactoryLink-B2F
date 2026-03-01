import 'package:flutter/material.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _orderUpdates = true;
  bool _promos = false;
  bool _zoneAlerts = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Settings'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Appearance
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('APPEARANCE', style: S.label)),
          AppCard(padding: EdgeInsets.zero, child: Column(children: [
            _toggleItem(Icons.dark_mode_rounded, 'Dark Mode', _darkMode, (v) => setState(() => _darkMode = v), C.blue),
            const Divider(height: 1, indent: 62),
            _navItem(Icons.language_rounded, 'Language', _language, C.orange),
            const Divider(height: 1, indent: 62),
            _navItem(Icons.text_fields_rounded, 'Font Size', 'Medium', C.green),
          ])),
          const SizedBox(height: 20),

          // Notifications
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('NOTIFICATIONS', style: S.label)),
          AppCard(padding: EdgeInsets.zero, child: Column(children: [
            _toggleItem(Icons.notifications_rounded, 'Push Notifications', _notifications, (v) => setState(() => _notifications = v), C.blue),
            const Divider(height: 1, indent: 62),
            _toggleItem(Icons.local_shipping_rounded, 'Order Updates', _orderUpdates, (v) => setState(() => _orderUpdates = v), C.green),
            const Divider(height: 1, indent: 62),
            _toggleItem(Icons.campaign_rounded, 'Promotions', _promos, (v) => setState(() => _promos = v), C.orange),
            const Divider(height: 1, indent: 62),
            _toggleItem(Icons.location_on_rounded, 'Zone Alerts', _zoneAlerts, (v) => setState(() => _zoneAlerts = v), C.yellow),
          ])),
          const SizedBox(height: 20),

          // Privacy
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('PRIVACY & SECURITY', style: S.label)),
          AppCard(padding: EdgeInsets.zero, child: Column(children: [
            _navItem(Icons.lock_rounded, 'Change PIN', '', C.blue),
            const Divider(height: 1, indent: 62),
            _navItem(Icons.fingerprint_rounded, 'Biometric Login', 'Enabled', C.green),
            const Divider(height: 1, indent: 62),
            _navItem(Icons.security_rounded, 'Two-Factor Auth', 'On', C.orange),
          ])),
          const SizedBox(height: 20),

          // Data
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('DATA', style: S.label)),
          AppCard(padding: EdgeInsets.zero, child: Column(children: [
            _navItem(Icons.download_rounded, 'Download My Data', '', C.blue),
            const Divider(height: 1, indent: 62),
            _navItem(Icons.delete_outline_rounded, 'Delete Account', '', C.red),
          ])),
          const SizedBox(height: 20),

          // About
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('ABOUT', style: S.label)),
          AppCard(padding: EdgeInsets.zero, child: Column(children: [
            _navItem(Icons.info_rounded, 'App Version', '0.1.0', C.textSec),
            const Divider(height: 1, indent: 62),
            _navItem(Icons.description_rounded, 'Terms of Service', '', C.textSec),
            const Divider(height: 1, indent: 62),
            _navItem(Icons.privacy_tip_rounded, 'Privacy Policy', '', C.textSec),
            const Divider(height: 1, indent: 62),
            _navItem(Icons.gavel_rounded, 'Licenses', '', C.textSec),
          ])),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _toggleItem(IconData icon, String label, bool value, ValueChanged<bool> onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: S.body.copyWith(fontWeight: FontWeight.w500))),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: C.blue),
      ]),
    );
  }

  Widget _navItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: color.withValues(alpha: 0.1)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: S.body.copyWith(fontWeight: FontWeight.w500))),
        if (value.isNotEmpty) Text(value, style: S.bodySmall),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, color: C.textTer, size: 20),
      ]),
    );
  }
}
