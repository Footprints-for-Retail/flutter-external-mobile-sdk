import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../cache/footprints_media_cache_manager.dart';
import '../models/sponsored_product.dart';

/// Sponsored product carousel widget.
///
/// Phase 2 implementation — uses real API data (not hardcoded like Android SDK).
class FootprintsProductCarousel extends StatelessWidget {
  final List<SponsoredProduct> products;
  final void Function(SponsoredProduct product)? onAddToCart;
  final void Function(SponsoredProduct product)? onProductTap;
  final Widget Function(SponsoredProduct product)? cardBuilder;

  const FootprintsProductCarousel({
    super.key,
    this.products = const [],
    this.onAddToCart,
    this.onProductTap,
    this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          if (cardBuilder != null) {
            return cardBuilder!(product);
          }
          return _DefaultProductCard(
            product: product,
            onTap: () => onProductTap?.call(product),
            onAddToCart: () => onAddToCart?.call(product),
          );
        },
      ),
    );
  }
}

class _DefaultProductCard extends StatelessWidget {
  final SponsoredProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const _DefaultProductCard({
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product.image != null)
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: product.image!,
                  cacheManager: FootprintsMediaCacheManager.instance,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                product.name ?? '',
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (product.offerPrice != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  product.offerPrice!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            if (onAddToCart != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: onAddToCart,
                  child: const Text('Add to Cart'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
