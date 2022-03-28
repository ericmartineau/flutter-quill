import '../../flutter_quill.dart';

class DeltaComparison {
  factory DeltaComparison(Delta a, Delta b) {
    final diffs = <String, List>{};
    if (a.length != b.length) {
      diffs['length'] = [
        a.length,
        b.length,
      ];
    }
    var i = 0;
    final bops = b.operations;
    for (final diff in a.operations) {
      final other = bops.tryGet(i);
      if (other != diff) {
        diffs['[$i]'] = [other, diff];
      }
      i++;
    }
    if (bops.length > a.operations.length) {
      for (var j = i; j < bops.length; j++) {
        diffs['[$j]'] = [bops[i], null];
      }
    }

    return DeltaComparison._(a, b, diffs);
  }

  const DeltaComparison._(this.a, this.b, this.differences);

  final Delta a;
  final Delta b;
  final Map<String, List> differences;

  @override
  String toString() {
    return differences.entries.map((entry) {
      return '- ${entry.key}: ${entry.value.join(' != ')}';
    }).join('\n');
  }
}

extension DeltaComparisonExt on Delta {
  DeltaComparison compareTo(Delta other) {
    return DeltaComparison(this, other);
  }
}

extension ListTryExt<X> on List<X> {
  X? tryGet(int index) {
    if (length > index && index >= 0) {
      return this[index];
    }
    return null;
  }
}
