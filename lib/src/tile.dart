import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/src/tile_layout.dart';

@immutable
class StaggeredGridTile {
  const StaggeredGridTile({
    required this.layout,
    required this.child,
  });

  final TileLayout layout;
  final Widget child;
}
