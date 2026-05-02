// lib/widgets/mascot_widget.dart
//
// Friendly animated mascot: a warm glowing orb-character with:
//   • Running / bobbing animation across the bottom
//   • Expressive "eyes" that blink and look around
//   • Particle sparkles that trail behind
//   • Occasional "happy jump" when it reaches screen edges

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MascotWidget extends StatefulWidget {
  const MascotWidget({super.key});

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin {
  late AnimationController _runCtrl;    // horizontal movement
  late AnimationController _bobCtrl;    // vertical bob
  late AnimationController _blinkCtrl;  // eye blink
  late AnimationController _glowCtrl;   // body glow pulse
  late AnimationController _jumpCtrl;   // edge jump

  late Animation<double> _bobAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _jumpAnim;
  late Animation<double> _blinkAnim;

  double _xFraction = 0.05;
  bool _facingRight = true;
  final Random _rng = Random();
  final List<_Particle> _particles = [];

  static const double _mascotSize = 80.0;
  static const double _bottomPad = 24.0;

  @override
  void initState() {
    super.initState();

    // Bob (vertical oscillation)
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut),
    );

    // Glow pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Blink
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.05).animate(_blinkCtrl);
    _scheduleBlink();

    // Edge jump
    _jumpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _jumpAnim = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _jumpCtrl, curve: Curves.easeOut),
    );

    // Run across screen
    _runCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // per-frame ticker
    )..addListener(_onTick)..repeat();
  }

  double _speed = 0.0008; // fraction of screen width per frame
  int _frameTick = 0;

  void _onTick() {
    _frameTick++;
    if (!mounted) return;
    setState(() {
      _xFraction += _facingRight ? _speed : -_speed;

      // Spawn particle every few frames
      if (_frameTick % 6 == 0) {
        _spawnParticle();
      }
      // Age particles
      _particles.removeWhere((p) => p.life <= 0);
      for (final p in _particles) {
        p.life -= 0.04;
        p.y -= p.vy;
        p.x += p.vx * (_facingRight ? -1 : 1);
      }

      // Flip at edges + jump
      if (_xFraction >= 0.88) {
        _xFraction = 0.88;
        _flip(toRight: false);
      } else if (_xFraction <= 0.02) {
        _xFraction = 0.02;
        _flip(toRight: true);
      }
    });
  }

  void _flip({required bool toRight}) {
    if (_facingRight == toRight) return; // already correct
    _facingRight = toRight;
    _jumpCtrl.forward(from: 0).then((_) => _jumpCtrl.reverse());
    _speed = 0.0006 + _rng.nextDouble() * 0.0008;
  }

  void _spawnParticle() {
    _particles.add(_Particle(
      x: 0,
      y: 0,
      vx: _rng.nextDouble() * 1.5 + 0.5,
      vy: _rng.nextDouble() * 1.0 + 0.3,
      life: 1.0,
      size: _rng.nextDouble() * 5 + 2,
      color: [AppTheme.gold, AppTheme.goldLight, Colors.white, AppTheme.starAmber][
          _rng.nextInt(4)],
    ));
  }

  void _scheduleBlink() {
    Future.delayed(Duration(seconds: 2 + _rng.nextInt(4)), () {
      if (!mounted) return;
      _blinkCtrl.forward().then((_) {
        _blinkCtrl.reverse().then((_) => _scheduleBlink());
      });
    });
  }

  @override
  void dispose() {
    _runCtrl.dispose();
    _bobCtrl.dispose();
    _glowCtrl.dispose();
    _blinkCtrl.dispose();
    _jumpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final xPos = _xFraction * screenWidth;

    return AnimatedBuilder(
      animation: Listenable.merge([_bobAnim, _glowAnim, _blinkAnim, _jumpAnim]),
      builder: (context, _) {
        final yOffset = -_bobAnim.value + _jumpAnim.value;
        return SizedBox(
          height: _mascotSize + _bottomPad + 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Particles ──────────────────────────────────────────────
              ..._particles.map((p) => Positioned(
                    left: xPos +
                        (_facingRight ? -1 : 1) * (20 + p.x * 4),
                    bottom: _bottomPad + _mascotSize * 0.3 + p.y * 8,
                    child: Opacity(
                      opacity: p.life.clamp(0, 1),
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.color,
                          boxShadow: [
                            BoxShadow(
                              color: p.color.withOpacity(0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),

              // ── Shadow ────────────────────────────────────────────────
              Positioned(
                left: xPos - _mascotSize * 0.35,
                bottom: _bottomPad - 4,
                child: Opacity(
                  opacity: 0.25,
                  child: Container(
                    width: _mascotSize * 0.7,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Mascot body ───────────────────────────────────────────
              Positioned(
                left: xPos - _mascotSize / 2,
                bottom: _bottomPad + yOffset,
                child: Transform.scale(
                  scaleX: _facingRight ? 1 : -1,
                  child: _MascotBody(
                    size: _mascotSize,
                    glowIntensity: _glowAnim.value,
                    blinkScale: _blinkAnim.value,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MascotBody extends StatelessWidget {
  final double size;
  final double glowIntensity;
  final double blinkScale;

  const _MascotBody({
    required this.size,
    required this.glowIntensity,
    required this.blinkScale,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MascotPainter(
          glowIntensity: glowIntensity,
          blinkScale: blinkScale,
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final double glowIntensity;
  final double blinkScale;

  _MascotPainter({required this.glowIntensity, required this.blinkScale});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // ── Outer glow ──────────────────────────────────────────────────────
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.gold.withOpacity(0.35 * glowIntensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.6));
    canvas.drawCircle(Offset(cx, cy), r * 1.6, glowPaint);

    // ── Body gradient ──────────────────────────────────────────────────
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          const Color(0xFFFFF0C0),
          AppTheme.gold,
          const Color(0xFFC8891A),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r * 0.92, bodyPaint);

    // ── Shine highlight ────────────────────────────────────────────────
    final shinePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.55), Colors.transparent],
        radius: 0.5,
      ).createShader(
        Rect.fromCircle(center: Offset(cx - r * 0.28, cy - r * 0.32), radius: r * 0.4),
      );
    canvas.drawCircle(
      Offset(cx - r * 0.28, cy - r * 0.32),
      r * 0.3,
      shinePaint,
    );

    // ── Cheek blush ────────────────────────────────────────────────────
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A65).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - r * 0.38, cy + r * 0.15), width: r * 0.35, height: r * 0.2),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + r * 0.38, cy + r * 0.15), width: r * 0.35, height: r * 0.2),
      blushPaint,
    );

    // ── Eyes ───────────────────────────────────────────────────────────
    final eyePaint = Paint()..color = const Color(0xFF1A0A00);
    final eyeWhitePaint = Paint()..color = Colors.white;

    void drawEye(double ex, double ey) {
      // Eye white
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex, ey),
          width: r * 0.28,
          height: r * 0.28 * blinkScale,
        ),
        eyeWhitePaint,
      );
      // Pupil
      canvas.drawCircle(
        Offset(ex + r * 0.02, ey),
        r * 0.1 * blinkScale.clamp(0.01, 1.0),
        eyePaint,
      );
      // Eye shine
      if (blinkScale > 0.5) {
        canvas.drawCircle(
          Offset(ex - r * 0.04, ey - r * 0.05),
          r * 0.04,
          Paint()..color = Colors.white,
        );
      }
    }

    drawEye(cx - r * 0.26, cy - r * 0.08);
    drawEye(cx + r * 0.26, cy - r * 0.08);

    // ── Smile ──────────────────────────────────────────────────────────
    final smilePaint = Paint()
      ..color = const Color(0xFF7A3E00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final smilePath = Path();
    smilePath.moveTo(cx - r * 0.22, cy + r * 0.18);
    smilePath.quadraticBezierTo(
      cx, cy + r * 0.42,
      cx + r * 0.22, cy + r * 0.18,
    );
    canvas.drawPath(smilePath, smilePaint);

    // ── Tiny legs (running indication) ────────────────────────────────
    final legPaint = Paint()
      ..color = const Color(0xFFC8891A)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - r * 0.2, cy + r * 0.88),
      Offset(cx - r * 0.3, cy + r * 1.05),
      legPaint,
    );
    canvas.drawLine(
      Offset(cx + r * 0.2, cy + r * 0.88),
      Offset(cx + r * 0.1, cy + r * 1.05),
      legPaint,
    );
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.glowIntensity != glowIntensity || old.blinkScale != blinkScale;
}

class _Particle {
  double x, y, vx, vy, life, size;
  Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
  });
}
