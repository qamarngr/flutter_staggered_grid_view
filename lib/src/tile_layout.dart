/// Holds the layout dimensions of a [SliverStaggeredGridView]'s child.
class TileLayout {
  const TileLayout.span({
    required this.crossAxisSpan,
    required this.mainAxisSpan,
  })   : assert(crossAxisSpan >= 0),
        assert(mainAxisSpan >= 0),
        mainAxisExtent = -1;

  const TileLayout.extent({
    required this.crossAxisSpan,
    required this.mainAxisExtent,
  })   : assert(crossAxisSpan >= 0),
        assert(mainAxisExtent >= 0),
        mainAxisSpan = -1;

  final int crossAxisSpan;
  final double mainAxisSpan;
  final double mainAxisExtent;
}
