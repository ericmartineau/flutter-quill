import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../flutter_quill.dart';
import 'box.dart';
import 'editor.dart';
import 'float/render_wrappable_text.dart';
import 'float/wrappable_text.dart';

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
  const EmbedProxy(
    Widget child,
  ) : super(child: child);

  @override
  RenderEmbedProxy createRenderObject(BuildContext context) =>
      RenderEmbedProxy(null);
}

class RenderEmbedProxy extends RenderProxyBox implements RenderContentProxyBox {
  RenderEmbedProxy(RenderBox? child) : super(child);

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    if (!selection.isCollapsed) {
      return <TextBox>[
        TextBox.fromLTRBD(0, 0, size.width, size.height, TextDirection.ltr)
      ];
    }

    final left = selection.extentOffset == 0 ? 0.0 : size.width;
    final right = selection.extentOffset == 0 ? 0.0 : size.width;
    return <TextBox>[
      TextBox.fromLTRBD(left, 0, right, size.height, TextDirection.ltr)
    ];
  }

  @override
  double getFullHeightForCaret(TextPosition position) => size.height;

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype,
      {bool includeFloats = true}) {
    assert(
        position.offset == 1 || position.offset == 0 || position.offset == -1);
    return position.offset <= 0
        ? Offset.zero
        : Offset(size.width - caretPrototype.width, 0);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) =>
      TextPosition(offset: offset.dx > size.width / 2 ? 1 : 0);

  @override
  TextRange getWordBoundary(TextPosition position) =>
      const TextRange(start: 0, end: 1);

  @override
  double get preferredLineHeight => size.height;
}

class RichTextProxy extends MultiChildRenderObjectWidget {
  /// Child argument should be an instance of RichText widget.
  RichTextProxy(
      {required this.richText,
      required this.floats,
      required this.textStyle,
      required this.textAlign,
      required this.textDirection,
      required this.locale,
      required this.strutStyle,
      this.textScaleFactor = 1.0,
      this.textWidthBasis = TextWidthBasis.parent,
      this.textHeightBehavior,
      Key? key})
      : super(key: key, children: [...floats]);

  final WrappableText richText;
  final List<Widget> floats;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final double textScaleFactor;
  final Locale locale;
  final StrutStyle strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  RenderParagraphProxy createRenderObject(BuildContext context) {
    return RenderParagraphProxy(
        richText, floats, textScaleFactor, DefaultTextStyle.of(context));
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderParagraphProxy renderObject) {
    renderObject
      ..richText = richText
      ..floats = floats
      ..defaultTextScaleFactor = textScaleFactor
      ..defaultTextStyle = DefaultTextStyle.of(context)
      ..textDirection = textDirection;
  }
}

class RenderParagraphProxy extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, RenderBoxParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, RenderBoxParentData>,
        FloatLayoutMixin
    implements RenderContentProxyBox {
  RenderParagraphProxy(
    this._richText,
    this.floats,
    double textScaleFactor,
    DefaultTextStyle defaultTextStyle,
  ) : super() {
    this.defaultTextStyle = defaultTextStyle;
    this.defaultTextScaleFactor = textScaleFactor;

    _paragraphRenderer = RenderWrappingText(
        floats.length, this, richText, textDirection, textScaleFactor);
    setupParentData(_paragraphRenderer);
    add(_paragraphRenderer);
  }

  WrappableText _richText;

  WrappableText get richText => _richText;

  set richText(WrappableText richText) {
    if (_richText != richText) {
      _richText = richText;

      _paragraphRenderer.updateWith(_richText, this, floats.length,
          textDirection, defaultTextStyle, defaultTextScaleFactor);
      markNeedsLayout();
    }
  }

  List<Widget> floats = [];

  late RenderWrappingText _paragraphRenderer;

  RenderWrappingText? get paragraph => _paragraphRenderer;

  @override
  double get preferredLineHeight => _paragraphRenderer.preferredLineHeight;

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype,
          {bool includeFloats = true}) =>
      paragraph!.getOffsetForCaret(position, caretPrototype,
          includeFloats: includeFloats);

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
}
