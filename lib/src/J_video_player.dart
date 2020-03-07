import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import './J_video_progress_colors.dart';
import 'J_video_player_ui.dart';

class JJVideoPlayer extends StatefulWidget {
  final JJVideoController controller;
  const JJVideoPlayer({
    Key key, 
    @required this.controller}) : super(key: key);

  @override
  _JJVideoPlayerState createState() => _JJVideoPlayerState();
}

class _JJVideoPlayerState extends State<JJVideoPlayer> {
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(JJVideoPlayer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return _JJVideoContollerProvider(
      controller: widget.controller,
      child: JJVideoPlayerUI(),
    );
  }

  void listener() async {
    if (widget.controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isFullScreen = false;
    }
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      settings: RouteSettings(isInitialRoute: false),
      pageBuilder: _fullScreenRoutePageBuilder,
    );
    
    SystemChrome.setEnabledSystemUIOverlays([]);
    if (isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    if (!widget.controller.allowedScreenSleep) {
      Wakelock.enable();
    }

    await Navigator.of(context, rootNavigator: true).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    Wakelock.disable();

    SystemChrome.setEnabledSystemUIOverlays(
        widget.controller.systemOverlaysAfterFullScreen);
    SystemChrome.setPreferredOrientations(
        widget.controller.deviceOrientationsAfterFullScreen);
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    var controllerProvider = _JJVideoContollerProvider(
      controller: widget.controller,
      child: JJVideoPlayerUI(),
    );

    if (widget.controller.routePageBuilder == null) {
      return _defaultRoutePageBuilder(
          context, animation, secondaryAnimation, controllerProvider);
    }
    return widget.controller.routePageBuilder(
        context, animation, secondaryAnimation, controllerProvider);
  }

  AnimatedWidget _defaultRoutePageBuilder(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      _JJVideoContollerProvider controllerProvider) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _buildFullScreenVideo(
      BuildContext context,
      Animation<double> animation,
      _JJVideoContollerProvider controllerProvider) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }

}

class JJVideoController extends ChangeNotifier {
  /// video_player控制器
  final VideoPlayerController videoPlayerController;

  /// 启动时初始化视频
  final bool autoInitialize;

  /// 是否自动播放
  final bool autoPlay;

  /// 在指定位置播放视频
  final Duration startAt;

  /// 是否循环播放
  final bool looping;

  /// 初始化时候是否显示控制条
  final bool showControlsOnInitialize;

  /// 是否显示控制栏
  final bool showControls;

  /// 显示标题栏
  final bool showTitles;

  /// 自定义控制栏
  final Widget customControls;

  /// 视频标题
  final String title;

  /// 出错时自定义显示组件
  final Widget Function(BuildContext context, String errorMessage) errorBuilder;

  /// 视频长宽比例
  final double aspectRatio;

  /// 控制栏颜色类
  final JVideoProgressColors materialProgressColors;

  /// 初始化之前，视频下方会显示占位符
  final Widget placeholder;

  /// 在视频和控件之间放置的小部件
  final Widget overlay;

  /// 是否默认全屏播放
  final bool fullScreenByDefault;

  /// 屏幕可以自动熄屏
  final bool allowedScreenSleep;

  /// 是否在线流式视频(缓冲型)
  final bool isLive;

  /// 是否允许全屏
  final bool allowFullScreen;

  /// 是否允许静音
  final bool allowMuting;

  /// 定义退出全屏后可见的系统覆盖
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// 退出全屏后定义一组允许的设备方向
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// 为全屏定义自定义RoutePageBuilder
  final JVideoRoutePageBuilder routePageBuilder;

  /// 播放完成回调,
  /// 只成功回调第一次播放完成, 之后的不再通知。
  final Function onPlayComplete;

  JJVideoController({
    this.videoPlayerController, 
    this.autoInitialize = false,
    this.autoPlay = true,
    this.startAt, 
    this.looping = false, 
    this.showControlsOnInitialize = true, 
    this.showControls = true, 
    this.showTitles = true,
    this.title = '',
    this.customControls, 
    this.errorBuilder, 
    this.aspectRatio, 
    this.materialProgressColors, 
    this.placeholder, 
    this.overlay, 
    this.fullScreenByDefault = false, 
    this.allowedScreenSleep = true, 
    this.isLive = false, 
    this.allowFullScreen = true, 
    this.allowMuting = true, 
    this.onPlayComplete,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values, 
    this.deviceOrientationsAfterFullScreen = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    this.routePageBuilder = null}) : assert(videoPlayerController != null,
            'You must provide a controller to play a video') {
    _initialize();
  }

  /// 当前是否全屏
  bool _isFullScreen = false;
  bool get isFullScreen => _isFullScreen;

  static JJVideoController of(BuildContext context) {
    final jVideoControllerProvider =
        context.dependOnInheritedWidgetOfExactType<_JJVideoContollerProvider>();
    return jVideoControllerProvider.controller;
  }

  /// 初始化视频控制器
  Future _initialize() async {
    // 设置video_player是否循环播放
    await videoPlayerController.setLooping(looping);
    // 如果需要自动初始化并且控制还没有初始化，那么执行初始化
    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.initialized) {
      await videoPlayerController.initialize();
    }
    // 如果需要自动播放 那么初始化完成后play()
    if (autoPlay) {
      if (fullScreenByDefault) { //全屏播放
        enterFullScreen();
      }
      await videoPlayerController.play();
    }
    // 有指定位置开始播放的，跳到指定位置播放
    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
    }
    // 默认是全屏启动播放的，那么监听全屏事件
    if (fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
    
    videoPlayerController.addListener(_completeListener);
  }

  void _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  void _completeListener() {
    if(videoPlayerController.value.initialized && !videoPlayerController.value.isPlaying &&
      videoPlayerController.value.position >= videoPlayerController.value.duration){
        if (onPlayComplete != null) {
           onPlayComplete();
           videoPlayerController.removeListener(_completeListener);
        }
    }
  }

  /// 进入全屏状态
  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  /// 退出全屏状态
  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  /// 切换全屏或非全屏
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  /// 播放视频
  Future<void> play() async {
    await videoPlayerController.play();
  }

  /// 设置视频循环
  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  /// 暂停视频
  Future<void> pause() async {
    await videoPlayerController.pause();
  }

  /// 跳到指定时间播放
  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
  }
}

class _JJVideoContollerProvider extends InheritedWidget {
  final JJVideoController controller;
  _JJVideoContollerProvider({
     Key key,
    @required this.controller,
    @required Widget child
  }): super(key: key, child: child);

  @override
 bool updateShouldNotify(_JJVideoContollerProvider old) => controller != old.controller;

}

typedef Widget JVideoRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    _JJVideoContollerProvider controllerProvider);
