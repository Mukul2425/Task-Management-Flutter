import 'package:flutter/material.dart';

TextSpan highlightOccurrences({
  required String text,
  required String query,
  required TextStyle baseStyle,
  required TextStyle highlightStyle,
}) {
  final q = query.trim();
  if (q.isEmpty) return TextSpan(text: text, style: baseStyle);

  final lower = text.toLowerCase();
  final lowerQ = q.toLowerCase();

  final spans = <TextSpan>[];
  var start = 0;
  while (true) {
    final index = lower.indexOf(lowerQ, start);
    if (index < 0) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
      break;
    }
    if (index > start) {
      spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
    }
    spans.add(
      TextSpan(
        text: text.substring(index, index + q.length),
        style: highlightStyle,
      ),
    );
    start = index + q.length;
  }

  return TextSpan(children: spans);
}

