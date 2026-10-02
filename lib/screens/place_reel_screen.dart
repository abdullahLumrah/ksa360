import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../theme/app_theme.dart';
import '../widgets/motion.dart';

/// Full-screen reel for a dining-place clip. Same cover-fill feel as Play reels.
class PlaceReelScreen extends StatefulWidget {
  const PlaceReelScreen({
    super.key,
    required this.youtubeId,
    required this.title,
  });

  final String youtubeId;
  final String title;

  @override
  State<PlaceReelScreen> createState() => _PlaceReelScreenState();
}

class _PlaceReelScreenState extends State<PlaceReelScreen> {
  static const _origin = 'https://ksaguide.app';

  WebViewController? _web;
  var _ready = false;

  String get _thumb =>
      'https://i.ytimg.com/vi/${widget.youtubeId}/hqdefault.jpg';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  void _boot() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final channel = 'Eat${widget.youtubeId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}';
    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        channel,
        onMessageReceived: (message) {
          if (message.message.startsWith('state:1') ||
              message.message == 'ready') {
            if (mounted) setState(() => _ready = true);
          }
        },
      );
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
    controller.loadHtmlString(
      _html(widget.youtubeId, channel),
      baseUrl: _origin,
    );
    _web = controller;
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          if (_web != null) _CoverFill(controller: _web!),
          if (!_ready)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: _thumb,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
              ),
            ),
          Positioned(
            top: pad.top + 6,
            left: 8,
            child: IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x66000000),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: pad.bottom + 18,
            child: Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.onDark,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _html(String id, String channel) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
html,body,#p{margin:0;padding:0;width:100%;height:100%;background:#000;overflow:hidden}
iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
</style>
</head>
<body>
<div id="p"></div>
<script>
var tag=document.createElement('script');
tag.src='https://www.youtube.com/iframe_api';
document.head.appendChild(tag);
var player;
function onYouTubeIframeAPIReady(){
  player=new YT.Player('p',{
    videoId:'$id',
    host:'https://www.youtube.com',
    playerVars:{
      autoplay:1,mute:0,controls:0,playsinline:1,loop:1,playlist:'$id',
      fs:0,rel:0,modestbranding:1,enablejsapi:1,iv_load_policy:3
    },
    events:{
      onReady:function(e){e.target.playVideo();$channel.postMessage('ready');},
      onStateChange:function(e){$channel.postMessage('state:'+e.data);}
    }
  });
}
</script>
</body>
</html>
''';
  }
}

class _CoverFill extends StatelessWidget {
  const _CoverFill({required this.controller});
  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const videoAspect = 9 / 16;
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final screenAspect = maxW / maxH;
        final double width;
        final double height;
        if (screenAspect > videoAspect) {
          width = maxW;
          height = maxW / videoAspect;
        } else {
          height = maxH;
          width = maxH * videoAspect;
        }
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: IgnorePointer(
              child: SizedBox(
                width: width,
                height: height,
                child: WebViewWidget(controller: controller),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ReelThumbnail extends StatelessWidget {
  const ReelThumbnail({
    super.key,
    required this.youtubeId,
    required this.onTap,
  });

  final String youtubeId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = 'https://i.ytimg.com/vi/$youtubeId/hqdefault.jpg';
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: thumb,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x22000000), Color(0x99000000)],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(color: AppColors.goldBright),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.onDark,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
