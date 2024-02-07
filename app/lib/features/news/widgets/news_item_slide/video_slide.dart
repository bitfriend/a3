import 'dart:io';

import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class VideoSlide extends StatefulWidget {
  final NewsSlide slide;
  final Color bgColor;
  final Color fgColor;

  const VideoSlide({
    super.key,
    required this.slide,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  State<VideoSlide> createState() => _VideoSlideState();
}

class _VideoSlideState extends State<VideoSlide> {
  Future<File> getNewsVideo() async {
    final newsVideo = await widget.slide.sourceBinary(null);
    final videoName = widget.slide.text();
    final tempDir = await getTemporaryDirectory();
    File file = File('${tempDir.path}/$videoName');
    if (!(await file.exists())) {
      await file.create();
      file.writeAsBytesSync(newsVideo.asTypedList());
    }
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.bgColor,
      alignment: Alignment.center,
      child: FutureBuilder<Uint8List>(
        future: newsVideo.then((value) => value.asTypedList()),
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.hasData) {
            return ActerVideoPlayer(
              videoFile: File.fromRawPath(snapshot.data!),
            );
          } else {
            return const Center(child: Text('Loading video'));
          }
        },
      ),
    );
  }
}
