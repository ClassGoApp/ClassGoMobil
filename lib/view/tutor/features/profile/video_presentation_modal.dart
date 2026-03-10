import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_projects/styles/app_styles.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class VideoPresentationDialog extends StatefulWidget {
  final String? videoUrl;

  const VideoPresentationDialog({
    Key? key,
    this.videoUrl,
  }) : super(key: key);

  @override
  State<VideoPresentationDialog> createState() => _VideoPresentationDialogState();
}

class _VideoPresentationDialogState extends State<VideoPresentationDialog> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    final url = widget.videoUrl;
    
    print("🎥 INTENTANDO CARGAR VIDEO DESDE: $url");

    if (url != null && url.isNotEmpty) {
      try {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
              _controller!.setLooping(true);
            }
          }).catchError((error) {
            print("❌ ERROR DE VIDEO_PLAYER: $error");
            if (mounted) setState(() => _hasError = true);
          });
      } catch (e) {
        print("❌ ERROR DE PARSEO DE URL: $e");
        if (mounted) setState(() => _hasError = true);
      }
    } else {
      _hasError = true;
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBgColor = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;
    final videoPlaceholderColor = isDark ? const Color(0xFF0C0E12) : Colors.grey[100];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBgColor,
          borderRadius: BorderRadius.circular(28), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Text(
                "MI VIDEO",
                style: TextStyle(
                  fontFamily: _kTitleFont,
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),

              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic, 
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: videoPlaceholderColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                    child: _buildVideoContent(), 
                  ),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent.withOpacity(0.05),
                    side: BorderSide(color: Colors.redAccent.withOpacity(isDark ? 0.4 : 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "Cerrar",
                    style: TextStyle(
                      fontFamily: _kTitleFont,
                      color: Colors.redAccent, 
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: Colors.grey.withOpacity(0.5), size: 40),
            const SizedBox(height: 8),
            const Text(
              "No se pudo cargar el video",
              style: TextStyle(fontFamily: _kBodyFont, color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_isInitialized && _controller != null) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
          });
        },
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio, 
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),
              
              if (!_controller!.value.isPlaying)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
            ],
          ),
        ),
      );
    }

    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.brandCyan),
      ),
    );
  }
}