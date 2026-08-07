import 'package:flutter/material.dart';
import '../theme/nipah_theme.dart';

class NipahLoader extends StatefulWidget {
  final double size;
  final Color? color;
  const NipahLoader({super.key, this.size = 24, this.color});

  @override
  State<NipahLoader> createState() => _NipahLoaderState();
}

class _NipahLoaderState extends State<NipahLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? NipahColors.gold;
    final w = widget.size * 4;
    final h = widget.size * 0.18;
    return SizedBox(
      width: w,
      height: h < 2 ? 2 : h,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size(w, h < 2 ? 2 : h),
          painter: _GlossyBarPainter(value: _c.value, color: color),
        ),
      ),
    );
  }
}

class _GlossyBarPainter extends CustomPainter {
  final double value;
  final Color color;
  _GlossyBarPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bg = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.06),
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.06),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    final shineWidth = size.width * 0.35;
    final cx = size.width * value;
    final shineRect = Rect.fromLTWH(
      cx - shineWidth / 2,
      0,
      shineWidth,
      size.height,
    );
    final shine = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          Color.lerp(color, Colors.white, 0.85)!.withValues(alpha: 0.9),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(shineRect);
    canvas.drawRect(shineRect, shine);
  }

  @override
  bool shouldRepaint(_GlossyBarPainter old) => old.value != value;
}

class NipahPulseLoader extends StatefulWidget {
  final double size;
  final Color? color;
  const NipahPulseLoader({super.key, this.size = 40, this.color});

  @override
  State<NipahPulseLoader> createState() => _NipahPulseLoaderState();
}

class _NipahPulseLoaderState extends State<NipahPulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _pulse;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _fade = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? NipahColors.gold;
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final p = _c.value < 0.5 ? _pulse.value : 1.6 - _pulse.value;
        final f = _c.value < 0.5 ? _fade.value : 1.6 - _fade.value;
        return Container(
          width: s * p,
          height: s * p,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.6 * f),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: s * 0.4,
              height: s * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: f),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NipahDotLoader extends StatefulWidget {
  final double size;
  final Color? color;
  const NipahDotLoader({super.key, this.size = 20, this.color});

  @override
  State<NipahDotLoader> createState() => _NipahDotLoaderState();
}

class _NipahDotLoaderState extends State<NipahDotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? NipahColors.gold;
    final dotSize = widget.size * 0.3;
    return SizedBox(
      width: widget.size,
      height: dotSize,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final t = (_c.value + i * 0.33) % 1.0;
              final scale = t < 0.5 ? 0.5 + t : 1.5 - t;
              return Container(
                width: dotSize * scale,
                height: dotSize * scale,
                margin: EdgeInsets.symmetric(horizontal: dotSize * 0.25),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.4 + scale * 0.6),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
