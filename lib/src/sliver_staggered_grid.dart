import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/src/tile_provider.dart';

import 'delegate.dart';
import 'grid_layout.dart';
import 'sliver_multi_discontinuous_box.dart';

class SliverStaggeredGridParentData extends SliverMultiBoxAdaptorParentData {
  /// The offset of the child in the non-scrolling axis.
  ///
  /// If the scroll axis is vertical, this offset is from the left-most edge of
  /// the parent to the left-most edge of the child. If the scroll axis is
  /// horizontal, this offset is from the top-most edge of the parent to the
  /// top-most edge of the child.
  double? crossAxisOffset;

  @override
  String toString() => 'crossAxisOffset=$crossAxisOffset; ${super.toString()}';
}

class RenderSliverStaggeredGrid extends RenderSliverMultiDiscontinuousBox {
  RenderSliverStaggeredGrid({
    required RenderSliverBoxChildManager childManager,
    required SliverStaggeredGridDelegate gridDelegate,
    required TileLayoutProvider tileLayoutProvider,
  })   : _gridDelegate = gridDelegate,
        _tileLayoutProvider = tileLayoutProvider,
        super(childManager: childManager);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverGridParentData) {
      child.parentData = SliverGridParentData();
    }
  }

  /// The delegate that controls the size and position of the children.
  SliverStaggeredGridDelegate get gridDelegate => _gridDelegate;
  SliverStaggeredGridDelegate _gridDelegate;
  set gridDelegate(SliverStaggeredGridDelegate value) {
    if (_gridDelegate == value) {
      return;
    }
    if (value.runtimeType != _gridDelegate.runtimeType ||
        value.shouldRelayout(_gridDelegate)) {
      markNeedsLayout();
    }
    _gridDelegate = value;
  }

  TileLayoutProvider get tileLayoutProvider => _tileLayoutProvider;
  TileLayoutProvider _tileLayoutProvider;
  set tileLayoutProvider(TileLayoutProvider value) {
    if (_tileLayoutProvider == value) {
      return;
    }
    _tileLayoutProvider = value;
  }

  /// Used by [performLayout] to remember the geometry of tiles which are not
  /// visible currently.
  List<SliverTileGeometry> _tileGeometriesCache = <SliverTileGeometry>[];

  @override
  void performLayout() {
    final constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final minOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(minOffset >= 0.0);
    final remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final maxOffset = minOffset + remainingExtent;

    final layout = _gridDelegate.getLayout(constraints);

    final tileGeometries = layout.getGeometries(
      minOffset,
      maxOffset,
      tileLayoutProvider,
    );

    // There are no visible geometries.
    if (tileGeometries.isEmpty) {
      // We remove all previously laid out children.
      collectGarbage(getChildrenAsList());

      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    double leadingScrollOffset = constraints.scrollOffset;
    double trailingScrollOffset = constraints.scrollOffset;

    void updateParentData(RenderBox child, SliverTileGeometry geometry) {
      final childParentData =
          child.parentData! as SliverStaggeredGridParentData;
      childParentData.crossAxisOffset = geometry.crossAxisOffset;
      childParentData.layoutOffset = geometry.mainAxisOffset;
      leadingScrollOffset = min(leadingScrollOffset, geometry.mainAxisOffset);
      trailingScrollOffset = max(trailingScrollOffset,
          geometry.mainAxisOffset + geometry.mainAxisExtent);
    }

    // There is at least one visible tile.
    // final firstIndex = tileGeometries.first.index;
    final lastIndex = tileGeometries.last.index;

    final visibleChildCount = tileGeometries.length;

    if (firstChild != null) {
      // We have to lay out all the new visible children that are before the
      // previous firstChild.
      final oldFirstChild = firstChild!;
      final oldFirstIndex = indexOf(firstChild!);

      // Get the index of the last visible child which is just before the old
      // first child.
      int? trailingChildWithLayoutIndex;
      int i = 0;
      while (i < visibleChildCount && tileGeometries[i].index < oldFirstIndex) {
        trailingChildWithLayoutIndex = i++;
      }

      RenderBox? trailingChildWithLayout;
      if (trailingChildWithLayoutIndex != null) {
        // We have to lay out new visible children before the old firstChild.
        for (int i = trailingChildWithLayoutIndex; i >= 0; i--) {
          final geometry = tileGeometries[i];
          final child = insertAndLayoutLeadingChild(
            tileGeometries[i].getBoxConstraints(constraints),
          );
          updateParentData(child!, geometry);
          trailingChildWithLayout ??= child;
        }
      }

      final childrenToDestroy = <RenderBox>[];

      // Then we have to lay out all new visible geometries and discard the
      // children that are no longer visible.
      final start = (trailingChildWithLayoutIndex ?? -1) + 1;
      RenderBox? child = oldFirstChild;
      int index = indexOf(child);
      for (int i = start; i < visibleChildCount; i++) {
        final tileGeometry = tileGeometries[i];
        final tileIndex = tileGeometry.index;
        if (index < tileIndex) {
          // The child is no longer visible. We have to remove it.
          childrenToDestroy.add(child!);
        }

        if (index == tileIndex) {
          // The child is still visible.
          child!.layout(tileGeometry.getBoxConstraints(constraints));
          trailingChildWithLayout = child;
        } else {
          // We have to create the child.
          trailingChildWithLayout = insertAndLayoutChild(
            tileGeometry.getBoxConstraints(constraints),
            after: trailingChildWithLayout,
          );
        }

        if (index <= tileIndex) {
          // We already processed this child.
          // We have to get the next one now.
          child = childAfter(child!);
          index = child == null ? lastIndex + 1 : indexOf(child);
        }

        // We have to set the offset and extent to the last layout child.
        updateParentData(trailingChildWithLayout!, tileGeometry);
      }

      // Destroy all the non visible children.
      collectGarbage(childrenToDestroy);
    } else {
      // We have to lay out all visible geometries.
      for (int i = 0; i < tileGeometries.length; i++) {
        final tileGeometry = tileGeometries[i];
        if (firstChild == null) {
          addInitialChild(
            index: i,
            layoutOffset: tileGeometry.mainAxisOffset,
          );
        } else {
          insertAndLayoutChild(
            tileGeometry.getBoxConstraints(constraints),
            after: lastChild,
          );
        }

        updateParentData(lastChild!, tileGeometry);
      }
    }

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    // TODO:
    final double estimatedTotalExtent = double.infinity;

    geometry = SliverGeometry(
      scrollExtent: estimatedTotalExtent,
      paintExtent: paintExtent,
      maxPaintExtent: estimatedTotalExtent,
      cacheExtent: cacheExtent,
      // Conservative to avoid complexity.
      hasVisualOverflow: true,
    );

    childManager.didFinishLayout();
  }

  /// Returns a list containing the children of this render object.
  ///
  /// This function is useful when you need random-access to the children of
  /// this render object. If you're accessing the children in order, consider
  /// walking the child list directly.
  List<RenderBox> getChildrenAsList() {
    final result = <RenderBox>[];
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData =
          child.parentData! as SliverStaggeredGridParentData;
      result.add(child);
      child = childParentData.nextSibling;
    }
    return result;
  }
}
