import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../cache/footprints_media_cache_manager.dart';
import '../config/footprints_sdk_client.dart';
import '../models/ad_content.dart';
import 'in_app_webview_screen.dart';

/// Video ad orientation.
enum VideoOrientation { horizontal, vertical, square }

/// Pure video banner ad. No text, no CTA button — just the video.
///
/// **Placement-specific rendering:** Provide [bannerType] to render only
/// videos matching that size (e.g., `mobileAppVideo1080x1080`). Useful when
/// the same screen has multiple video slots with different orientations.
///
/// **Self-fetching mode:** Provide [sdk] without [adContent] — the widget
/// fetches content and picks the first matching video (optionally filtered
/// by [bannerType]).
///
/// Behavior:
/// - Auto-play when >50% visible, pause when <20% visible
/// - Always looping, muted by default
/// - Impression fires after 2 continuous seconds at >=50% visibility (MRC video)
/// - Impression does NOT reset on scroll-out (fires once per widget instance)
/// - Aspect ratio parsed from bannerType
/// - Tap only when [AdContent.linkUrl] is present
class FootprintsVideoAd extends StatefulWidget {
  /// Screen identifier for content filtering and self-fetch.
  final String? screenIdentifier;

  /// Ad content to render (if pre-fetched via data API).
  /// If null and [sdk] is provided, the widget fetches content automatically.
  final AdContent? adContent;

  /// SDK instance for self-fetching + auto-tracking. When provided, the widget
  /// fetches content on its own and auto-sends trackImpression on visibility.
  final FootprintsSdk? sdk;

  /// Filter self-fetched videos by this bannerType
  /// (e.g., `mobileAppVideo1080x1080`). When set, only videos matching this
  /// exact bannerType will render. Ignored when [adContent] is provided.
  final String? bannerType;

  final VideoOrientation orientation;
  final bool autoPlay;

  /// When true (default), the video plays silently — volume is forced to 0
  /// at controller creation, after `initialize()`, and after `play()`.
  /// This matches ad-industry norms and prevents surprise audio when a user
  /// scrolls past an ad.
  ///
  /// Pass `muted: false` to allow audio playback (e.g., for a full-screen
  /// video ad where sound is intentional).
  final bool muted;

  /// If true (default), the SDK auto-opens [AdContent.linkUrl] in an in-app
  /// WebView when the video is tapped. Set to false for full client control.
  final bool autoOpenUrl;

  final void Function(AdContent ad)? onAdClick;
  final void Function(AdContent ad)? onImpression;

  /// Called when self-fetching mode returns no matching ad.
  final VoidCallback? onNoContent;

  /// Optional builder for custom layouts around the video player.
  final Widget Function(
    BuildContext context,
    AdContent ad,
    Widget videoPlayer,
  )? builder;

  const FootprintsVideoAd({
    super.key,
    this.screenIdentifier,
    this.adContent,
    this.sdk,
    this.bannerType,
    this.orientation = VideoOrientation.horizontal,
    this.autoPlay = true,
    this.muted = true,
    this.autoOpenUrl = true,
    this.onAdClick,
    this.onImpression,
    this.onNoContent,
    this.builder,
  });

  @override
  State<FootprintsVideoAd> createState() => _FootprintsVideoAdState();
}

class _FootprintsVideoAdState extends State<FootprintsVideoAd>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Per-instance unique key for VisibilityDetector so multiple widgets
  // sharing an adId (same campaign, different orientations) don't collide.
  final Key _visibilityKey = UniqueKey();

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  /// Last playback position captured when the ad scrolled out of view.
  ///
  /// Android's MediaCodec layer may reclaim a paused off-screen hardware
  /// decoder when another decoder is visible and under memory pressure
  /// (seen on Pixel exynos drivers as `"keep callback message for reclaim"`
  /// followed by a new decoder id on scroll-back). When that happens, the
  /// controller resumes at position 0. Seeking to this value before `play()`
  /// restores the frame; if the decoder was *not* reclaimed, seeking to its
  /// current position is a near-noop.
  Duration? _pausedPosition;

  /// Latest visibility fraction reported by VisibilityDetector.
  /// Used so playback/impression logic can catch up after `initialize()`
  /// completes if the widget was already visible on first paint.
  double _lastVisibleFraction = 0.0;
  bool _impressionFired = false;
  Timer? _impressionTimer;
  AdContent? _fetchedAd;
  bool _isLoading = false;

  AdContent? get _effectiveAd => widget.adContent ?? _fetchedAd;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant FootprintsVideoAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-initialize on true content-identity changes. Ignore sdk
    // reference changes — host apps often hold the SDK in state that
    // rebuilds, and we don't want to tear down the player every rebuild.
    final oldUrl = oldWidget.adContent?.contentUrl;
    final newUrl = widget.adContent?.contentUrl;
    if (oldUrl != newUrl ||
        oldWidget.screenIdentifier != widget.screenIdentifier ||
        oldWidget.bannerType != widget.bannerType) {
      _reset();
      _init();
    }
  }

  void _reset() {
    _disposePlayer();
    _impressionTimer?.cancel();
    _impressionTimer = null;
    _isInitialized = false;
    _hasError = false;
    _impressionFired = false;
    _fetchedAd = null;
  }

  Future<void> _init() async {
    if (widget.adContent != null) {
      _initializePlayer(widget.adContent!.contentUrl);
      return;
    }
    if (widget.sdk == null) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final result = await widget.sdk!.getContentDelivery(
      screenIdentifier: widget.screenIdentifier,
    );

    if (!mounted) return;

    if (result.isSuccess && result.data?.data != null) {
      final videos = <AdContent>[
        ...result.data!.data!.videoAdHorizontal,
        ...result.data!.data!.videoAdVertical,
      ];
      final candidates = widget.bannerType == null
          ? videos
          : videos.where((v) => v.bannerType == widget.bannerType).toList();

      // pickAd runs once per State instance (initState + one didUpdateWidget
      // path at most). With AutomaticKeepAliveClientMixin, State is preserved
      // for the page's lifetime, so rotation advances on page re-entry only.
      final rotationKey = 'video_${widget.bannerType ?? "any"}';
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
      } else {
        _initializePlayer(match.contentUrl);
      }
    } else {
      setState(() => _isLoading = false);
      widget.onNoContent?.call();
    }
  }

  void _initializePlayer(String? url) {
    if (url == null || url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    // Try to serve from the SDK's unified media cache. If a local file is
    // already present, play from it for near-zero first-frame latency.
    // Otherwise stream from the URL *immediately* (no wait) and kick off a
    // background download so the next mount hits cache.
    FootprintsMediaCacheManager.instance
        .getFileForUrl(url)
        .then((cachedFile) {
      if (!mounted) return;
      if (cachedFile != null) {
        _buildController(
          VideoPlayerController.file(
            cachedFile,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          ),
        );
      } else {
        _buildController(
          VideoPlayerController.networkUrl(
            Uri.parse(url),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          ),
        );
        // Background warm so the next mount of this URL plays from file.
        unawaited(FootprintsMediaCacheManager.instance.prewarm(url));
      }

      // Pre-warm sibling video URLs on the same screen. Guarded by config
      // inside the SDK call.
      final sdk = widget.sdk;
      final ad = widget.adContent ?? _fetchedAd;
      if (sdk != null) {
        unawaited(
          sdk.prewarmMediaForBannerType(
            ad?.bannerType ?? widget.bannerType,
            screenIdentifier: widget.screenIdentifier,
          ),
        );
      }
    }).catchError((Object _) {
      if (!mounted) return;
      // Cache lookup blew up — fall back to streaming.
      _buildController(
        VideoPlayerController.networkUrl(
          Uri.parse(url),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        ),
      );
    });
  }

  /// Common controller-initialization path shared by cache-hit and streaming
  /// fallback paths. Keeps the existing "catch up on visibility post-init"
  /// behavior and the mute belt-and-suspenders.
  void _buildController(VideoPlayerController newController) {
    _controller = newController;
    _controller!.setLooping(true);

    // Force mute BEFORE initialize so the buffered audio track never has
    // a chance to emit. Re-applied after initialize since some platforms
    // reset volume during media load.
    if (widget.muted) {
      _controller!.setVolume(0.0);
    }

    _controller!.initialize().then((_) {
      if (!mounted) return;
      // Re-apply mute after initialize — belt and suspenders.
      if (widget.muted) {
        _controller!.setVolume(0.0);
      }
      setState(() => _isInitialized = true);
      // Catch up if the widget was already visible while we were loading —
      // otherwise two videos mounting together would race and only the
      // "lucky" one that got its visibility callback post-init would play.
      _applyVisibility();
    }).catchError((Object error) {
      if (!mounted) return;
      setState(() => _hasError = true);
    });
  }

  void _disposePlayer() {
    _controller?.dispose();
    _controller = null;
  }

  /// Resolves the aspect ratio from [AdContent.bannerType].
  double _aspectRatio(AdContent? ad) {
    final bannerType = ad?.bannerType ?? '';
    if (bannerType.contains('1920x1080')) return 16.0 / 9.0;
    if (bannerType.contains('1080x1920')) return 9.0 / 16.0;
    if (bannerType.contains('1080x1080')) return 1.0;
    return 16.0 / 9.0;
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _lastVisibleFraction = info.visibleFraction;
    _applyVisibility();
  }

  /// Apply the latest visibility fraction to playback + impression state.
  /// Called both from VisibilityDetector callbacks AND from the
  /// `initialize()` completion callback — ensures videos that were already
  /// on-screen when they finished loading still auto-play.
  void _applyVisibility() {
    if (!_isInitialized || _controller == null) return;

    if (_lastVisibleFraction >= 0.5) {
      if (widget.autoPlay && !_controller!.value.isPlaying) {
        // Re-enforce mute right before play, in case the platform reset it.
        if (widget.muted) {
          _controller!.setVolume(0.0);
        }
        // Restore the position we captured on scroll-out. If Android
        // reclaimed the hardware decoder while we were paused off-screen,
        // the controller is now at position 0; this seek brings us back
        // to the frame the user was watching.
        if (_pausedPosition != null && _pausedPosition! > Duration.zero) {
          _controller!.seekTo(_pausedPosition!);
        }
        _controller!.play();
      }

      if (!_impressionFired && _impressionTimer == null) {
        _impressionTimer = Timer(const Duration(seconds: 2), () {
          if (!_impressionFired && mounted) {
            _impressionFired = true;
            final ad = _effectiveAd;
            if (ad != null) {
              widget.onImpression?.call(ad);
              if (widget.sdk != null &&
                  ad.campaignId != null &&
                  ad.adId != null) {
                widget.sdk!.trackImpression(
                  campaignId: ad.campaignId!,
                  adId: ad.adId!,
                );
              }
            }
          }
        });
      }
    } else if (_lastVisibleFraction < 0.2) {
      if (_controller!.value.isPlaying) {
        // Capture the current frame before pausing so we can restore it
        // on scroll-back if Android reclaimed the decoder in the meantime.
        _pausedPosition = _controller!.value.position;
        _controller!.pause();
      }
      _impressionTimer?.cancel();
      _impressionTimer = null;
    }
  }

  void _handleTap() {
    final ad = _effectiveAd;
    if (ad == null) return;

    // Fire client callback first (so they can see / short-circuit)
    widget.onAdClick?.call(ad);

    // Auto-open linkUrl in an in-app WebView
    // (click tracked server-side via smart URL)
    if (widget.autoOpenUrl && ad.linkUrl != null && ad.linkUrl!.isNotEmpty) {
      FootprintsInAppWebView.open(
        context,
        url: ad.linkUrl!,
        title: ad.campaignName,
      );
    }
  }

  @override
  void dispose() {
    _impressionTimer?.cancel();
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: _aspectRatio(null),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final ad = _effectiveAd;
    if (ad == null || _hasError) {
      return const SizedBox.shrink();
    }

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildContent(ad),
    );
  }

  Widget _buildContent(AdContent ad) {
    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: _aspectRatio(ad),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final videoPlayer = AspectRatio(
      aspectRatio: _aspectRatio(ad),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );

    final content = widget.builder != null
        ? widget.builder!(context, ad, videoPlayer)
        : ClipRect(
            child: AspectRatio(
              aspectRatio: _aspectRatio(ad),
              child: videoPlayer,
            ),
          );

    // Only wrap in GestureDetector if linkUrl is present
    final tappable = ad.linkUrl != null && ad.linkUrl!.isNotEmpty;
    return tappable
        ? GestureDetector(onTap: _handleTap, child: content)
        : content;
  }
}
