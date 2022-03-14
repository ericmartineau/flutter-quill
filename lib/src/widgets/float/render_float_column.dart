// // Copyright (c) 2021 Ron Booth. All rights reserved.
// // Use of this source code is governed by a license that can be found in the
// // LICENSE file.
//
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
//
// import '../../../flutter_quill.dart';
// import '../box.dart';
//
// typedef FloatColumnParentData = RenderBoxParentDataMixin;
// typedef RenderFloatColumn = RenderEditor;
//
// /// A render object that displays a vertical list of widgets and paragraphs of
// /// text.
// ///
// /// ## Layout algorithm
// ///
// /// _This section describes how [RenderFloatColumn] positions its children._
// /// _See [BoxConstraints] for an introduction to box layout models._
// ///
// /// Layout for a [RenderFloatColumn] proceeds in six steps:
// ///
// /// 1. Layout each child with unbounded main axis constraints and the incoming
// ///    cross axis constraints. If the [crossAxisAlignment] is
// ///    [CrossAxisAlignment.stretch], instead use tight cross axis constraints
// ///    that match the incoming max extent in the cross axis.
// ///
// /// 2. The cross axis extent of the [RenderFloatColumn] is the maximum cross
// ///    axis extent of the children (which will always satisfy the incoming
// ///    constraints).
// ///
// /// 3. The main axis extent of the [RenderFloatColumn] is the sum of the main
// ///    axis extents of the children (subject to the incoming constraints).
// ///
// //   with
// //       ContainerRenderObjectMixin<RenderEditableBox,
// //           EditableContainerParentData>,
// //       RenderBoxContainerDefaultsMixin<RenderEditableBox,
// //           EditableContainerParentData>,
// //       DebugOverflowIndicatorMixin,
// //       VisitChildrenOfAnyTypeMixin {
// // /// Creates a FloatColumn render object.
// // ///
// // /// By default, the children are aligned to the start of the cross axis.
// // RenderFloatColumn(
// //   this._textAndWidgets, {
// //   required CrossAxisAlignment crossAxisAlignment,
// //   required TextDirection textDirection,
// //   required DefaultTextStyle defaultTextStyle,
// //   required double defaultTextScaleFactor,
// //   Clip clipBehavior = Clip.none,
// //   List<RenderEditableBox>? children,
// // })  :
// //       // ignore: unnecessary_null_comparison
// //       assert(crossAxisAlignment != null),
// //       // ignore: unnecessary_null_comparison
// //       assert(clipBehavior != null),
// //       _internalTextAndWidgets = _textAndWidgets,
// //       _crossAxisAlignment = crossAxisAlignment,
// //       _textDirection = textDirection,
// //       _defaultTextStyle = defaultTextStyle,
// //       _defaultTextScaleFactor = defaultTextScaleFactor,
// //       _clipBehavior = clipBehavior {
// //   addAll(children);
// //   _updateCache();
// // }
//
// extension _PrivateExtOnMapOfListOfList<S, T> on Map<S, List<List<T>>> {
//   bool anyItem(bool Function(T) test) {
//     for (final entry in entries) {
//       for (final list in entry.value) {
//         if (list.any(test)) return true;
//       }
//     }
//     return false;
//   }
// }
//
// extension RenderEditableBoxFloatData on RenderEditableBox {
//   // FloatRenderInfo get floatData => (this as RenderEditableTextLine).metaData;
// }
//
// // extension on RenderFloatColumn {
// //   bool get isLTR => textDirection == TextDirection.ltr;
// //   bool get isRTL => textDirection == TextDirection.rtl;
// // }
//
// extension on Object {}
//
// extension on Object {
//   // WrappableText get wrappableText {
//   //   final self = this;
//   //   if (self is EditableTextLine && self.inlineNode is InlineText) {
//   //     final meta = self.metaData;
//   //     final txt = self.inlineNode as InlineText;
//   //     return WrappableText(
//   //       text: txt.textSpan,
//   //       textKey: (self.body as TextLine).defaultKey,
//   //       textAlign: txt.textAlign,
//   //       textDirection: txt.textDirection,
//   //       textScaleFactor: txt.textScaleFactor,
//   //       strutStyle: txt.strutStyle,
//   //       clear: meta.clear,
//   //       margin: meta.margin,
//   //       padding: meta.padding,
//   //       indent: meta.indent,
//   //     );
//   //   } else {
//   //     throw StateError('Cannot create from wrong type');
//   //   }
//   // }
// }
//
// extension on Object {
//   // WrappableText get wrappableText {
//   //   final self = this;
//   //   if (self is EditableTextLine && self.inlineNode is InlineText) {
//   //     final meta = self.metaData;
//   //     final txt = self.inlineNode as InlineText;
//   //     return WrappableText(
//   //       text: txt.textSpan,
//   //       textKey: (self.body as TextLine).defaultKey,
//   //       textAlign: txt.textAlign,
//   //       textDirection: txt.textDirection,
//   //       textScaleFactor: txt.textScaleFactor,
//   //       strutStyle: txt.strutStyle,
//   //       clear: meta.clear,
//   //       margin: meta.margin,
//   //       padding: meta.padding,
//   //       indent: meta.indent,
//   //     );
//   //   } else {
//   //     throw StateError('Cannot create from wrong type');
//   //   }
//   // }
// }
// //
// // extension on RenderLeafNode {
// //   RenderTextNode get textNode {
// //     return this as RenderTextNode;
// //   }
// //
// //   RenderEmbedNode get embedNode {
// //     return this as RenderEmbedNode;
// //   }
// // }
// //
// // extension on RenderLeafNode {
// //   bool get isTextItem {
// //     final item = this;
// //     return item is RenderTextNode;
// //   }
// //
// //   bool get isWidgetItem {
// //     final item = this;
// //     return item is RenderEmbedNode;
// //   }
// // }
// //
// // class RenderLeafDetails {
// //   RenderLeafDetails(this.leaf, this.parent);
// //
// //   final RenderLeafNode leaf;
// //   final RenderContainerNode parent;
// // }
//
// // extension RenderCNExt<S extends container_node.Container>
// //     on RenderContainerNode<S> {
// //   Iterable<RenderLeafDetails> get leavesDetails sync* {
// //     for (final child in children) {
// //       if (child is RenderLeafNode) {
// //         yield RenderLeafDetails(child, this);
// //       } else {
// //         assert(child is RenderContainerNode);
// //         for (final leaf in (child as RenderContainerNode).leavesDetails) {
// //           yield RenderLeafDetails(leaf as RenderLeafNode, child);
// //         }
// //       }
// //     }
// //   }
// //
// //   Iterable<RenderLeafNode> get leaves sync* {
// //     for (final child in children) {
// //       if (child is RenderLeafNode) {
// //         yield child as RenderLeafNode;
// //       } else {
// //         assert(child is RenderContainerNode);
// //         for (final leaf in (child as RenderContainerNode).leaves) {
// //           yield leaf;
// //         }
// //       }
// //     }
// //   }
// // }
