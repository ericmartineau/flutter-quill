import 'package:flutter/widgets.dart';
import 'package:flutter_quill/src/widgets/float/wrappable_text.dart';

import 'float_column_semantics_tag.dart';
import 'float_data.dart';

// List<Widget> extractWidgets(List<Object> list) {
//   var index = 0;
//   final result = <Widget>[];
//   for (final child in list) {
//     if (child is Widget) {
//       result.add(
//         MetaData(
//           metaData: FloatData.ofObject(index, 0, child),
//           child: Semantics(
//             tagForChildren: FloatColumnPlaceholderSpanSemanticsTag(index, 0),
//             child: child,
//           ),
//         ),
//       );
//     } else if (child is IWrappableText) {
// // Traverses the child's InlineSpan tree and depth-first collects
// // the list of child widgets that are created in WidgetSpans.
//       var placeholderIndex = 0;
//       child.text.visitChildren((span) {
//         if (span is WidgetSpan) {
//           result.add(
//             MetaData(
//               metaData: FloatData.ofObject(index, placeholderIndex, span.child),
//               child: Semantics(
//                 tagForChildren: FloatColumnPlaceholderSpanSemanticsTag(
//                     index, placeholderIndex),
//                 child: span.child,
//               ),
//             ),
//           );
//           placeholderIndex++;
//         }
//         return true;
//       });
//     } else {
//       assert(false,
//           'FloatColumn only supports Widget and WrappableText children.');
//     }
//     index++;
//   }
//
//   return result;
// }
