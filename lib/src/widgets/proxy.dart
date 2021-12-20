import 'dart:math' as math;

import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/src/widgets/extensions.dart';
import 'package:flutter_quill/src/widgets/text_line.dart';

import 'box.dart';

class BaselineProxy extends SingleChildRenderObjectWidget {
  const BaselineProxy({Key? key, Widget? child, this.textStyle, this.padding})
      : super(key: key, child: child);

  final TextStyle? textStyle;
  final EdgeInsets? padding;

  @override
  RenderBaselineProxy createRenderObject(BuildContext context) {
    return RenderBaselineProxy(
      null,
      textStyle!,
      padding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderBaselineProxy renderObject) {
    renderObject
      ..textStyle = textStyle!
      ..padding = padding!;
  }
}

class RenderBaselineProxy extends RenderProxyBox {
  RenderBaselineProxy(
    RenderParagraph? child,
    TextStyle textStyle,
    EdgeInsets? padding,
  )   : _prototypePainter = TextPainter(
            text: TextSpan(text: ' ', style: textStyle),
            textDirection: TextDirection.ltr,
            strutStyle:
                StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true)),
        super(child);

  final TextPainter _prototypePainter;

  set textStyle(TextStyle value) {
    if (_prototypePainter.text!.style == value) {
      return;
    }
    _prototypePainter.text = TextSpan(text: ' ', style: value);
    markNeedsLayout();
  }

  EdgeInsets? _padding;

  set padding(EdgeInsets value) {
    if (_padding == value) {
      return;
    }
    _padding = value;
    markNeedsLayout();
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) =>
      _prototypePainter.computeDistanceToActualBaseline(baseline);

  // SEE What happens + _padding?.top;

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout();
  }
}

class EmbedProxy extends SingleChildRenderObjectWidget {
  const EmbedProxy(Widget child) : super(child: child);

  @override
  RenderEmbedProxy createRenderObject(BuildContext context) =>
      RenderEmbedProxy(null);
}

class RenderEmbedProxy extends RenderProxyBox implements RenderContentProxyBox {
  RenderEmbedProxy(RenderBox? child) : super(child);

  late Size _size;
  late Rect _leadingSize;

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    super.layout(constraints, parentUsesSize: parentUsesSize);
    _size = size;
  }

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    if (!selection.isCollapsed) {
      return <TextBox>[
        TextBox.fromLTRBD(0, 0, _size.width, _size.height, TextDirection.ltr)
      ];
    }

    final left = selection.extentOffset == 0 ? 0.0 : _size.width;
    final right = selection.extentOffset == 0 ? 0.0 : _size.width;
    return <TextBox>[
      TextBox.fromLTRBD(left, 0, right, _size.height, TextDirection.ltr)
    ];
  }

  @override
  double getFullHeightForCaret(TextPosition position) => _size.height;

  @override
  Offset getOffsetForCaret(TextPosition position, Rect? caretPrototype) {
    if (!(position.offset == 1 ||
        position.offset == 0 ||
        position.offset == -1)) {
      return Offset.zero;
    }
    return position.offset <= 0
        ? Offset.zero
        : Offset(
            _size.width - (caretPrototype == null ? 0 : caretPrototype.width),
            0);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) =>
      TextPosition(offset: offset.dx > _size.width / 2 ? 1 : 0);

  @override
  TextRange getWordBoundary(TextPosition position) =>
      const TextRange(start: 0, end: 1);

  @override
  double getPreferredLineHeight() {
    return _size.height;
  }

  @override
  set leadingSize(Rect size) {
    _leadingSize = size;
  }
}
