import 'package:flutter/material.dart';

const lime = Color(0xFFA8E63A);
const bgColor = Color(0xFF0B0F0A);
const cardColor = Color(0xFF161B14);
const dimText = Color(0xFF8E9A88);
const okColor = Color(0xFF3DDC84);
const errColor = Color(0xFFFF6B6B);
const warnColor = Color(0xFFFFA940);

Color difficultyColor(String d) {
  if (d == 'Fácil') return okColor;
  if (d == 'Difícil') return errColor;
  return warnColor;
}

Widget pill(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );

String fmtTime(int secs) {
  final m = (secs ~/ 60).toString().padLeft(2, '0');
  final s = (secs % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String dateBr(Object? iso) {
  final s = (iso ?? '').toString();
  if (s.length < 10) return s;
  return '${s.substring(8, 10)}/${s.substring(5, 7)}/${s.substring(0, 4)}';
}
