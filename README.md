# Footprints AI Flutter SDK

Cross-platform (Android + iOS) SDK for integrating Footprints AI campaign delivery, ad rendering, and tracking into any Flutter application.

## Features

- **4 ad widget types** — Display, Video, Lead, Sponsored Post
- **Automatic impression tracking** — zero boilerplate for integrators, MRC-standard viewability
- **Creative rotation** — round-robin across multiple campaigns targeting the same placement, persistent cursor
- **Offline-first event queue** — persistent SQLite-backed queue, flushes every 15 seconds
- **Content caching** — single-fetch-many-consumers pattern with 5-minute TTL
- **In-app WebView** for click-through — no external browser, server-side click tracking via smart URL
- **Location support** — opt-in geolocator integration
- **Placement-specific rendering** — widgets filter by `bannerType` so each ad slot renders the right creative
- **Silent no-content** — widgets collapse when no ad is available, no layout disruption

## Installation

Since the sample app bundles the SDK via a local path dependency, clone both repos side by side:

```bash
git clone https://github.com/Footprints-for-Retail/flutter-mobile-sdk.git footprints_sdk
```

Then reference it from your app's `pubspec.yaml`:

```yaml
dependencies:
  footprints_sdk:
    path: ../footprints_sdk
```

Or as a git dependency if you prefer not to clone:

```yaml
dependencies:
  footprints_sdk:
    git:
      url: https://github.com/Footprints-for-Retail/flutter-mobile-sdk.git
      ref: main
```

Then run `flutter pub get`.

## Quick Start

### 1. Initialize once at app startup

```dart
import 'package:footprints_sdk/footprints_sdk.dart';

late final FootprintsSdk sdk;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sdk = FootprintsSdk(
    baseUrl: 'https://studio.footprints-ai.com',
    appKey: 'YOUR_APP_KEY',
  );

  await sdk.init(userEmail: 'user@example.com');

  runApp(const MyApp());
}
```

### 2. Drop a display ad into any screen

```dart
FootprintsDisplayAd(
  sdk: sdk,
  bannerType: 'mobileAppBanner300x250',  // match your placement size
)
```

That's it. The widget:
- Fetches content delivery (or reads from cache)
- Filters for an ad matching the requested `bannerType`
- Rotates across multiple creatives if more than one campaign targets the placement
- Renders the image at the correct aspect ratio
- Tracks impression automatically when MRC viewability is met (50% visible for 1 second)
- Opens the click-through URL in an in-app WebView on tap
- Collapses silently if no ad is available

## Ad Widgets

All four widgets share the same pattern — provide the `sdk` instance and they handle fetching, filtering, rotation, impression tracking, and click-through automatically.

| Widget | Renders | Impression trigger | Standard |
|--------|---------|-------------------|----------|
| `FootprintsDisplayAd` | Image banner (no text) | **50% visible for 1 second** | MRC Display |
| `FootprintsVideoAd` | Video banner, auto-play at ≥50% visible, pause at <20% | **50% visible for 2 continuous seconds** | MRC Video |
| `FootprintsLeadAd` | Image → inline WebView form on tap | **50% visible for 1 second** | MRC Display |
| `FootprintsSponsoredPost` | Rich card (image + title + messages + CTA button) | **50% visible for 1 second** | MRC Display |

**All impressions fire once per widget instance** — not on every render. Re-firing requires the widget to be re-created (e.g., navigating away and back).

## Integration Examples

### Example 1 — Drop ads into a content feed

```dart
import 'package:flutter/material.dart';
import 'package:footprints_sdk/footprints_sdk.dart';

import 'main.dart'; // for the `sdk` global

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        children: [
          const _WelcomeBanner(),

          // Top small banner
          FootprintsDisplayAd(
            sdk: sdk,
            bannerType: 'mobileAppBanner320x50',
          ),

          const _ProductGrid(),

          // Mid-feed sponsored post (rich card)
          FootprintsSponsoredPost(sdk: sdk),

          const _MoreContent(),

          // Bottom rectangle banner
          FootprintsDisplayAd(
            sdk: sdk,
            bannerType: 'mobileAppBanner300x250',
          ),
        ],
      ),
    );
  }
}
```

Three ads, three different placements, **one line each**. The SDK handles everything: content delivery, rotation, impression tracking, click-through.

### Example 2 — Ad at a specific position in an existing list

```dart
class ProductListScreen extends StatelessWidget {
  final List<Product> products;

  const ProductListScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView.builder(
        itemCount: products.length + 1,   // +1 for the ad slot
        itemBuilder: (context, index) {
          // Show a video ad at position 3
          if (index == 3) {
            return FootprintsVideoAd(
              sdk: sdk,
              bannerType: 'mobileAppVideo1080x1080',
              onNoContent: () {
                // Optional: log or collapse surrounding elements
                debugPrint('No video ad available for this slot');
              },
            );
          }

          final productIndex = index > 3 ? index - 1 : index;
          return ProductCard(product: products[productIndex]);
        },
      ),
    );
  }
}
```

### Example 3 — Pre-fetched content + manual widget control

If you want full control over when content is fetched and which creative renders:

```dart
class CustomAdScreen extends StatefulWidget {
  const CustomAdScreen({super.key});

  @override
  State<CustomAdScreen> createState() => _CustomAdScreenState();
}

class _CustomAdScreenState extends State<CustomAdScreen> {
  ContentDeliveryResponse? _content;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final result = await sdk.getContentDelivery(screenIdentifier: 'product_detail');
    if (result.isSuccess) {
      setState(() => _content = result.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayAds = _content?.data?.displayAd ?? [];
    if (displayAds.isEmpty) return const SizedBox.shrink();

    // Pick one via the SDK's rotation logic
    return FutureBuilder<AdContent?>(
      future: sdk.pickAd(displayAds, rotationKey: 'product_banner'),
      builder: (context, snapshot) {
        final ad = snapshot.data;
        if (ad == null) return const SizedBox.shrink();

        return FootprintsDisplayAd(
          sdk: sdk,
          adContent: ad,   // pre-picked, no self-fetch
          onAdClick: (ad) {
            // Your custom logic runs BEFORE the in-app WebView opens
            Analytics.log('ad_tap', adId: ad.adId);
          },
        );
      },
    );
  }
}
```

### Example 4 — Custom styling with a builder

```dart
FootprintsDisplayAd(
  sdk: sdk,
  bannerType: 'mobileAppBanner300x250',
  builder: (context, ad) => Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.network(ad.contentUrl!, fit: BoxFit.cover),
  ),
)
```

## Creative Rotation

When multiple campaigns target the same placement (e.g., 3 campaigns with a `mobileAppBanner320x50` creative), the content-delivery API returns all matching ads. The SDK rotates across them automatically.

**Default:** round-robin with a persistent cursor (survives app restarts). Each time a widget picks an ad, it picks the next one in the list. After the last, it wraps to the first.

Configure via `FootprintsConfig.rotationStrategy`:

| Strategy | Behavior |
|----------|----------|
| `RotationStrategy.roundRobin` (default) | Cycle through candidates in order, persistent cursor |
| `RotationStrategy.random` | Random pick each render, no state |
| `RotationStrategy.none` | Always pick `.first` |

## Supported Banner Types

Returned by the content-delivery API on each ad's `bannerType` field:

| Image banners | Videos | Sponsored Post |
|---------------|--------|---------------|
| `mobileAppBanner320x50` | `mobileAppVideo1080x1920` (portrait) | `default` |
| `mobileAppBanner300x100` | `mobileAppVideo1920x1080` (landscape) | |
| `mobileAppBanner300x250` | `mobileAppVideo1080x1080` (square) | |
| `mobileAppBanner320x480` | | |
| `mobileAppBanner600x400` | | |

`FootprintsDisplayAd` filters for `mobileAppBanner*` types. `FootprintsSponsoredPost` filters for `bannerType == 'default'`. They're mutually exclusive — no risk of rendering the same ad twice.

## Tracking Architecture

Impressions are written to a local SQLite queue the moment they fire, then flushed to the server in batches every 15 seconds (or when 10 events accumulate). This provides:

- **Accurate reporting** — no impressions lost to flaky networks
- **Battery / data savings** — batched calls instead of one HTTP request per impression
- **Resilience** — events persist across app crashes and OS kills

Click tracking is handled **server-side** via the smart URL encoded in each ad's `linkUrl` — the SDK doesn't send a separate click event when the WebView loads.

## Configuration

```dart
FootprintsSdk(
  baseUrl: 'https://studio.footprints-ai.com',
  appKey: 'YOUR_APP_KEY',
  config: FootprintsConfig(
    enableLocation: false,
    enableOfflineQueue: true,
    contentCacheTtl: Duration(minutes: 5),
    eventBatchSize: 10,
    eventBatchInterval: Duration(seconds: 15),
    connectTimeout: Duration(seconds: 15),
    readTimeout: Duration(seconds: 30),
    maxRetryAttempts: 3,
    rotationStrategy: RotationStrategy.roundRobin,
    logLevel: LogLevel.none,
  ),
);
```

## Platform Requirements

- **Flutter:** 3.22+
- **Dart:** 3.4+
- **iOS:** 13.0+
- **Android:** API level 21+ (Android 5.0 Lollipop)

## Permissions

### iOS — add to `Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses your location to deliver relevant ad content.</string>
<key>NSUserTrackingUsageDescription</key>
<string>Your data is used to deliver personalized ads and measure ad performance.</string>
```

### Android — add to `AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

## Sample App

See the [flutter-mobile-sdk-sample-app](https://github.com/Footprints-for-Retail/flutter-mobile-sdk-sample-app) repository for a complete working integration demonstrating all four widget types, tracking, a live console, and an iOS + Android build setup with all permissions pre-configured.

## License

Proprietary — Footprints AI / Footprints for Retail.
