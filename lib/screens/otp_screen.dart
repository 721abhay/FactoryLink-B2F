import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';

class OtpScreen extends StatefulWidget {
  final String userType;
  const OtpScreen({super.key, required this.userType});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _phoneCtrl = TextEditingController();
  bool _phoneDone = false;
  bool _otpSent = false;
  final List<TextEditingController> _otpCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());
  int _timer = 0;
  Timer? _countdownTimer;

  Color get _accent => widget.userType == 'customer' ? C.blue : C.orange;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (var c in _otpCtrls) c.dispose();
    for (var f in _otpFocus) f.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _sendOtp() {
    setState(() { _otpSent = true; _timer = 30; });
    _otpFocus[0].requestFocus();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timer <= 0) { t.cancel(); } else { setState(() => _timer--); }
    });
  }

  void _onOtpChanged(int i, String val) {
    if (val.isNotEmpty && i < 5) _otpFocus[i + 1].requestFocus();
    if (val.isEmpty && i > 0) _otpFocus[i - 1].requestFocus();
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length == 6) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _RegistrationRouter(userType: widget.userType),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.userType == 'customer';
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: C.text), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _accent.withValues(alpha: 0.1)),
              child: Icon(Icons.phone_android_rounded, color: _accent, size: 28),
            ),
            const SizedBox(height: 24),
            Text(_otpSent ? 'Verify OTP' : 'Enter your\nphone number', style: S.h1),
            const SizedBox(height: 8),
            Text(
              _otpSent ? 'Code sent to +91 ${_phoneCtrl.text}' : 'We\'ll send you a verification code via SMS',
              style: S.body.copyWith(color: C.textSec),
            ),
            const SizedBox(height: 32),

            if (!_otpSent) ...[
              // Phone Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14), color: C.surface,
                  border: Border.all(color: C.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    const Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: C.textTer, size: 20),
                    Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 12), color: C.border),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Phone number', hintStyle: TextStyle(color: C.textTer),
                          border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 18),
                        ),
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1),
                        onChanged: (v) => setState(() => _phoneDone = v.length == 10),
                      ),
                    ),
                    if (_phoneDone) Icon(Icons.check_circle_rounded, color: C.green, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppBtn(text: 'Send OTP', onTap: _phoneDone ? _sendOtp : () {}, color: _phoneDone ? _accent : C.textTer),
            ] else ...[
              // OTP Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => SizedBox(
                  width: 48, height: 56,
                  child: TextField(
                    controller: _otpCtrls[i],
                    focusNode: _otpFocus[i],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _accent),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      filled: true, fillColor: C.surface,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 2)),
                    ),
                    onChanged: (v) => _onOtpChanged(i, v),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              Center(
                child: _timer > 0
                    ? Text('Resend in ${_timer}s', style: S.bodySmall)
                    : GestureDetector(
                        onTap: _sendOtp,
                        child: Text('Resend OTP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _accent)),
                      ),
              ),
            ],
            const SizedBox(height: 40),
            // Benefit cards
            _benefitRow(
              isCustomer ? Icons.savings_rounded : Icons.inventory_2_rounded,
              isCustomer ? 'Save 35-50%' : 'Guaranteed Orders',
              isCustomer ? 'Buy directly from factories' : 'Monthly bulk orders from customers',
            ),
            const SizedBox(height: 12),
            _benefitRow(
              isCustomer ? Icons.verified_rounded : Icons.payments_rounded,
              isCustomer ? 'Quality Verified' : '48hr Payment',
              isCustomer ? 'All factories are quality checked' : 'Get paid within 48 hours of delivery',
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitRow(IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _accent.withValues(alpha: 0.08)),
          child: Icon(icon, color: _accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: S.h4.copyWith(fontSize: 14)),
              Text(sub, style: S.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegistrationRouter extends StatelessWidget {
  final String userType;
  const _RegistrationRouter({required this.userType});

  @override
  Widget build(BuildContext context) {
    // Lazy import to avoid circular deps — actual screens imported in main.dart
    if (userType == 'customer') {
      return _CustomerRegPlaceholder();
    }
    return _FactoryRegPlaceholder();
  }
}

class _CustomerRegPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Loading...')));
}

class _FactoryRegPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Loading...')));
}
