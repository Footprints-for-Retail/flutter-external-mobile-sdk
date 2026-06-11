import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../cache/footprints_media_cache_manager.dart';
import '../config/footprints_sdk_client.dart';
import '../models/ad_content.dart';
import 'banner_type_parser.dart';
import 'in_app_webview_screen.dart';

/// Pure image banner ad. No text, no CTA button — just the image.
///
/// For rich content cards with title/messages/button, use
/// `FootprintsSponsoredPost` instead.
///
/// **Placement-specific rendering:** Provide [bannerType] to render only
/// ads matching that size (e.g., `mobileAppBanner300x250`). Useful when the
/// same screen has multiple ad slots with different sizes.
///
/// **Self-fetching mode:** Provide [sdk] without [adContent] — the widget
/// fetches content and picks the first matching ad (optionally filtered
/// by [bannerType]).
///
/// **BannerType sizing:** aspect ratio is parsed from the `bannerType`
/// field (e.g., `mobileAppBanner600x400` → 3:2). Set [sizing] to
/// [AdSizing.fillParent] to ignore and fill the container.
///
/// **Interaction:** If [AdContent.linkUrl] is present, the entire image
/// is tappable and fires [onAdClick]. If absent, the image is purely
/// displayed (not tappable).
///
/// **Impression tracking:** IAB/Google/Facebook standard — fires on first
/// pixel visible. Auto-sends `trackImpression(campaignId, adId)` when [sdk]
/// is provided.
class FootprintsDisplayAd extends StatefulWidget {
  /// Screen identifier for content filtering and self-fetch.
  final String? screenIdentifier;

  /// Ad content to render (if pre-fetched via data API).
  /// If null and [sdk] is provided, the widget fetches content automatically.
  final AdContent? adContent;

  /// SDK instance for self-fetching mode. When provided, the widget
  /// fetches content on its own and auto-tracks impressions.
  final FootprintsSdk? sdk;

  /// Filter self-fetched ads by this bannerType (e.g., `mobileAppBanner300x250`).
  /// When set, only ads matching this exact bannerType will render.
  /// Ignored when [adContent] is provided directly.
  final String? bannerType;

  /// Controls how the widget sizes itself.
  final AdSizing sizing;

  /// Full custom builder for rendering.
  final Widget Function(BuildContext context, AdContent ad)? builder;

  /// Called when the ad is tapped (only fires when [AdContent.linkUrl] is present).
  /// After this callback, the SDK auto-opens [AdContent.linkUrl] in an in-app
  /// WebView unless [autoOpenUrl] is set to false.
  final void Function(AdContent ad)? onAdClick;

  /// If true (default), the SDK auto-opens [AdContent.linkUrl] in an in-app
  /// WebView when the ad is tapped. Set to false if the integrator wants full
  /// control over the click behavior via [onAdClick].
  final bool autoOpenUrl;

  /// Called when the ad becomes visible (IAB: first pixel visible).
  final void Function(AdContent ad)? onImpression;

  /// Called when self-fetching mode returns no matching ad.
  /// Useful for collapsing the slot in the layout.
  final VoidCallback? onNoContent;

  const FootprintsDisplayAd({
    super.key,
    this.screenIdentifier,
    this.adContent,
    this.sdk,
    this.bannerType,
    this.sizing = AdSizing.fromServer,
    this.builder,
    this.onAdClick,
    this.onImpression,
    this.onNoContent,
    this.autoOpenUrl = true,
  });

  @override
  State<FootprintsDisplayAd> createState() => _FootprintsDisplayAdState();
}

class _FootprintsDisplayAdState extends State<FootprintsDisplayAd>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Per-instance unique key for VisibilityDetector so multiple widgets
  // rendering the same ad (e.g., same campaign, different banner sizes
  // sharing an adId) don't collide in the visibility tracker.
  final Key _visibilityKey = UniqueKey();
  bool _impressionFired = false;
  Timer? _impressionTimer;
  AdContent? _fetchedAd;
  bool _isLoading = false;

  AdContent? get _effectiveAd => widget.adContent ?? _fetchedAd;

  @override
  void initState() {
    super.initState();
    _fetchIfNeeded();
    _prewarmIfEnabled();
  }

  void _prewarmIfEnabled() {
    final sdk = widget.sdk;
    if (sdk == null) return;
    if (!sdk.config.mediaPrewarmEnabled) return;
    // Fire-and-forget. Prewarmer tolerates a missing cached response.
    sdk.prewarmMediaForBannerType(
      widget.bannerType,
      screenIdentifier: widget.screenIdentifier,
    );
  }

  @override
  void didUpdateWidget(covariant FootprintsDisplayAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only refetch on real slot-config changes. Ignore sdk reference
    // changes so host rebuilds don't re-pick and advance rotation.
    if (oldWidget.screenIdentifier != widget.screenIdentifier ||
        oldWidget.bannerType != widget.bannerType) {
      _fetchIfNeeded();
    }
  }

  Future<void> _fetchIfNeeded() async {
    if (widget.adContent != null) return;
    if (widget.sdk == null) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final result = await widget.sdk!.getContentDelivery(
      screenIdentifier: widget.screenIdentifier,
    );

    if (!mounted) return;

    if (result.isSuccess && result.data?.data != null) {
      // Exclude sponsored posts (ads with populated text) — those belong
      // to FootprintsSponsoredPost widget.
      final plainAds = result.data!.data!.displayAd
          .where(_isPlainDisplayAd)
          .toList();

      // Filter by bannerType if specified
      final candidates = widget.bannerType == null
          ? plainAds
          : plainAds
              .where((a) => a.bannerType == widget.bannerType)
              .toList();

      // Rotation-aware pick from the candidate list.
      final rotationKey = 'display_${widget.bannerType ?? "any"}';
      final match = await widget.sdk!.pickAd(
        candidates,
        rotationKey: rotationKey,
      );

      if (!mounted) return;

      setState(() {
        _fetchedAd = match;
        _isLoading = false;
      });

      if (match == null) {
        widget.onNoContent?.call();
      }
    } else {
      setState(() => _isLoading = false);
      widget.onNoContent?.call();
    }
  }

  /// Returns true if the ad is a plain image banner (not a Sponsored Post).
  ///
  /// Server discriminator: `mobile_display_ads_image` (multi-size banners)
  /// returns specific banner types like `mobileAppBanner600x400`. The
  /// `displayAds` channel (Sponsored Post - Image) returns `bannerType: "default"`
  /// which should be rendered by [FootprintsSponsoredPost] instead.
  /// See `mobileAppController.js:1341` for the 'default' assignment.
  bool _isPlainDisplayAd(AdContent ad) {
    return ad.bannerType != 'default';
  }

  void _handleTap(AdContent ad) {
    // Fire client callback first (so they can see / short-circuit)
    widget.onAdClick?.call(ad);

    // Auto-open linkUrl in an in-app WebView (click tracked server-side via smart URL)
    if (widget.autoOpenUrl && ad.linkUrl != null && ad.linkUrl!.isNotEmpty) {
      FootprintsInAppWebView.open(
        context,
        url: ad.linkUrl!,
        title: ad.campaignName,
      );
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_impressionFired || _effectiveAd == null) return;

    // MRC display standard: 50% visible for 1 continuous second.
    if (info.visibleFraction >= 0.5) {
      _impressionTimer ??= Timer(const Duration(seconds: 1), () {
        if (_impressionFired || !mounted) return;
        _impressionFired = true;
        final ad = _effectiveAd;
        if (ad == null) return;
        widget.onImpression?.call(ad);
        if (widget.sdk != null &&
            ad.campaignId != null &&
            ad.adId != null) {
          widget.sdk!.trackImpression(
            campaignId: ad.campaignId!,
            adId: ad.adId!,
          );
        }
      });
    } else {
      // Visibility dropped below 50% — reset the timer so re-entry re-counts.
      _impressionTimer?.cancel();
      _impressionTimer = null;
    }
  }

  @override
  void dispose() {
    _impressionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final ad = _effectiveAd;
    if (ad == null) {
      return const SizedBox.shrink();
    }

    final Widget content = widget.builder != null
        ? widget.builder!(context, ad)
        : _buildImage(ad);

    // Only wrap in GestureDetector if linkUrl is present
    final tappable = ad.linkUrl != null && ad.linkUrl!.isNotEmpty;
    final wrapped = tappable
        ? GestureDetector(
            onTap: () => _handleTap(ad),
            child: content,
          )
        : content;

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: wrapped,
    );
  }

  Widget _buildImage(AdContent ad) {
    if (ad.contentUrl == null || ad.contentUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final image = CachedNetworkImage(
      imageUrl: ad.contentUrl!,
      cacheManager: FootprintsMediaCacheManager.instance,
      fit: BoxFit.cover,
      placeholder: (context, url) => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 120,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                'Image failed to load',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    // Apply aspect ratio from bannerType if sizing is fromServer
    if (widget.sizing == AdSizing.fromServer) {
      final ratio = BannerTypeParser.aspectRatio(ad.bannerType);
      if (ratio != null) {
        return AspectRatio(
          aspectRatio: ratio,
          child: image,
        );
      }
    }

    return image;
  }
}
