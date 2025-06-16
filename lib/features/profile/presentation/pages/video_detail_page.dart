import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../core/models/video.dart';
import '../../../../core/services/videos_service.dart';
import '../../../../core/theme/app_theme.dart';

class VideoDetailPage extends StatefulWidget {
  final String videoId;

  const VideoDetailPage({
    super.key,
    required this.videoId,
  });

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  final VideosService _videosService = VideosService();
  Video? _video;
  bool _isLoading = true;
  String? _error;
  bool _isFavorite = false;
  bool _isLiked = false;
  
  // Contrôleurs vidéo
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
    // Permettre toutes les orientations pour le mode plein écran
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    // Rétablir l'orientation portrait uniquement lorsqu'on quitte la page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final video = await _videosService.getVideoById(widget.videoId);
      
      if (mounted) {
        setState(() {
          _video = video;
          _isLoading = false;
        });
        
        if (video?.videoUrl != null) {
          _initializeVideoPlayer(video!.videoUrl!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        fullScreenByDefault: false,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showOptions: true,
        showControlsOnInitialize: false,
        hideControlsTimer: const Duration(seconds: 3),
        // Utilisation des contrôles par défaut sans paramètres personnalisés
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(height: 8),
                Text(
                  'Erreur de lecture: $errorMessage',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _initializeVideoPlayer(videoUrl),
                  child: Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
        placeholder: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryOrange,
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryOrange,
          handleColor: AppTheme.primaryOrange,
          backgroundColor: Colors.grey.shade700,
          bufferedColor: Colors.white.withOpacity(0.5),
        ),
      );

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement de la vidéo: $e';
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
        appBar: AppBar(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _video == null) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
        appBar: AppBar(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          title: const Text('Erreur'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Vidéo non trouvée',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadVideo,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Formater la durée de la vidéo
    String formattedDuration = _video!.formattedDuration ?? "00:00";

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          _video!.title ?? 'Vidéo sans titre',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorite 
                        ? 'Ajouté aux favoris' 
                        : 'Retiré des favoris',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          // Si en mode plein écran, quitter d'abord le mode plein écran
          if (_chewieController?.isFullScreen ?? false) {
            _chewieController?.exitFullScreen();
            return false; // Ne pas quitter la page
          }
          return true; // Quitter la page
        },
        child: OrientationBuilder(
          builder: (context, orientation) {
            // Ajuster la hauteur du conteneur vidéo en fonction de l'orientation
            final videoHeight = orientation == Orientation.portrait ? 250.0 : MediaQuery.of(context).size.height;
            
            return SingleChildScrollView(
              physics: orientation == Orientation.portrait 
                  ? const AlwaysScrollableScrollPhysics() 
                  : const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lecteur vidéo
                  Container(
                    width: double.infinity,
                    height: videoHeight,
                    color: Colors.black,
                    child: _isVideoInitialized && _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_video!.thumbnailUrl != null)
                                Image.network(
                                  _video!.thumbnailUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(
                                        Icons.video_library,
                                        size: 64,
                                        color: Colors.white54,
                                      ),
                                    );
                                  },
                                )
                              else
                                Container(
                                  color: Colors.grey.shade800,
                                  child: const Icon(
                                    Icons.video_library,
                                    size: 64,
                                    color: Colors.white54,
                                  ),
                                ),
                              // Bouton play ou indicateur de chargement
                              GestureDetector(
                                onTap: () {
                                  if (_video?.videoUrl != null && !_isVideoInitialized) {
                                    _initializeVideoPlayer(_video!.videoUrl!);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: _error != null
                                      ? const Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 48,
                                        )
                                      : const Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                ),
                              ),
                              // Durée
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    formattedDuration,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Ne pas afficher le reste du contenu en mode paysage (plein écran)
                  if (orientation == Orientation.portrait)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre
                          Text(
                            _video!.title ?? 'Vidéo sans titre',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Statistiques
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 16,
                                color: isDarkMode ? Colors.white60 : Colors.black45,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_video!.views ?? 0} vues',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white60 : Colors.black45,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.thumb_up,
                                size: 16,
                                color: isDarkMode ? Colors.white60 : Colors.black45,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_video!.likes ?? 0} likes',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white60 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Catégorie et auteur
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _video!.category ?? 'Non catégorisé',
                                  style: TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_video!.authorName != null) ...[
                                const SizedBox(width: 12),
                                Text(
                                  'Par ${_video!.authorName ?? 'Auteur inconnu'}',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Boutons d'action restructurés (seulement Like et Partager)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isLiked = !_isLiked;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isLiked ? 'Vidéo likée' : 'Like retiré',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                  ),
                                  label: const Text('Like'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLiked 
                                        ? AppTheme.primaryOrange 
                                        : isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                    foregroundColor: _isLiked 
                                        ? Colors.white 
                                        : isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Partage à implémenter'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Partager'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDarkMode ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Description
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _video!.description ?? 'Aucune description disponible',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tags
                          if (_video!.tags != null && _video!.tags!.isNotEmpty) ...[
                            Text(
                              'Tags',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _video!.tags!.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode 
                                      ? Colors.grey.shade800 
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}
