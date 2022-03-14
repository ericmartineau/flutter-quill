// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:ui' as ui show hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show EdgeInsetsGeometry, EdgeInsets;
import 'package:flutter/widgets.dart';

import '../../models/documents/nodes/line.dart';
import '../text_line.dart';
import 'shared.dart';

class ProxyData {
  ProxyData(
      {required this.floatData,
      this.startOffset = -1,
      this.stopOffset = -1,
      required TextLineStyle lineStyle});

  final FloatData floatData;
  final int startOffset;
  final int stopOffset;
}

abstract class FloatRenderInfo {
  // /// The index of the child.
  // Line get line;

  double get indent;

  /// Index of the placeholder span in the child `WrappableText`, or 0 for
  /// child `Widget`s.
  int get placeholderIndex;

  /// Should the child float to the `left`, `right`, `start`, or `end`? The
  /// default is `none`.
  FCFloat get float;

  /// Should the child "clear" (i.e. be placed below) floated siblings?
  /// And if so, should it be placed below floated siblings on just one side
  /// (`left`, `right`, `start`, or `end`) or `both`? The default is `none`.
  FCClear get clear;

  /// Minimum vertical spacing below a cleared sibling. Defaults to 0.0. Only
  /// used if `clear` is set to `left`, `right`, `start`, or `end`, and it is
  /// below a floated sibling.
  double get clearMinSpacing;

  /// Empty space to surround the child. Similar to CSS, the top overlaps
  /// the previous sibling's bottom margin, the bottom overlaps the next
  /// sibling's top margin, and the left and right overlap floated siblings.
  EdgeInsetsGeometry get margin;

  /// Empty space to surround the child that does not overlap siblings.
  EdgeInsetsGeometry get padding;

  /// Maximum width as percentage of the parent FloatColumn's width. Defaults
  /// to 100%.
  double get maxWidthPercentage;
}

@immutable
class FloatData implements FloatRenderInfo {
  const FloatData({
    // required this.line,
    required this.placeholderIndex,
    this.float = FCFloat.none,
    this.clear = FCClear.none,
    this.indent = 0.0,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.maxWidthPercentage = 1.0,
    this.clearMinSpacing = 0.0,
  });

  /// The index of the child.
  // @override
  // final int index;

  // @override
  // final Line line;

  @override
  final double indent;

  /// Index of the placeholder span in the child `WrappableText`, or 0 for
  /// child `Widget`s.
  @override
  final int placeholderIndex;

  /// Should the child float to the `left`, `right`, `start`, or `end`? The
  /// default is `none`.
  @override
  final FCFloat float;

  /// Should the child "clear" (i.e. be placed below) floated siblings?
  /// And if so, should it be placed below floated siblings on just one side
  /// (`left`, `right`, `start`, or `end`) or `both`? The default is `none`.
  @override
  final FCClear clear;

  /// Minimum vertical spacing below a cleared sibling. Defaults to 0.0. Only
  /// used if `clear` is set to `left`, `right`, `start`, or `end`, and it is
  /// below a floated sibling.
  @override
  final double clearMinSpacing;

  /// Empty space to surround the child. Similar to CSS, the top overlaps
  /// the previous sibling's bottom margin, the bottom overlaps the next
  /// sibling's top margin, and the left and right overlap floated siblings.
  @override
  final EdgeInsetsGeometry margin;

  /// Empty space to surround the child that does not overlap siblings.
  @override
  final EdgeInsetsGeometry padding;

  /// Maximum width as percentage of the parent FloatColumn's width. Defaults
  /// to 100%.
  @override
  final double maxWidthPercentage;

  @override
  bool operator ==(Object other) {
    return other is FloatData &&
        // other.line == line &&
        other.placeholderIndex == placeholderIndex &&
        other.float == float &&
        other.clear == clear &&
        other.clearMinSpacing == clearMinSpacing &&
        other.margin == margin &&
        other.padding == padding &&
        other.maxWidthPercentage == maxWidthPercentage;
  }

  @override
  int get hashCode => ui.hashValues(
      FloatData,
      float,
      clear,
      clearMinSpacing,
      // line,
      placeholderIndex,
      margin,
      padding,
      maxWidthPercentage);
}
