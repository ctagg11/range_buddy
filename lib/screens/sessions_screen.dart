import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../models/club.dart';
import '../providers/session_provider.dart';
import '../providers/club_provider.dart';
import '../providers/bag_provider.dart';
import 'live_session_screen.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          final activeSession = sessionProvider.activeSession;
          final sessions = sessionProvider.sessions;

          if (activeSession != null) {
            return LiveSessionScreen(session: activeSession);
          }

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.golf_course,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your first practice session',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showStartSessionDialog(context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to practice?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your shots and improve your game',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showStartSessionDialog(context),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return _buildSessionCard(context, session);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Session session) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSessionDetails(context, session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.location,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (session.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(session.startTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeFormat.format(session.startTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (session.clubIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${session.clubIds.length} clubs used',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  void _showStartSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StartSessionDialog(),
    );
  }

  void _showSessionDetails(BuildContext context, Session session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SessionDetailsSheet(session: session),
    );
  }
}

class StartSessionDialog extends StatefulWidget {
  const StartSessionDialog({super.key});

  @override
  State<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends State<StartSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  String? _selectedBagId;
  final Set<String> _selectedClubIds = {};
  bool _useQuickSelect = true;

  @override
  Widget build(BuildContext context) {
    final bagProvider = Provider.of<BagProvider>(context);
    final clubProvider = Provider.of<ClubProvider>(context);

    return AlertDialog(
      title: const Text('Start Practice Session'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., TopGolf Downtown',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              if (bagProvider.bags.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            label: Text('Select Bag'),
                            icon: Icon(Icons.backpack),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text('Select Clubs'),
                            icon: Icon(Icons.sports_golf),
                          ),
                        ],
                        selected: {_useQuickSelect},
                        onSelectionChanged: (value) {
                          setState(() {
                            _useQuickSelect = value.first;
                            _selectedClubIds.clear();
                            _selectedBagId = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (_useQuickSelect && bagProvider.bags.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedBagId,
                  decoration: const InputDecoration(
                    labelText: 'Select Bag',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.backpack),
                  ),
                  items: bagProvider.bags.map((bag) {
                    return DropdownMenuItem(
                      value: bag.id,
                      child: Row(
                        children: [
                          Text(bag.name),
                          if (bag.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBagId = value;
                      if (value != null) {
                        final bag = bagProvider.getBagById(value);
                        if (bag != null) {
                          _selectedClubIds.clear();
                          _selectedClubIds.addAll(bag.clubIds);
                        }
                      }
                    });
                  },
                  validator: (value) {
                    if (!_useQuickSelect) return null;
                    if (value == null) {
                      return 'Please select a bag';
                    }
                    return null;
                  },
                ),
              ] else ...[
                const Text(
                  'Select Clubs:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (clubProvider.clubs.isEmpty)
                  const Text(
                    'No clubs available. Add clubs first.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: clubProvider.clubs.length,
                      itemBuilder: (context, index) {
                        final club = clubProvider.clubs[index];
                        return CheckboxListTile(
                          title: Text(club.displayName),
                          subtitle: Text(Club.getClubTypeDisplayName(club.type)),
                          value: _selectedClubIds.contains(club.id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedClubIds.add(club.id);
                              } else {
                                _selectedClubIds.remove(club.id);
                              }
                            });
                          },
                          dense: true,
                        );
                      },
                    ),
                  ),
              ],
              
              if (_selectedClubIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${_selectedClubIds.length} club${_selectedClubIds.length == 1 ? '' : 's'} selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _startSession,
          child: const Text('Start Session'),
        ),
      ],
    );
  }

  void _startSession() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedClubIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one club'),
        ),
      );
      return;
    }

    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    
    final session = Session(
      location: _locationController.text.trim(),
      clubIds: _selectedClubIds.toList(),
    );

    sessionProvider.startSession(session);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}

class SessionDetailsSheet extends StatelessWidget {
  final Session session;

  const SessionDetailsSheet({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.location,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateFormat.format(session.startTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildDetailRow(
                Icons.access_time,
                'Start Time',
                timeFormat.format(session.startTime),
              ),
              if (session.endTime != null)
                _buildDetailRow(
                  Icons.timer_off,
                  'End Time',
                  timeFormat.format(session.endTime!),
                ),
              if (duration != null)
                _buildDetailRow(
                  Icons.timer,
                  'Duration',
                  _formatDuration(duration),
                ),
              _buildDetailRow(
                Icons.sports_golf,
                'Clubs Used',
                '${session.clubIds.length}',
              ),
              
              const SizedBox(height: 24),
              
              if (session.notes != null && session.notes!.isNotEmpty) ...[
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.notes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} minutes';
  }
}