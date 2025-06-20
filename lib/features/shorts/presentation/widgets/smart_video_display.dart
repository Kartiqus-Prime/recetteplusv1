import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/services/video_format_service.dart';

class SmartVideoDisplay extends StatelessWidget {
  final VideoPlayerController controller;
  final bool showFormatInfo;

  const SmartVideoDisplay({
    super.key,
    required this.controller,
    this.showFormatInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final videoSize = controller.value.size;
    final formatInfo = VideoFormatService.analyzeVideoFormat(
      videoSize.width,
      videoSize.height,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Vidéo avec affichage intelligent
        _buildVideoPlayer(formatInfo),

        // Informations de format (debug)
        if (showFormatInfo) _buildFormatInfo(formatInfo, videoSize),
      ],
    );
  }

  Widget _buildVideoPlayer(VideoFormatInfo formatInfo) {
    BoxFit boxFit;

    switch (formatInfo.recommendedFit) {
      case VideoFit.cover:
        boxFit = BoxFit.cover;
        break;
      case VideoFit.contain:
        boxFit = BoxFit.contain;
        break;
      case VideoFit.fill:
        boxFit = BoxFit.fill;
        break;
      case VideoFit.fitWidth:
        boxFit = BoxFit.fitWidth;
        break;
      case VideoFit.fitHeight:
        boxFit = BoxFit.fitHeight;
        break;
    }

    Widget videoWidget = AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );

    // Ajouter des barres noires si nécessaire
    if (formatInfo.needsLetterboxing || formatInfo.needsPillarboxing) {
      videoWidget = Container(
        color: Colors.black,
        child: Center(
          child: FittedBox(
            fit: boxFit,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      );
    } else {
      videoWidget = FittedBox(
        fit: boxFit,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    return videoWidget;
  }

  Widget _buildFormatInfo(VideoFormatInfo formatInfo, Size videoSize) {
    return Positioned(
      top: 50,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Format: ${formatInfo.description}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Dimensions: ${videoSize.width.toInt()}x${videoSize.height.toInt()}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              'Ratio: ${formatInfo.aspectRatio.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              'Fit: ${formatInfo.recommendedFit.name}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            if (formatInfo.needsLetterboxing)
              const Text(
                'Letterboxing: Oui',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                ),
              ),
            if (formatInfo.needsPillarboxing)
              const Text(
                'Pillarboxing: Oui',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
