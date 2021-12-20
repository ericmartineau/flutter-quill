import 'dart:math' as math;

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/src/widgets/extensions.dart';
import 'package:flutter_quill/src/widgets/text_line.dart';

import 'box.dart';

class RenderFloatingText extends RenderProxyBox
    implements RenderContentProxyBox {
  RenderFloatingText(FloatingText text)
      : _prototypePainter = TextPainter(
            text: TextSpan(text: ' ', style: text.textStyle),
            textAlign: text.textAlign,
            textDirection: text.textDirection,
            textScaleFactor: text.textScaleFactor,
            strutStyle: text.strutStyle,
            locale: text.locale,
            textWidthBasis: text.textWidthBasis,
            textHeightBehavior: text.textHeightBehavior),
        super();

  final TextPainter _prototypePainter;

  set textStyle(TextStyle value) {
    if (_prototypePainter.text!.style == value) {
      return;
    }
    _prototypePainter.text = TextSpan(text: ' ', style: value);
    markNeedsLayout();
  }

  set textAlign(TextAlign value) {
    if (_prototypePainter.textAlign == value) {
      return;
    }
    _prototypePainter.textAlign = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_prototypePainter.textDirection == value) {
      return;
    }
    _prototypePainter.textDirection = value;
    markNeedsLayout();
  }

  set textScaleFactor(double value) {
    if (_prototypePainter.textScaleFactor == value) {
      return;
    }
    _prototypePainter.textScaleFactor = value;
    markNeedsLayout();
  }

  set strutStyle(StrutStyle value) {
    if (_prototypePainter.strutStyle == value) {
      return;
    }
    _prototypePainter.strutStyle = value;
    markNeedsLayout();
  }

  set locale(Locale value) {
    if (_prototypePainter.locale == value) {
      return;
    }
    _prototypePainter.locale = value;
    markNeedsLayout();
  }

  set textWidthBasis(TextWidthBasis value) {
    if (_prototypePainter.textWidthBasis == value) {
      return;
    }
    _prototypePainter.textWidthBasis = value;
    markNeedsLayout();
  }

  set textHeightBehavior(TextHeightBehavior? value) {
    if (_prototypePainter.textHeightBehavior == value) {
      return;
    }
    _prototypePainter.textHeightBehavior = value;
    markNeedsLayout();
  }

  // @override
  // BoxyChild? get child => super.child as BoxyChild?;

  RenderContentProxyBox? get paragraph {
    if (child == null) return null;
    final pg = (child as RenderBox).proxyBox;
    // if (pg != null) {
    //   pg.leadingSize = leadingSize;
    // }
    return pg;
  }

  @override
  double getPreferredLineHeight() {
    return _prototypePainter.preferredLineHeight;
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect? caretPrototype) =>
      paragraph!.getOffsetForCaret(position, caretPrototype!);

  @override
  TextPosition getPositionForOffset(Offset offset) =>
      paragraph!.getPositionForOffset(offset);

  @override
  double? getFullHeightForCaret(TextPosition position) =>
      paragraph!.getFullHeightForCaret(position);

  @override
  TextRange getWordBoundary(TextPosition position) =>
      paragraph!.getWordBoundary(position);

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) =>
      paragraph!.getBoxesForSelection(selection);

  @override
  void performLayout() {
    super.performLayout();

    if (floatingTextParentData().rect.isEmpty &&
        floatingTextParentData().padding.isEmpty) {
      _prototypePainter.layout(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      );
    } else {
      /// We need to figure out if the text will stretch beyond the bottom of
      /// _leadingSize
      final child = this.child;
      if (child != null) {
        child.floatingTextParentData().rect = floatingTextParentData().rect;
        child.floatingTextParentData().padding =
            floatingTextParentData().padding;
      }
    }
  }
}

class FloatingText extends StatelessWidget {
  const FloatingText(
    this.data, {
    required this.textScaleFactor,
    required this.locale,
    required this.strutStyle,
    required this.textWidthBasis,
    required this.textStyle,
    this.textHeightBehavior,
    Key? key,
    this.dropCapStyle,
    this.textAlign = TextAlign.start,
    this.embedPadding = EdgeInsets.zero,
    this.indentation = Offset.zero,
    this.dropCapChars = 1,
    this.forceNoDescent = false,
    this.textDirection = TextDirection.ltr,
    this.overflow = TextOverflow.clip,
    this.maxLines,
  });

  final TextSpan data;
  final TextStyle textStyle;
  final TextStyle? dropCapStyle;
  final TextAlign textAlign;
  final EdgeInsets embedPadding;
  final Offset indentation;
  final bool forceNoDescent;
  final TextDirection textDirection;
  final int dropCapChars;
  final double textScaleFactor;
  final Locale locale;
  final StrutStyle strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    return CustomBoxy(
      delegate: FloatingTextBoxyDelegate(this, context),
      children: [],
    );
  }

  RichText toRichText([TextSpan? text]) {
    return RichText(
      text: text ?? data,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      locale: locale,
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: textDirection,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      strutStyle: strutStyle,
    );
  }
}

class FloatingTextParentData extends BoxParentData {
  Rect rect = Rect.zero;

  /// The actual amount of offset once rendered
  Rect? _actualRect;

  Rect get actualRect => _actualRect ?? rect;

  set actualRect(Rect rect) {
    _actualRect = rect;
  }

  EdgeInsets padding = EdgeInsets.zero;
}

extension RenderObjectFloatingTextParentData on RenderObject {
  FloatingTextParentData floatingTextParentData({bool create = true}) =>
      parentAsOrNull(create ? () => FloatingTextParentData() : null) ??
      FloatingTextParentData();
}

class FloatingTextBoxyDelegate extends BoxyDelegate {
  FloatingTextBoxyDelegate(this.floatingText, this.context);

  final FloatingText floatingText;
  final BuildContext context;

  @override
  bool shouldRepaint(FloatingTextBoxyDelegate oldDelegate) {
    return oldDelegate.floatingText != floatingText;
  }

  @override
  Size layout() {
    // final textStyle = TextStyle(
    //   color: Theme.of(context).textTheme.bodyText1?.color ?? Colors.black,
    //   fontSize: 14,
    //   height: 1,
    //   fontFamily: Theme.of(context).textTheme.bodyText1?.fontFamily,
    // ).merge(style);
    //
    // if (data.plainText == '') return Text('', style: textStyle);

    double capWidth, capHeight;
    // final dropCapChars = dropCap != null ? 0 : this.dropCapChars;
    var sideCrossAxisAlignment = CrossAxisAlignment.start;

    // final dropCapStr = data.substring(0, dropCapChars);

    // if (mode == FloatingEmbedMode.baseline && dropCap == null) {
    //   return _buildBaseline(context, textStyle, capStyle);
    // }

    // custom DropCap

    // final rect = Rect.fromLTRB(0, 0, 300, 200);
    // final dropCapPadding = floatingText.dropCapPadding;
    final data = floatingText.data;
    final textDirection = floatingText.textDirection;
    final textAlign = floatingText.textAlign;
    final indentation = floatingText.indentation;
    final style = floatingText.textStyle;

    final floatingParentData = render.floatingTextParentData();
    final rect = floatingParentData.rect;
    final embedPadding = floatingParentData.padding + floatingText.embedPadding;
    capWidth = rect.width;
    capHeight = rect.height;

    // compute drop cap embedPadding
    capWidth += embedPadding.left + embedPadding.right;
    capHeight += embedPadding.top + embedPadding.bottom;

    final firstTextInsets = EdgeInsets.only(
      left: rect.width + embedPadding.left,
      top: embedPadding.top,
    );

    // final mdRest = parseInlineMarkdown ? mdData!.subchars(dropCapChars) : null;
    final restData = data.plainText;

    final textSpan = TextSpan(
      text: restData,
    );

    final textPainter = TextPainter(
      textDirection: textDirection,
      text: textSpan,
      textAlign: textAlign,
    );
    final lineHeight = textPainter.preferredLineHeight;

    int rows = ((capHeight - indentation.dy) / lineHeight).ceil();
    if (rows == 0) rows = 1;

    // BUILDER

    var boundsWidth = constraints.maxWidth - capWidth;
    if (boundsWidth < 1) boundsWidth = 1;

    //int startMillis = new DateTime.now().millisecondsSinceEpoch;

    textPainter.layout(maxWidth: boundsWidth);
    final yPos = rows * lineHeight;
    final charIndex = textPainter
        .getPositionForOffset(
          Offset(0, yPos),
        )
        .offset;
    textPainter
      ..maxLines = rows
      ..layout(maxWidth: boundsWidth);

    if (textPainter.didExceedMaxLines) {
      final first = inflate(
        floatingText.toRichText(
          textSpan.subchars(
            0,
            math.min(charIndex, restData.length),
          ),
        ),
        id: #first,
      );
      final firstSize = first.layout(
        constraints.deflate(firstTextInsets),
      );
      first.position(Offset(capWidth, 0));
      floatingParentData.actualRect = first.size.toRect();

      final second = inflate(
        RichText(
          text: TextSpan(
            text: restData.substring(
              math.min(
                charIndex,
                restData.length,
              ),
            ),
            style: style.apply(
              fontSizeFactor: MediaQuery.of(context).textScaleFactor,
            ),
          ),
          textHeightBehavior: floatingText.textHeightBehavior,
          textWidthBasis: floatingText.textWidthBasis,
          locale: floatingText.locale,
          maxLines: floatingText.maxLines,
          textAlign: floatingText.textAlign,
          textDirection: floatingText.textDirection,
          overflow: floatingText.overflow,
          textScaleFactor: floatingText.textScaleFactor,
          strutStyle: floatingText.strutStyle,
        ),
        id: #second,
      );
      final secondSize = second.layout(BoxConstraints(
          maxHeight: constraints.maxHeight - firstSize.height,
          maxWidth: constraints.maxWidth));
      second.position(Offset(0, firstSize.height));

      return Size(constraints.maxWidth, firstSize.height + secondSize.height);
    } else {
      final first = inflate(floatingText.toRichText(), id: #first);
      final size = first.layout(
        constraints.deflate(firstTextInsets),
      );
      first.position(Offset(capWidth, 0));
      if (hasChild(#second)) {
        getChild(#second).ignore();
      }
      return size;
    }
  }
}
