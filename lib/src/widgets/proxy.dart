import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/iterables.dart';

import '../../flutter_quill.dart';
import '../models/documents/nodes/line.dart';
import '../utils/core_ext.dart';
import 'box.dart';
import 'editor.dart';
import 'float/render_wrappable_text.dart';
import 'float/wrappable_text.dart';
import 'render_editable_ext.dart';

DeepCollectionEquality deepEq = const DeepCollectionEquality();

int i = 0;

class Reporter {
  Reporter(String debugName, {this.labels = const [], int indent = 0})
      : debugName = [
          ...List.generate(indent, (index) => '  '),
          debugName,
          '[${i++}]'
        ].join();

  dynamic value;
  final String debugName;
  final List<String> labels;
  void sync(dynamic value) {
    if (!deepEq.equals(value, this.value)) {
      this.value = value;
      if (labels.isNotEmpty && value is Iterable) {
        final values =
            zip([value, labels]).map((x) => '${x[1]} = ${x[0]};').join(' ');
        print('$debugName: $values');
      } else {
        print('$debugName: $value');
      }
    }
  }
}

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
  void performLayout() {
    super.performLayout();
    quillParent.endingFloats = FloatResult();
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
  TextPosition getPositionForOffset(Offset offset,
          {bool includeFloats = true}) =>
      TextPosition(offset: offset.dx > size.width / 2 ? 1 : 0);

  @override
  TextRange getWordBoundary(TextPosition position) =>
      const TextRange(start: 0, end: 1);

  @override
  double get preferredLineHeight => size.height;

  @override
  bool contains(Offset offset) {
    return size.contains(offset);
  }

  @override
  TextPosition? getPositionAbove(TextPosition from) {
    return null;
  }

  @override
  TextPosition? getPositionBelow(TextPosition from) {
    return null;
  }
}

class RichTextProxy extends MultiChildRenderObjectWidget {
  /// Child argument should be an instance of RichText widget.
  RichTextProxy(
      {required this.line,
      required this.richText,
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
      : super(key: key, children: [...floats.values]);

  final Line line;
  final WrappableText richText;
  final Map<int, Widget> floats;
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
        line, richText, floats, textScaleFactor, DefaultTextStyle.of(context));
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderParagraphProxy renderObject) {
    renderObject
      ..line = line
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
    this.line,
    this._richText,
    this.floats,
    double textScaleFactor,
    DefaultTextStyle defaultTextStyle,
  ) : super() {
    this.defaultTextStyle = defaultTextStyle;
    defaultTextScaleFactor = textScaleFactor;

    _paragraphRenderer = RenderWrappingText([...floats.keys], floats.length,
        this, richText, textDirection, textScaleFactor);
    addAll([_paragraphRenderer]);
    // setupParentData(_paragraphRenderer);
    // add(_paragraphRenderer);
  }

  Line line;
  WrappableText _richText;

  WrappableText get richText => _richText;

  set richText(WrappableText richText) {
    if (_richText != richText) {
      _richText = richText;

      _paragraphRenderer.updateWith(_richText, this, [...floats.keys],
          textDirection, defaultTextStyle, defaultTextScaleFactor);
      markNeedsLayout();
    }
  }

  Map<int, Widget> floats = {};

  int floatPosition(int index) {
    var i = 0;
    for (final offset in floats.keys) {
      if (i == index) return offset;
      i++;
    }
    throw StateError('Index out of bounds: $index');
  }

  late RenderWrappingText _paragraphRenderer;

  RenderWrappingText? get paragraph => _paragraphRenderer;

  @override
  double get preferredLineHeight => _paragraphRenderer.preferredLineHeight;

  final _offsetReporter = Reporter('paragraphOffsetForCaret:');

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype,
      {bool includeFloats = true}) {
    final found = _atTextPos(position);
    _offsetReporter.sync(position.offset);
    if (found == null) {
      throw StateError('Not found for $position');
    }
    if (found.isText) {
      final localTextOffset = position - paragraph!.paragraphOffset;
      final paragraphOffset = paragraph!.getOffsetForCaret(
          localTextOffset, caretPrototype,
          includeFloats: includeFloats);
      return paragraphOffset;
    } else {
      final childOffset = found.box.renderOffset;
      final boxSize = found.box.size;
      return Offset(childOffset.dx + boxSize.width, childOffset.dy);
    }
  }

  @override
  TextPosition getPositionForOffset(Offset offset,
      {required bool includeFloats}) {
    final found = _atOffset(offset);
    if (found == null) {
      print('Falling back to start!');
      return const TextPosition(offset: 0);
    }
    return found.isText
        // Somebody needs the paragraph offset here, but in other contexts, it's not
        // included.  Would it be better for something higher to add back the paragraph
        // offset?
        ? (found.text.getWrappedTextPosForOffset(offset) +
            (includeFloats ? found.text.paragraphOffset : 0))
        : TextPosition(offset: floatPosition(found.floatIndex));
  }

  _ChildPlacement? _atOffset(Offset offset) {
    var child = firstChild;
    var floatIndex = 0;
    while (child != null) {
      if (child is RenderWrappingText) {
        final childRenderer = child.findRendererAtOffset(offset);
        if (childRenderer != null) {
          return _ChildPlacement.paragraph(child, childRenderer);
        }
      } else {
        final childOffset = child.renderOffset;
        final size = child.size;
        final rect = Rect.fromLTWH(
          childOffset.dx,
          childOffset.dy,
          size.width,
          size.height,
        );
        if (rect.contains(offset)) {
          return _ChildPlacement.float(child, floatIndex);
        }
        floatIndex++;
      }
      child = childAfter(child);
    }

    return null;
  }

  _ChildPlacement? _atTextPos(TextPosition pos) {
    final floatOffsets = [...floats.keys];
    final idx = floatOffsets.indexOf(pos.offset);
    if (idx > -1) {
      final child = getChildrenAsList()[idx];
      return _ChildPlacement.float(child, idx);
    } else {
      // Isn't this where you'd put it?  Otherwise, you'll always be guessing
      // what the offset should include floats or not
      var foundRenderer =
          paragraph!.findRendererAtPosition(pos - paragraph!.paragraphOffset);
      if (foundRenderer == null) {
        final valid = paragraph!.validRenderers.toList(growable: false);
        foundRenderer = valid.lastOrNull;
        if (foundRenderer == null) {
          print("Found renderer was null!");
        }
      }
      return _ChildPlacement.paragraph(paragraph!, foundRenderer);
    }
  }

  @override
  double? getFullHeightForCaret(TextPosition position) {
    final found = _atTextPos(position);

    if (found == null) {
      throw StateError('No element found for $position');
    }
    return found.isText
        ? found.text.getFullHeightForCaret(position)
        : found.box.size.height;
  }

  @override
  TextRange getWordBoundary(TextPosition position) =>
      paragraph!.getWordBoundary(position);

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    return childPlacement.expand((element) {
      if (element.isText) {
        return element.text.getBoxesForSelection(selection);
      } else {
        final floatPos = floatPosition(element.floatIndex);
        if (selection.baseOffset <= floatPos &&
            selection.extentOffset >= floatPos) {
          final rect = element.box.renderRect;
          return [
            TextBox.fromLTRBD(
                rect.left, rect.top, rect.right, rect.bottom, TextDirection.ltr)
          ];
        } else {
          return const <TextBox>[];
        }
      }
    }).toList(growable: false);
  }

  Iterable<_ChildPlacement> get childPlacement {
    final r = <_ChildPlacement>[];

    var child = firstChild;
    var floatIndex = 0;
    while (child != null) {
      if (child is RenderWrappingText) {
        r.add(_ChildPlacement.paragraph(child, child.renderer));
      } else {
        r.add(_ChildPlacement.float(child, floatIndex));
        floatIndex++;
      }
      child = childAfter(child);
    }
    return r;
  }

  @override
  bool contains(Offset offset) {
    return _atOffset(offset) != null;
  }

  @override
  TextPosition? getPositionAbove(TextPosition from) {
    final focused = _atTextPos(from);
    assert(focused != null, 'No element at $from');
    Offset currOffset;
    if (focused!.isText) {
      // Since it's text, we should always remove our paragraph offset
      from = from - focused.text.paragraphOffset;
      currOffset = focused.text.getOffsetForCaret(
          from, Rect.fromLTWH(0, 0, 2, focused.text.preferredLineHeight));
      final nextPosition =
          _getPosition(currOffset, -0.5 * focused.text.preferredLineHeight);
      return nextPosition == null
          ? (paragraph!.paragraphOffset > 0
              ? TextPosition(offset: paragraph!.paragraphOffset - 1)
              : null)
          : (nextPosition + focused.text.paragraphOffset);
    } else {
      final above = from - 1;
      return above == from ? null : above;
    }
  }

  @override
  TextPosition? getPositionBelow(TextPosition from) {
    final focused = _atTextPos(from);
    assert(focused != null, 'No element at $from');
    if (focused!.isText) {
      final localTextOffset = from - focused.text.paragraphOffset;
      final currOffset = focused.text.getOffsetForCaret(localTextOffset,
          Rect.fromLTWH(0, 0, 2, focused.text.preferredLineHeight));
      final nextPosition =
          _getPosition(currOffset, 1.5 * focused.text.preferredLineHeight);
      return nextPosition?.plusOffset(focused.text.paragraphOffset);
    } else {
      final below = from + 1;
      return below == from ? null : below;
    }
  }

  TextPosition? _getPosition(Offset currOffset, double unitHeight) {
    final offset = currOffset.translate(0, unitHeight);
    final localOffset = offset;
    if (contains(localOffset)) {
      final newPosition =
          getPositionForOffset(localOffset, includeFloats: false);
      return _checkPosition(newPosition);
    } else {
      // Find the source element, and it's preceding sibling
      final fromElement = _atOffset(currOffset);
      if (fromElement != null) {
        final renderer = unitHeight < 0
            ? fromElement.text.rendererBefore(fromElement.renderer!)
            : fromElement.text.rendererAfter(fromElement.renderer!);
        if (renderer != null) {
          return TextPosition(
              offset: renderer.textOffset + renderer.textLength - 1);
        } else {
          return null;
        }
      }

      return null;
    }
  }

  TextPosition? _checkPosition(TextPosition position) {
    return (line.length >= position.offset) ? position : null;
  }
}

class _ChildPlacement {
  _ChildPlacement.paragraph(RenderWrappingText found, TextRenderer? _renderer)
      : renderer = _renderer,
        _found = found,
        floatIndex = -1;
  _ChildPlacement.float(RenderObject found, this.floatIndex)
      : _found = found,
        renderer = null,
        assert(floatIndex > -1);

  final TextRenderer? renderer;
  final RenderObject _found;
  final int floatIndex;
  bool get isFloat => !isText;
  bool get isText => floatIndex == -1;
  RenderWrappingText get text => _found as RenderWrappingText;
  RenderBox get box => _found as RenderBox;
}
