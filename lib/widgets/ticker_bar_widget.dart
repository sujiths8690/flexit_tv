// lib/widgets/ticker_bar_widget.dart
//
// An infinite horizontal scrolling ticker bar showing promotional messages.
// Similar to a stock ticker — always in motion.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TickerBarWidget extends StatefulWidget {
  final CategoryTheme catTheme;

  const TickerBarWidget({super.key, required this.catTheme});

  @override
  State<TickerBarWidget> createState() => _TickerBarWidgetState();
}

class _TickerBarWidgetState extends State<TickerBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late ScrollController _scrollCtrl;

  static const List<String> _messages = [
    '🌟  Today\'s Special — Get 15% off on all starred items',
    '🍽️  Fresh ingredients prepared daily by our expert chefs',
    '✨  Use our app to customize your experience',
    '🎉  Family combos available — ask our staff for details',
    '🌿  All vegetarian dishes prepared in a separate kitchen',
    '🏆  Award-winning flavors since 2010',
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _ctrl.addListener(_onTick);
  }

  double _offset = 0;

  void _onTick() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    _offset = _ctrl.value * max;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.jumpTo(_offset);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: widget.catTheme.primary.withOpacity(0.12),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: widget.catTheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Label tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            color: widget.catTheme.primary.withOpacity(0.2),
            child: Text(
              'TODAY',
              style: TextStyle(
                fontFamily: GoogleFonts.nunito().fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: widget.catTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Scrolling messages
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: List.generate(
                  _messages.length * 3, // repeat for infinite feel
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          _messages[i % _messages.length],
                          style: TextStyle(
                            fontFamily: GoogleFonts.nunito().fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.whiteDim,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.catTheme.primary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
