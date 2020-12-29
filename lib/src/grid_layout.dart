import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/src/tile.dart';
import 'package:flutter_staggered_grid_view/src/tile_provider.dart';

import 'algorithm.dart';
import 'tile_layout.dart';

typedef LayoutAlgorithmFactory = StaggeredGridLayoutAlgorithm Function(
    double spacing, int crossAxisCount);

/// The layout of a [RenderSliverStaggeredGrid].
@immutable
class SliverStaggeredGridLayout {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverStaggeredGridLayout({
    required this.cellExtent,
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.layoutAlgorithmFactory,
  })   : assert(crossAxisCount >= 0),
        assert(crossAxisCount > 0),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        _crossAxisStride = cellExtent + crossAxisSpacing;

  /// The extent in both axis of a cell of this grid.
  final double cellExtent;

  /// The number of cells in the cross axis.
  final int crossAxisCount;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  final LayoutAlgorithmFactory layoutAlgorithmFactory;

  final double _crossAxisStride;

  double _mainAxisExtentOf(TileLayout tileLayout) {
    return tileLayout.mainAxisExtent >= 0
        ? tileLayout.mainAxisExtent
        : _getExtent(
            tileLayout.mainAxisSpan,
            mainAxisSpacing,
          );
  }

  double _crossAxisExtentOf(TileLayout tileLayout) {
    return _getExtent(
      tileLayout.crossAxisSpan.toDouble(),
      crossAxisSpacing,
    );
  }

  double _crossAxisOffsetOf(TileOrigin origin) {
    return origin.crossAxisIndex * _crossAxisStride;
  }

  double _getExtent(double span, double spacing) {
    if (span < 0) {
      return span;
    }
    return span * (cellExtent + spacing) - spacing;
  }

  List<SliverTileGeometry> getGeometries(
    double minOffset,
    double maxOffset,
    TileLayoutProvider tileLayoutProvider,
  ) {
    final layoutAlgorithm =
        layoutAlgorithmFactory(mainAxisSpacing, crossAxisCount);
    final geometries = <SliverTileGeometry>[];
    int index = 0;
    TileLayout? tileLayout = tileLayoutProvider[index];

    // We iterate through tiles until there are no more tiles or, if there are
    // more tiles, no one will be visible.
    while (tileLayout != null &&
        layoutAlgorithm.haveSpaceForMoreTilesBetween(minOffset, maxOffset)) {
      final mainAxisExtent = _mainAxisExtentOf(tileLayout);
      final mainAxisStride = mainAxisExtent + mainAxisSpacing;
      final origin = layoutAlgorithm.nextTileOrigin(
        tileLayout.crossAxisSpan,
        mainAxisStride,
      );
      final leadingOffset = origin.mainAxisOffset;
      final trailingOffset = leadingOffset + mainAxisStride;
      final visible = leadingOffset < maxOffset && trailingOffset > minOffset;
      if (visible) {
        geometries.add(SliverTileGeometry(
          index: index,
          mainAxisOffset: leadingOffset,
          mainAxisExtent: mainAxisExtent,
          crossAxisOffset: _crossAxisOffsetOf(origin),
          crossAxisExtent: _crossAxisExtentOf(tileLayout),
        ));
      }

      tileLayout = tileLayoutProvider[++index];
    }

    return geometries;
  }
}

@immutable
class StaggeredGridBounds {
  const StaggeredGridBounds({
    required this.minChildIndex,
    required this.maxChildIndex,
  });

  final int minChildIndex;
  final int maxChildIndex;
}

@immutable
class SliverTileGeometry {
  const SliverTileGeometry({
    required this.index,
    required this.mainAxisOffset,
    required this.mainAxisExtent,
    required this.crossAxisOffset,
    required this.crossAxisExtent,
  });

  final int index;
  final double mainAxisOffset;
  final double mainAxisExtent;
  final double crossAxisOffset;
  final double crossAxisExtent;

  /// Returns a tight [BoxConstraints] that forces the child to have the
  /// required size.
  BoxConstraints getBoxConstraints(SliverConstraints constraints) {
    return constraints.asBoxConstraints(
      minExtent: mainAxisExtent,
      maxExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
    );
  }
}
