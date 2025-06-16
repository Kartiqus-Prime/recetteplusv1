import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_stats_service.dart';
import '../pages/favorites_page.dart';
import '../pages/orders_page.dart';
import '../pages/recipes_page.dart';

class ProfileStats extends StatefulWidget {
  final UserStatsService statsService;

  const ProfileStats({
    super.key,
    required this.statsService,
  });

  @override
  State<ProfileStats> createState() => _ProfileStatsState();
}

class _ProfileStatsState extends State<ProfileStats> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _cachedStats;
  DateTime? _lastFetch;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats({bool forceRefresh = false}) async {
    // Éviter les requêtes multiples simultanées
    if (_isLoading) return;

    // Cache de 30 secondes sauf si forceRefresh
    if (!forceRefresh && 
        _cachedStats != null && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!).inSeconds < 30) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await widget.statsService.getUserStats();
      if (mounted) {
        setState(() {
          _cachedStats = stats;
          _lastFetch = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Méthode publique pour forcer le rafraîchissement
  void refreshStats() {
    _loadStats(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Auto-refresh si les données sont anciennes (plus de 2 minutes)
    if (_lastFetch != null && 
        DateTime.now().difference(_lastFetch!).inMinutes > 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStats();
      });
    }

    if (_isLoading && _cachedStats == null) {
      return _buildLoadingStats(isDarkMode);
    }

    if (_cachedStats == null) {
      return _buildErrorStats(isDarkMode);
    }

    return _buildStatsRow(context, _cachedStats!, isDarkMode);
  }

  Widget _buildLoadingStats(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (index) => Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 12,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorStats(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (index) => Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erreur',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _loadStats(forceRefresh: true),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réessayer'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, dynamic> stats, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context,
            'Favoris',
            stats['favorites_count'] ?? 0,
            Icons.favorite,
            Colors.red,
            isDarkMode,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              );
              // Rafraîchir les stats si on revient de la page des favoris
              if (result == true || result == null) {
                _loadStats(forceRefresh: true);
              }
            },
          ),
          _buildStatItem(
            context,
            'Commandes',
            stats['orders_count'] ?? 0,
            Icons.shopping_bag,
            Colors.blue,
            isDarkMode,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrdersPage()),
              );
              if (result == true || result == null) {
                _loadStats(forceRefresh: true);
              }
            },
          ),
          _buildStatItem(
            context,
            'Recettes',
            stats['recipes_count'] ?? 0,
            Icons.restaurant_menu,
            Colors.green,
            isDarkMode,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipesPage()),
              );
              if (result == true || result == null) {
                _loadStats(forceRefresh: true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int count,
    IconData icon,
    Color color,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
