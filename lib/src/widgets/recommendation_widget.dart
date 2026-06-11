import 'package:flutter/material.dart';

import '../models/recommendation_product.dart';

/// Recommendation products widget with list and grid layout.
///
/// Phase 2 implementation.
class FootprintsRecommendationList extends StatelessWidget {
  final List<RecommendationProduct> products;
  final bool useGridLayout;
  final void Function(RecommendationProduct product)? onProductTap;
  final Widget Function(RecommendationProduct product)? itemBuilder;

  const FootprintsRecommendationList({
    super.key,
    this.products = const [],
    this.useGridLayout = false,
    this.onProductTap,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    if (useGridLayout) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => _buildItem(context, products[index]),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildItem(context, products[index]),
    );
  }

  Widget _buildItem(BuildContext context, RecommendationProduct product) {
    if (itemBuilder != null) return itemBuilder!(product);

    return ListTile(
      leading: product.image != null
          ? Image.network(
              product.image!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
            )
          : null,
      title: Text(product.name ?? ''),
      subtitle: product.price != null ? Text(product.price!) : null,
      onTap: () => onProductTap?.call(product),
    );
  }
}
