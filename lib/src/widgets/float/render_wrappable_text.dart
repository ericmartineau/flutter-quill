// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math';
import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'float_data.dart';
import 'inline_span_ext.dart';
import 'render_object_ext.dart';
import 'render_text_mixin.dart';
import 'shared.dart';
import 'util.dart';
import 'wrappable_text.dart';

///
/// WrappableTextRenderer
///
class RenderWrappingText extends RenderBox {
  RenderWrappingText(
    this.floatCount,
    this.parent,
    this.wrappingText,
    TextDirection defaultTextDirection,
    double defaultTextScaleFactor,
  ) : renderer = TextRenderer(
            parent,
            TextPainter(
                text: wrappingText.text,
                textAlign: wrappingText.textAlign ?? TextAlign.start,
                textDirection:
                    wrappingText.textDirection ?? defaultTextDirection,
                textScaleFactor:
                    wrappingText.textScaleFactor ?? defaultTextScaleFactor,
                locale: wrappingText.locale,
                strutStyle: wrappingText.strutStyle,
                textHeightBehavior: wrappingText.textHeightBehavior),
            0);

  int floatCount;
  late Size calculatedSize;
  final TextRenderer renderer;
  final WrappableText wrappingText;

  @override
  RenderBox parent;
  final subs = <TextRenderer>[];

  bool get isValid => validRenderers.isNotEmpty;

  TextRenderer operator [](int index) => index == -1 ? renderer : subs[index];

  TextDirection get textDirection => renderer._painter.textDirection!;

  List<TextRenderer> get renderers => subs.isNotEmpty ? subs : [renderer];

  Iterable<TextRenderer> get validRenderers =>
      renderers.where((element) => element.isValid);

  @override
  void performLayout() {
    final size = renderers.where((r) => r.isValid).fold<Size>(Size.zero,
        (folded, element) {
      final rect = element.textRect;
      return Size(
        max(folded.width, rect.right),
        max(folded.height, rect.bottom),
      );
    });

    calculatedSize = size;
    this.size = size;
  }

  TextRenderer rendererWithPlaceholder(int index) {
    if (subs.isEmpty) {
      return renderer;
    } else {
      var i = index;
      for (final sub in subs) {
        final count = sub.placeholderSpans.length;
        if (i < count) {
          return sub;
        } else {
          i -= count;
        }
      }
      assert(false);
      return renderer;
    }
  }

  RenderComparison updateWith(
    WrappableText wrapText,
    RenderBox parent,
    int floatCount,
    TextDirection defaultTextDirection,
    DefaultTextStyle defaultTextStyle,
    double defaultTextScaleFactor,
  ) {
    var needsPaint = false;
    var needsLayout = false;
    this.floatCount = floatCount;
    final mergedStyle = (wrapText.text.style ?? const TextStyle())
        .merge(defaultTextStyle.style);

    final textSpan = wrapText.text.copyWith(style: mergedStyle);
    final comparison = renderer._painter.text!.compareTo(textSpan);
    switch (comparison) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        break;
      case RenderComparison.paint:
        renderer._painter.text = textSpan;
        renderer._semanticsInfo = null;
        renderer._cachedCombinedSemanticsInfos = null;
        renderer.clearPlaceholderSpans();
        needsPaint = true;
        break;
      case RenderComparison.layout:
        renderer._painter.text = textSpan;
        renderer._semanticsInfo = null;
        renderer._cachedCombinedSemanticsInfos = null;
        renderer.clearPlaceholderSpans();
        needsLayout = true;
        break;
    }

    final textAlign =
        wrapText.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
    if (renderer._painter.textAlign != textAlign) {
      renderer._painter.textAlign = textAlign;
      needsLayout = true;
    }

    final textDirection = wrapText.textDirection ?? defaultTextDirection;
    if (renderer._painter.textDirection != textDirection) {
      renderer._painter.textDirection = textDirection;
      needsLayout = true;
    }

    final textScaleFactor = wrapText.textScaleFactor ?? defaultTextScaleFactor;
    if (renderer._painter.textScaleFactor != textScaleFactor) {
      renderer._painter.textScaleFactor = textScaleFactor;
      needsLayout = true;
    }

    if (renderer._painter.locale != wrapText.locale) {
      renderer._painter.locale = wrapText.locale;
      needsLayout = true;
    }

    if (renderer._painter.strutStyle != wrapText.strutStyle) {
      renderer._painter.strutStyle = wrapText.strutStyle;
      needsLayout = true;
    }

    if (renderer._painter.textHeightBehavior != wrapText.textHeightBehavior) {
      renderer._painter.textHeightBehavior = wrapText.textHeightBehavior;
      needsLayout = true;
    }

    if (needsLayout) {
      parent.markNeedsLayout();
    } else if (needsPaint) {
      for (final sub in subs) {
        sub._semanticsInfo = sub._cachedCombinedSemanticsInfos = null;
      }

      parent
        ..markNeedsPaint()
        ..markNeedsSemanticsUpdate();
    }

    return comparison;
  }

  TextPosition getPositionForOffset(Offset offset) {
    final found = validRenderers.where((r) => r.textRect.contains(offset));

    if (found.isEmpty) {
      if (renderers.isEmpty) {
        return const TextPosition(offset: 0);
      } else {
        final last = renderers.last;
        return TextPosition(
          offset: last.textOffset +
              last.text
                  .toPlainText(
                    includePlaceholders: false,
                    includeSemanticsLabels: false,
                  )
                  .length,
        );
      }
    } else {
      return found.first.getPositionForOffset(offset);
    }
  }

  TextRange getWordBoundary(TextPosition position) {
    return _atPosition(position).getWordBoundary(position);
  }

  TextRenderer _atPosition(TextPosition pos, {bool includeFloats = false}) {
    final iter = renderers.iterator;
    final offset = pos.offset;
    while (iter.moveNext()) {
      final split = iter.current;
      if (offset <=
          (split.textOffset +
              split.textLength +
              (includeFloats ? 0 : floatCount))) {
        return split;
      }
    }

    throw StateError('No renderer for pos: $pos');
  }

  List<TextBox> getBoxesForSelection(TextSelection textSelection) {
    return [
      for (final r in validRenderers)
        for (final box in r.getBoxesForSelection(textSelection)) box,
    ];
  }

  double? getFullHeightForCaret(TextPosition position) {
    return _atPosition(position).getFullHeightForCaret(position);
  }

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype,
      {bool includeFloats = true}) {
    if (!includeFloats) {
      position = position - floatCount;
    }
    return _atPosition(position, includeFloats: includeFloats)
        .getOffsetForCaret(position, caretPrototype);
  }

  double get preferredLineHeight => renderers.first.initialLineHeight();
}

///
/// TextRenderer
///
class TextRenderer with RenderTextMixin {
  TextRenderer(
    this._parent,
    this._painter,
    this.startingPlaceholderIndex, {
    this.textOffset = 0,
    this.maxWidth,
  })  : assert(_painter.text != null),
        textLength = _painter.text!.toPlainText().length;

  final int textOffset;
  final RenderBox _parent;
  final TextPainter _painter;
  final int startingPlaceholderIndex;
  List<PlaceholderSpan>? _placeholderSpans;

  final int textLength;

  String toPlainText() => text.toPlainText(includeSemanticsLabels: false);

  Offset _offset = Offset.zero;

  set offset(Offset value) => _offset = value;

  @override
  Offset get offset => _offset;
  double? maxWidth;

  Rect get textRect {
    final size = textSize;
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }

  int get nextPlaceholderIndex =>
      startingPlaceholderIndex + placeholderSpans.length;

  List<PlaceholderSpan> get placeholderSpans {
    if (_placeholderSpans == null) {
      _placeholderSpans = <PlaceholderSpan>[];
      _painter.text!.visitChildren((span) {
        if (span is PlaceholderSpan) _placeholderSpans!.add(span);
        return true;
      });
    }
    return _placeholderSpans!;
  }

  void clearPlaceholderSpans() => _placeholderSpans = null;

  /// Computes the visual position of the glyphs for painting the text and the
  /// position of the inline widget children.
  void layout(BoxConstraints constraints) {
    maxWidth = constraints.maxWidth;
    _painter.layout(
        minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }

  TextRenderer copyWith({
    required InlineSpan text,
    required int startingPlaceholderIndex,
    int? textOffset,
  }) =>
      TextRenderer(
        _parent,
        TextPainter(
            text: text,
            textAlign: _painter.textAlign,
            textDirection: _painter.textDirection,
            textScaleFactor: _painter.textScaleFactor,
            locale: _painter.locale,
            strutStyle: _painter.strutStyle,
            textHeightBehavior: _painter.textHeightBehavior),
        startingPlaceholderIndex,
        textOffset: textOffset ?? this.textOffset,
      );

  TextBox placeholderBoxForWidgetIndex(int index) {
    final i = index - startingPlaceholderIndex;
    if ((_painter.inlinePlaceholderBoxes?.length ?? 0) > i) {
      return _painter.inlinePlaceholderBoxes![i];
    } else {
      return TextBox.fromLTRBD(0, 0, 0, 0, _painter.textDirection!);
    }
  }

  double placeholderScaleForWidgetIndex(int index) {
    final i = index - startingPlaceholderIndex;
    if ((_painter.inlinePlaceholderScales?.length ?? 0) > i) {
      return _painter.inlinePlaceholderScales![i];
    } else {
      // assert(false);
      return 1.0;
    }
  }

  /// Returns an estimate of the initial line height based on the initial font
  /// size, initial line height scale, and the text scale factor.
  double initialLineHeight() {
    final fontSize = _painter.text!.initialFontSize(14.0);
    final lineHeightScale = _painter.text!.initialLineHeightScale(1.12);
    return fontSize * lineHeightScale * _painter.textScaleFactor;
  }

  double initialScaledFontSize() {
    final fontSize = _painter.text!.initialFontSize(14.0);
    return fontSize * _painter.textScaleFactor;
  }

  /// Sets the placeholder dimensions for this paragraph's inline widget
  /// children, if any. Returns true iff any of the children are floated.
  bool setPlaceholderDimensions(
    RenderBox? firstChild,
    BoxConstraints constraints,
    double textScaleFactor,
  ) {
    if (firstChild == null) return false;

    // final currentLine = firstChild.line;

    // The children will be scaled by textScaleFactor during the painting
    // phase, so the constraints are divided by textScaleFactor.
    final childConstraints =
        BoxConstraints(maxWidth: constraints.maxWidth) / textScaleFactor;

    final placeholderDimensions = List<PlaceholderDimensions>.filled(
        placeholderSpans.length, PlaceholderDimensions.empty,
        growable: false);

    var hasFloatedChildren = false;
    firstChild.walkTree<RenderBox>(
      (child, state) {
        if (child is RenderMetaData && child.metaData is FloatData) {
          final floatData = child.metaData as FloatData;

          final i = floatData.placeholderIndex - startingPlaceholderIndex;
          if (i >= 0 && i < placeholderSpans.length) {
            if (floatData.float != FCFloat.none) {
              hasFloatedChildren = true;
              if (!child.hasSize) {
                _layoutChild(child, i, BoxConstraints.tight(Size.zero));
              }
            } else {
              placeholderDimensions[i] =
                  _layoutChild(child, i, childConstraints);
            }
          }
        }
      },
      walkSelf: false,
      earlyTerminate: false,
    );

    _painter.setPlaceholderDimensions(placeholderDimensions);

    return hasFloatedChildren;
  }

  /// Layout the [child] inline widget at the given [childIndex].
  PlaceholderDimensions _layoutChild(
    RenderBox child,
    int childIndex,
    BoxConstraints constraints, {
    bool dry = false,
  }) {
    assert(childIndex >= 0 && childIndex < placeholderSpans.length);

    double? baselineOffset;
    final Size childSize;
    if (!dry) {
      if (!child.hasSize) {
        // TODO(ron): Maybe need to call this every time in case constraints change?
        child.layout(
          constraints,
          parentUsesSize: true,
        );
      }
      childSize = child.size;
      switch (placeholderSpans[childIndex].alignment) {
        case ui.PlaceholderAlignment.baseline:
          baselineOffset = child
              .getDistanceToBaseline(placeholderSpans[childIndex].baseline!);
          break;
        default:
          baselineOffset = null;
          break;
      }
    } else {
      assert(placeholderSpans[childIndex].alignment !=
          ui.PlaceholderAlignment.baseline);
      childSize = child.getDryLayout(constraints);
    }

    return PlaceholderDimensions(
      size: childSize,
      alignment: placeholderSpans[childIndex].alignment,
      baseline: placeholderSpans[childIndex].baseline,
      baselineOffset: baselineOffset,
    );
  }

  //
  // Semantics related:
  //
  List<InlineSpanSemanticsInformation>? _semanticsInfo;
  List<InlineSpanSemanticsInformation>? _cachedCombinedSemanticsInfos;

  List<InlineSpanSemanticsInformation> getSemanticsInfo({
    bool combined = false,
  }) {
    if (combined) {
      _cachedCombinedSemanticsInfos ??= combineSemanticsInfo(_semanticsInfo!);
      return _cachedCombinedSemanticsInfos!;
    } else {
      _semanticsInfo ??= text.getSemanticsInformation();
      return _semanticsInfo!;
    }
  }

  //
  // RenderTextAdapter overrides:
  //

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    return _painter
        .getBoxesForSelection(selection - textOffset)
        .offset(_offset);
  }

  @override
  double? getFullHeightForCaret(TextPosition position) =>
      _painter.getFullHeightForCaret(position - textOffset, Rect.zero);

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    if (isValid) {
      return _painter.getOffsetForCaret(position - textOffset, caretPrototype) +
          _offset;
    } else {
      return Offset.zero;
    }
  }

  @override
  TextPosition getPositionForOffset(Offset offset) =>
      _painter.getPositionForOffset(offset - _offset) + textOffset;

  @override
  TextRange getWordBoundary(TextPosition position) =>
      _painter.getWordBoundary(position);

  @override
  double get height => _painter.height;

  @override
  Locale? get locale => _painter.locale;

  @override
  int? get maxLines => _painter.maxLines;

  @override
  RenderBox get renderBox => _parent;

  @override
  StrutStyle? get strutStyle => _painter.strutStyle;

  @override
  InlineSpan get text => _painter.text!;

  @override
  TextAlign get textAlign => _painter.textAlign;

  @override
  TextDirection get textDirection => _painter.textDirection!;

  @override
  TextHeightBehavior? get textHeightBehavior => _painter.textHeightBehavior;

  @override
  double get textScaleFactor => _painter.textScaleFactor;

  @override
  Size get textSize => _painter.size;

  @override
  TextWidthBasis get textWidthBasis => _painter.textWidthBasis;

  bool get isValid {
    final txt = _painter.text;

    if (txt is TextSpan) {
      if (txt.text == null && txt.children?.isNotEmpty != true) {
        return false;
      }
    } else if (txt == null) {
      return false;
    }
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (isValid) {
      _painter.paint(context.canvas, this.offset + offset);
    } else {
      // print('Skip painting for: $_painter');
    }
  }

  @override
  double get width => _painter.width;
}

// extension on RenderBox {
//   FloatData get floatData => ((this as RenderMetaData).metaData as FloatData);
// }

extension on TextPosition {
  TextPosition operator +(int amount) {
    return TextPosition(offset: offset + amount, affinity: affinity);
  }

  TextPosition operator -(int amount) {
    return TextPosition(offset: max(0, offset - amount), affinity: affinity);
  }
}

extension on TextSelection {
  TextSelection operator +(int textOffset) {
    final adjusted = copyWith(
        baseOffset: baseOffset + textOffset,
        extentOffset: extentOffset + textOffset);
    return adjusted;
  }

  TextSelection operator -(int textOffset) {
    final adjusted = copyWith(
        baseOffset: max(0, baseOffset - textOffset),
        extentOffset: max(0, extentOffset - textOffset));
    return adjusted;
  }
}
