import 'package:boxy/boxy.dart';
import 'package:flutter/rendering.dart';

extension QuillTextSpanExt on TextSpan {
  String get plainText => toPlainText(
        includePlaceholders: false,
        includeSemanticsLabels: false,
      );

  int get length => plainText.length;

  String substring(int start, [int? end]) {
    final substr = plainText.substring(start, end);
    return substr;
  }

  TextSpan subchars(int start, [int? end]) {
    final substr = substring(start, end);
    return TextSpan(
      text: substr,
      style: style,
      locale: locale,
      mouseCursor: mouseCursor,
      onEnter: onEnter,
      onExit: onExit,
      recognizer: recognizer,
      semanticsLabel: semanticsLabel,
      spellOut: spellOut,
    );
  }
}

extension QuillListBoxes on List<TextBox> {
  List<TextBox> translate({double dx = 0, double dy = 0}) {
    return [
      for (var box in this) box.translate(dx: dx, dy: dy),
    ];
  }
}

extension QuillSizeExt on Size {
  Size expand({double dx = 0, double dy = 0}) {
    return Size(
      width + dx,
      height + dy,
    );
  }

  Rect toRect() {
    return Rect.fromLTRB(0, 0, width, height);
  }
}

extension QuillRectExt on Rect {
  Rect expand({double dx = 0, double dy = 0}) {
    return Rect.fromLTRB(
      left,
      top,
      right + dx,
      bottom + dy,
    );
  }
}

extension QuillTextBoxAdjust on TextBox {
  TextBox translate({double dx = 0.0, double dy = 0.0}) {
    return TextBox.fromLTRBD(
      left + dx,
      top + dy,
      right + dx,
      bottom + dy,
      direction,
    );
  }
}

extension QuillSliverSizeToRect on SliverSize {
  Rect toRect() {
    return Rect.fromLTRB(0, 0, width, height);
  }
}

extension QuillEdgeInsetsExtensions on EdgeInsets {
  bool get isEmpty {
    return top == 0 && left == 0 && right == 0 && bottom == 0;
  }
}

/// Formats a double to have standard formatting.
///
