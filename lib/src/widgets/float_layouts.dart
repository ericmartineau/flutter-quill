import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'editor.dart';
import 'float/float_column_semantics_tag.dart';
import 'float/float_data.dart';
import 'float/inline_span_ext.dart';
import 'float/render_float_column.dart';
import 'float/render_object_ext.dart';
import 'float/render_wrappable_text.dart';
import 'float/shared.dart';
import 'float/util.dart';
import 'float_layouts_ext.dart';
import 'render_editable_ext.dart';

// The padding applied to text field. Used to determine the bounds when
// moving the floating cursor.
const EdgeInsets _kFloatingCursorAddedMargin = EdgeInsets.fromLTRB(4, 4, 4, 5);

// The additional size on the x and y axis with which to expand the prototype
// cursor to render the floating cursor in pixels.
const EdgeInsets _kFloatingCaretSizeIncrease =
    EdgeInsets.symmetric(horizontal: 0.5, vertical: 1);

//todo:Ericm remove this
typedef RenderContentProxy = RenderBox;
typedef FloatColumnParentData = RenderBoxParentDataMixin;
typedef RenderFloatColumn = RenderEditor;

/// Displays a document as a vertical list of document segments (lines
/// and blocks).
///
/// Children of [RenderEditor] must be instances of [RenderEditableBox].
mixin FloatLayoutMixin
    on ContainerRenderObjectMixin<RenderBox, RenderBoxParentData>
    implements RenderBox {
  double _scrollBottomInset = 0.0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is RenderBoxParentData) {
      return;
    }

    child.parentData = RenderBoxParentData();
  }

  /// How the children should be placed along the cross axis.
  ///
  /// If the [crossAxisAlignment] is either [CrossAxisAlignment.start] or
  /// [CrossAxisAlignment.end], then the [textDirection] must not be null.
  CrossAxisAlignment get crossAxisAlignment =>
      _crossAxisAlignment ?? CrossAxisAlignment.start;
  CrossAxisAlignment? _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    assert(value != null); // ignore: unnecessary_null_comparison
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// Controls the meaning of the [crossAxisAlignment] property's
  /// [CrossAxisAlignment.start] and [CrossAxisAlignment.end] values.
  ///
  /// If the [crossAxisAlignment] is either [CrossAxisAlignment.start] or
  /// [CrossAxisAlignment.end], then the [textDirection] must not be null.
  TextDirection get textDirection => _textDirection ?? TextDirection.ltr;
  TextDirection? _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  DefaultTextStyle get defaultTextStyle => _defaultTextStyle!;
  DefaultTextStyle? _defaultTextStyle;
  set defaultTextStyle(DefaultTextStyle value) {
    if (_defaultTextStyle != value) {
      _defaultTextStyle = value;
      markNeedsLayout();
    }
  }

  double get defaultTextScaleFactor => _defaultTextScaleFactor ?? 1.0;
  double? _defaultTextScaleFactor;
  set defaultTextScaleFactor(double value) {
    if (_defaultTextScaleFactor != value) {
      _defaultTextScaleFactor = value;
      markNeedsLayout();
    }
  }

  bool get _debugHasNecessaryDirections {
    assert(crossAxisAlignment != null); // ignore: unnecessary_null_comparison
    if (crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end) {
      assert(
          textDirection != null, // ignore: unnecessary_null_comparison
          '$runtimeType has a null textDirection, so the alignment cannot be '
          'resolved.');
    }
    return true;
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow = 0;

  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    assert(value != null); // ignore: unnecessary_null_comparison
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void markNeedsLayout() {
    super.markNeedsLayout();
    _overflow = 0.0;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final hitText = walkTree<RenderWrappingText>((child, state) {
      for (final tr in child.renderers) {
        if (tr.isValid) {
          final rect = tr.textRect;
          if (rect.contains(position)) {
            final textPosition = tr.getPositionForOffset(position - tr.offset);
            final span = tr.text.getSpanForPosition(textPosition);
            if (span != null && span is HitTestTarget) {
              result.add(HitTestEntry(span as HitTestTarget));
              state.stop();
            }
          }
        }
      }
    });
    if (hitText.stopped) {
      return true;
    }
    final resultEmbeds = walkTree<RenderBox>((child, state) {
      if (child.isWidgetItem) {
        final textParentData = child.parentData! as FloatColumnParentData;
        final transform = Matrix4.translationValues(
          textParentData.offset.dx,
          textParentData.offset.dy,
          0,
        )..scale(
            textParentData.scale,
            textParentData.scale,
            textParentData.scale,
          );
        final hitChild = result.addWithPaintTransform(
          transform: transform,
          position: position,
          hitTest: (result, transformed) {
            assert(() {
              final manualPosition =
                  (position - textParentData.offset) / textParentData.scale;
              return (transformed.dx - manualPosition.dx).abs() <
                      precisionErrorTolerance &&
                  (transformed.dy - manualPosition.dy).abs() <
                      precisionErrorTolerance;
            }());
            return child.hitTest(result, position: transformed);
          },
        );

        // Stop at the first child hit.
        if (hitChild) {
          state.stop();
        }
      }
    });
    return resultEmbeds.stopped;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(debugCannotComputeDryLayout(
        reason: 'Dry layout cannot be efficiently computed.'));
    return Size.zero;
  }

  @override
  void performLayout() {
    assert(_debugHasNecessaryDirections);

    _cachedCombinedSemanticsInfos = null;

    final constraints = this.constraints;
    final maxWidth = constraints.maxWidth;

    final BoxConstraints childConstraints;
    if (crossAxisAlignment == CrossAxisAlignment.stretch) {
      childConstraints = BoxConstraints.tightFor(width: maxWidth);
    } else {
      childConstraints = BoxConstraints(maxWidth: maxWidth);
    }

    // These will hold the rectangles of widgets that are floated to the left
    // or right.
    final floatBuilder = quillParent.startingFloats.builder();

    // // This gets updated to the y position for the next child.
    // var yPosNext = 0.0;
    //
    // // This gets updated to the previous non-floated child's bottom margin.
    // var prevBottomMargin = 0.0;

    final isBreak = true;
    walkValidChildren((child, state) {
      if (child.isTextItem) {
        final renderWrappedText = child.wrappingText;
        final wrappable = renderWrappedText.wrappingText;
        // final renderWrappedText = _cache[wrappable.textKey]!;
        // assert(renderWrappedText.renderer.placeholderSpans.isEmpty ||
        //     (child != null && child.editableIndex == i));

        // Resolve the margin and update `yPosNext` and `prevBottomMargin`.
        final margin =
            wrappable.margin.resolve(renderWrappedText.textDirection);
        final topMargin = math.max(floatBuilder.prevBottomMargin, margin.top);
        if (isBreak) {
          // isBreak = false;
          floatBuilder
            ..yPosNext += topMargin
            ..prevBottomMargin = margin.bottom;
        }
        // else {
        // prevBottomMargin = 0.0;
        // }

        _layoutWrappableText(renderWrappedText, childConstraints, maxWidth,
            floats: floatBuilder, breakAfter: true, breakBefore: isBreak);

        // isBreak = false;
        // If this paragraph has inline widget children, set the `offset` and
        // `scale` for each.
        var widgetIndex = 0;

        // state.doWhile(
        //     condition: (item) => item.line == line.line,
        //     onEach: (child) {
        //       assert(child.placeholderIndex == widgetIndex);
        //       final childParentData =
        //           child.parentData! as FloatColumnParentData;
        //       if (child.floatData.float == FCFloat.none) {
        //         final renderer =
        //             renderWrappedText.rendererWithPlaceholder(widgetIndex);
        //         final box =
        //             renderer.placeholderBoxForWidgetIndex(widgetIndex);
        //         childParentData
        //           ..offset = Offset(box.left + renderer.offset.dx,
        //               box.top + renderer.offset.dy)
        //           ..scale =
        //               renderer.placeholderScaleForWidgetIndex(widgetIndex);
        //       }
        //       widgetIndex++;
        //     });
      } else if (child.isWidgetItem) {
        final floatData = child.floatData;
        // assert(editableIndex == i && floatData.placeholderIndex == 0);

        // If not floated, resolve the margin and update `yPosNext` and
        // `prevBottomMargin`.
        if (floatData != null && floatData.float == FCFloat.none) {
          final margin = floatData.margin.resolve(textDirection);
          final topMargin = math.max(floatBuilder.prevBottomMargin, margin.top);
          floatBuilder
            ..yPosNext += topMargin
            ..prevBottomMargin = margin.bottom;
        }

        final childParentData = child.parentData! as FloatColumnParentData;

        _layoutWidget(child, childParentData, childConstraints, maxWidth,
            floatData: floatData, floats: floatBuilder);
      } else {
        assert(false);
      }
    });

    floatBuilder.yPosNext += floatBuilder.prevBottomMargin;
    final totalHeight = math.max(
        floatBuilder.floatL.maxYBelow(floatBuilder.yPosNext),
        floatBuilder.floatR.maxYBelow(floatBuilder.yPosNext));
    _overflow = totalHeight > constraints.maxHeight
        ? totalHeight - constraints.maxHeight
        : 0.0;
    size = constraints.constrain(Size(maxWidth, totalHeight));
    quillParent.endingFloats = floatBuilder.build();
  }

  bool get isLTR => textDirection == TextDirection.ltr;
  bool get isRTL => textDirection == TextDirection.rtl;

  ///
  /// Lays out the given [child] widget, and returns the y position for the
  /// next child.
  ///
  void _layoutWidget(
    RenderBox child,
    FloatColumnParentData parentData,
    BoxConstraints childConstraints,
    double maxWidth, {
    required FloatRenderInfo? floatData,
    required Floats floats,
  }) {
    final origPos = floats.yPosNext;
    final margin = floatData?.margin.resolve(textDirection) ?? EdgeInsets.zero;
    final padding =
        floatData?.padding.resolve(textDirection) ?? EdgeInsets.zero;

    final maxWidthMinusPadding = math.max(0.0,
        maxWidth - margin.left - margin.right - padding.left - padding.right);
    final childMaxWidth = math.min(maxWidthMinusPadding,
        maxWidth * (floatData?.maxWidthPercentage ?? 1.0));

    var layoutConstraints = childConstraints;
    if (childMaxWidth != childConstraints.maxWidth) {
      layoutConstraints = childConstraints.copyWith(
        maxWidth: childMaxWidth,
        minWidth: math.min(layoutConstraints.minWidth, childMaxWidth),
      );
    }

    // child.renderBoxParent.floatStart = floats;
    child.layout(layoutConstraints, parentUsesSize: true);

    var alignment = crossAxisAlignment;

    // Should this child widget be floated to the left or right?
    List<Rect>? addToFloatRects;

    if (floatData != null && floatData.float != FCFloat.none) {
      final float = resolveFloat(floatData.float, withDir: textDirection);
      assert(float == FCFloat.left || float == FCFloat.right);
      if (float == FCFloat.left) {
        addToFloatRects = floats.floatL;
        alignment = isLTR ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      } else {
        addToFloatRects = floats.floatR;
        alignment = isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      }
    }

    // var yPosNext = yPos;

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear = resolveClear(floats.clear ?? floatData?.clear ?? FCClear.none,
        withDir: textDirection);
    final spacing = floatData?.clearMinSpacing ?? 0.0;
    if (clear == FCClear.left || clear == FCClear.both) {
      floats
        ..yPosNext = floats.floatL.nextY(floats.yPosNext, spacing)
        ..yPosStart = floats.yPosNext;
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      floats
        ..yPosNext = floats.floatR.nextY(floats.yPosNext, spacing)
        ..yPosStart = floats.yPosNext;
    }

    final totalMinWidth = child.size.width + padding.left + padding.right;
    final minX = margin.left;
    final maxX = math.max(minX + totalMinWidth, maxWidth - margin.right);

    // Find space for this widget...
    var rect = findSpaceFor(
      floats: floats,
      width: math.min(maxWidth, totalMinWidth),
      height: child.size.height + padding.top + padding.bottom,
      minX: minX,
      maxX: maxX,
    );

    // Adjust rect for padding.
    if (padding != EdgeInsets.zero) {
      rect = Rect.fromLTRB(
        rect.left + padding.left,
        rect.top + padding.top,
        rect.right - padding.right,
        rect.bottom - padding.bottom,
      );
    }

    // Calculate `xPos` based on alignment and available space.
    final xPos = xPosForChildWithWidth(
        child.size.width, alignment, rect.left, rect.right);

    // floats.yPosNext = rect.top;
    // floats.offset = Offset(xPos, rect.top);
    parentData
      ..offset = Offset(xPos, rect.top)
      ..scale = 1.0;

    if (addToFloatRects != null) {
      // Include padding for the floated rect.
      addToFloatRects.add(Rect.fromLTRB(
        xPos - padding.left,
        rect.top - padding.top,
        xPos + child.size.width + padding.right,
        rect.top + child.size.height + padding.bottom,
      ));
      // This widget was floated, so set `yPosNext` back to `yPos`.
      floats.yPosNext = origPos;
    } else {
      floats.yPosNext = rect.top + child.size.height + padding.bottom;
    }
  }

  VisitorState<RenderBox> walkValidChildren(
      void Function(RenderBox box, VisitorState<RenderBox> state) onEach) {
    return walkTree<RenderBox>((child, state) {
      // if (!child.isTextItem || child.wrappingText.isValid) {
      onEach(child, state);
      // }
    });
  }

  ///
  /// Lays out the given WrappableText object, and returns the y position for
  /// the next child.
  ///
  void _layoutWrappableText(
    RenderWrappingText render,
    // RenderEditableTextLine line,
    BoxConstraints childConstraints,
    double maxWidth, {
    required Floats floats,
    required bool breakBefore,
    required bool breakAfter,
    // required RenderContainerNode line,
    // required RenderLeafNode editable,
  }) {
    final meta = render.wrappingText;
    final margin = meta.margin.resolve(render.textDirection);
    final padding = meta.padding.resolve(render.textDirection);

    if (breakBefore) {
      floats.yPosNext += padding.top;
    }

    // Check for `clear` and adjust `yPosNext` accordingly.
    final clear =
        resolveClear(floats.clear ?? meta.clear, withDir: render.textDirection);
    if (clear == FCClear.left || clear == FCClear.both) {
      floats.yPosNext = floats.floatL.maxYBelow(floats.yPosNext);
      floats.yPosStart = floats.yPosNext;
    }
    if (clear == FCClear.right || clear == FCClear.both) {
      floats.yPosNext = floats.floatR.maxYBelow(floats.yPosNext);
      floats.yPosStart = floats.yPosNext;
    }

    // Clear the sub-paragraph renderers for wrapping text.
    render.subs.clear();

    // Keep track of the indices of the floated inline widget children that
    // have already been laid out, because they can only be laid out once.
    final laidOutFloaterIndices = <int>{};

    TextRenderer? rendererBeforeSplit;

    //
    // Loop over this WrappableText's renderers. It starts out with the default
    // text renderer which includes all the text, but if the text needs to be
    // split because the available width and/or x position changes (because of
    // floated widgets), the the text is split into two new renderers that
    // replace the current renderer, and the loop is run again. This continues
    // until all the text is laid out, using as many renderers as necessary to
    // wrap around floated widget positions.
    //
    var subIndex = -1;
    while (subIndex < render.subs.length) {
      // Get the estimated line height for the first line. We want to find
      // space for at least the first line of text.
      final estLineHeight = render[subIndex].initialLineHeight();

      // If the text starts with a line feed, remove the line feed, add the
      // line height to `yPosNext`, and re-run the loop.
      final initialText = render[subIndex].text.initialText();
      if (initialText.isNotEmpty && initialText.codeUnitAt(0) == 0x0a) {
        final textRenderer = render[subIndex];
        final split = textRenderer.text.splitAtCharacterIndex(1);
        if (split.length == 2) {
          if (subIndex == -1) {
            subIndex = 0;
          } else {
            render.subs.removeAt(subIndex);
          }

          render.subs.add(textRenderer.copyWith(
              textOffset: textRenderer.textOffset + 1,
              text: split.last,
              startingPlaceholderIndex: subIndex == 0
                  ? 0
                  : render.subs[subIndex - 1].nextPlaceholderIndex));

          if (breakAfter) {
            floats.yPosNext += estLineHeight;
          }

          // Re-run the loop, keeping the index the same.
          continue; //-------------------------------------------->
        }
      }

      final estScaledFontSize = render[subIndex].initialScaledFontSize();

      // Adjust the left padding based on indent value.
      final paddingLeft = padding.left + (subIndex <= 0 ? meta.indent : 0.0);

      final lineMinWidth =
          estScaledFontSize * 4.0 + paddingLeft + padding.right;
      final lineMinX = margin.left;
      final lineMaxX =
          math.max(lineMinX + lineMinWidth, maxWidth - margin.right);

      // Find space for a width of at least `estLineHeight * 4.0`. This may
      // need to be tweaked, or it could be an option passed in, or we could
      // layout the text and find the actual width of the first word, and that
      // could be the minimum width?
      var rect = findSpaceFor(
          floats: floats,
          width: lineMinWidth,
          height: estLineHeight,
          minX: lineMinX,
          maxX: lineMaxX);

      // Adjust rect for padding.
      rect = Rect.fromLTRB(
        rect.left + paddingLeft,
        rect.top,
        rect.right - padding.right,
        rect.bottom,
      );

      // dmPrint('findSpaceFor $yPosNext, estLineHeight $estLineHeight: $rect');

      final subConstraints = childConstraints.copyWith(
        maxWidth: rect.width,
        minWidth: math.min(childConstraints.minWidth, rect.width),
      );

      var hasFloatedChildren = floats.hasFloats;

      // If the sub-renderer has inline widget children, set placeholder
      // dimensions, which MUST be done before `wtr[subIndex].layout` is
      // called.
      if (render[subIndex].placeholderSpans.isNotEmpty) {
        final _hasFloatedChildren = render[subIndex].setPlaceholderDimensions(
            this, subConstraints, meta.textScaleFactor ?? 1.0);
        hasFloatedChildren = _hasFloatedChildren || _hasFloatedChildren;
      }

      // Layout the text and inline widget children.
      render[subIndex].layout(subConstraints);

      // If this is the default (-1) or last renderer, check to see if it needs
      // to be split.
      if (subIndex == -1 || subIndex == render.subs.length - 1) {
        // TODO(ron): It is possible that the estimated line height is less
        // than the actual first line height, which could cause the text in the
        // line to overlap floated widgets below it. This could be fixed by
        // using `painter.computeLineMetrics` to check, and then call
        // `findSpaceFor` again, if necessary, with the actual first line
        // height.

        // If this is the first line of the paragraph, and the indent value is
        // not zero, the second line has a different left padding, so it needs
        // to be laid out separately, so set the `bottom` value accordingly.
        final bottom = math.min(
            rect.bottom,
            subIndex > 0 || meta.indent == 0.0
                ? rect.bottom
                : rect.top + estLineHeight / 2.0);

        // `findSpaceFor` just checked for space for the first line of text.
        // Now that the text has been laid out, we need to see if the available
        // space extends the full height of the text.
        final startY = rect.top + estLineHeight;
        final nextFloatTop = math.min(
          floats.floatL.topOfTopMostRectAtOrBelow(startY),
          floats.floatR.topOfTopMostRectAtOrBelow(startY),
        );
        final nextChangeY = math.min(bottom, nextFloatTop);

        // If the text extends past `nextChangeY`, we need to split the text,
        // and layout each part individually...
        if (rect.top + render[subIndex].height > nextChangeY) {
          final span = render[subIndex].text;
          if (span is TextSpan) {
            //
            // Calculate the approximate x, y to split the text at, which
            // depends on the text direction.
            //
            // ⦿ Shows the x, y offsets the text should be split at:
            //
            // RTL example:
            //  | This is what you   ┌──────────┐
            //  | shall do; Love the ⦿          │
            //  ├────────┐ earth and ⦿──────────┤
            //  │        │ sun and the animals, |
            //  ├────────┘ despise riches, give ⦿
            //  │ alms to every one that asks...|
            //
            // LTR example:
            //  |   you what is This ┌──────────┐
            //  ⦿ the Love ;do shall │          │
            //  ├────────⦿ and earth └──────────┤
            //  │        │ ,animals the and sun |
            //  ├────────⦿ give ,riches despise |
            //  │...asks that one every to alms |
            //
            final dir = render[subIndex].textDirection;
            final x = dir == TextDirection.ltr ? rect.width : 0.0;
            final y =
                math.min(nextChangeY, nextFloatTop - estLineHeight) - rect.top;

            // Get the character index in the text from the point offset.
            var charIndex =
                render[subIndex].getPositionForOffset(Offset(x, y)).offset;
            if (charIndex > 0) {
              final text = span.toPlainText(includeSemanticsLabels: false);
              if (charIndex < text.length - 1) {
                // Skip trailing spaces.
                final codeUnits = text.codeUnits;
                while (charIndex < codeUnits.length - 1 &&
                    codeUnits[charIndex] == 0x0020) {
                  charIndex++;
                }

                // final str1 = text.substring(0, charIndex);
                // dmPrint('Splitting at ${Offset(x, y)} after "$str1"');

                // Split the TextSpan at `charIndex`.
                final split = span.splitAtCharacterIndex(charIndex);

                // If it was split into two spans...
                if (split.length == 2) {
                  //
                  // This fixes a bug where, if a span is split right before a
                  // line feed, and we don't remove the line feed, it is
                  // rendered like two line feeds.
                  //
                  // If the second span starts with a '\n' (line feed), remove
                  // the '\n'.
                  if (text.codeUnitAt(charIndex) == 0x0a) {
                    final s2 = split.last.splitAtCharacterIndex(1);
                    if (s2.length == 2) {
                      assert(
                          s2.first.toPlainText(includeSemanticsLabels: false) ==
                              '\n');
                      split[1] = s2.last;
                    }
                  }

                  final textRenderer = render[subIndex];
                  rendererBeforeSplit = textRenderer;
                  if (subIndex == -1) {
                    subIndex = 0;
                  } else {
                    render.subs.removeLast();
                  }
                  render.subs
                    ..add(textRenderer.copyWith(
                        text: split.first,
                        startingPlaceholderIndex: subIndex == 0
                            ? 0
                            : render.subs[subIndex - 1].nextPlaceholderIndex))
                    ..add(textRenderer.copyWith(
                        text: split.last,
                        textOffset: textRenderer.textOffset + charIndex,
                        startingPlaceholderIndex:
                            render.subs[subIndex].nextPlaceholderIndex));

                  // Re-run the loop, keeping the index the same.
                  continue; //------------------------------------>
                }
              }
            }
          }
        }
      }

      // At this point renderer wtr[subIndex] has gone through its final
      // layout, so we can now layout its floated widget children, if any.

      if (hasFloatedChildren) {
        /// Local func that lays out the first floated child that has not
        /// already been laid out, if any, and returns true iff a child was
        /// laid out.
        ///
        /// The floated children need to be laid out one at a time because
        /// each time one is laid out the positions of subsequent floated
        /// children will likely be affected.
        bool _layoutFloatedChildren(
            TextRenderer renderer, RenderBox? firstChild) {
          if (firstChild == null) return false;
          RenderBox? child = firstChild;
          int i = 0;
          while (child != null) {
            final childParentData = child.parentData! as FloatColumnParentData;
            if (child.isWidgetItem && child.floatData != null) {
              // final ctpIndex = child.editableData.placeholderIndex;
              // If this child is floated...

              final floatData = child.floatData!;
              if (floatData.float != FCFloat.none &&
                  !laidOutFloaterIndices.contains(i)) {
                laidOutFloaterIndices.add(i);
                final boxTop = renderer.placeholderBoxForWidgetIndex(i).top;
                floats.yPosNext = boxTop + rect.top - estLineHeight;
                _layoutWidget(
                    child, childParentData, childConstraints, maxWidth,
                    floatData: floatData, floats: floats);
                return true;
              }
            }
            child = childParentData.nextSibling;
          }
          return false;
        }

        final rerunLoop = _layoutFloatedChildren(render[subIndex], render);
        if (rerunLoop) {
          // If the original renderer was split, undo the split because it
          // will likely need to be re-split differently.
          if (rendererBeforeSplit != null) {
            assert(render.subs.length == subIndex + 2);
            render.subs
              ..removeLast()
              ..removeLast()
              ..add(rendererBeforeSplit);
            rendererBeforeSplit = null;
          }

          // Re-run the loop, keeping the index the same.
          continue; //-------------------------------------------->
        }
      }

      // Clear this before the next loop.
      rendererBeforeSplit = null;

      CrossAxisAlignment alignment() {
        switch (render[subIndex].textAlign) {
          case TextAlign.left:
            return isLTR ? CrossAxisAlignment.start : CrossAxisAlignment.end;
          case TextAlign.right:
            return isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end;
          case TextAlign.center:
            return CrossAxisAlignment.center;
          case TextAlign.justify:
            return CrossAxisAlignment.stretch;
          case TextAlign.start:
            return CrossAxisAlignment.start;
          case TextAlign.end:
            return CrossAxisAlignment.end;
        }
      }

      // Calculate `xPos` based on alignment and available space.
      final xPos = xPosForChildWithWidth(
          render[subIndex].width, alignment(), rect.left, rect.right);

      render[subIndex].offset = Offset(xPos, rect.top);
      floats.yPosNext = rect.top;
      if (breakAfter) {
        floats.yPosNext += render[subIndex].height;
      }

      subIndex++;
    } // while (subIndex < wtr.subs.length)

    if (breakAfter) {
      floats.yPosNext += padding.bottom;
    }
  }

  ///
  /// Given a child's [width] and [alignment], and the [minX] and [maxX],
  /// returns the x position for the child.
  ///
  double xPosForChildWithWidth(
      double width, CrossAxisAlignment alignment, double minX, double maxX) {
    final double childCrossPosition;
    switch (alignment) {
      case CrossAxisAlignment.start:
        childCrossPosition = isLTR ? minX : maxX - width;
        break;
      case CrossAxisAlignment.end:
        childCrossPosition = isRTL ? minX : maxX - width;
        break;
      case CrossAxisAlignment.center:
        childCrossPosition = (minX + maxX) / 2.0 - width / 2.0;
        break;
      case CrossAxisAlignment.stretch:
      case CrossAxisAlignment.baseline:
        childCrossPosition = minX;
        break;
    }
    return childCrossPosition;
  }

  void _paintFloatColumn(PaintingContext context, Offset offset) {
    // RenderEd? child = firstChild;
    // if (child == null) return;

    // line.leading?.paint(context, offset);

    final paintResult = walkValidChildren((el, state) {
      //---------------------------------------------------------------------
      // If it is a Widget
      //
      if (el.isWidgetItem) {
        // assert(editableIndex == i && placeholderIndex == 0,
        //     "Float data index should match! ${editableIndex}: ${i} and ph:${placeholderIndex}==0");

        final childParentData = el.parentData! as FloatColumnParentData;
        context.paintChild(el, childParentData.offset + offset);
      }

      //---------------------------------------------------------------------
      // Else, if it is a WrappableText
      //
      else if (el.isTextItem) {
        var wtr = el.wrappingText;

        for (final textRenderer in wtr.renderers) {
          textRenderer.paint(context, offset);
        }

        // dmPrint('painted $i, text at ${wtr.offset! + offset}');

        // If this paragraph DOES have inline widget children...

        // var widgetIndex = 0;
        // state.doWhile(
        //     condition: (child) => child.line == el.line,
        //     onEach: (child) {
        //       final childParentData = child.editableData;
        //
        //       if (child.floatData.float != FCFloat.none) {
        //         // Floated inline widget children are rendered like normal
        //         // children.
        //         context.paintChild(child, childParentData.offset + offset);
        //       } else {
        //         // Non-floated inline widget children are scaled with the text.
        //         final scale = childParentData.scale;
        //         context.pushTransform(
        //           needsCompositing,
        //           offset + childParentData.offset,
        //           Matrix4.diagonal3Values(scale, scale, scale),
        //           (context, offset) => context.paintChild(child, offset),
        //         );
        //       }
        //
        //       widgetIndex++;
        //     });
      } else {
        assert(false);
      }
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      _paintFloatColumn(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty) return;

    if (clipBehavior == Clip.none) {
      _clipRectLayer = null;
      _paintFloatColumn(context, offset);
    } else {
      // We have overflow and the clipBehavior isn't none. Clip it.
      _clipRectLayer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paintFloatColumn,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer,
      );
    }
  }

  ClipRectLayer? _clipRectLayer;

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _hasOverflow ? Offset.zero & size : null;

  @override
  String toStringShort() {
    var header = '';
    if (_hasOverflow) header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(EnumProperty<CrossAxisAlignment>(
          'crossAxisAlignment', crossAxisAlignment))
      ..add(EnumProperty<TextDirection>('textDirection', textDirection,
          defaultValue: null));
  }

  //
  // Semantics related:
  //

  /// Collected during [describeSemanticsConfiguration], used by
  /// [assembleSemanticsNode].
  AttributedString? _cachedAttributedLabel;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    final semanticsInfo = getSemanticsInfo();

    if (semanticsInfo.anyItem((info) => info.recognizer != null)) {
      config
        ..explicitChildNodes = true
        ..isSemanticBoundary = true;
    } else {
      if (_cachedAttributedLabel == null) {
        final buffer = StringBuffer();
        var offset = 0;
        final attributes = <StringAttribute>[];
        for (final entry in semanticsInfo.entries) {
          for (final list in entry.value) {
            for (final info in list) {
              final label = info.semanticsLabel ?? info.text;
              for (final infoAttribute in info.stringAttributes) {
                final originalRange = infoAttribute.range;
                attributes.add(
                  infoAttribute.copy(
                      range: TextRange(
                          start: offset + originalRange.start,
                          end: offset + originalRange.end)),
                );
              }
              buffer.write(label);
              offset += label.length;
            }
          }
        }
        _cachedAttributedLabel =
            AttributedString(buffer.toString(), attributes: attributes);
      }
      config
        ..attributedLabel = _cachedAttributedLabel!
        ..textDirection = textDirection;
    }
  }

  // Caches [SemanticsNode]s created during [assembleSemanticsNode] so they
  // can be re-used when [assembleSemanticsNode] is called again. This ensures
  // stable ids for the [SemanticsNode]s of [TextSpan]s across
  // [assembleSemanticsNode] invocations.
  Queue<SemanticsNode>? _cachedChildNodes;

  Map<int, List<List<InlineSpanSemanticsInformation>>>?
      _cachedCombinedSemanticsInfos;

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    final semanticsChildren = children;
    final newSemanticsChildren = <SemanticsNode>[];

    var renderChild = firstChild;

    var currentDirection = textDirection;
    var ordinal = 0.0;
    var semanticsChildIndex = 0;
    final newChildCache = Queue<SemanticsNode>();

    _cachedCombinedSemanticsInfos ??= getSemanticsInfo(combined: true);

    // dmPrint('\n\n************ assembleSemanticsNode *************');

    for (final entry in _cachedCombinedSemanticsInfos!.entries) {
      final floatIndex = entry.key;
      var placeholderIndex = 0;

      final el = get<RenderBox>(floatIndex);

      final wtr = (el.isTextItem) ? el.wrappingText : null;
      assert(wtr == null || wtr.renderer.placeholderSpans.isEmpty);

      var textRendererIndex = 0;

      for (final list in entry.value) {
        var textRangeStart = 0;
        for (final info in list) {
          if (info.isPlaceholder) {
            // A placeholder span may have 0 to multiple semantics nodes.
            while (semanticsChildren.length > semanticsChildIndex &&
                semanticsChildren.elementAt(semanticsChildIndex).isTagged(
                    FloatColumnPlaceholderSpanSemanticsTag(
                        floatIndex, placeholderIndex))) {
              final semanticsChildNode =
                  semanticsChildren.elementAt(semanticsChildIndex);
              final parentData =
                  renderChild!.parentData! as FloatColumnParentData;
              final rect = Rect.fromLTWH(
                semanticsChildNode.rect.left,
                semanticsChildNode.rect.top,
                semanticsChildNode.rect.width * parentData.scale,
                semanticsChildNode.rect.height * parentData.scale,
              );
              semanticsChildNode.rect = rect;
              // dmPrint('Adding semantics node for widget $floatColumnChildIndex '
              //     'with rect $rect');
              newSemanticsChildren.add(semanticsChildNode);
              semanticsChildIndex += 1;
            }
            renderChild = childAfter(renderChild!);
            placeholderIndex += 1;
          } else {
            if (wtr == null || textRendererIndex >= wtr.renderers.length) {
              assert(false);
            } else {
              final textRenderer = wtr.renderers[textRendererIndex];

              final selection = TextSelection(
                baseOffset: textRangeStart,
                extentOffset: textRangeStart + info.text.length,
              );
              textRangeStart += info.text.length;

              // dmPrint('\n\ncalling getBoxes for '
              //     '[${selection.baseOffset}, ${selection.extentOffset}] '
              //     'substring '
              //     '[${info.text}] in [${textRenderer.toPlainText()}]\n');

              final initialDirection = currentDirection;
              final rects = textRenderer.getBoxesForSelection(selection);
              if (rects.isNotEmpty) {
                var rect = rects.first.toRect();
                currentDirection = rects.first.direction;
                for (final textBox in rects.skip(1)) {
                  rect = rect.expandToInclude(textBox.toRect());
                  currentDirection = textBox.direction;
                }

                // Any of the text boxes may have had infinite dimensions.
                // We shouldn't pass infinite dimensions up to the bridges.
                rect = Rect.fromLTWH(
                  math.max(0, rect.left),
                  math.max(0, rect.top),
                  math.min(rect.width, constraints.maxWidth),
                  math.min(rect.height, constraints.maxHeight),
                );

                // Round the current rectangle to make this API testable and
                // add some padding so that the accessibility rects do not
                // overlap with the text.
                final currentRect = Rect.fromLTRB(
                  rect.left.floorToDouble() - 4.0,
                  rect.top.floorToDouble() - 4.0,
                  rect.right.ceilToDouble() + 4.0,
                  rect.bottom.ceilToDouble() + 4.0,
                );

                final configuration = SemanticsConfiguration()
                  ..sortKey = OrdinalSortKey(ordinal++)
                  ..textDirection = initialDirection
                  ..attributedLabel = AttributedString(
                      info.semanticsLabel ?? info.text,
                      attributes: info.stringAttributes);

                final recognizer = info.recognizer;
                if (recognizer != null) {
                  if (recognizer is TapGestureRecognizer) {
                    if (recognizer.onTap != null) {
                      configuration
                        ..onTap = recognizer.onTap
                        ..isLink = true;
                    }
                  } else if (recognizer is DoubleTapGestureRecognizer) {
                    if (recognizer.onDoubleTap != null) {
                      configuration
                        ..onTap = recognizer.onDoubleTap
                        ..isLink = true;
                    }
                  } else if (recognizer is LongPressGestureRecognizer) {
                    if (recognizer.onLongPress != null) {
                      configuration.onLongPress = recognizer.onLongPress;
                    }
                  } else {
                    assert(
                        false, '${recognizer.runtimeType} is not supported.');
                  }
                }

                // dmPrint('Adding semantics node for span $floatColumnChildIndex:'
                //     '$textRendererIndex with rect $rect '
                //     '${recognizer == null ? '' : 'WITH RECOGNIZER '}'
                //     'for text "${info.text}" ');

                final newChild = ((_cachedChildNodes?.isNotEmpty == true)
                    ? _cachedChildNodes!.removeFirst()
                    : SemanticsNode())
                  ..updateWith(config: configuration)
                  ..rect = currentRect;

                newChildCache.addLast(newChild);
                newSemanticsChildren.add(newChild);
              }
            }
          }
        }
        textRendererIndex++;
      }
    }

    // Make sure we annotated all of the semantics children.
    assert(semanticsChildIndex == semanticsChildren.length);
    assert(renderChild == null);

    _cachedChildNodes = newChildCache;
    node.updateWith(
        config: config, childrenInInversePaintOrder: newSemanticsChildren);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _cachedChildNodes = null;
  }

  //
  // Utility functions:
  //
  Map<int, List<List<InlineSpanSemanticsInformation>>> getSemanticsInfo({
    bool combined = false,
  }) {
    final semanticsInfo = <int, List<List<InlineSpanSemanticsInformation>>>{};

    final result = walkValidChildren((child, state) {
      if (child.isWidgetItem) {
        // Add a placeholder for each regular child widget.
        semanticsInfo[state.index] = [
          [InlineSpanSemanticsInformation.placeholder]
        ];
      } else if (child.isTextItem) {
        var wtr = child.wrappingText;

        semanticsInfo[state.index] = [
          for (final textRenderer in wtr.renderers)
            textRenderer.getSemanticsInfo(combined: combined)
        ];
      }
    });

    return semanticsInfo;
  }
}

extension _PrivateExtOnMapOfListOfList<S, T> on Map<S, List<List<T>>> {
  bool anyItem(bool Function(T) test) {
    for (final entry in entries) {
      for (final list in entry.value) {
        if (list.any(test)) return true;
      }
    }
    return false;
  }
}
