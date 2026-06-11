import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app WebView shown when a Display or Video ad is tapped.
///
/// Opens the ad's `linkUrl` inside the host app (not an external browser).
/// Provides a close button in the AppBar to return to the ad.
///
/// Click tracking is handled server-side via the smart URL encoded in
/// `linkUrl` — no explicit click event is sent by the SDK.
class FootprintsInAppWebView extends StatefulWidget {
  /// The URL to load (from `AdContent.linkUrl`).
  final String url;

  /// Optional title shown in the AppBar.
  final String? title;

  const FootprintsInAppWebView({
    super.key,
    required this.url,
    this.title,
  });

  /// Convenience: push this screen onto the navigation stack.
  ///
  /// Rejects non-http(s) URLs (javascript:, file:, content:, intent:, etc.)
  /// to prevent malicious or accidental loads via the WebView.
  static Future<void> open(
    BuildContext context, {
    required String url,
    String? title,
  }) {
    final parsed = Uri.tryParse(url);
    if (parsed == null ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      debugPrint(
        'FootprintsInAppWebView: refusing to open non-http(s) URL '
        '(scheme=${parsed?.scheme})',
      );
      return Future<void>.value();
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FootprintsInAppWebView(url: url, title: title),
      ),
    );
  }

  @override
  State<FootprintsInAppWebView> createState() => _FootprintsInAppWebViewState();
}

class _FootprintsInAppWebViewState extends State<FootprintsInAppWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            if (target == null ||
                (target.scheme != 'http' && target.scheme != 'https')) {
              debugPrint(
                'FootprintsInAppWebView: blocking non-http(s) navigation '
                '(scheme=${target?.scheme})',
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Sponsored'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
