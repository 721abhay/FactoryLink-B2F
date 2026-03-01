import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

class TrustScoreScreen extends StatelessWidget {
  const TrustScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Trust Score'), backgroundColor: C.bg, elevation: 0, scrolledUnderElevation: 0.5),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.green, Color(0xFF16A34A)]),
              boxShadow: [BoxShadow(color: C.green.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(children: [
              const Text('Your Trust Score', style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 12),
              // Circular score
              SizedBox(
                width: 120, height: 120,
                child: CustomPaint(
                  painter: _ScorePainter(0.86),
                  child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('4.3', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('out of 5.0', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ])),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: 0.2)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('VERIFIED FACTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Breakdown
          const SectionHeader(title: 'Score Breakdown'),
          _scoreItem('Product Quality', 4.5, C.green, Icons.star_rounded, '+0.2 this month'),
          _scoreItem('On-time Delivery', 4.6, C.blue, Icons.schedule_rounded, 'Consistent'),
          _scoreItem('Communication', 3.9, C.yellow, Icons.chat_rounded, '-0.1 this month'),
          _scoreItem('Packaging', 4.4, C.green, Icons.inventory_2_rounded, '+0.1 this month'),
          _scoreItem('Response Rate', 4.0, C.orange, Icons.reply_rounded, 'Needs improvement'),
          const SizedBox(height: 16),

          // Recent Reviews
          const SectionHeader(title: 'Recent Reviews'),
          _review('Rahul S.', 5, 'Excellent quality T-shirts! Fabric is very soft and colors are vibrant. Will order again.', '2 days ago'),
          _review('Priya M.', 4, 'Good quality soap but packaging could be better for bulk orders.', '5 days ago'),
          _review('Amit K.', 4, 'Rice quality is consistent. Delivery was a day late though.', '1 week ago'),
          const SizedBox(height: 16),

          // Tips
          const SectionHeader(title: 'Improve Your Score'),
          AppCard(child: Column(children: [
            _tip(Icons.timer_rounded, 'Respond within 2 hours', 'Improve response rate by replying faster', C.orange),
            const Divider(height: 20),
            _tip(Icons.inventory_2_rounded, 'Better packaging', 'Use eco-friendly, padded packaging', C.blue),
            const Divider(height: 20),
            _tip(Icons.local_shipping_rounded, 'Ship on time', 'Maintain your streak of on-time delivery', C.green),
          ])),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, double score, Color color, IconData icon, String trend) {
    return AppCard(child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withValues(alpha: 0.1)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: S.h4.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: score / 5, backgroundColor: C.border, valueColor: AlwaysStoppedAnimation(color), minHeight: 5),
        ),
        const SizedBox(height: 4),
        Text(trend, style: S.caption),
      ])),
      const SizedBox(width: 12),
      Text('${score}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
    ]));
  }

  Widget _review(String name, int stars, String text, String time) {
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: C.blueSurface),
          child: Center(child: Text(name[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.blue))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: S.h4.copyWith(fontSize: 13)),
          Text(time, style: S.caption),
        ])),
        Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < stars ? C.yellow : C.border))),
      ]),
      const SizedBox(height: 8),
      Text(text, style: S.body.copyWith(fontSize: 13, color: C.textSec)),
    ]));
  }

  Widget _tip(IconData icon, String title, String sub, Color color) {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withValues(alpha: 0.1)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: S.h4.copyWith(fontSize: 13)),
        Text(sub, style: S.caption),
      ])),
    ]);
  }
}

class _ScorePainter extends CustomPainter {
  final double progress;
  _ScorePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    final fgPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi, false, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
