import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/activity_log.dart';
import '../../../../core/services/activity_history_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/extensions/context_extensions.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final ActivityHistoryService _historyService = ActivityHistoryService();
  final ScrollController _scrollController = ScrollController();
  
  List<ActivityLog> _activities = [];
  List<Map<String, dynamic>> _availableTypes = [];
  Map<String, dynamic> _activitySummary = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _offset = 0;
  final int _limit = 20;
  
  String? _selectedActivityType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initializeData();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore &&
          _hasMoreData) {
        _loadMoreActivities();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadAvailableTypes(),
      _loadActivitySummary(),
    ]);

    await _loadActivities();
  }

  Future<void> _loadAvailableTypes() async {
    final types = await _historyService.getAvailableActivityTypes();
    setState(() {
      _availableTypes = types;
    });
  }

  Future<void> _loadActivitySummary() async {
    final summary = await _historyService.getActivitySummary();
    setState(() {
      _activitySummary = summary;
    });
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
    });

    final activities = await _historyService.getUserActivityHistory(
      limit: _limit,
      offset: _offset,
      activityType: _selectedActivityType,
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() {
      _activities = activities;
      _isLoading = false;
      _hasMoreData = activities.length == _limit;
      _offset = activities.length;
    });
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    final activities = await _historyService.getUserActivityHistory(
      limit: _limit,
      offset: _offset,
      activityType: _selectedActivityType,
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() {
      _activities.addAll(activities);
      _isLoadingMore = false;
      _hasMoreData = activities.length == _limit;
      _offset += activities.length;
    });
  }

  Future<void> _showFilterDialog() async {
    String? tempActivityType = _selectedActivityType;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF252525) : Colors.white,
              title: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: AppTheme.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtrer les activités',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Résumé des activités
                    if (_activitySummary.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Résumé',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_activitySummary['totalActivities'] ?? 0} activités au total',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Text(
                      'Type d\'activité',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF333333) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: tempActivityType ?? 'all',
                        isExpanded: true,
                        dropdownColor: isDarkMode ? const Color(0xFF333333) : Colors.white,
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: 'all',
                            child: Text(
                              'Toutes les activités',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          ..._availableTypes.map((typeData) {
                            final actionType = typeData['action_type'] as String;
                            final entityType = typeData['entity_type'] as String?;
                            final displayName = typeData['display_name'] as String;
                            final count = typeData['count'] as int;
                            final key = '$actionType${entityType != null ? '_$entityType' : ''}';
                            
                            return DropdownMenuItem<String>(
                              value: actionType,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryOrange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryOrange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            tempActivityType = value == 'all' ? null : value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Période',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateSelector(
                            context,
                            tempStartDate,
                            'Date début',
                            (date) => setDialogState(() => tempStartDate = date),
                            isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDateSelector(
                            context,
                            tempEndDate,
                            'Date fin',
                            (date) => setDialogState(() => tempEndDate = date),
                            isDarkMode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Correction du problème d'overflow
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                tempStartDate = null;
                                tempEndDate = null;
                              });
                            },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Effacer les dates'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryOrange,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              final now = DateTime.now();
                              setDialogState(() {
                                tempStartDate = DateTime(now.year, now.month, now.day - 7);
                                tempEndDate = now;
                              });
                            },
                            icon: const Icon(Icons.date_range, size: 16),
                            label: const Text('7 derniers jours'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryOrange,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedActivityType = tempActivityType;
                      _startDate = tempStartDate;
                      _endDate = tempEndDate;
                    });
                    Navigator.of(context).pop();
                    _loadActivities();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Appliquer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    DateTime? selectedDate,
    String placeholder,
    Function(DateTime?) onDateSelected,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppTheme.primaryOrange,
                  onPrimary: Colors.white,
                  surface: isDarkMode ? const Color(0xFF252525) : Colors.white,
                  onSurface: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );
        onDateSelected(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF333333) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(selectedDate)
                    : placeholder,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActivityDetails(ActivityLog activity) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Récupérer les détails de l'entité et de l'IP
    final futures = <Future>[];
    
    if (activity.entityId != null && activity.entityType != null) {
      futures.add(_historyService.getEntityDetails(
        activity.entityType,
        activity.entityId,
      ));
    } else {
      futures.add(Future.value(null));
    }
    
    if (activity.ipAddress != null && activity.ipAddress!.isNotEmpty) {
      futures.add(_historyService.getIpInfo(activity.ipAddress!));
    } else {
      futures.add(Future.value(null));
    }
    
    final results = await Future.wait(futures);
    final entityDetails = results.isNotEmpty ? results[0] as Map<String, dynamic>? : null;
    final ipInfo = results.length > 1 ? results[1] as Map<String, dynamic>? : null;
    
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF252525) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: activity.getTypeColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      activity.typeIcon,
                      color: activity.getTypeColor(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.typeDisplayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          activity.getRelativeTime(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF333333) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activity.getDetailText(),
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              
              // Image de l'entité si disponible
              if (entityDetails != null && entityDetails['image_url'] != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    entityDetails['image_url'],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              ],
              
              // Informations sur l'IP
              if (ipInfo != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Localisation',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (ipInfo['type'] == 'private')
                        Text(
                          ipInfo['location'],
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        )
                      else ...[
                        if (ipInfo['city'] != null)
                          Text(
                            '${ipInfo['city']}, ${ipInfo['region']}, ${ipInfo['country']}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        if (ipInfo['isp'] != null)
                          Text(
                            'Fournisseur: ${ipInfo['isp']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              
              // Détails techniques
              Text(
                'Détails techniques',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              ...activity.getDetailItems().map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        item['label']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['value']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
              
              const SizedBox(height: 20),
              
              // Actions spécifiques
              if (activity.type == ActivityType.recipeDeleted && activity.entityId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await _historyService.restoreDeletedEntity(
                        'recipes',
                        activity.entityId!,
                      );
                      
                      Navigator.pop(context);
                      
                      if (success) {
                        if (mounted) {
                          context.showSnackBar('Recette restaurée avec succès');
                          _loadActivities();
                        }
                      } else {
                        if (mounted) {
                          context.showSnackBar(
                            'Impossible de restaurer la recette',
                            isError: true,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurer cette recette'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(ActivityLog activity) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () => _showActivityDetails(activity),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: activity.getTypeColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                activity.typeIcon,
                color: activity.getTypeColor(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.typeDisplayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        activity.getRelativeTime(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.getDetailText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDarkMode ? Colors.white60 : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityList() {
    if (_activities.isEmpty) {
      return [
        const SizedBox(height: 40),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune activité trouvée',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedActivityType != null || _startDate != null || _endDate != null
                    ? 'Essayez de modifier vos filtres'
                    : 'Vos activités apparaîtront ici',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final List<Widget> widgets = [];
    String? currentDate;

    for (final activity in _activities) {
      final date = DateFormat('dd/MM/yyyy').format(activity.timestamp);
      
      if (currentDate != date) {
        currentDate = date;
        widgets.add(_buildDateHeader(currentDate));
      }
      
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildActivityItem(activity),
      ));
    }

    if (_isLoadingMore) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Chargement...',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF121212) 
          : const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: isDarkMode 
            ? const Color(0xFF1E1E1E) 
            : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Historique d\'activité',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              if (_selectedActivityType != null || _startDate != null || _endDate != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _initializeData();
        },
        color: AppTheme.primaryOrange,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  controller: _scrollController,
                  children: _buildActivityList(),
                ),
              ),
      ),
    );
  }
}
