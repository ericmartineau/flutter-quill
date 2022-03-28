import 'dart:math';

import 'package:flutter/rendering.dart';

import '../models/documents/attribute.dart';
import '../models/documents/nodes/node.dart';
import 'editor.dart';
import 'float/shared.dart';

extension RenderEditableBoxParentData on RenderBox {
  RenderBoxParentDataMixin<R> quillParentTyped<R extends RenderBox>() {
    return parentData as RenderBoxParentDataMixin<R>;
  }

  RenderBoxParentDataMixin get quillParent {
    return parentData as RenderBoxParentDataMixin;
  }
}

extension NumRoundExt on double {
  double roundTo([int places = 3]) {
    var mod = pow(10.0, places);
    return (this * mod).round().toDouble() / mod;
  }
}

extension OffsetRoundExt on Offset {
  Offset round() {
    final ry = dy.roundTo();
    final rx = dx.roundTo();

    if (dy == ry && dx == rx) {
      return this;
    } else {
      return Offset(rx, ry);
    }
  }
}

extension RenderObjectParentDataExt on RenderObject {
  bool containsOffset(Offset point) {
    final self = this;
    if (self is RenderBox) {
      return renderRect.contains(point);
    }

    return false;
  }

  BoxParentData? get boxParentData {
    return parentData is BoxParentData ? parentData as BoxParentData : null;
  }

  Rect get renderRect {
    final self = this;
    if (self is RenderBox) {
      final childSize = self.size;
      final childOffset = self.renderOffset;
      final rect = Rect.fromLTWH(
        childOffset.dx,
        childOffset.dy,
        childSize.width,
        childSize.height,
      );
      return rect;
    } else {
      return Rect.zero;
    }
  }

  Offset get renderOffset {
    final self = this;

    if (self.parentData is BoxParentData) {
      return (self.parentData as BoxParentData).offset;
    } else if (self is RenderProxyBox) {
      return self.child?.renderOffset ?? Offset.zero;
    } else {
      return Offset.zero;
    }
  }
}

extension NodeFloatExt on Node {
  bool get isFloat {
    return float != FCFloat.none;
  }

  bool get isNotFloat {
    return float == FCFloat.none;
  }

  FCFloat get float {
    final self = this;
    final floatValue = self.style.attributes[Attribute.float.key]?.value;
    final fv = floatOf(floatValue);
    return fv;
  }
}
