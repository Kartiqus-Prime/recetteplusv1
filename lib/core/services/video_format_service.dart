import 'dart:ui';

enum VideoFormatType {
  portrait, // 9:16 (TikTok, Instagram Stories)
  square, // 1:1 (Instagram posts)
  landscape, // 16:9 (YouTube)
  ultraWide, // 21:9 ou plus large
  ultraTall, // Plus haut que 9:16
  unknown
}

enum VideoFit {
  cover,
  contain,
  fill,
  fitWidth,
  fitHeight,
}

class VideoFormatInfo {
  final VideoFormatType format;
  final double aspectRatio;
  final String description;
  final VideoFit recommendedFit;
  final bool needsLetterboxing;
  final bool needsPillarboxing;

  const VideoFormatInfo({
    required this.format,
    required this.aspectRatio,
    required this.description,
    required this.recommendedFit,
    this.needsLetterboxing = false,
    this.needsPillarboxing = false,
  });
}

class VideoFormatService {
  static const double _portraitThreshold = 0.75; // 3:4
  static const double _squareMinThreshold = 0.85; // Proche de 1:1
  static const double _squareMaxThreshold = 1.15; // Proche de 1:1
  static const double _landscapeThreshold = 1.5; // 3:2
  static const double _ultraWideThreshold = 2.0; // 2:1
  static const double _ultraTallThreshold = 0.4; // 2:5

  /// Analyse le format d'une vidéo basé sur ses dimensions
  static VideoFormatInfo analyzeVideoFormat(double width, double height) {
    if (width <= 0 || height <= 0) {
      return const VideoFormatInfo(
        format: VideoFormatType.unknown,
        aspectRatio: 1.0,
        description: 'Format inconnu',
        recommendedFit: VideoFit.contain,
      );
    }

    final aspectRatio = width / height;

    if (aspectRatio < _ultraTallThreshold) {
      return VideoFormatInfo(
        format: VideoFormatType.ultraTall,
        aspectRatio: aspectRatio,
        description: 'Ultra vertical (${_formatRatio(aspectRatio)})',
        recommendedFit: VideoFit.contain,
        needsPillarboxing: true,
      );
    }

    if (aspectRatio < _portraitThreshold) {
      return VideoFormatInfo(
        format: VideoFormatType.portrait,
        aspectRatio: aspectRatio,
        description: 'Portrait (${_formatRatio(aspectRatio)})',
        recommendedFit: VideoFit.cover,
      );
    }

    if (aspectRatio >= _squareMinThreshold &&
        aspectRatio <= _squareMaxThreshold) {
      return VideoFormatInfo(
        format: VideoFormatType.square,
        aspectRatio: aspectRatio,
        description: 'Carré (${_formatRatio(aspectRatio)})',
        recommendedFit: VideoFit.cover,
      );
    }

    if (aspectRatio > _ultraWideThreshold) {
      return VideoFormatInfo(
        format: VideoFormatType.ultraWide,
        aspectRatio: aspectRatio,
        description: 'Ultra large (${_formatRatio(aspectRatio)})',
        recommendedFit: VideoFit.contain,
        needsLetterboxing: true,
      );
    }

    if (aspectRatio > _landscapeThreshold) {
      return VideoFormatInfo(
        format: VideoFormatType.landscape,
        aspectRatio: aspectRatio,
        description: 'Paysage (${_formatRatio(aspectRatio)})',
        recommendedFit: VideoFit.contain,
        needsLetterboxing: true,
      );
    }

    // Format intermédiaire
    return VideoFormatInfo(
      format: VideoFormatType.landscape,
      aspectRatio: aspectRatio,
      description: 'Standard (${_formatRatio(aspectRatio)})',
      recommendedFit: VideoFit.cover,
    );
  }

  /// Formate le ratio pour l'affichage
  static String _formatRatio(double ratio) {
    if (ratio < 1) {
      // Format portrait : afficher comme 9:16
      final height = 16;
      final width = (height * ratio).round();
      return '$width:$height';
    } else {
      // Format paysage : afficher comme 16:9
      final width = 16;
      final height = (width / ratio).round();
      return '$width:$height';
    }
  }

  /// Détermine le BoxFit optimal pour l'écran
  static VideoFit getOptimalFit(VideoFormatInfo formatInfo, Size screenSize) {
    final screenRatio = screenSize.width / screenSize.height;

    switch (formatInfo.format) {
      case VideoFormatType.portrait:
        // Pour les vidéos portrait, utiliser cover si l'écran est aussi portrait
        return screenRatio < 1 ? VideoFit.cover : VideoFit.contain;

      case VideoFormatType.square:
        return VideoFit.cover;

      case VideoFormatType.landscape:
        // Pour les vidéos paysage, utiliser contain pour éviter le crop
        return VideoFit.contain;

      case VideoFormatType.ultraWide:
      case VideoFormatType.ultraTall:
        return VideoFit.contain;

      case VideoFormatType.unknown:
        return VideoFit.contain;
    }
  }

  /// Calcule les dimensions optimales pour l'affichage
  static Size calculateOptimalSize(
      VideoFormatInfo formatInfo, Size screenSize, Size videoSize) {
    final screenRatio = screenSize.width / screenSize.height;
    final videoRatio = formatInfo.aspectRatio;

    if (formatInfo.recommendedFit == VideoFit.cover) {
      // Remplit l'écran en gardant le ratio
      if (videoRatio > screenRatio) {
        // Vidéo plus large que l'écran
        return Size(screenSize.width, screenSize.width / videoRatio);
      } else {
        // Vidéo plus haute que l'écran
        return Size(screenSize.height * videoRatio, screenSize.height);
      }
    } else {
      // Contient dans l'écran
      if (videoRatio > screenRatio) {
        // Vidéo plus large que l'écran
        return Size(screenSize.width, screenSize.width / videoRatio);
      } else {
        // Vidéo plus haute que l'écran
        return Size(screenSize.height * videoRatio, screenSize.height);
      }
    }
  }
}
