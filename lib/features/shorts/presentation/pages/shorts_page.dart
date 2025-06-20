import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/models/video.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/videos_service.dart';
import '../../../../core/services/video_format_service.dart';
import 'smart_video_display.dart';

class ShortsVideoPlayer extends StatefulWidget {
  final Video video;
  final bool isActive;

  const ShortsVideoPlayer({
    super.key,
    required this.video,
    required this.isActive,
  });

  @override
  State<ShortsVideoPlayer> createState() => _ShortsVideoPlayerState();
}

class _ShortsVideoPlayerState extends State<ShortsVideoPlayer>
    with SingleTickerProviderStateMixin {
  final VideosService _videosService = VideosService();

  VideoPlayerController? _videoController;
  VideoFormatInfo? _formatInfo;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLoading = false;
  bool _isVideoLoading = true;
  bool _hasVideoError = false;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _showFormatInfo = false; // Pour le debug

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.video.userHasLiked;
    _likesCount = widget.video.likes;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _initializeVideo();

    if (widget.isActive) {
      _incrementViews();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ShortsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _incrementViews();
        _playVideo();
      } else {
        _pauseVideo();
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.video.videoUrl != null && widget.video.videoUrl!.isNotEmpty) {
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.videoUrl!),
        );

        await _videoController!.initialize();

        // Analyser le format une fois la vidéo initialisée
        final videoSize = _videoController!.value.size;
        _formatInfo = VideoFormatService.analyzeVideoFormat(
          videoSize.width,
          videoSize.height,
        );

        _videoController!.addListener(_videoListener);

        if (mounted) {
          setState(() {
            _isVideoLoading = false;
          });

          if (widget.isActive) {
            _playVideo();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
            _hasVideoError = true;
          });
        }
      }
    } else {
      setState(() {
        _isVideoLoading = false;
        _hasVideoError = true;
      });
    }
  }

  void _videoListener() {
    if (_videoController != null && mounted) {
      final isPlaying = _videoController!.value.isPlaying;
      if (_isPlaying != isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }

      // Relancer la vidéo en boucle
      if (_videoController!.value.position >=
          _videoController!.value.duration) {
        _videoController!.seekTo(Duration.zero);
        if (widget.isActive) {
          _videoController!.play();
        }
      }
    }
  }

  Future<void> _incrementViews() async {
    try {
      await _videosService.incrementViews(widget.video.id);
    } catch (e) {
      // Silently handle error
    }
  }

  void _playVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.play();
    }
  }

  void _pauseVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.pause();
    }
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_isPlaying) {
        _pauseVideo();
      } else {
        _playVideo();
      }
    }

    // Afficher les contrôles temporairement
    setState(() {
      _showControls = true;
    });

    // Masquer les contrôles après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleFormatInfo() {
    setState(() {
      _showFormatInfo = !_showFormatInfo;
    });
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    // Animation immédiate pour la réactivité
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Mise à jour optimiste de l'UI
    final wasLiked = _isLiked;
    final previousCount = _likesCount;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
      _isLoading = true;
    });

    try {
      if (wasLiked) {
        await _videosService.unlikeVideo(widget.video.id);
      } else {
        await _videosService.likeVideo(widget.video.id);
      }
    } catch (e) {
      // Rollback en cas d'erreur
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likesCount = previousCount;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      onLongPress: _toggleFormatInfo, // Debug: long press pour voir les infos
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player intelligent ou placeholder
          _buildVideoContent(),

          // Overlay avec informations
          _buildOverlay(),

          // Contrôles de lecture
          _buildPlayControls(),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isVideoLoading) {
      return _buildLoadingPlaceholder();
    }

    if (_hasVideoError || _videoController == null) {
      return _buildErrorPlaceholder();
    }

    if (_videoController!.value.isInitialized) {
      return SmartVideoDisplay(
        controller: _videoController!,
        showFormatInfo: _showFormatInfo,
      );
    }

    return _buildDefaultPlaceholder();
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryOrange,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement de la vidéo...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.3),
            AppTheme.primaryOrange.withOpacity(0.3),
          ],
        ),
      ),
      child: widget.video.thumbnailUrl != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.video.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultPlaceholder(),
                ),
                Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            )
          : _buildDefaultPlaceholder(),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.3),
            AppTheme.primaryOrange.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_outline,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.video.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayControls() {
    if (!_showControls && _isPlaying) return const SizedBox.shrink();

    return Center(
      child: AnimatedOpacity(
        opacity: _showControls || !_isPlaying ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Informations vidéo
            Expanded(
              child: GestureDetector(
                onTap: () {}, // Empêche la propagation du tap
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.video.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.video.description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.video.formattedViews,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.video.formattedDuration,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        if (_formatInfo != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            _getFormatIcon(_formatInfo!.format),
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: _buildActionButton(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        label: _formatCount(_likesCount),
                        onTap: _toggleLike,
                        color: _isLiked ? Colors.red : Colors.white,
                        isLoading: _isLoading,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Partager',
                  onTap: () {
                    // TODO: Partager la vidéo
                  },
                ),
                if (widget.video.recipeId != null) ...[
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.restaurant_menu,
                    label: 'Recette',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/recipe-detail',
                        arguments: widget.video.recipeId,
                      );
                    },
                    color: AppTheme.primaryOrange,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFormatIcon(VideoFormat format) {
    switch (format) {
      case VideoFormat.portrait:
        return Icons.smartphone;
      case VideoFormat.landscape:
        return Icons.tablet_mac;
      case VideoFormat.square:
        return Icons.crop_square;
      case VideoFormat.ultraWide:
        return Icons.aspect_ratio;
      case VideoFormat.ultraTall:
        return Icons.height;
      case VideoFormat.unknown:
        return Icons.help_outline;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              // Empêche la propagation du tap vers le lecteur vidéo
              onTap();
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
