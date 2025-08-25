import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/shot.dart';
import '../models/club.dart';
import '../providers/session_provider.dart';
import '../providers/club_provider.dart';

class LiveSessionScreen extends StatefulWidget {
  final Session session;

  const LiveSessionScreen({super.key, required this.session});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  String? _selectedClubId;
  Club? _selectedClub;
  final _distanceController = TextEditingController();
  ShotShape? _selectedShape;

  @override
  void initState() {
    super.initState();
    final clubs = Provider.of<ClubProvider>(context, listen: false).clubs;
    if (widget.session.clubIds.isNotEmpty) {
      _selectedClubId = widget.session.clubIds.first;
      _selectedClub = clubs.firstWhere(
        (c) => c.id == _selectedClubId,
        orElse: () => clubs.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final clubProvider = Provider.of<ClubProvider>(context);
    final sessionClubs = widget.session.clubIds
        .map((id) => clubProvider.getClubById(id))
        .where((club) => club != null)
        .cast<Club>()
        .toList();

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showEndSessionDialog();
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live Session',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                widget.session.location,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => _showEndSessionDialog(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Club Selector with stats at top
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: sessionClubs.length,
                itemBuilder: (context, index) {
                  final club = sessionClubs[index];
                  final isSelected = club.id == _selectedClubId;
                  final sessionAvg = sessionProvider.getSessionAverageForClub(club.id);
                  final shotCount = sessionProvider.getSessionShotCountForClub(club.id);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedClubId = club.id;
                          _selectedClub = club;
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 110,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Stats at top
                            if (shotCount > 0) ...[
                              Text(
                                '${sessionAvg?.toStringAsFixed(0) ?? 0} yds',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$shotCount ${shotCount == 1 ? 'shot' : 'shots'}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Club name
                            Text(
                              club.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (shotCount == 0)
                              Text(
                                'Tap to start',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white60
                                      : Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Simplified Input Section
            _buildSimplifiedInput(sessionProvider),


            // Recent Shots
            Expanded(
              child: Consumer<SessionProvider>(
                builder: (context, provider, child) {
                  final clubShots = provider.getShotsForClub(_selectedClubId ?? '');
                  
                  if (clubShots.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_golf,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No shots recorded yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your first shot distance above',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: clubShots.length,
                    itemBuilder: (context, index) {
                      final shot = clubShots[index];
                      return Dismissible(
                        key: Key(shot.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          provider.deleteShot(shot.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Shot deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  provider.addShot(shot);
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${shot.distance.toStringAsFixed(0)} yards',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: shot.shape != null
                                ? Text(Shot.getShotShapeDisplayName(shot.shape!))
                                : null,
                            trailing: Icon(
                              Icons.golf_course,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedInput(SessionProvider sessionProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Distance buttons grid - main input method
          Container(
            height: 240,
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDistanceButton(50, sessionProvider),
                _buildDistanceButton(75, sessionProvider),
                _buildDistanceButton(100, sessionProvider),
                _buildDistanceButton(125, sessionProvider),
                _buildDistanceButton(150, sessionProvider),
                _buildDistanceButton(175, sessionProvider),
                _buildDistanceButton(200, sessionProvider),
                _buildDistanceButton(225, sessionProvider),
                _buildDistanceButton(250, sessionProvider),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Shot shape selector (optional)
          Container(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildShapeChip(null, 'Straight'),
                const SizedBox(width: 8),
                _buildShapeChip(ShotShape.draw, 'Draw'),
                const SizedBox(width: 8),
                _buildShapeChip(ShotShape.fade, 'Fade'),
                const SizedBox(width: 8),
                _buildShapeChip(ShotShape.hook, 'Hook'),
                const SizedBox(width: 8),
                _buildShapeChip(ShotShape.slice, 'Slice'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Custom distance input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Custom distance',
                    hintText: 'Enter yards',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        if (_distanceController.text.isNotEmpty) {
                          _addShotWithDistance(
                            double.parse(_distanceController.text),
                            sessionProvider,
                          );
                        }
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _addShotWithDistance(
                        double.parse(value),
                        sessionProvider,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceButton(int distance, SessionProvider sessionProvider) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          _addShotWithDistance(distance.toDouble(), sessionProvider);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$distance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'yards',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShapeChip(ShotShape? shape, String label) {
    final isSelected = _selectedShape == shape;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedShape = selected ? shape : null;
        });
        if (selected) {
          HapticFeedback.selectionClick();
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontSize: 12,
      ),
    );
  }


  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context)
                .colorScheme
                .onPrimaryContainer
                .withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _addShotWithDistance(double distance, SessionProvider sessionProvider) {
    if (_selectedClubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a club first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid distance'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final shot = Shot(
      sessionId: widget.session.id,
      clubId: _selectedClubId!,
      distance: distance,
      shape: _selectedShape,
    );

    sessionProvider.addShot(shot);
    
    // Clear custom input
    _distanceController.clear();
    
    // Keep shape selected for next shot (user preference)
    // Reset shape after a delay if needed
    
    // Haptic feedback - light for success
    HapticFeedback.lightImpact();
    
    // Visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${distance.toStringAsFixed(0)} yards recorded',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 800),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 100,
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<bool?> _showEndSessionDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text(
          'Are you sure you want to end this practice session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<SessionProvider>(context, listen: false).endSession();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }
}