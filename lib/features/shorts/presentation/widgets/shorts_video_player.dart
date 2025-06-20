import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/models/video.dart';
import '../../../../core/services/videos_service.dart';
import '../../../../core/services/video_format_service.dart';
import '../../../../core/theme/app_theme.dart';
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

class _ShortsVideoPlayerState extends State<ShortsVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _isLiked = false;
  bool _showFormatInfo = false;
  int _likesCount = 0;
  int _viewsCount = 0;
  final VideosService _videosService = VideosService();

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _likesCount = widget.video.likes ?? 0;
    _viewsCount = widget.video.views ?? 0;
    _isLiked = widget.video.isLikedByUser ?? false;
  }

  @override
  void didUpdateWidget(ShortsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _playVideo();
        _incrementViews();
      } else {
        _pauseVideo();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.video.videoUrl != null && widget.video.videoUrl!.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.videoUrl!),
        );

        await _controller!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });

          _controller!.setLooping(true);

          if (widget.isActive) {
            _playVideo();
            _incrementViews();
          }
        }
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation de la vidéo: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _playVideo() {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _pauseVideo() {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }

    // Afficher les contrôles temporairement
    setState(() {
      _showControls = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _toggleLike() async {
    try {
      final wasLiked = _isLiked;

      // Mise à jour optimiste de l'UI
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });

      if (_isLiked) {
        await _videosService.likeVideo(widget.video.id);
      } else {
        await _videosService.unlikeVideo(widget.video.id);
      }
    } catch (e) {
      // Rollback en cas d'erreur
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du like: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _incrementViews() async {
    try {
      await _videosService.incrementVideoViews(widget.video.id);
      setState(() {
        _viewsCount += 1;
      });
    } catch (e) {
      print('Erreur lors de l\'incrémentation des vues: $e');
    }
  }

  void _showRecipe() {
    if (widget.video.recipeId != null) {
      Navigator.pushNamed(
        context,
        '/recipe-detail',
        arguments: widget.video.recipeId,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune recette associée à cette vidéo'),
        ),
      );
    }
  }

  void _shareVideo() {
    // TODO: Implémenter le partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage bientôt disponible'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vidéo ou image de fallback
          GestureDetector(
            onTap: _togglePlayPause,
            onLongPress: () {
              setState(() {
                _showFormatInfo = !_showFormatInfo;
              });
            },
            child: _buildVideoDisplay(),
          ),

          // Overlay avec informations et contrôles
          _buildOverlay(),

          // Boutons d'actions
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildVideoDisplay() {
    if (_controller != null && _isInitialized) {
      return SmartVideoDisplay(
        controller: _controller!,
        showFormatInfo: _showFormatInfo,
      );
    } else {
      // Fallback avec image
      return Container(
        decoration: BoxDecoration(
          image: widget.video.thumbnailUrl != null
              ? DecorationImage(
                  image: NetworkImage(widget.video.thumbnailUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: Colors.grey[900],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.video.thumbnailUrl == null)
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
              const SizedBox(height: 16),
              Text(
                _isInitialized ? 'Vidéo prête' : 'Chargement...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 80,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre
            Text(
              widget.video.title ?? 'Vidéo sans titre',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            if (widget.video.description != null &&
                widget.video.description!.isNotEmpty)
              Text(
                widget.video.description!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 8),

            // Statistiques
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatCount(_viewsCount)} vues',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.favorite,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatCount(_likesCount)} likes',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          // Bouton Like
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(_likesCount),
            color: _isLiked ? Colors.red : Colors.white,
            onTap: _toggleLike,
          ),

          const SizedBox(height: 24),

          // Bouton Partage
          _buildActionButton(
            icon: Icons.share,
            label: 'Partager',
            color: Colors.white,
            onTap: _shareVideo,
          ),

          const SizedBox(height: 24),

          // Bouton Recette (si disponible)
          if (widget.video.recipeId != null)
            _buildActionButton(
              icon: Icons.restaurant_menu,
              label: 'Recette',
              color: AppTheme.primaryOrange,
              onTap: _showRecipe,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
