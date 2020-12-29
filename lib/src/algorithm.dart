import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

@immutable
class TileOrigin {
  const TileOrigin(this.crossAxisIndex, this.mainAxisOffset);

  final int crossAxisIndex;
  final double mainAxisOffset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TileOrigin &&
        crossAxisIndex == other.crossAxisIndex &&
        mainAxisOffset == other.mainAxisOffset;
  }

  @override
  int get hashCode => hashValues(crossAxisIndex, mainAxisOffset);

  @override
  String toString() {
    return 'crossAxisIndex: $crossAxisIndex; mainAxisOffset: $mainAxisOffset';
  }
}

class EmptySpace {
  EmptySpace(int length)
      : offsets = List.filled(length, 0),
        extents = List.filled(length, double.infinity);

  final List<double> offsets;
  final List<double> extents;
}

abstract class StaggeredGridLayoutAlgorithm {
  StaggeredGridLayoutAlgorithm({
    required this.crossAxisCount,
  });

  final int crossAxisCount;

  /// Gets the origin of the next tile overlapping [crossAxisSpan] grid cells.
  TileOrigin nextTileOrigin(int crossAxisSpan, double mainAxisStride);

  /// Indicates whether there is an empty space available for another tile
  /// between [minOffset] inclusive and [maxOffset] inclusive.
  bool haveSpaceForMoreTilesBetween(double minOffset, double maxOffset);
}

class ClosestToOriginLayoutAlgorithm extends StaggeredGridLayoutAlgorithm {
  ClosestToOriginLayoutAlgorithm({
    required int crossAxisCount,
  })   : offsets = List.filled(crossAxisCount, 0),
        super(crossAxisCount: crossAxisCount);

  final List<double> offsets;

  @override
  TileOrigin nextTileOrigin(int crossAxisSpan, double mainAxisStride) {
    assert(crossAxisSpan >= 0 && crossAxisSpan <= offsets.length);

    // Computes the potential candidates.
    final length = offsets.length;
    TileOrigin bestCandidate = const TileOrigin(0, double.infinity);
    for (int i = 0; i < length; i++) {
      final offset = offsets[i];
      if (_lessOrNearEqual(bestCandidate.mainAxisOffset, offset)) {
        // Skip when the potential candidate is already higher
        // than a better candidate.
        continue;
      }
      int start = 0;
      int size = 0;
      for (int x = 0;
          size < crossAxisSpan &&
              x < length &&
              length - x >= crossAxisSpan - size;
          x++) {
        if (_lessOrNearEqual(offsets[x], offset)) {
          size++;
          if (size == crossAxisSpan) {
            bestCandidate = TileOrigin(start, offset);
          }
        } else {
          start = x + 1;
          size = 0;
        }
      }
    }

    // Updates the offsets.
    final start = bestCandidate.crossAxisIndex;
    final end = start + crossAxisSpan;
    for (int i = start; i < end; i++) {
      offsets[i] += mainAxisStride;
    }

    // Returns the candidate with the lowest dy value.
    return bestCandidate;
  }

  bool haveSpaceForMoreTilesBetween(double minOffset, double maxOffset) {
    return offsets.any((offset) => _lessOrNearEqual(offset - maxOffset, 0));
  }
}

bool _lessOrNearEqual(double a, double b) {
  return a < b || nearEqual(a, b, Tolerance.defaultTolerance.distance);
}
