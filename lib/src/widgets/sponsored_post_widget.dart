import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../cache/footprints_media_cache_manager.dart';
import '../config/footprints_sdk_client.dart';
import '../models/ad_content.dart';
import 'in_app_webview_screen.dart';

/// Rich content card for feeds — image + title + messages + CTA button.
///
/// Use this for "Sponsored Post - Image" creatives (with title, top/bottom
/// descriptions, and call-to-action button). For minimal image-only banners,
/// use [FootprintsDisplayAd] instead.
///
/// **Server shape note:** Sponsored posts come through the same `displayAd[]`
/// array as plain display ads, with `adType: "displayAds"`. The SDK
/// distinguishes them by checking whether text fields (title, topMessage,
/// buttonText) are populated. In self-fetch mode, this widget filters for
/// ads with non-empty content.
///
/// **Self-fetching mode:** Provide [sdk] without [adContent] — the widget
/// fetches content and picks the first sponsored post (ad with populated
/// title/topMessage/buttonText).
///
/// **Interaction:**
/// 1. Fires `onAdClick` when card or CTA button is tapped
/// 2. Auto-opens `linkUrl` in an in-app WebView (unless `autoOpenUrl: false`)
///
/// **Impression tracking:** IAB standard — fires on first pixel visible.
/// Auto-sends `trackImpression(campaignId, adId)` when [sdk] is provided.
class FootprintsSponsoredPost extends StatefulWidget {
  /// Screen identifier for content filtering and self-fetch.
  final String? screenIdentifier;

  /// Ad content to render (if pre-fetched via data API).
  final AdContent? adContent;

  /// SDK instance for self-fetching + auto-tracking.
  final FootprintsSdk? sdk;

  /// Custom theme for styling.
  final FootprintsSponsoredPostTheme? theme;

  /// Full custom builder for rendering.
  final Widget Function(BuildContext context, AdContent ad)? builder;

  /// Fires on tap (card or CTA button).
  final void Function(AdContent ad)? onAdClick;

  /// Fires once on first pixel visible.
  final void Function(AdContent ad)? onImpression;

  /// Fires when self-fetching returns no sponsored post.
  final VoidCallback? onNoContent;

  /// If true (default), auto-opens `linkUrl` in an in-app WebView on tap.
  final bool autoOpenUrl;

  const FootprintsSponsoredPost({
    super.key,
    this.screenIdentifier,
    this.adContent,
    this.sdk,
    this.theme,
    this.builder,
    this.onAdClick,
    this.onImpression,
    this.onNoContent,
    this.autoOpenUrl = true,
  });

  @override
  State<FootprintsSponsoredPost> createState() =>
      _FootprintsSponsoredPostState();
}

class _FootprintsSponsoredPostState extends State<FootprintsSponsoredPost>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Per-instance unique key for VisibilityDetector so multiple sponsored
  // posts sharing an adId don't collide in the visibility tracker.
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
    // Sponsored posts come through `displayAd[]` with bannerType=='default'.
    sdk.prewarmMediaForBannerType(
      'default',
      screenIdentifier: widget.screenIdentifier,
    );
  }

  @override
  void didUpdateWidget(covariant FootprintsSponsoredPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only refetch on a real slot-config change. Ignore sdk reference
    // changes — rotation should advance on page re-entry, not host rebuild.
    if (oldWidget.screenIdentifier != widget.screenIdentifier) {
      _fetchIfNeeded();
    }
  }

  /// Returns true if the ad is a Sponsored Post.
  ///
  /// Server discriminator: the `displayAds` channel (Sponsored Post - Image)
  /// returns `bannerType: "default"`, while `mobile_display_ads_image`
  /// (multi-size banners) returns specific sizes like `mobileAppBanner600x400`.
  /// See `mobileAppController.js:1341` for the 'default' assignment.
  bool _isSponsoredPost(AdContent ad) {
    return ad.bannerType == 'default';
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
      final candidates = result.data!.data!.displayAd
          .where(_isSponsoredPost)
          .toList();

      final match = await widget.sdk!.pickAd(
        candidates,
        rotationKey: 'sponsored_default',
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
      _impressionTimer?.cancel();
      _impressionTimer = null;
    }
  }

  @override
  void dispose() {
    _impressionTimer?.cancel();
    super.dispose();
  }

  void _handleTap(AdContent ad) {
    widget.onAdClick?.call(ad);

    if (widget.autoOpenUrl &&
        ad.linkUrl != null &&
        ad.linkUrl!.isNotEmpty) {
      FootprintsInAppWebView.open(
        context,
        url: ad.linkUrl!,
        title: ad.campaignName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final ad = _effectiveAd;
    if (ad == null) {
      return const SizedBox.shrink();
    }

    final Widget content = widget.builder != null
        ? widget.builder!(context, ad)
        : _DefaultSponsoredPostCard(
            ad: ad,
            theme: widget.theme ?? const FootprintsSponsoredPostTheme(),
            onTap: () => _handleTap(ad),
          );

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: content,
    );
  }
}

class _DefaultSponsoredPostCard extends StatelessWidget {
  final AdContent ad;
  final FootprintsSponsoredPostTheme theme;
  final VoidCallback onTap;

  const _DefaultSponsoredPostCard({
    required this.ad,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = ad.title ?? '';
    final top = ad.topMessage ?? '';
    final bottom = ad.bottomMessage ?? '';
    final cta = ad.buttonText ?? '';

    return Card(
      margin: theme.margin,
      elevation: theme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (top.isNotEmpty)
              Padding(
                padding: theme.topMessagePadding,
                child: Text(
                  top,
                  style: theme.topMessageStyle ??
                      Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (ad.contentUrl != null && ad.contentUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: ad.contentUrl!,
                cacheManager: FootprintsMediaCacheManager.instance,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey[600]),
                        const SizedBox(height: 4),
                        Text(
                          'Image failed to load',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (title.isNotEmpty)
              Padding(
                padding: theme.titlePadding,
                child: Text(
                  title,
                  style: theme.titleStyle ??
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                ),
              ),
            if (bottom.isNotEmpty)
              Padding(
                padding: theme.bottomMessagePadding,
                child: Text(
                  bottom,
                  style: theme.bottomMessageStyle ??
                      Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (cta.isNotEmpty)
              Padding(
                padding: theme.ctaPadding,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.ctaColor,
                      foregroundColor: theme.ctaTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      cta,
                      style: theme.ctaTextStyle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Theme tokens for [FootprintsSponsoredPost].
class FootprintsSponsoredPostTheme {
  final TextStyle? titleStyle;
  final TextStyle? topMessageStyle;
  final TextStyle? bottomMessageStyle;
  final TextStyle? ctaTextStyle;
  final Color? ctaColor;
  final Color? ctaTextColor;
  final double borderRadius;
  final double elevation;
  final EdgeInsets margin;
  final EdgeInsets topMessagePadding;
  final EdgeInsets titlePadding;
  final EdgeInsets bottomMessagePadding;
  final EdgeInsets ctaPadding;

  const FootprintsSponsoredPostTheme({
    this.titleStyle,
    this.topMessageStyle,
    this.bottomMessageStyle,
    this.ctaTextStyle,
    this.ctaColor,
    this.ctaTextColor,
    this.borderRadius = 12.0,
    this.elevation = 2.0,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.topMessagePadding =
        const EdgeInsets.fromLTRB(16, 12, 16, 8),
    this.titlePadding = const EdgeInsets.fromLTRB(16, 12, 16, 4),
    this.bottomMessagePadding =
        const EdgeInsets.fromLTRB(16, 4, 16, 12),
    this.ctaPadding =
        const EdgeInsets.fromLTRB(16, 4, 16, 16),
  });
}
