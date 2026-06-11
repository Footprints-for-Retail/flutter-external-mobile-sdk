import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';

import '../cache/footprints_media_cache_manager.dart';
import '../config/footprints_sdk_client.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/ad_content.dart';

/// Lead capture ad widget with embedded WebView form.
///
/// Two-phase display:
/// 1. **Creative phase** — shows the ad image, title, messages, and CTA button.
/// 2. **WebView phase** — loads [AdContent.linkUrl] inline after the user taps
///    the CTA. A close button returns to the creative phase.
///
/// Uses [linkUrl] from the API response (not hardcoded like the Android SDK).
///
/// Includes MRC-standard viewability tracking: fires [onImpression] when the
/// ad is at least 50 % visible for 1 continuous second.
class FootprintsLeadAd extends StatefulWidget {
  /// Ad content to render.
  final AdContent? adContent;

  /// SDK instance for auto-tracking. When provided, the widget
  /// auto-sends trackImpression(campaignId, adId) on visibility.
  final FootprintsSdk? sdk;

  /// Called when the user taps the creative (before the WebView opens).
  final void Function(AdContent ad)? onAdClick;

  /// Called when the WebView navigates to a URL that looks like a completed
  /// form submission (contains "thank", "success", or "complete").
  final void Function(AdContent ad)? onFormComplete;

  /// Called once when the ad meets MRC viewability (50 % visible for 1 s).
  final void Function(AdContent ad)? onImpression;

  /// Optional custom builder for rendering the creative phase.
  /// When provided the default creative layout is replaced entirely.
  final Widget Function(BuildContext context, AdContent ad)? builder;

  const FootprintsLeadAd({
    super.key,
    this.adContent,
    this.sdk,
    this.onAdClick,
    this.onFormComplete,
    this.onImpression,
    this.builder,
  });

  @override
  State<FootprintsLeadAd> createState() => _FootprintsLeadAdState();
}

class _FootprintsLeadAdState extends State<FootprintsLeadAd>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Per-instance unique key for VisibilityDetector so multiple lead ads
  // sharing an adId don't collide in the visibility tracker.
  final Key _visibilityKey = UniqueKey();

  /// Whether the WebView phase is visible.
  bool _showWebView = false;

  /// Whether the WebView page has finished its initial load.
  bool _webViewLoaded = false;

  /// Whether the form-complete callback has already fired.
  bool _formCompleteFired = false;

  /// MRC viewability timer.


  /// Whether the impression callback has already fired.
  bool _impressionFired = false;

  /// MRC viewability timer — fires after 1s at ≥50% visible.
  Timer? _impressionTimer;

  /// The WebView controller — created lazily when the WebView phase opens.
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _prewarmIfEnabled();
  }

  void _prewarmIfEnabled() {
    final sdk = widget.sdk;
    final ad = widget.adContent;
    if (sdk == null || ad == null) return;
    if (!sdk.config.mediaPrewarmEnabled) return;
    sdk.prewarmMediaForBannerType(ad.bannerType);
  }

  @override
  void dispose() {
    _impressionTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Viewability
  // ---------------------------------------------------------------------------

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_impressionFired || widget.adContent == null) return;

    // MRC display standard: 50% visible for 1 continuous second.
    if (info.visibleFraction >= 0.5) {
      _impressionTimer ??= Timer(const Duration(seconds: 1), () {
        if (_impressionFired || !mounted) return;
        _impressionFired = true;
        final ad = widget.adContent;
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
      return;
    }

    // Visibility dropped below 50% — reset the timer.
    _impressionTimer?.cancel();
    _impressionTimer = null;
  }

  // ---------------------------------------------------------------------------
  // WebView helpers
  // ---------------------------------------------------------------------------

  void _openWebView() {
    final ad = widget.adContent;
    if (ad == null || ad.linkUrl == null) return;

    // Reject non-http(s) URLs (javascript:, file:, content:, intent:, etc.)
    // before opening the embedded WebView.
    final parsed = Uri.tryParse(ad.linkUrl!);
    if (parsed == null ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      debugPrint(
        'FootprintsLeadAd: refusing to open non-http(s) URL '
        '(scheme=${parsed?.scheme})',
      );
      return;
    }

    widget.onAdClick?.call(ad);

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _webViewLoaded = true);
            }
          },
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            if (target == null ||
                (target.scheme != 'http' && target.scheme != 'https')) {
              debugPrint(
                'FootprintsLeadAd: blocking non-http(s) navigation '
                '(scheme=${target?.scheme})',
              );
              return NavigationDecision.prevent;
            }
            _checkFormComplete(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(ad.linkUrl!));

    setState(() {
      _webViewController = controller;
      _showWebView = true;
      _webViewLoaded = false;
    });
  }

  void _closeWebView() {
    setState(() {
      _showWebView = false;
      _webViewLoaded = false;
      _webViewController = null;
    });
  }

  void _checkFormComplete(String url) {
    if (_formCompleteFired || widget.adContent == null) return;

    final lower = url.toLowerCase();
    if (lower.contains('thank') ||
        lower.contains('success') ||
        lower.contains('complete')) {
      _formCompleteFired = true;
      widget.onFormComplete?.call(widget.adContent!);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final ad = widget.adContent;
    if (ad == null) {
      return const SizedBox.shrink();
    }

    final child = _showWebView ? _buildWebView(ad) : _buildCreative(ad);

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Creative phase
  // ---------------------------------------------------------------------------

  Widget _buildCreative(AdContent ad) {
    if (widget.builder != null) {
      return GestureDetector(
        onTap: ad.linkUrl != null ? _openWebView : null,
        child: widget.builder!(context, ad),
      );
    }

    return GestureDetector(
      onTap: ad.linkUrl != null ? _openWebView : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ad.contentUrl != null)
              CachedNetworkImage(
                imageUrl: ad.contentUrl!,
                cacheManager: FootprintsMediaCacheManager.instance,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) =>
                    const SizedBox.shrink(),
              ),
            if (ad.topMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Text(
                  ad.topMessage!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            if (ad.title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  ad.title!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (ad.bottomMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ad.bottomMessage!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            if (ad.buttonText != null && ad.linkUrl != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: _openWebView,
                  child: Text(ad.buttonText!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WebView phase
  // ---------------------------------------------------------------------------

  Widget _buildWebView(AdContent ad) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use available height from parent, fall back to 400 if unbounded.
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0;

        return SizedBox(
          height: height,
          child: Column(
            children: [
              // Close / back bar
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: _closeWebView,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    if (_webViewController != null)
                      WebViewWidget(controller: _webViewController!),
                    if (!_webViewLoaded)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
