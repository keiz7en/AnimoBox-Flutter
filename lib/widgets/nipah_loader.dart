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
      duration: const Duration(milliseconds: 1200),
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
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return CustomPaint(
            painter: _LoaderPainter(value: _c.value, color: color),
          );
        },
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double value;
  final Color color;
  _LoaderPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.square;

    // Track
    paint.color = color.withValues(alpha: 0.1);
    canvas.drawRect(
      Rect.fromCenter(center: c, width: size.width, height: size.height),
      paint,
    );

    // Spinning arc
    final start = value * 6.283;
    paint.color = color;
    canvas.drawArc(
      Rect.fromCenter(center: c, width: r * 2, height: r * 2),
      start,
      1.8,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.value != value;
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
                color: color.withValues(alpha: 0.4 + scale * 0.6),
              );
            }),
          );
        },
      ),
    );
  }
}
