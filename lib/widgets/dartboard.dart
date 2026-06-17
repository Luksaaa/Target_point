import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/dart_hit.dart';
import '../theme/app_palette.dart';

class Dartboard extends StatefulWidget {
  const Dartboard({
    required this.enabled,
    required this.onHit,
    required this.currentTurn,
    this.checkoutHint,
    super.key,
  });

  final bool enabled;
  final ValueChanged<DartHit> onHit;
  final List<DartHit> currentTurn;
  final String? checkoutHint;

  @override
  State<Dartboard> createState() => _DartboardState();
}

class _DartboardState extends State<Dartboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (DartboardCheckoutTarget.parse(widget.checkoutHint) != null) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant Dartboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasTarget =
        DartboardCheckoutTarget.parse(widget.checkoutHint) != null;
    if (hasTarget && !_blinkController.isAnimating) {
      _blinkController.repeat(reverse: true);
    } else if (!hasTarget && _blinkController.isAnimating) {
      _blinkController.stop();
      _blinkController.value = 0;
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapDown: widget.enabled
              ? (details) {
                  final hit = DartboardGeometry.hitTest(
                    details.localPosition,
                    Size.square(size),
                  );
                  widget.onHit(hit);
                }
              : null,
          child: AnimatedBuilder(
            animation: _blinkController,
            builder: (context, child) => CustomPaint(
              size: Size.square(size),
              painter: DartboardPainter(
                palette: AppPalette.of(context),
                currentTurn: widget.currentTurn,
                checkoutTarget: DartboardCheckoutTarget.parse(
                  widget.checkoutHint,
                ),
                blinkValue: _blinkController.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class DartboardCheckoutTarget {
  const DartboardCheckoutTarget({required this.band, this.number});

  final SegmentBand band;
  final int? number;

  static DartboardCheckoutTarget? parse(String? hint) {
    if (hint == null || hint.trim().isEmpty) {
      return null;
    }

    final first = hint.split('+').first.trim().toUpperCase();
    if (first == 'BULL') {
      return const DartboardCheckoutTarget(band: SegmentBand.bull);
    }
    if (first == '25') {
      return const DartboardCheckoutTarget(band: SegmentBand.outerBull);
    }

    if (first.length < 2) {
      return null;
    }
    final number = int.tryParse(first.substring(1));
    if (number == null || number < 1 || number > 20) {
      return null;
    }

    final band = switch (first[0]) {
      'D' => SegmentBand.double,
      'T' => SegmentBand.triple,
      'S' => SegmentBand.single,
      _ => null,
    };
    if (band == null) {
      return null;
    }
    return DartboardCheckoutTarget(band: band, number: number);
  }
}

class DartboardGeometry {
  static const segmentNumbers = [
    20,
    1,
    18,
    4,
    13,
    6,
    10,
    15,
    2,
    17,
    3,
    19,
    7,
    16,
    8,
    11,
    14,
    9,
    12,
    5,
  ];

  static DartHit hitTest(Offset position, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distanceRatio = math.sqrt(dx * dx + dy * dy) / radius;

    final normDx = dx / radius;
    final normDy = dy / radius;

    if (distanceRatio > 0.98) {
      return DartHit(
        label: 'MISS',
        score: 0,
        band: SegmentBand.miss,
        dx: normDx,
        dy: normDy,
      );
    }

    if (distanceRatio <= 0.055) {
      return DartHit(
        label: 'BULL',
        score: 50,
        band: SegmentBand.bull,
        dx: normDx,
        dy: normDy,
      );
    }

    if (distanceRatio <= 0.12) {
      return DartHit(
        label: '25',
        score: 25,
        band: SegmentBand.outerBull,
        dx: normDx,
        dy: normDy,
      );
    }

    final number = numberForPosition(dx, dy);
    final band = bandForDistance(distanceRatio);
    final multiplier = switch (band) {
      SegmentBand.double => 2,
      SegmentBand.triple => 3,
      SegmentBand.single => 1,
      _ => 0,
    };
    final prefix = switch (band) {
      SegmentBand.double => 'D',
      SegmentBand.triple => 'T',
      SegmentBand.single => 'S',
      _ => '',
    };

    return DartHit(
      label: '$prefix$number',
      score: number * multiplier,
      band: band,
      number: number,
      dx: normDx,
      dy: normDy,
    );
  }

  static int numberForPosition(double dx, double dy) {
    final angle = (math.atan2(dy, dx) * 180 / math.pi + 450) % 360;
    final index = ((angle + 9) % 360 / 18).floor();
    return segmentNumbers[index];
  }

  static SegmentBand bandForDistance(double distanceRatio) {
    if (distanceRatio >= 0.84) {
      return SegmentBand.double;
    }
    if (distanceRatio >= 0.52 && distanceRatio <= 0.62) {
      return SegmentBand.triple;
    }
    return SegmentBand.single;
  }
}

class DartboardPainter extends CustomPainter {
  const DartboardPainter({
    required this.palette,
    required this.currentTurn,
    required this.checkoutTarget,
    required this.blinkValue,
  });

  final AppPalette palette;
  final List<DartHit> currentTurn;
  final DartboardCheckoutTarget? checkoutTarget;
  final double blinkValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final boardRadius = radius * 0.98;
    final segmentSweep = 2 * math.pi / 20;
    final startOffset = -math.pi / 2 - segmentSweep / 2;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final outerPaint = Paint()..color = const Color(0xFF161513);
    canvas.drawCircle(center, boardRadius, outerPaint);

    for (var i = 0; i < 20; i++) {
      final start = startOffset + i * segmentSweep;
      final isEven = i.isEven;

      // Single Outer & Inner
      _drawRingSegment(
        canvas,
        center,
        radius,
        innerRatio: 0.64,
        outerRatio: 0.84,
        start: start,
        sweep: segmentSweep,
        color: isEven ? palette.dartboardLight : palette.dartboardDark,
      );
      _drawRingSegment(
        canvas,
        center,
        radius,
        innerRatio: 0.12,
        outerRatio: 0.52,
        start: start,
        sweep: segmentSweep,
        color: isEven ? palette.dartboardLight : palette.dartboardDark,
      );

      // Triple Ring
      _drawRingSegment(
        canvas,
        center,
        radius,
        innerRatio: 0.52,
        outerRatio: 0.62,
        start: start,
        sweep: segmentSweep,
        color: isEven ? palette.primary : const Color(0xFFC7352F),
      );

      // Double Ring
      _drawRingSegment(
        canvas,
        center,
        radius,
        innerRatio: 0.84,
        outerRatio: 0.98,
        start: start,
        sweep: segmentSweep,
        color: isEven ? const Color(0xFFC7352F) : palette.primary,
      );

      // Numbers
      final number = DartboardGeometry.segmentNumbers[i];
      final angle = start + segmentSweep / 2;
      final labelOffset = Offset(
        center.dx + math.cos(angle) * radius * 0.91,
        center.dy + math.sin(angle) * radius * 0.91,
      );
      textPainter.text = TextSpan(
        text: '$number',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.075,
          fontWeight: FontWeight.w900,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        labelOffset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    _drawCheckoutHighlight(
      canvas,
      center,
      radius,
      startOffset: startOffset,
      segmentSweep: segmentSweep,
    );

    // Wires
    final wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * 0.006)
      ..color = palette.border.withValues(alpha: 0.8);

    for (final ratio in [0.12, 0.52, 0.62, 0.84, 0.98]) {
      canvas.drawCircle(center, radius * ratio, wirePaint);
    }

    for (var i = 0; i < 20; i++) {
      final angle = startOffset + i * segmentSweep;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.12,
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.98,
        wirePaint,
      );
    }

    // Bullseye
    canvas.drawCircle(center, radius * 0.12, Paint()..color = palette.primary);
    canvas.drawCircle(
      center,
      radius * 0.055,
      Paint()..color = const Color(0xFFC7352F),
    );
    canvas.drawCircle(center, radius * 0.12, wirePaint);
    canvas.drawCircle(center, radius * 0.055, wirePaint);

    // Draw Throw Pins
    for (int i = 0; i < currentTurn.length; i++) {
      final hit = currentTurn[i];
      if (hit.dx == null || hit.dy == null) continue;

      final pinOffset = Offset(
        center.dx + hit.dx! * radius,
        center.dy + hit.dy! * radius,
      );

      final pinColor = switch (i) {
        0 => const Color(0xFFFFD369), // Gold/Amber
        1 => const Color(0xFF00B074), // Green
        2 => const Color(0xFFC7352F), // Red
        _ => Colors.white,
      };

      // Draw shadow
      canvas.drawCircle(
        pinOffset + const Offset(1.5, 2.0),
        radius * 0.022,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );

      canvas.drawCircle(
        pinOffset,
        radius * 0.024,
        Paint()..color = Colors.black87,
      );

      // Draw pin color center
      canvas.drawCircle(pinOffset, radius * 0.018, Paint()..color = pinColor);

      // Draw a small white highlight dot inside the pin
      canvas.drawCircle(
        pinOffset - Offset(radius * 0.004, radius * 0.004),
        radius * 0.005,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  static void _drawRingSegment(
    Canvas canvas,
    Offset center,
    double radius, {
    required double innerRatio,
    required double outerRatio,
    required double start,
    required double sweep,
    required Color color,
  }) {
    final path = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * outerRatio),
        start,
        sweep,
        false,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * innerRatio),
        start + sweep,
        -sweep,
        false,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCheckoutHighlight(
    Canvas canvas,
    Offset center,
    double radius, {
    required double startOffset,
    required double segmentSweep,
  }) {
    final target = checkoutTarget;
    if (target == null) {
      return;
    }

    final alpha = 0.28 + (blinkValue * 0.42);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD369).withValues(alpha: alpha);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3, radius * 0.02)
      ..color = const Color(0xFFFFD369).withValues(alpha: 0.75);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(6, radius * 0.034)
      ..color = const Color(
        0xFFFFD369,
      ).withValues(alpha: 0.18 + blinkValue * 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    if (target.band == SegmentBand.bull) {
      canvas.drawCircle(center, radius * 0.055, fill);
      canvas.drawCircle(center, radius * 0.055, glow);
      canvas.drawCircle(center, radius * 0.055, stroke);
      return;
    }

    if (target.band == SegmentBand.outerBull) {
      canvas.drawCircle(center, radius * 0.12, fill);
      canvas.drawCircle(center, radius * 0.12, glow);
      canvas.drawCircle(center, radius * 0.12, stroke);
      return;
    }

    final number = target.number;
    if (number == null) {
      return;
    }
    final index = DartboardGeometry.segmentNumbers.indexOf(number);
    if (index == -1) {
      return;
    }

    final start = startOffset + index * segmentSweep;
    final (innerRatio, outerRatio) = switch (target.band) {
      SegmentBand.double => (0.84, 0.98),
      SegmentBand.triple => (0.52, 0.62),
      SegmentBand.single => (0.12, 0.84),
      _ => (0.0, 0.0),
    };
    if (outerRatio == 0.0) {
      return;
    }

    final path = _ringSegmentPath(
      center,
      radius,
      innerRatio: innerRatio,
      outerRatio: outerRatio,
      start: start,
      sweep: segmentSweep,
    );
    canvas.drawPath(path, glow);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  static Path _ringSegmentPath(
    Offset center,
    double radius, {
    required double innerRatio,
    required double outerRatio,
    required double start,
    required double sweep,
  }) {
    return Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * outerRatio),
        start,
        sweep,
        false,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * innerRatio),
        start + sweep,
        -sweep,
        false,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant DartboardPainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.currentTurn != currentTurn ||
      oldDelegate.checkoutTarget != checkoutTarget ||
      oldDelegate.blinkValue != blinkValue;
}
