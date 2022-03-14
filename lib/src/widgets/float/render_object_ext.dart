// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math';

import 'package:flutter/rendering.dart';

typedef Visitor<T> = void Function(T item);
typedef Condition<T> = bool Function(T item);

class VisitorState<T> {
  VisitorState({
    required this.predicate,
    required this.earlyTerminate,
    required this.maxDepth,
    required this.walkSelf,
    required this.visitor,
  });

  final void Function(T child, VisitorState<T> state) visitor;
  final bool walkSelf;
  final bool Function(T item)? predicate;
  final bool earlyTerminate;
  final int maxDepth;

  var _idx = 0;
  int get index => _idx;
  var _stopped = false;
  var _inspected = 0;
  var _filtered = -1;

  var _depth = 0;
  var _maxDepth = 0;
  bool get stopped => _stopped;
  bool get notStopped => !stopped;
  int get inspected => _inspected;
  int get filtered => _filtered;

  bool _inspect(Object? item) {
    _inspected++;
    return item is T && (walkSelf || _depth > 0);
  }

  void _descend() {
    _depth++;
    _maxDepth = max(_maxDepth, _depth);
  }

  void _ascend() {
    _depth--;
  }

  int get depth => _depth;

  void stop() {
    _stopped = true;
  }

  Condition<T>? _condition;
  Visitor<T>? _onEach;

  bool _executeCondition(T item) {
    if (_filtered == -1) {
      _filtered = 0;
    }
    _filtered++;
    if (_condition == null) return false;

    final isTrue = _condition!(item);
    if (!isTrue) {
      _condition = null;
      _onEach = null;
      return false;
    } else {
      _onEach!(item);
      _idx++;
      return true;
    }
  }

  /// Allows to intercept the loop until a condition is false;
  void doWhile(
      {required bool Function(T item) condition, required Visitor<T> onEach}) {
    assert(_condition == null && _onEach == null);
    _condition = condition;
    _onEach = onEach;
  }
}

class ChildAndNeighbors<T> {
  ChildAndNeighbors(this.child, this.before, this.after);

  final T child;
  final T? before;
  final T? after;
}

/// Extensions on RenderObject.
extension FloatColumnExtOnRenderObject on RenderObject {
  VisitorState<T> walkTree<T>(
      void Function(T child, VisitorState<T> state) visitor,
      {bool Function(T item)? predicate,
      bool earlyTerminate = false,
      bool walkSelf = false,
      int maxDepth = 1}) {
    final state = VisitorState<T>(
      visitor: visitor,
      predicate: predicate,
      earlyTerminate: earlyTerminate,
      walkSelf: walkSelf,
      maxDepth: maxDepth,
    );

    _walkTree<T>(state);
    return state;
  }

  void _walkTree<T>(VisitorState<T> state) {
    if (state.notStopped) {
      if (state._inspect(this)) {
        final t = this as T;

        if (!state._executeCondition(t)) {
          state.visitor(t, state);
        }
      } else if (state.earlyTerminate) {
        state.stop();
      }

      if (state.notStopped) {
        visitChildren((child) {
          state._descend();
          if (state.depth <= state.maxDepth) {
            child._walkTree<T>(state);
          }
          state._ascend();
        });
      }
    }
  }

  T first<T>() {
    final fst = find<T>((c) => true);
    assert(fst != null, 'Expected first, but found empty: $T');
    return fst!;
  }

  T last<T>() {
    T? last;
    walkTree<T>((child, state) {
      last = child;
    });

    assert(last != null, 'Expected last, but found empty: $T');
    return last!;
  }

  T? find<T>(bool predicate(T child)) {
    T? found;
    walkTree<T>((child, state) {
      if (predicate(child)) {
        found = child;
        state.stop();
      }
    }, walkSelf: false);
    return found;
  }

  ChildAndNeighbors<T>? findWithNeighbors<T>(bool Function(T child) predicate) {
    T? before;
    T? found;
    T? after;

    walkTree<T>((child, state) {
      if (found != null) {
        after = child;
        state.stop();
      } else if (predicate(child)) {
        found = child;
      }
      if (found == null) {
        before = child;
      }
    });
    return found == null ? null : ChildAndNeighbors<T>(found!, before, after);
  }

  T findIndexed<T>(bool predicate(T child, int index)) {
    T? found;
    walkTree<T>((child, state) {
      if (predicate(child, state.index)) {
        found = child;
        state.stop();
      }
    });
    assert(found != null, "Nothing found for $T: $predicate");
    return found!;
  }

  T get<T>(int index) {
    return findIndexed((child, idx) => index == idx);
  }
}
