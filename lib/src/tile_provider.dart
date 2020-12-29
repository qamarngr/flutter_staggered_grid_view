import 'package:flutter_staggered_grid_view/src/tile.dart';
import 'package:flutter_staggered_grid_view/src/tile_layout.dart';

abstract class TileLayoutProvider {
  const TileLayoutProvider();

  TileLayout? operator [](int index);
}

class TileLayoutListProvider implements TileLayoutProvider{
  const TileLayoutListProvider(this.tiles);

  final List<TileLayout> tiles;

  @override
  TileLayout? operator [](int index){
    if (index < 0 || index >= tiles.length) {
      return null;
    }

    return tiles[index];
  }
}

typedef IndexedTileLayoutBuilder = TileLayout? Function(int index);

class TileLayoutBuilderProvider implements TileLayoutProvider{
  const TileLayoutBuilderProvider(this.builder);

  final IndexedTileLayoutBuilder builder;

  @override
  TileLayout? operator [](int index){
    return builder(index);
  }
}
