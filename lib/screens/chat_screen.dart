import 'package:flutter/material.dart';
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = [
    {'text': 'Hi Abhay! How can we help you today?', 'me': false, 'time': '10:00 AM'},
    {'text': 'When will the Basmati Rice group order close?', 'me': true, 'time': '10:05 AM'},
    {'text': 'The group order needs 3 more participants or will auto-close in 2 hours and 11 minutes. Whichever happens first!', 'me': false, 'time': '10:06 AM'},
  ];

  void _send() {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _msgs.add({'text': _ctrl.text.trim(), 'me': true, 'time': 'Now'});
      _ctrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
    // Auto reply
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _msgs.add({'text': 'Thank you! We have noted your request and our team will check.', 'me': false, 'time': 'Now'}));
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: C.blueSurface, border: Border.all(color: C.blue.withValues(alpha: 0.3))),
            child: const Icon(Icons.support_agent_rounded, color: C.blue, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FactoryLink Support', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text('Typically replies in 5 mins', style: TextStyle(fontSize: 11, color: C.textSec)),
          ]),
        ]),
        backgroundColor: C.surface, elevation: 1, scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.all(20),
          itemCount: _msgs.length,
          itemBuilder: (_, i) {
            final m = _msgs[_msgs.length - 1 - i];
            final me = m['me'] as bool;
            return Align(
              alignment: me ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: me ? C.blue : C.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(me ? 16 : 4), bottomRight: Radius.circular(me ? 4 : 16),
                  ),
                  border: me ? null : Border.all(color: C.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                  Text(m['text'] as String, style: TextStyle(fontSize: 14, color: me ? Colors.white : C.text, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(m['time'] as String, style: TextStyle(fontSize: 10, color: me ? Colors.white70 : C.textTer)),
                ]),
              ),
            );
          },
        )),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(color: C.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3))]),
          child: SafeArea(child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: C.surfaceAlt, border: Border.all(color: C.border)),
              child: const Icon(Icons.attach_file_rounded, color: C.textSec, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: C.surfaceAlt, border: Border.all(color: C.border)),
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: 'Type a message...', hintStyle: TextStyle(fontSize: 14, color: C.textTer),
                  border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            )),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: C.blue),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ])),
        ),
      ]),
    );
  }
}
