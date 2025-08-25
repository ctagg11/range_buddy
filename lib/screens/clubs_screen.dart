import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/club.dart';
import '../providers/club_provider.dart';

class ClubsScreen extends StatelessWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ClubProvider>(
        builder: (context, clubProvider, child) {
          if (clubProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (clubProvider.clubs.isEmpty) {
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
                    'No clubs added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first club',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final clubsByType = <ClubType, List<Club>>{};
          for (final club in clubProvider.clubs) {
            clubsByType.putIfAbsent(club.type, () => []).add(club);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: clubsByType.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      Club.getClubTypeDisplayName(entry.key),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  ...entry.value.map((club) => _buildClubCard(context, club)),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClubDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClubCard(BuildContext context, Club club) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _showEditClubDialog(context, club),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => _deleteClub(context, club),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                _getClubIcon(club.type),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              club.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: club.loft != null
                ? Text('${club.loft}° • ${club.shaft ?? 'Standard'}')
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClubDetails(context, club),
          ),
        ),
      ),
    );
  }

  IconData _getClubIcon(ClubType type) {
    switch (type) {
      case ClubType.driver:
        return Icons.sports_golf;
      case ClubType.fairwayWood:
      case ClubType.hybrid:
        return Icons.grass;
      case ClubType.iron:
        return Icons.straighten;
      case ClubType.wedge:
        return Icons.terrain;
      case ClubType.putter:
        return Icons.flag;
    }
  }

  void _showAddClubDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ClubFormDialog(),
    );
  }

  void _showEditClubDialog(BuildContext context, Club club) {
    showDialog(
      context: context,
      builder: (context) => ClubFormDialog(club: club),
    );
  }

  void _showClubDetails(BuildContext context, Club club) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClubDetailsSheet(club: club),
    );
  }

  void _deleteClub(BuildContext context, Club club) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Club'),
        content: Text('Are you sure you want to delete ${club.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ClubProvider>(context, listen: false)
                  .deleteClub(club.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ClubFormDialog extends StatefulWidget {
  final Club? club;

  const ClubFormDialog({super.key, this.club});

  @override
  State<ClubFormDialog> createState() => _ClubFormDialogState();
}

class _ClubFormDialogState extends State<ClubFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late ClubType _selectedType;
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _loftController;
  late TextEditingController _shaftController;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.club?.type ?? ClubType.driver;
    _nameController = TextEditingController(
      text: widget.club?.name ?? _getDefaultName(_selectedType),
    );
    _brandController = TextEditingController(text: widget.club?.brand);
    _modelController = TextEditingController(text: widget.club?.model);
    _loftController = TextEditingController(text: widget.club?.loft);
    _shaftController = TextEditingController(text: widget.club?.shaft);
  }

  String _getDefaultName(ClubType type) {
    switch (type) {
      case ClubType.driver:
        return 'Driver';
      case ClubType.fairwayWood:
        return '3 Wood';
      case ClubType.hybrid:
        return '3 Hybrid';
      case ClubType.iron:
        return '7 Iron';
      case ClubType.wedge:
        return 'Pitching Wedge';
      case ClubType.putter:
        return 'Putter';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.club == null ? 'Add Club' : 'Edit Club'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ClubType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Club Type',
                  border: OutlineInputBorder(),
                ),
                items: ClubType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(Club.getClubTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      if (widget.club == null) {
                        _nameController.text = _getDefaultName(value);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _loftController,
                decoration: const InputDecoration(
                  labelText: 'Loft (optional)',
                  border: OutlineInputBorder(),
                  suffixText: '°',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shaftController,
                decoration: const InputDecoration(
                  labelText: 'Shaft (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
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
          onPressed: _saveClub,
          child: Text(widget.club == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _saveClub() {
    if (!_formKey.currentState!.validate()) return;

    final clubProvider = Provider.of<ClubProvider>(context, listen: false);
    
    final club = Club(
      id: widget.club?.id,
      type: _selectedType,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      loft: _loftController.text.trim().isEmpty
          ? null
          : _loftController.text.trim(),
      shaft: _shaftController.text.trim().isEmpty
          ? null
          : _shaftController.text.trim(),
      createdAt: widget.club?.createdAt,
    );

    if (widget.club == null) {
      clubProvider.addClub(club);
    } else {
      clubProvider.updateClub(club);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _loftController.dispose();
    _shaftController.dispose();
    super.dispose();
  }
}

class ClubDetailsSheet extends StatelessWidget {
  final Club club;

  const ClubDetailsSheet({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            club.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Club.getClubTypeDisplayName(club.type),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          if (club.brand != null) _buildDetailRow('Brand', club.brand!),
          if (club.model != null) _buildDetailRow('Model', club.model!),
          if (club.loft != null) _buildDetailRow('Loft', '${club.loft}°'),
          if (club.shaft != null) _buildDetailRow('Shaft', club.shaft!),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to shot history for this club
                  },
                  child: const Text('View Stats'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Start a session with this club
                  },
                  child: const Text('Practice'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}