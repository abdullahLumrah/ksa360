import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../theme/app_theme.dart';

const _origin = 'https://ksaguide.app';

class ShortClip extends StatefulWidget {
  const ShortClip({super.key, required this.youtubeId});

  final String youtubeId;

  @override
  State<ShortClip> createState() => _ShortClipState();
}

class _ShortClipState extends State<ShortClip> {
  WebViewController? _web;

  String get _thumb => 'https://i.ytimg.com/vi/${widget.youtubeId}/hqdefault.jpg';

  String get _channel {
    final safe = widget.youtubeId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return 'Place$safe';
  }

  void _play() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(_channel, onMessageReceived: (_) {});
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
    controller.loadHtmlString(
      _playerHtml(widget.youtubeId, channel: _channel),
      baseUrl: _origin,
    );
    setState(() => _web = controller);
  }

  @override
  Widget build(BuildContext context) {
    final web = _web;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Short',
          style: TextStyle(
            color: AppColors.goldSoft,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 250,
              height: 420,
              child: web == null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _thumb,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const ColoredBox(
                            color: Colors.black,
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x22000000), Color(0xAA000000)],
                            ),
                          ),
                        ),
                        Center(
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _play,
                              child: Ink(
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
                          ),
                        ),
                      ],
                    )
                  : WebViewWidget(controller: web),
            ),
          ),
        ),
      ],
    );
  }
}

String _playerHtml(String id, {required String channel}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta name="referrer" content="strict-origin-when-cross-origin">
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
function kick(){
  try{if(player){player.mute();player.playVideo();}}catch(e){}
}
function onYouTubeIframeAPIReady(){
  player=new YT.Player('p',{
    videoId:'$id',
    host:'https://www.youtube.com',
    playerVars:{
      autoplay:1,mute:1,controls:1,playsinline:1,loop:1,playlist:'$id',
      fs:0,rel:0,modestbranding:1,enablejsapi:1,
      origin:'$_origin',iv_load_policy:3,cc_load_policy:0,widget_referrer:'$_origin'
    },
    events:{
      onReady:function(e){
        e.target.mute();
        e.target.playVideo();
        $channel.postMessage('ready');
      },
      onStateChange:function(e){
        $channel.postMessage('state:'+e.data);
        if(e.data!==1 && e.data!==3) kick();
      },
      onError:function(e){$channel.postMessage('error:'+e.data);}
    }
  });
}
setInterval(function(){
  if(!player||typeof player.getPlayerState!=='function') return;
  var s=player.getPlayerState();
  if(s!==1 && s!==3) kick();
},700);
</script>
</body>
</html>
''';
}
