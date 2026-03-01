import 'package:flutter/material.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════
class C {
  static const blue = Color(0xFF4A6CF7);
  static const blueLight = Color(0xFF6B8AFF);
  static const blueDark = Color(0xFF3451DB);
  static const blueSurface = Color(0xFFEEF2FF);
  static const orange = Color(0xFFE8613C);
  static const orangeLight = Color(0xFFFF7F5C);
  static const orangeSurface = Color(0xFFFFF1ED);
  static const green = Color(0xFF22C55E);
  static const greenLight = Color(0xFFDCFCE7);
  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEE2E2);
  static const yellow = Color(0xFFF59E0B);
  static const yellowLight = Color(0xFFFEF3C7);
  static const bg = Color(0xFFF5F7FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F3FF);
  static const border = Color(0xFFE5E9F2);
  static const text = Color(0xFF1A1D26);
  static const textSec = Color(0xFF6B7280);
  static const textTer = Color(0xFF9CA3AF);
  static const dark1 = Color(0xFF0F0C29);
  static const dark2 = Color(0xFF1E1B4B);
  static const dark3 = Color(0xFF302B83);
}

// ═══════════════════════════════════════════════════
// TEXT STYLES
// ═══════════════════════════════════════════════════
class S {
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: C.text, height: 1.2);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.text, height: 1.3);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.text, height: 1.3);
  static const h4 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text, height: 1.4);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: C.text, height: 1.5);
  static const bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: C.textSec, height: 1.5);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.textSec, letterSpacing: 0.5);
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: C.textTer);
  static const price = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.blue);
  static const priceCut = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: C.textTer, decoration: TextDecoration.lineThrough);
  static const badge = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.green);
  static const btnText = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white);
}

// ═══════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  const AppCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class AppBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  final bool outline;
  final IconData? icon;
  const AppBtn({super.key, required this.text, required this.onTap, this.color = C.blue, this.outline = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: outline ? Colors.transparent : color,
          foregroundColor: outline ? color : Colors.white,
          elevation: 0,
          side: outline ? BorderSide(color: color, width: 1.5) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(text, style: S.btnText.copyWith(color: outline ? color : Colors.white)),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusChip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: color, size: 13), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: S.h4),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.blue)),
            ),
        ],
      ),
    );
  }
}
