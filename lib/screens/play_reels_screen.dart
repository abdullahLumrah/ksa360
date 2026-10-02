import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../data/life_settings.dart';
import '../data/play_reels.dart';
import '../data/reel_watch_store.dart';
import '../data/reels_repository.dart';
import '../models/activity.dart';
import '../models/restaurant.dart';
import 'restaurant_detail_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import 'activity_detail_screen.dart';

class PlayReelsScreen extends StatefulWidget {
  const PlayReelsScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<PlayReelsScreen> createState() => _PlayReelsScreenState();
}

class _PlayReelsScreenState extends State<PlayReelsScreen> {
  static const _behind = 1;
  static const _ahead = 2;

  late final List<PlayReel> _reels;
  late final PageController _page;
  late int _index;
  var _paused = false;
  var _lastPage = 0;

  @override
  void initState() {
    super.initState();
    _reels = orderedReels(
      watchedIds: ReelWatchStore.instance.watched,
      preferCity: LifeSettings.instance.city.name,
    );
    _index = _reels.isEmpty ? 0 : widget.initialIndex.clamp(0, _reels.length - 1);
    _lastPage = _index;
    _page = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _mark(_index));
  }

  void _mark(int index) {
    if (index < 0 || index >= _reels.length) return;
    ReelWatchStore.instance.mark(_reels[index].youtubeId);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  bool _warm(int index) =>
      index >= _index - _behind && index <= _index + _ahead;

  Future<void> _openRestaurant(Restaurant place) async {
    setState(() => _paused = true);
    await openCard(context, RestaurantDetailScreen(place: place));
    if (mounted) setState(() => _paused = false);
  }

  Future<void> _openActivity(KsaActivity activity) async {
    final settings = LifeSettings.instance;
    final here = activity.withDistance(
      KsaActivity.kmBetween(
        settings.prayerLat,
        settings.prayerLng,
        activity.lat,
        activity.lng,
      ),
    );
    setState(() => _paused = true);
    await openCard(context, ActivityDetailScreen(activity: here));
    if (mounted) setState(() => _paused = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _WarmPageView(
            controller: _page,
            itemCount: _reels.length,
            onPageChanged: (index) {
              if (index == _lastPage) return;
              _lastPage = index;
              HapticFeedback.selectionClick();
              _mark(index);
              setState(() => _index = index);
            },
            itemBuilder: (context, index) {
              final reel = _reels[index];
              return _ReelSlide(
                key: ValueKey(reel.youtubeId),
                reel: reel,
                index: index,
                active: index == _index && !_paused,
                warm: _warm(index),
                onOpen: () {
                  final activity = reel.activity;
                  final restaurant = reel.restaurant;
                  if (activity != null) {
                    _openActivity(activity);
                  } else if (restaurant != null) {
                    _openRestaurant(restaurant);
                  }
                },
              );
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 6,
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
            top: MediaQuery.paddingOf(context).top + 18,
            right: 16,
            child: Text(
              '${_index + 1} / ${_reels.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayReelsStrip extends StatelessWidget {
  const PlayReelsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ReelWatchStore.instance,
        ReelsRepository.instance,
      ]),
      builder: (context, _) {
        final reels = orderedReels(
          watchedIds: ReelWatchStore.instance.watched,
          preferCity: LifeSettings.instance.city.name,
        );
        return SizedBox(
          height: 236,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            scrollDirection: Axis.horizontal,
            itemCount: reels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final reel = reels[index];
              return StaggerIn(
            index: index,
            child: PressableScale(
              borderRadius: BorderRadius.circular(22),
              onTap: () => openCard(
                context,
                PlayReelsScreen(initialIndex: index),
              ),
              child: SizedBox(
                width: 142,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: reel.thumb,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF1C2521),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x14000000), Color(0xF2000000)],
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 46,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REEL',
                              style: TextStyle(
                                color: AppColors.goldBright,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              reel.displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.onDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
            },
          ),
        );
      },
    );
  }
}

class _WarmPageView extends StatelessWidget {
  const _WarmPageView({
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onPageChanged,
  });

  final PageController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 &&
            notification is ScrollUpdateNotification &&
            notification.metrics is PageMetrics) {
          final page = (notification.metrics as PageMetrics).page;
          if (page != null) onPageChanged(page.round());
        }
        return false;
      },
      child: Scrollable(
        axisDirection: AxisDirection.down,
        controller: controller,
        physics:
            const PageScrollPhysics().applyTo(const ClampingScrollPhysics()),
        viewportBuilder: (context, position) {
          return Viewport(
            cacheExtent: 2.0,
            cacheExtentStyle: CacheExtentStyle.viewport,
            axisDirection: AxisDirection.down,
            offset: position,
            slivers: [
              SliverFillViewport(
                viewportFraction: controller.viewportFraction,
                delegate: SliverChildBuilderDelegate(
                  itemBuilder,
                  childCount: itemCount,
                  addAutomaticKeepAlives: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReelSlide extends StatefulWidget {
  const _ReelSlide({
    super.key,
    required this.reel,
    required this.index,
    required this.active,
    required this.warm,
    required this.onOpen,
  });

  final PlayReel reel;
  final int index;
  final bool active;
  final bool warm;
  final VoidCallback onOpen;

  @override
  State<_ReelSlide> createState() => _ReelSlideState();
}

class _ReelSlideState extends State<_ReelSlide>
    with AutomaticKeepAliveClientMixin {
  WebViewController? _web;
  var _ready = false;

  @override
  bool get wantKeepAlive => widget.warm;

  @override
  void initState() {
    super.initState();
    if (widget.warm) _attach();
  }

  @override
  void dispose() {
    _web = null;
    _ready = false;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReelSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateKeepAlive();
    if (widget.warm && _web == null) {
      _attach();
    } else if (widget.warm) {
      _setLive(widget.active);
    } else if (_web != null) {
      _web = null;
      _ready = false;
    }
  }

  void _attach() {
    final channel = 'Reel${widget.index}';
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
      ..addJavaScriptChannel(
        channel,
        onMessageReceived: (message) {
          debugPrint('reel ${widget.reel.youtubeId} ${message.message}');
          if (!mounted) return;
          final text = message.message;
          if (text.startsWith('state:1') || text.startsWith('state:3')) {
            if (!_ready) setState(() => _ready = true);
          }
        },
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadHtmlString(
      _playerHtml(
        widget.reel.youtubeId,
        channel: channel,
        live: widget.active,
      ),
      baseUrl: _kReelOrigin,
    );
    _web = controller;
  }

  void _setLive(bool live) {
    final web = _web;
    if (web == null) return;
    web.runJavaScript(
      'try{setLive(${live ? 'true' : 'false'});}catch(e){}',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final activity = widget.reel.activity;
    final pad = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (_web != null)
          Positioned.fill(child: _CoverFillPlayer(controller: _web!)),
        if (!_ready)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.reel.thumb,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
            ),
          ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xF2000000),
                ],
                stops: [0, 0.22, 0.52, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: pad.bottom + 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.reel.hook,
                style: const TextStyle(
                  color: AppColors.goldBright,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity?.name ?? 'Activity',
                style: const TextStyle(
                  color: AppColors.onDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  height: 1.15,
                ),
              ),
              if (activity != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${activity.city}  ·  ${activity.priceLabel}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              PressableScale(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.onOpen,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Open this activity',
                    style: TextStyle(
                      color: Color(0xFF121816),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _kReelOrigin = 'https://ksaguide.app';

class _CoverFillPlayer extends StatelessWidget {
  const _CoverFillPlayer({required this.controller});

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

String _playerHtml(
  String id, {
  required String channel,
  required bool live,
}) {
  const origin = _kReelOrigin;
  final liveJs = live ? 'true' : 'false';
  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>
html,body,#p{margin:0;padding:0;width:100%;height:100%;background:#000;overflow:hidden;pointer-events:none}
iframe{position:absolute;inset:0;width:100%;height:100%;border:0;pointer-events:none}
</style>
</head>
<body>
<div id="p"></div>
<script>
var tag=document.createElement('script');
tag.src='https://www.youtube.com/iframe_api';
document.head.appendChild(tag);
var player;
var live=$liveJs;
function kick(){
  try{if(player){player.mute();player.playVideo();}}catch(e){}
}
function setLive(v){
  live=!!v;
  try{
    if(!player) return;
    player.mute();
    if(live) player.playVideo();
    else player.pauseVideo();
  }catch(e){}
}
function hideChrome(){
  try{
    var f=document.querySelector('iframe');
    if(!f) return;
    var d=f.contentDocument||f.contentWindow.document;
    if(!d||!d.head) return;
    if(d.getElementById('ksa-hide')) return;
    var s=d.createElement('style');
    s.id='ksa-hide';
    s.textContent='.ytp-chrome-top,.ytp-chrome-bottom,.ytp-gradient-top,.ytp-gradient-bottom,.ytp-pause-overlay,.ytp-pause-overlay-container,.ytp-button,.ytp-title,.ytp-show-cards-title,.ytp-ce-element,.ytp-next-button,.ytp-prev-button,.ytp-play-button,.ytp-overflow-button,.ytp-impression-link,.ytp-endscreen-content,.ytp-scroll-min,.ytp-cards-teaser,.ytp-watermark,.ytp-youtube-button,.ytp-chrome-controls,.ytp-progress-bar-container{display:none!important;opacity:0!important;pointer-events:none!important}';
    d.head.appendChild(s);
  }catch(e){}
}
function onYouTubeIframeAPIReady(){
  player=new YT.Player('p',{
    videoId:'$id',
    host:'https://www.youtube.com',
    playerVars:{
      autoplay:1,mute:1,controls:0,playsinline:1,loop:1,playlist:'$id',
      fs:0,rel:0,modestbranding:1,enablejsapi:1,disablekb:1,
      origin:'$origin',iv_load_policy:3,cc_load_policy:0,widget_referrer:'$origin'
    },
    events:{
      onReady:function(e){
        e.target.mute();
        e.target.playVideo();
        hideChrome();
        $channel.postMessage('ready');
      },
      onStateChange:function(e){
        $channel.postMessage('state:'+e.data);
        hideChrome();
        if(!live && e.data===1){e.target.pauseVideo();return;}
        if(live && e.data!==1 && e.data!==3) kick();
      },
      onError:function(e){$channel.postMessage('error:'+e.data);}
    }
  });
  try{player.setSize(window.innerWidth,window.innerHeight);}catch(e){}
}
setInterval(function(){
  if(!player||typeof player.getPlayerState!=='function') return;
  var s=player.getPlayerState();
  $channel.postMessage('state:'+s);
  hideChrome();
  if(!live && s===1){player.pauseVideo();return;}
  if(live && s!==1 && s!==3) kick();
},700);
</script>
</body>
</html>
''';
}
