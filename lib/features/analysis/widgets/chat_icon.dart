import 'package:flutter/material.dart';
import 'package:moneyfy/design_system/spec.dart';

enum ChatGlyph { newChat, rooms, send, copy, sources, externalLink }

class ChatIcon extends StatelessWidget {
  const ChatIcon(this.glyph, {super.key, this.size});

  final ChatGlyph glyph;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final color = theme.color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox.square(
      dimension: size ?? theme.size ?? VisualSpec.icon.sizeDefault,
      child: CustomPaint(
        painter: _ChatIconPainter(
          glyph,
          color.withValues(alpha: color.a * (theme.opacity ?? 1)),
        ),
      ),
    );
  }
}

class _ChatIconPainter extends CustomPainter {
  const _ChatIconPainter(this.glyph, this.color);
  final ChatGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (glyph) {
      case ChatGlyph.newChat:
        path
          ..moveTo(5, 12)
          ..lineTo(19, 12)
          ..moveTo(12, 5)
          ..lineTo(12, 19);
      case ChatGlyph.rooms:
        path
          ..moveTo(6, 3.5)
          ..lineTo(18, 3.5)
          ..quadraticBezierTo(21, 3.5, 21, 6.5)
          ..lineTo(21, 15)
          ..quadraticBezierTo(21, 18, 18, 18)
          ..lineTo(10, 18)
          ..lineTo(5, 21)
          ..lineTo(5, 18)
          ..quadraticBezierTo(3, 17.6, 3, 15)
          ..lineTo(3, 6.5)
          ..quadraticBezierTo(3, 3.5, 6, 3.5)
          ..close()
          ..moveTo(7.5, 8.5)
          ..lineTo(16.5, 8.5)
          ..moveTo(7.5, 13)
          ..lineTo(13, 13);
      case ChatGlyph.send:
        path
          ..moveTo(12, 19)
          ..lineTo(12, 5)
          ..moveTo(6, 11)
          ..lineTo(12, 5)
          ..lineTo(18, 11);
      case ChatGlyph.copy:
        path
          ..addRRect(RRect.fromLTRBR(8, 8, 20, 21, const Radius.circular(2.5)))
          ..moveTo(4, 15)
          ..lineTo(4, 5.5)
          ..quadraticBezierTo(4, 3, 6.5, 3)
          ..lineTo(15, 3);
      case ChatGlyph.sources:
        path
          ..addRRect(RRect.fromLTRBR(5, 3, 19, 21, const Radius.circular(2.5)))
          ..moveTo(9, 8)
          ..lineTo(15, 8)
          ..moveTo(9, 12)
          ..lineTo(15, 12)
          ..moveTo(9, 16)
          ..lineTo(12, 16);
      case ChatGlyph.externalLink:
        path
          ..moveTo(11, 5)
          ..lineTo(6, 5)
          ..quadraticBezierTo(3.5, 5, 3.5, 7.5)
          ..lineTo(3.5, 18)
          ..quadraticBezierTo(3.5, 20.5, 6, 20.5)
          ..lineTo(16.5, 20.5)
          ..quadraticBezierTo(19, 20.5, 19, 18)
          ..lineTo(19, 13)
          ..moveTo(11, 13)
          ..lineTo(20, 4)
          ..moveTo(14, 4)
          ..lineTo(20, 4)
          ..lineTo(20, 10);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ChatIconPainter oldDelegate) =>
      glyph != oldDelegate.glyph || color != oldDelegate.color;
}
