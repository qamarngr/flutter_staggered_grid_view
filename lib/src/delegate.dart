import 'package:flutter/rendering.dart';

import 'grid_layout.dart';

abstract class SliverStaggeredGridDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SliverStaggeredGridDelegate();

  /// Returns information about the size and position of the tiles in the grid.
  SliverStaggeredGridLayout getLayout(SliverConstraints constraints);

  /// Override this method to return true when the children need to be
  /// laid out.
  ///
  /// This should compare the fields of the current delegate and the given
  /// `oldDelegate` and return true if the fields are such that the layout would
  /// be different.
  bool shouldRelayout(covariant SliverStaggeredGridDelegate oldDelegate);
}
