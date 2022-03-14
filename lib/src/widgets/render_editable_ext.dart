import 'package:flutter/rendering.dart';

import 'editor.dart';

extension RenderEditableBoxParentData on RenderBox {
  RenderBoxParentDataMixin<R> quillParentTyped<R extends RenderBox>() {
    return parentData as RenderBoxParentDataMixin<R>;
  }

  RenderBoxParentDataMixin get quillParent {
    return parentData as RenderBoxParentDataMixin;
  }
}
