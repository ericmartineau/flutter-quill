import 'dart:collection';

import '../../../widgets/float/shared.dart';
import '../../../widgets/render_editable_ext.dart';
import '../attribute.dart';
import '../style.dart';
import 'leaf.dart';
import 'line.dart';
import 'node.dart';
import 'leaf.dart';

/// Container can accommodate other nodes.
///
/// Delegates insert, retain and delete operations to children nodes. For each
/// operation container looks for a child at specified index position and
/// forwards operation to that child.
///
/// Most of the operation handling logic is implemented by [Line] and [Text].
abstract class Container<T extends Node?> extends Node {
  final LinkedList<Node> _children = LinkedList<Node>();

  /// List of children.
  LinkedList<Node> get children => _children;

  /// Returns total number of child nodes in this container.
  ///
  /// To get text length of this container see [length].
  int get childCount => _children.length;

  /// Returns the first child [Node].
  Node get first => _children.first;

  /// Returns the last child [Node].
  Node get last => _children.last;

  /// Returns `true` if this container has no child nodes.
  bool get isEmpty => _children.isEmpty;

  /// Returns `true` if this container has at least 1 child.
  bool get isNotEmpty => _children.isNotEmpty;

  /// Returns an instance of default child for this container node.
  ///
  /// Always returns fresh instance.
  T get defaultChild;

  /// Adds [node] to the end of this container children list.
  void add(T node) {
    assert(node?.parent == null);
    node?.parent = this;
    _children.add(node as Node);
  }

  /// Adds [node] to the beginning of this container children list.
  void addFirst(T node) {
    assert(node?.parent == null);
    node?.parent = this;
    _children.addFirst(node as Node);
  }

  /// Removes [node] from this container.
  void remove(T node) {
    assert(node?.parent == this);
    node?.parent = null;
    _children.remove(node as Node);
  }

  /// Moves children of this node to [newParent].
  void moveChildToNewParent(Container? newParent) {
    if (isEmpty) {
      return;
    }

    final last = newParent!.isEmpty ? null : newParent.last as T?;
    while (isNotEmpty) {
      final child = first as T;
      child?.unlink();
      newParent.add(child);
    }

    /// In case [newParent] already had children we need to make sure
    /// combined list is optimized.
    if (last != null) last.adjust();
  }

  /// Queries the child [Node] at [offset] in this container.
  ///
  /// The result may contain the found node or `null` if no node is found
  /// at specified offset.
  ///
  /// [ChildQuery.offset] is set to relative offset within returned child node
  /// which points at the same character position in the document as the
  /// original [offset].
  ChildQuery queryChild(int offset, bool inclusive,
      {bool includeFloats = true}) {
    if (offset < 0 || offset > length) {
      return ChildQuery(null, 0);
    }
    var skippedNodes = 0;
    for (final node in children) {
      if (node.isFloat) {
        skippedNodes++;
      }
      if (!node.isFloat || includeFloats) {
        final len = node.length;
        if (offset < len || (inclusive && offset == len && node.isLast)) {
          return ChildQuery(node, offset, skippedNodes: skippedNodes);
        }
        offset -= len;
      }
    }
    return ChildQuery(null, 0, skippedNodes: skippedNodes);
  }

  @override
  String toPlainText() => children.map((child) => child.toPlainText()).join();

  /// Content length of this node's children.
  ///
  /// To get number of children in this node use [childCount].
  @override
  int get length => _children.fold(0, (cur, node) => cur + node.length);

  @override
  void insert(int index, Object data, Style? style) {
    assert(index == 0 || (index > 0 && index < length));

    if (isNotEmpty) {
      final child = queryChild(index, false, includeFloats: false);
      child.node!.insert(child.offset, data, style);
      return;
    }

    // empty
    assert(index == 0);
    final node = defaultChild;
    add(node);
    node?.insert(index, data, style);
  }

  @override
  void retain(int index, int? length, Style? attributes) {
    assert(isNotEmpty);
    final child = queryChild(index, false);
    child.node!.retain(child.offset, length, attributes);
  }

  @override
  void delete(int index, int? length) {
    assert(isNotEmpty);
    final child = queryChild(index, false);
    child.node!.delete(child.offset, length);
  }

  @override
  String toString() => _children.join('\n');
}

/// Result of a child query in a [Container].
class ChildQuery {
  ChildQuery(this.node, this.offset, {this.skippedNodes = 0});

  /// The child node if found, otherwise `null`.
  final Node? node;

  final int skippedNodes;

  /// Starting offset within the child [node] which points at the same
  /// character in the document as the original offset passed to
  /// [Container.queryChild] method.
  final int offset;

  /// Returns `true` if there is no child node found, e.g. [node] is `null`.
  bool get isEmpty => node == null;

  /// Returns `true` [node] is not `null`.
  bool get isNotEmpty => node != null;
}
