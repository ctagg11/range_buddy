import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/session_provider.dart';
import '../providers/club_provider.dart';
import '../models/club.dart';
import '../services/database_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();
  Map<String, List<double>> _clubDistances = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload analytics when screen becomes visible
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final clubs = Provider.of<ClubProvider>(context, listen: false).clubs;
      final Map<String, List<double>> distances = {};
      
      for (final club in clubs) {
        final shots = await _db.getShotsForClub(club.id);
        if (shots.isNotEmpty) {
          distances[club.id] = shots.map((s) => s.distance).toList();
        }
      }
      
      setState(() {
        _clubDistances = distances;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'By Club'),
                Tab(text: 'Progress'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildByClubTab(),
                _buildProgressTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use provider data which is always up to date
    final sessionProvider = Provider.of<SessionProvider>(context);
    final sessions = sessionProvider.sessions;
    
    // Calculate total shots from all sessions
    int totalShots = 0;
    for (final entry in _clubDistances.entries) {
      totalShots += entry.value.length;
    }

    if (totalShots == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No data yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a practice session to see analytics',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Total Sessions',
          sessions.length.toString(),
          Icons.golf_course,
          Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Total Shots',
          totalShots.toString(),
          Icons.sports_golf,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Average Distance',
          _calculateOverallAverage(),
          Icons.straighten,
          Colors.blue,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distance Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildDistanceChart(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildByClubTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final clubProvider = Provider.of<ClubProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);
    final clubsWithData = clubProvider.clubs
        .where((club) => _clubDistances.containsKey(club.id))
        .toList();

    if (clubsWithData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_golf,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No club data available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clubsWithData.length,
      itemBuilder: (context, index) {
        final club = clubsWithData[index];
        final distances = _clubDistances[club.id] ?? [];
        final average = distances.isEmpty
            ? 0.0
            : distances.reduce((a, b) => a + b) / distances.length;
        final min = distances.isEmpty
            ? 0.0
            : distances.reduce((a, b) => a < b ? a : b);
        final max = distances.isEmpty
            ? 0.0
            : distances.reduce((a, b) => a > b ? a : b);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.sports_golf,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              club.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Avg: ${average.toStringAsFixed(1)} yds • ${distances.length} shots',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat('Min', '${min.toStringAsFixed(0)} yds'),
                        _buildMiniStat('Avg', '${average.toStringAsFixed(1)} yds'),
                        _buildMiniStat('Max', '${max.toStringAsFixed(0)} yds'),
                      ],
                    ),
                    if (distances.length >= 2) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: _buildClubChart(distances),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Progress Tracking',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your improvement over time',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceChart() {
    final allDistances = _clubDistances.values
        .expand((list) => list)
        .toList()
      ..sort();

    if (allDistances.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final Map<int, int> distribution = {};
    for (final distance in allDistances) {
      final bucket = (distance ~/ 10) * 10;
      distribution[bucket] = (distribution[bucket] ?? 0) + 1;
    }

    final sortedBuckets = distribution.keys.toList()..sort();
    final maxY = distribution.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barGroups: sortedBuckets.map((bucket) {
          return BarChartGroupData(
            x: bucket,
            barRods: [
              BarChartRodData(
                toY: distribution[bucket]!.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildClubChart(List<double> distances) {
    final spots = distances.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateOverallAverage() {
    final allDistances = _clubDistances.values.expand((list) => list).toList();
    if (allDistances.isEmpty) return '0 yds';
    
    final average = allDistances.reduce((a, b) => a + b) / allDistances.length;
    return '${average.toStringAsFixed(1)} yds';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}