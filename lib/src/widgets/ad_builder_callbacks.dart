import 'package:flutter/material.dart';

import '../models/ad_content.dart';
import '../models/sponsored_product.dart';
import '../models/recommendation_product.dart';

/// Type definitions for custom ad rendering callbacks.

/// Builder for fully custom display ad rendering.
typedef DisplayAdBuilder = Widget Function(
  BuildContext context,
  AdContent ad,
);

/// Builder for fully custom video ad rendering.
typedef VideoAdBuilder = Widget Function(
  BuildContext context,
  AdContent ad,
);

/// Builder for fully custom product card rendering.
typedef ProductCardBuilder = Widget Function(
  SponsoredProduct product,
);

/// Builder for fully custom recommendation item rendering.
typedef RecommendationItemBuilder = Widget Function(
  RecommendationProduct product,
);
