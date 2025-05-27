
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';


class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onClose;

  VideoPlayerWidget({required this.videoUrl, required this.onClose});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isBuffering = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);

    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor:  AppColors.primaryGreen,
        handleColor: AppColors.whiteColor,
        backgroundColor:  AppColors.greyColor,
      ),
      showControls: true,
      showControlsOnInitialize: true,
    );

    setState(() {
      _isBuffering = false;
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized
        ? Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Chewie(
                controller: _chewieController!,
              ),
              if (_isBuffering)
                Center(child: CircularProgressIndicator(
                    color: AppColors.primaryGreen
                )),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.blackColor.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.close,
                        color:  AppColors.whiteColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    )
        : Center(
      child: CircularProgressIndicator(
        color:  AppColors.primaryGreen,
      ),
    );
  }
}
