import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';

/// Full-screen in-app browser with a close (X) control — used by Ask KSA links.
Future<void> openInAppBrowser(
  BuildContext context, {
  required String url,
  String? title,
}) async {
  final uri = normalizeInAppUrl(url);
  if (uri == null) return;

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => InAppBrowserScreen(uri: uri, title: title ?? uri.host),
    ),
  );
}

/// Keep only http(s) URLs, strip trailing junk, and rewrite maps deep-links
/// into a WebView-friendly Google Maps https URL.
Uri? normalizeInAppUrl(String url) {
  var href = url.trim().replaceAll(RegExp(r'[.,;:!?)\]]+$'), '');
  if (href.isEmpty) return null;

  // Intent / geo / googlemaps schemes → https maps (or embedded fallback).
  final rewritten = _httpFromAppScheme(href);
  if (rewritten != null) href = rewritten;

  if (!href.startsWith('http://') && !href.startsWith('https://')) {
    href = 'https://$href';
  }

  Uri uri;
  try {
    uri = Uri.parse(href);
  } catch (_) {
    return null;
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return _preferWebMaps(uri);
}

Uri _preferWebMaps(Uri uri) {
  final host = uri.host.toLowerCase();
  final isMaps = host.contains('google.') &&
      (host.startsWith('maps.') ||
          uri.path.toLowerCase().contains('/maps') ||
          host == 'goo.gl');
  if (!isMaps) return uri;

  // Prefer the stable search URL — less likely to bounce into intent:// / geo:.
  final q = uri.queryParameters['q'] ??
      uri.queryParameters['query'] ??
      uri.queryParameters['ll'];
  if (q != null && q.trim().isNotEmpty) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': q.trim(),
    });
  }

  // /maps/@lat,lng,zoom
  final at = RegExp(r'/@(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(uri.path);
  if (at != null) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${at.group(1)},${at.group(2)}',
    });
  }

  return uri.replace(host: 'www.google.com');
}

String? _httpFromAppScheme(String raw) {
  final lower = raw.toLowerCase();

  // intent://…#Intent;scheme=https;…;S.browser_fallback_url=…;end
  if (lower.startsWith('intent:')) {
    final fallback = RegExp(
      r'S\.browser_fallback_url=([^;]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (fallback != null) {
      return Uri.decodeComponent(fallback.group(1)!);
    }
    // intent://host/path#Intent;scheme=https;…
    final scheme = RegExp(
      r'scheme=([a-z0-9+.-]+)',
      caseSensitive: false,
    ).firstMatch(raw)?.group(1);
    final pathPart = raw.split('#Intent').first;
    final without = pathPart.replaceFirst(RegExp(r'^intent:', caseSensitive: false), '');
    if (scheme == 'http' || scheme == 'https') {
      return '$scheme://$without';
    }
    if (without.contains('maps') || without.contains('google')) {
      final q = RegExp(r'[?&]q=([^&]+)').firstMatch(without)?.group(1);
      if (q != null) {
        return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(Uri.decodeComponent(q))}';
      }
      return 'https://$without';
    }
    return null;
  }

  // geo:lat,lng or geo:0,0?q=lat,lng(Label)
  if (lower.startsWith('geo:')) {
    final q = RegExp(r'[?&]q=([^&]+)').firstMatch(raw)?.group(1);
    if (q != null) {
      final decoded = Uri.decodeComponent(q).split('(').first.trim();
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(decoded)}';
    }
    final coords = RegExp(r'geo:(-?\d+\.?\d*),(-?\d+\.?\d*)', caseSensitive: false)
        .firstMatch(raw);
    if (coords != null) {
      return 'https://www.google.com/maps/search/?api=1&query=${coords.group(1)},${coords.group(2)}';
    }
  }

  // google.navigation:q=… / comgooglemaps://…
  if (lower.startsWith('google.navigation:') ||
      lower.startsWith('comgooglemaps:') ||
      lower.startsWith('googlemaps:')) {
    final q = RegExp(r'[?&]q=([^&]+)').firstMatch(raw)?.group(1);
    if (q != null) {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(Uri.decodeComponent(q))}';
    }
  }

  return null;
}

class InAppBrowserScreen extends StatefulWidget {
  const InAppBrowserScreen({
    super.key,
    required this.uri,
    this.title = '',
  });

  final Uri uri;
  final String title;

  @override
  State<InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<InAppBrowserScreen> {
  late final WebViewController _controller;
  var _loading = true;
  var _progress = 0;
  String _pageTitle = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.title;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Prefer the mobile web site over Android app deep-links.
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7 Pro) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final current = request.url;
            // Google Maps (and others) bounce Android WebViews into intent:/geo:.
            if (_isMapsDeepLink(current) ||
                !(current.startsWith('http://') || current.startsWith('https://'))) {
              final next = normalizeInAppUrl(current) ?? _preferWebMaps(widget.uri);
              _controller.loadRequest(next);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
          },
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onPageFinished: (url) async {
            final title = await _controller.getTitle();
            if (!mounted) return;
            setState(() {
              _loading = false;
              _progress = 100;
              if (title != null && title.trim().isNotEmpty) {
                _pageTitle = title.trim();
              }
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            // Ignore subresource noise; only surface main-frame failures.
            if (error.isForMainFrame == false) return;
            final desc = error.description;
            final looksLikeScheme = desc.toLowerCase().contains('unknown url scheme') ||
                desc.toLowerCase().contains('err_unknown_url_scheme');
            if (looksLikeScheme) {
              final fallback = normalizeInAppUrl(error.url ?? widget.uri.toString());
              if (fallback != null && fallback.toString() != error.url) {
                _controller.loadRequest(fallback);
                return;
              }
            }
            setState(() {
              _loading = false;
              _error = looksLikeScheme
                  ? 'This link tried to open an external app. Reloading the web map…'
                  : 'Web page not available.';
            });
            if (looksLikeScheme) {
              _controller.loadRequest(_preferWebMaps(widget.uri));
            }
          },
        ),
      )
      ..loadRequest(widget.uri);
  }

  bool _isMapsDeepLink(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('intent:') ||
        lower.startsWith('geo:') ||
        lower.startsWith('google.navigation:') ||
        lower.startsWith('comgooglemaps:') ||
        lower.startsWith('googlemaps:');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          _pageTitle.isEmpty ? widget.uri.host : _pageTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => _error = null);
              _controller.loadRequest(widget.uri);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _loading || _progress < 100
              ? LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 2,
                  color: AppColors.green,
                  backgroundColor: AppColors.line,
                )
              : const SizedBox(height: 2),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_error != null)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.bg,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public_off_rounded, size: 40, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() => _error = null);
                            _controller.loadRequest(_preferWebMaps(widget.uri));
                          },
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
