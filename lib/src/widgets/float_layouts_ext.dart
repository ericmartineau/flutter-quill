import 'package:flutter/rendering.dart';

import 'float/float_data.dart';
import 'float/render_wrappable_text.dart';

extension FloatRenderBox on RenderBox {
  bool get isTextItem {
    return this is RenderWrappingText;
  }

  RenderWrappingText get wrappingText {
    return this as RenderWrappingText;
  }

  bool get isWidgetItem {
    return this is! RenderWrappingText;
  }

  FloatData? get floatData {
    final self = this;
    return self is RenderMetaData ? self.metaData as FloatData? : null;
  }
}
