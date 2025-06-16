import 'package:flutter/material.dart';
import '../../../../core/services/activity_history_service.dart';
import '../../../../core/theme/app_theme.dart';

class ActivityStats extends StatefulWidget {
  const ActivityStats({super.key});

  @override
  State<ActivityStats> createState() => _ActivityStatsState();
}

class _ActivityStatsState extends State<ActivityStats> {
  final ActivityHistoryService _historyService = ActivityHistoryService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    final stats = await _historyService.getUserActivityStats();

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_stats.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé des 30 derniers jours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                context,
                Icons.login,
                _stats['login_count']?.toString() ?? '0',
                'Connexions',
                Colors.green,
              ),
              _buildStatItem(
                context,
                Icons.restaurant,
                _stats['recipe_count']?.toString() ?? '0',
                'Recettes',
                Colors.purple,
              ),
              _buildStatItem(
                context,
                Icons.favorite,
                _stats['favorite_count']?.toString() ?? '0',
                'Favoris',
                Colors.pink,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                context,
                Icons.edit,
                _stats['update_count']?.toString() ?? '0',
                'Modifications',
                Colors.amber,
              ),
              _buildStatItem(
                context,
                Icons.settings,
                _stats['settings_count']?.toString() ?? '0',
                'Paramètres',
                Colors.blue,
              ),
              _buildStatItem(
                context,
                Icons.more_horiz,
                _stats['other_count']?.toString() ?? '0',
                'Autres',
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
