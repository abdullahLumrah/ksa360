import 'package:flutter/material.dart';

/// Single-line label that scrolls when the text is wider than its slot.
class MarqueeText extends StatefulWidget {
  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.velocity = 26,
    this.gap = 28,
    this.pause = const Duration(milliseconds: 800),
  });

  final String text;
  final TextStyle? style;
  final double velocity;
  final double gap;
  final Duration pause;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  TextPainter _painter(TextStyle style) {
    return TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _ensureController(double distance) {
    final seconds = (distance / widget.velocity).clamp(2.2, 9.0);
    final existing = _controller;
    if (existing != null &&
        existing.duration?.inMilliseconds == (seconds * 1000).round()) {
      return;
    }
    existing?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (seconds * 1000).round()),
    );
    _controller = controller;
    Future<void> loop() async {
      while (mounted && identical(_controller, controller)) {
        await Future<void>.delayed(widget.pause);
        if (!mounted || !identical(_controller, controller)) return;
        await controller.forward(from: 0);
        controller.value = 0;
      }
    }

    loop();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0) {
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
        }
        final painter = _painter(style);
        if (painter.width <= maxW + 1) {
          _controller?.stop();
          return Text(widget.text, maxLines: 1, style: style);
        }
        final distance = painter.width + widget.gap;
        _ensureController(distance);
        final controller = _controller!;
        return SizedBox(
          height: painter.height,
          width: maxW,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final dx = controller.value * distance;
                return Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(-dx, 0),
                      child: Text(widget.text, maxLines: 1, style: style),
                    ),
                    Transform.translate(
                      offset: Offset(-dx + distance, 0),
                      child: Text(widget.text, maxLines: 1, style: style),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
