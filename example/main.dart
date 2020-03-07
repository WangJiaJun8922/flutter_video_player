import 'package:flutter/material.dart';
import 'package:j_video_player/j_video_player.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Tavel',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: Body()
    );
  }
}

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  VideoPlayerController videoPlayerControl;
  JJVideoController jjVideoController;

  @override
  void initState() {
    super.initState();
    videoPlayerControl = VideoPlayerController.network('http://media.yangqungongshe.com/sv/a756272-170393e8e78/a756272-170393e8e78.mp4');
    jjVideoController = JJVideoController(
      videoPlayerController: videoPlayerControl,
      aspectRatio: 16 / 9,
      autoPlay: true,
      looping: false,
      title: '不知道什么东西的饿标题',
      onPlayComplete: (){print('只支持第一次onPlayComplete');}
    );
  }

  @override
  void dispose() {
    super.dispose();
    videoPlayerControl.dispose();
    jjVideoController.dispose();
  }

  void changeSource() {
    setState(() {
      videoPlayerControl.pause();
      videoPlayerControl.seekTo(Duration(seconds: 0));
      jjVideoController.dispose();
      videoPlayerControl = VideoPlayerController.network('http://media.yangqungongshe.com/sv/43302181-1702d3f762e/43302181-1702d3f762e.mp4');
      jjVideoController = JJVideoController(
        videoPlayerController: videoPlayerControl,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        title: '换了个视频呀',
        onPlayComplete: (){print('loop不支持onPlayComplete');}
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: JJVideoPlayer(controller: jjVideoController),
      ),
    );
  }
}