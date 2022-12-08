// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

enum FCFloat { none, left, right, start, end }
enum FCClear { none, left, right, start, end, both }

extension FCFloatValueExt on FCFloat {
  String? get value {
    switch (this) {
      case FCFloat.none:
        return null;
      case FCFloat.left:
        return 'left';

      case FCFloat.right:
        return 'right';

      case FCFloat.start:
        return 'start';
      case FCFloat.end:
        return 'end';
    }
  }
}

FCFloat floatOf(String? value) {
  if (value == null) return FCFloat.none;
  switch (value) {
    case 'right':
      return FCFloat.right;
    case 'left':
      return FCFloat.left;
    case 'start':
      return FCFloat.start;
    case 'end':
      return FCFloat.end;
    default:
      throw StateError('Invalid float constant: $value');
  }
}
