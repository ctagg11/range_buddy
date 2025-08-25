import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/bag.dart';
import '../models/club.dart';
import '../providers/bag_provider.dart';
import '../providers/club_provider.dart';

class BagsScreen extends StatelessWidget {
  const BagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BagProvider>(
        builder: (context, bagProvider, child) {
          if (bagProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bagProvider.bags.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.backpack,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bags created yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first bag',
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
            padding: const EdgeInsets.all(16),
            itemCount: bagProvider.bags.length,
            itemBuilder: (context, index) {
              final bag = bagProvider.bags[index];
              return _buildBagCard(context, bag);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBagDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBagCard(BuildContext context, Bag bag) {
    final clubProvider = Provider.of<ClubProvider>(context);
    final bagProvider = Provider.of<BagProvider>(context, listen: false);
    final clubs = bagProvider.getClubsForBag(bag.id, clubProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _showEditBagDialog(context, bag),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => _deleteBag(context, bag),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          elevation: bag.isDefault ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: bag.isDefault
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => _showBagDetails(context, bag),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.backpack,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  bag.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (bag.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${clubs.length} ${clubs.length == 1 ? 'club' : 'clubs'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  if (clubs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: clubs.take(5).map((club) {
                        return Chip(
                          label: Text(
                            club.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                        );
                      }).toList()
                        ..addAll(
                          clubs.length > 5
                              ? [
                                  Chip(
                                    label: Text(
                                      '+${clubs.length - 5} more',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                  ),
                                ]
                              : [],
                        ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddBagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BagFormDialog(),
    );
  }

  void _showEditBagDialog(BuildContext context, Bag bag) {
    showDialog(
      context: context,
      builder: (context) => BagFormDialog(bag: bag),
    );
  }

  void _showBagDetails(BuildContext context, Bag bag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BagDetailsScreen(bag: bag),
      ),
    );
  }

  void _deleteBag(BuildContext context, Bag bag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bag'),
        content: Text('Are you sure you want to delete "${bag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<BagProvider>(context, listen: false)
                  .deleteBag(bag.id);
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

class BagFormDialog extends StatefulWidget {
  final Bag? bag;

  const BagFormDialog({super.key, this.bag});

  @override
  State<BagFormDialog> createState() => _BagFormDialogState();
}

class _BagFormDialogState extends State<BagFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bag?.name);
    _isDefault = widget.bag?.isDefault ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.bag == null ? 'Create Bag' : 'Edit Bag'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Bag Name',
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
            SwitchListTile(
              title: const Text('Set as default'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveBag,
          child: Text(widget.bag == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  void _saveBag() {
    if (!_formKey.currentState!.validate()) return;

    final bagProvider = Provider.of<BagProvider>(context, listen: false);
    
    final bag = Bag(
      id: widget.bag?.id,
      name: _nameController.text.trim(),
      clubIds: widget.bag?.clubIds,
      isDefault: _isDefault,
      createdAt: widget.bag?.createdAt,
    );

    if (widget.bag == null) {
      bagProvider.addBag(bag);
    } else {
      bagProvider.updateBag(bag);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class BagDetailsScreen extends StatelessWidget {
  final Bag bag;

  const BagDetailsScreen({super.key, required this.bag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bag.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => BagFormDialog(bag: bag),
              );
            },
          ),
        ],
      ),
      body: Consumer2<BagProvider, ClubProvider>(
        builder: (context, bagProvider, clubProvider, child) {
          final updatedBag = bagProvider.getBagById(bag.id) ?? bag;
          final clubs = bagProvider.getClubsForBag(updatedBag.id, clubProvider);
          final allClubs = clubProvider.clubs;
          final availableClubs = allClubs
              .where((club) => !updatedBag.clubIds.contains(club.id))
              .toList();

          return Column(
            children: [
              if (updatedBag.isDefault)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Default Bag',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: clubs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_golf,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No clubs in this bag',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add clubs',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: clubs.length,
                        itemBuilder: (context, index) {
                          final club = clubs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Slidable(
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (_) {
                                      bagProvider.removeClubFromBag(
                                          updatedBag.id, club.id);
                                    },
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.remove_circle,
                                    label: 'Remove',
                                  ),
                                ],
                              ),
                              child: Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    child: Icon(
                                      Icons.sports_golf,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  title: Text(
                                    club.displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    Club.getClubTypeDisplayName(club.type),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClubsDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddClubsDialog(BuildContext context) {
    final bagProvider = Provider.of<BagProvider>(context, listen: false);
    final clubProvider = Provider.of<ClubProvider>(context, listen: false);
    final availableClubs = clubProvider.clubs
        .where((club) => !bag.clubIds.contains(club.id))
        .toList();

    if (availableClubs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No clubs available to add'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final selectedClubs = <String>{};
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Clubs to Bag'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableClubs.length,
                  itemBuilder: (context, index) {
                    final club = availableClubs[index];
                    return CheckboxListTile(
                      title: Text(club.displayName),
                      subtitle: Text(Club.getClubTypeDisplayName(club.type)),
                      value: selectedClubs.contains(club.id),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedClubs.add(club.id);
                          } else {
                            selectedClubs.remove(club.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedClubs.isEmpty
                      ? null
                      : () {
                          for (final clubId in selectedClubs) {
                            bagProvider.addClubToBag(bag.id, clubId);
                          }
                          Navigator.pop(context);
                        },
                  child: Text('Add (${selectedClubs.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}