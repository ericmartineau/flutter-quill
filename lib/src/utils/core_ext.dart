import 'dart:math';

import 'package:flutter/rendering.dart';

extension TextPositionOperatorExt on TextPosition {
  TextPosition operator +(int amount) {
    if (amount == 0) return this;
    return TextPosition(offset: offset + amount, affinity: affinity);
  }

  TextPosition operator -(int amount) {
    if (amount == 0) return this;
    return TextPosition(offset: max(0, offset - amount), affinity: affinity);
  }

  TextPosition plusOffset(int amount) {
    return this + amount;
  }

  TextPosition minusOffset(int amount) {
    return this - amount;
  }
}

extension TextSelectionOperatorExt on TextSelection {
  TextSelection operator +(int textOffset) {
    if (textOffset == 0) return this;
    final adjusted = copyWith(
        baseOffset: baseOffset + textOffset,
        extentOffset: extentOffset + textOffset);
    return adjusted;
  }

  TextSelection operator -(int textOffset) {
    if (textOffset == 0) return this;
    final adjusted = copyWith(
        baseOffset: max(0, baseOffset - textOffset),
        extentOffset: max(0, extentOffset - textOffset));
    return adjusted;
  }

  TextSelection plusOffset(int textOffset) {
    return this + textOffset;
  }

  TextSelection minusOffset(int textOffset) {
    return this - textOffset;
  }
}
