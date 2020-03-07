import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import './J_video_player.dart';
import 'J_video_progress_colors.dart';
import 'material_progress_bar.dart';

class JJVideoPlayerUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final JJVideoController controller = JJVideoController.of(context);
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: controller.aspectRatio ?? _calculateAspectRatio(context),
          child: _buildPlayerWithControls(controller, context),
        ),
      ),
    );
  }

  Widget _buildPlayerWithControls(JJVideoController controller, BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          controller.placeholder ?? Container(),
          Center(
            child: AspectRatio(
              aspectRatio: controller.aspectRatio ?? _calculateAspectRatio(context),
              child: VideoPlayer(controller.videoPlayerController),
            ),
          ),
          controller.overlay ?? Container(),
          _buildControls(controller, context),
        ],
      ),
    );
  }

  Widget _buildControls(JJVideoController controller, BuildContext context){
    if (controller.showControls) {
      if(controller.customControls != null)
        return controller.customControls;
      else
        return MaterialControls();
    } else {
      return Container();
    }
  }

  double _calculateAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    return width > height ? width / height : height / width;
  }
}

class MaterialControls extends StatefulWidget {
  @override
  _MaterialControlsState createState() => _MaterialControlsState();
}
class _MaterialControlsState extends State<MaterialControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  VideoPlayerController controller;
  JJVideoController jVideoController;
  final barHeight = 48.0;
  final marginSize = 5.0;

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      if (jVideoController.errorBuilder != null) {
        return jVideoController.errorBuilder(context, jVideoController.videoPlayerController.value.errorDescription);
      } else {
        return Center(
          child: Icon(Icons.error, color: Colors.white, size: 42),
        );
      }
    }
    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: <Widget>[
              _buildTopBar(),
              _latestValue != null &&
                          !_latestValue.isPlaying &&
                          _latestValue.duration == null ||
                          _latestValue.isBuffering
                  ? const Expanded(
                      child: const Center(
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : _buildHitArea(),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    final _oldController = jVideoController;
    jVideoController = JJVideoController.of(context);
    controller = jVideoController.videoPlayerController;
    if (_oldController != jVideoController) {
      _dispose();
      _initialize();
    }
    super.didChangeDependencies();
  }
  
  Future<Null> _initialize() async {
    controller.addListener(_updateState);
    _updateState();
    if ((controller.value != null && controller.value.isPlaying) ||
        jVideoController.autoPlay) {
      _startHideTimer();
    }
    if (jVideoController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();
    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  /// 构建中间可点击区域
  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else
              _cancelAndRestartTimer();
          } else {
            _playPause();
            setState(() {
              _hideStuff = true;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity:
                  _latestValue != null && !_latestValue.isPlaying && !_dragging
                      ? 1.0
                      : 0.0,
              duration: Duration(milliseconds: 300),
              child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(48.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.play_arrow, size: 32.0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        height: barHeight,
        color: Color.fromRGBO(1, 1, 1, 0.6),
        child: Row(
          children: <Widget>[
            jVideoController.showTitles ? Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 30, right: 30),
                child: Text(
                  jVideoController.title,
                  style: TextStyle(color: Colors.white,fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              )
            ) : Container()
          ]
        ),
      ),
    );
  }

  /// 构建底部控制栏
  Widget _buildBottomBar(BuildContext context) {
    final iconColor = Colors.white;
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        height: barHeight,
        color: Color.fromRGBO(1, 1, 1, 0.6),
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller, iconColor),
            jVideoController.isLive
                ? Expanded(child: const Text('LIVE'))
                : _buildPosition(),
            jVideoController.isLive ? const SizedBox() : _buildProgressBar(),
            jVideoController.allowMuting
                ? _buildMuteButton(controller, iconColor)
                : Container(),
            jVideoController.allowFullScreen
                ? _buildExpandButton(iconColor)
                : Container(),
          ],
        ),
      ),
    );
  }

  /// 播放暂停按钮
  GestureDetector _buildPlayPause(VideoPlayerController controller, Color iconColor) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 8.0, right: 4.0),
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: iconColor,
        ),
      ),
    );
  }

   Widget _buildPosition() {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;
    return Padding(
      padding: EdgeInsets.only(right: 24.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.white
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: MaterialVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });
            _startHideTimer();
          },
          colors: jVideoController.materialProgressColors ??
              JVideoProgressColors(
                  playedColor:Colors.white,
                  handleColor: Colors.pink[400],
                  bufferedColor:Colors.grey,
                  backgroundColor: Colors.grey[600]),
        ),
      ),
    );
  }

  /// 构建静音按钮
  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
    Color iconColor
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();
        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 1.0);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
              ),
              child: Icon(
                (_latestValue != null && _latestValue.volume > 0)
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建全屏按钮
  GestureDetector _buildExpandButton(Color iconColor) {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: EdgeInsets.only(right: 12.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              jVideoController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  /// 暂停和播放
  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;
    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();
        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration(seconds: 0));
          }
          controller.play();
        }
      }
    });
  }

  /// 点击全屏
  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;
      jVideoController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }
}

String formatDuration(Duration position) {
  final ms = position.inMilliseconds;
  int seconds = ms ~/ 1000;
  final int hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  var minutes = seconds ~/ 60;
  seconds = seconds % 60;

  final hoursString = hours >= 10 ? '$hours' : hours == 0 ? '00' : '0$hours';

  final minutesString =
      minutes >= 10 ? '$minutes' : minutes == 0 ? '00' : '0$minutes';

  final secondsString =
      seconds >= 10 ? '$seconds' : seconds == 0 ? '00' : '0$seconds';

  final formattedTime =
      '${hoursString == '00' ? '' : hoursString + ':'}$minutesString:$secondsString';

  return formattedTime;
}