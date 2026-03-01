import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'theme.dart';
import 'screens/otp_screen.dart';
import 'screens/customer_registration_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/factory_registration_screen.dart';
import 'screens/factory_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FactoryLinkApp());
}

class FactoryLinkApp extends StatelessWidget {
  const FactoryLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FactoryLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto', brightness: Brightness.light, scaffoldBackgroundColor: C.bg),
      home: const EntryScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════
// ENTRY SCREEN
// ═══════════════════════════════════════════════════
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});
  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl, _logoCtrl, _contentCtrl, _pulseCtrl, _floatCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0C29),
    ));

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 200), () {
      _logoCtrl.forward().then((_) => _contentCtrl.forward());
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _logoCtrl.dispose(); _contentCtrl.dispose();
    _pulseCtrl.dispose(); _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // Gradient BG
        AnimatedBuilder(animation: _bgCtrl, builder: (_, __) {
          final v = _bgCtrl.value * 2 * math.pi;
          return Container(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment(math.cos(v) * 0.4, -0.8), end: Alignment(math.sin(v) * 0.4, 0.8),
            colors: const [C.dark1, C.dark2, C.dark3, C.dark2], stops: const [0, 0.35, 0.7, 1],
          )));
        }),

        // Orbs
        AnimatedBuilder(animation: Listenable.merge([_floatCtrl, _pulseCtrl]), builder: (_, __) {
          final f = _floatCtrl.value * 2 - 1;
          final p = 0.6 + _pulseCtrl.value * 0.4;
          return Stack(children: [
            _orb(sz, -0.1, 0.06, 0.55, C.blue, 0.18 * p, f * 8),
            _orb(sz, -0.18, 0.7, 0.45, C.orange, 0.10 * p, -f * 6),
            _orb(sz, 0.15, 0.38, 0.22, C.green, 0.12 * p, f * 4),
          ]);
        }),

        // Content
        SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const Spacer(flex: 5),
            _buildLogo(),
            const Spacer(flex: 5),
            _buildButtons(context),
            const Spacer(flex: 1),
            _buildFooter(),
            const SizedBox(height: 20),
          ]),
        )),
      ]),
    );
  }

  Widget _orb(Size sz, double x, double y, double r, Color c, double a, double dy) {
    return Positioned(left: sz.width * x, top: sz.height * y,
      child: Transform.translate(offset: Offset(0, dy),
        child: Container(width: sz.width * r, height: sz.width * r,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withValues(alpha: a), Colors.transparent])))));
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoCtrl, _floatCtrl, _pulseCtrl]),
      builder: (_, __) {
        final progress = _logoCtrl.value;
        final scale = progress < 0.5
            ? Curves.easeOut.transform(progress * 2) * 1.15
            : 1.0 + 0.15 * (1 - Curves.easeInOut.transform((progress - 0.5) * 2));
        final opacity = (progress * 3).clamp(0.0, 1.0);
        final tagOp = ((progress - 0.6) * 4).clamp(0.0, 1.0);
        final floatY = (_floatCtrl.value * 2 - 1) * 4;
        final pulse = 0.7 + _pulseCtrl.value * 0.3;

        return Opacity(opacity: opacity, child: Transform.translate(
          offset: Offset(0, floatY), child: Transform.scale(scale: scale,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.blue, C.blueLight]),
                boxShadow: [BoxShadow(color: C.blue.withValues(alpha: 0.5 * pulse), blurRadius: 28 * pulse, spreadRadius: 1)],
              ),
              child: Stack(alignment: Alignment.center, children: [
                ClipRRect(borderRadius: BorderRadius.circular(26), child: Opacity(opacity: 0.15,
                  child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment(-1 + _bgCtrl.value * 3, -1), end: Alignment(_bgCtrl.value * 3, 1),
                    colors: const [Colors.transparent, Colors.white, Colors.transparent], stops: const [0.3, 0.5, 0.7]))))),
                const Icon(Icons.precision_manufacturing_rounded, color: Colors.white, size: 42),
              ]),
            ),
            const SizedBox(height: 22),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [Colors.white, Color(0xFFB4C6FF)]).createShader(b),
              child: const Text('FactoryLink', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5, height: 1.1)),
            ),
            const SizedBox(height: 10),
            Opacity(opacity: tagOp, child: const Text(
              'Factory Direct  ·  Group Smart  ·  Save Big',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3BF), letterSpacing: 0.8),
            )),
          ]))));
      },
    );
  }

  Widget _buildButtons(BuildContext context) {
    return AnimatedBuilder(animation: _contentCtrl, builder: (_, __) {
      final p = _contentCtrl.value;
      final labelOp = (p * 3).clamp(0.0, 1.0);
      final btn1Op = ((p - 0.1) * 3).clamp(0.0, 1.0);
      final btn1S = 40 * (1 - Curves.easeOutCubic.transform((p * 1.3).clamp(0.0, 1.0)));
      final btn2Op = ((p - 0.25) * 3).clamp(0.0, 1.0);
      final btn2S = 40 * (1 - Curves.easeOutCubic.transform(((p - 0.1) * 1.3).clamp(0.0, 1.0)));

      return Column(children: [
        Opacity(opacity: labelOp, child: const Text('GET STARTED AS',
          style: TextStyle(fontSize: 12, color: Color(0xFF7C82A1), letterSpacing: 2.5, fontWeight: FontWeight.w500))),
        const SizedBox(height: 22),
        Opacity(opacity: btn1Op, child: Transform.translate(offset: Offset(0, btn1S),
          child: _GlassBtn(icon: Icons.shopping_bag_rounded, title: 'CUSTOMER',
            sub: 'Buy at factory prices · Save 35-50%', colors: const [C.blue, C.blueLight],
            glow: C.blue, pulse: _pulseCtrl, onTap: () => _go(context, 'customer')))),
        const SizedBox(height: 14),
        Opacity(opacity: btn2Op, child: Transform.translate(offset: Offset(0, btn2S),
          child: _GlassBtn(icon: Icons.factory_rounded, title: 'FACTORY',
            sub: 'Get guaranteed orders · Fast payment', colors: const [C.orange, C.orangeLight],
            glow: C.orange, pulse: _pulseCtrl, onTap: () => _go(context, 'factory')))),
      ]);
    });
  }

  Widget _buildFooter() {
    return AnimatedBuilder(animation: _contentCtrl, builder: (_, __) {
      final op = ((_contentCtrl.value - 0.5) * 2.5).clamp(0.0, 1.0);
      return Opacity(opacity: op, child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _chip(Icons.verified_rounded, '100% Verified'),
          const SizedBox(width: 10),
          _chip(Icons.lock_rounded, 'Secure Payments'),
        ]),
        const SizedBox(height: 14),
        const Text('No middlemen · Direct from factory to you', style: TextStyle(fontSize: 11.5, color: Color(0xFF4A4E6A))),
      ]));
    });
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: C.blue, size: 13),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8B90B0), fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _go(BuildContext ctx, String type) {
    Navigator.push(ctx, PageRouteBuilder(
      pageBuilder: (_, __, ___) => FullOtpScreen(userType: type),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c)),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }
}

// ═══════════════════════════════════════════════════
// GLASS BUTTON
// ═══════════════════════════════════════════════════
class _GlassBtn extends StatefulWidget {
  final IconData icon; final String title, sub;
  final List<Color> colors; final Color glow;
  final AnimationController pulse; final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.title, required this.sub,
    required this.colors, required this.glow, required this.pulse, required this.onTap});
  @override State<_GlassBtn> createState() => _GlassBtnState();
}

class _GlassBtnState extends State<_GlassBtn> with SingleTickerProviderStateMixin {
  late AnimationController _press;
  @override void initState() { super.initState(); _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 150)); }
  @override void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: Listenable.merge([widget.pulse, _press]), builder: (_, __) {
      final p = 0.65 + widget.pulse.value * 0.35;
      return Transform.scale(scale: 1.0 - _press.value * 0.03, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: widget.glow.withValues(alpha: 0.22 * p), blurRadius: 28, offset: const Offset(0, 10))]),
        child: GestureDetector(
          onTapDown: (_) => _press.forward(),
          onTapUp: (_) { _press.reverse(); widget.onTap(); },
          onTapCancel: () => _press.reverse(),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.04)]),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14))),
            child: Row(children: [
              Container(width: 50, height: 50,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.colors),
                  boxShadow: [BoxShadow(color: widget.colors[0].withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))]),
                child: Icon(widget.icon, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2.5)),
                const SizedBox(height: 3),
                Text(widget.sub, style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.55))),
              ])),
              Container(width: 34, height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.6), size: 17)),
            ]),
          ),
        ),
      ));
    });
  }
}

// ═══════════════════════════════════════════════════
// FULL OTP SCREEN (navigates to registration)
// ═══════════════════════════════════════════════════
class FullOtpScreen extends StatefulWidget {
  final String userType;
  const FullOtpScreen({super.key, required this.userType});
  @override State<FullOtpScreen> createState() => _FullOtpScreenState();
}

class _FullOtpScreenState extends State<FullOtpScreen> {
  final _phoneCtrl = TextEditingController();
  bool _phoneDone = false;
  bool _otpSent = false;
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());
  int _timer = 0;

  Color get _accent => widget.userType == 'customer' ? C.blue : C.orange;

  void _sendOtp() {
    setState(() { _otpSent = true; _timer = 30; });
    _otpFocus[0].requestFocus();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_timer > 0) { setState(() => _timer--); _tick(); }
    });
  }

  void _onOtp(int i, String v) {
    if (v.isNotEmpty && i < 5) _otpFocus[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _otpFocus[i - 1].requestFocus();
    if (_otpCtrls.every((c) => c.text.isNotEmpty)) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => widget.userType == 'customer'
            ? const CustomerRegistrationScreen()
            : const FactoryRegistrationScreen(),
      ));
    }
  }

  @override void dispose() {
    _phoneCtrl.dispose();
    for (var c in _otpCtrls) c.dispose();
    for (var f in _otpFocus) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCust = widget.userType == 'customer';
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: C.text), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          Container(width: 56, height: 56,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _accent.withValues(alpha: 0.1)),
            child: Icon(Icons.phone_android_rounded, color: _accent, size: 28)),
          const SizedBox(height: 24),
          Text(_otpSent ? 'Verify OTP' : 'Enter your\nphone number',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: C.text, height: 1.2)),
          const SizedBox(height: 8),
          Text(_otpSent ? 'Code sent to +91 ${_phoneCtrl.text}' : 'We\'ll send you a verification code',
            style: const TextStyle(fontSize: 14, color: C.textSec)),
          const SizedBox(height: 32),

          if (!_otpSent) ...[
            Container(padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: C.surface,
                border: Border.all(color: C.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))]),
              child: Row(children: [
                const Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: C.textTer, size: 20),
                Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 12), color: C.border),
                Expanded(child: TextField(controller: _phoneCtrl,
                  decoration: const InputDecoration(hintText: 'Phone number', hintStyle: TextStyle(color: C.textTer),
                    border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 18)),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1),
                  onChanged: (v) => setState(() => _phoneDone = v.length == 10))),
                if (_phoneDone) const Icon(Icons.check_circle_rounded, color: C.green, size: 22),
              ])),
            const SizedBox(height: 24),
            AppBtn(text: 'Send OTP', onTap: _phoneDone ? _sendOtp : () {}, color: _phoneDone ? _accent : C.textTer),
          ] else ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => SizedBox(width: 48, height: 56,
                child: TextField(controller: _otpCtrls[i], focusNode: _otpFocus[i],
                  textAlign: TextAlign.center, maxLength: 1, keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _accent),
                  decoration: InputDecoration(counterText: '', contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: true, fillColor: C.surface,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 2))),
                  onChanged: (v) => _onOtp(i, v))))),
            const SizedBox(height: 24),
            Center(child: _timer > 0
              ? Text('Resend in ${_timer}s', style: const TextStyle(fontSize: 13, color: C.textSec))
              : GestureDetector(onTap: _sendOtp,
                  child: Text('Resend OTP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _accent)))),
          ],
          const SizedBox(height: 40),
          _ben(isCust ? Icons.savings_rounded : Icons.inventory_2_rounded,
            isCust ? 'Save 35-50%' : 'Guaranteed Orders',
            isCust ? 'Buy directly from factories' : 'Monthly bulk orders from customers'),
          const SizedBox(height: 12),
          _ben(isCust ? Icons.verified_rounded : Icons.payments_rounded,
            isCust ? 'Quality Verified' : '48hr Payment',
            isCust ? 'All factories are quality checked' : 'Fast payment to your bank'),
        ]),
      ),
    );
  }

  Widget _ben(IconData icon, String title, String sub) {
    return Row(children: [
      Container(width: 42, height: 42,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _accent.withValues(alpha: 0.08)),
        child: Icon(icon, color: _accent, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
        Text(sub, style: const TextStyle(fontSize: 11, color: C.textTer)),
      ])),
    ]);
  }
}
