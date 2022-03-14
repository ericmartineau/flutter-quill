import 'package:flutter/material.dart';

extension IterableOfNExt<N extends Object> on List<N> {
  N? tryGet(int index) {
    if (index < length && index > -1) {
      return this[index];
    } else {
      return null;
    }
  }
}

extension NumIterable<n extends num> on Iterable<n> {
  n get max {
    n? highest;
    for (final value in this) {
      if (highest == null || value > highest) {
        highest = value;
      }
    }
    assert(highest != null, 'empty iterable cannot produce max');
    return highest!;
  }

  n get min {
    n? lowest;
    for (final value in this) {
      if (lowest == null || value < lowest) {
        lowest = value;
      }
    }
    assert(lowest != null, 'empty iterable cannot produce max');
    return lowest!;
  }

  n get sum {
    n? total;
    for (final value in this) {
      if (total == null) {
        total = value;
      } else {
        total = total + value as n;
      }
    }

    assert(total != null, 'empty iterable cannot produce max');
    return total!;
  }
}

extension InlineTextExt on InlineSpan {
  List<Widget> get nonText {
    final self = this;
    if (self is TextSpan) {
      return self.children?.expand((element) => element.nonText).toList() ?? [];
    } else if (self is WidgetSpan) {
      return [self.child];
    } else if (self is PlaceholderSpan) {
      return [];
    } else {
      return [];
    }
  }

  TextSpan? get textOnly {
    final self = this;
    if (self is TextSpan) {
      return TextSpan(
        text: self.text,
        style: self.style,
        recognizer: self.recognizer,
        mouseCursor: self.mouseCursor,
        onEnter: self.onEnter,
        onExit: self.onExit,
        children: self.children?.whereType<TextSpan>().toList(growable: false),
        spellOut: self.spellOut,
        semanticsLabel: self.semanticsLabel,
        locale: self.locale,
      );
    } else if (self is WidgetSpan) {
      return null;
    } else if (self is PlaceholderSpan) {
      return null;
    }
  }
}
