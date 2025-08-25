import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/club.dart';
import '../models/bag.dart';
import '../providers/club_provider.dart';
import '../providers/bag_provider.dart';

class GolfBagScreen extends StatefulWidget {
  const GolfBagScreen({super.key});

  @override
  State<GolfBagScreen> createState() => _GolfBagScreenState();
}

class _GolfBagScreenState extends State<GolfBagScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBagId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Select default bag initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bagProvider = Provider.of<BagProvider>(context, listen: false);
      if (bagProvider.bags.isNotEmpty) {
        setState(() {
          _selectedBagId = bagProvider.defaultBag?.id ?? bagProvider.bags.first.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<BagProvider, ClubProvider>(
        builder: (context, bagProvider, clubProvider, child) {
          if (bagProvider.isLoading || clubProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final selectedBag = _selectedBagId != null 
              ? bagProvider.getBagById(_selectedBagId!)
              : bagProvider.defaultBag;

          return Column(
            children: [
              // Bag Selector
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: bagProvider.bags.length + 1,
                  itemBuilder: (context, index) {
                    if (index == bagProvider.bags.length) {
                      // Add bag button
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: IconButton(
                            onPressed: _showAddBagDialog,
                            icon: const Icon(Icons.add_circle),
                            color: Theme.of(context).colorScheme.primary,
                            tooltip: 'Create Custom Bag',
                          ),
                        ),
                      );
                    }

                    final bag = bagProvider.bags[index];
                    final isSelected = bag.id == _selectedBagId;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBagId = bag.id;
                          });
                        },
                        onLongPress: () => _showBagOptions(bag),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.backpack,
                                    size: 16,
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    bag.name,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (bag.isDefault) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: isSelected ? Colors.yellow : Colors.orange,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Tab Bar
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(
                      text: 'Bags',
                      icon: Icon(Icons.backpack, size: 20),
                    ),
                    Tab(
                      text: 'All Clubs',
                      icon: Icon(Icons.sports_golf, size: 20),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBagsTab(selectedBag, bagProvider, clubProvider),
                    _buildAllClubs(clubProvider, selectedBag, bagProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBagsTab(Bag? selectedBag, BagProvider bagProvider, ClubProvider clubProvider) {
    if (selectedBag == null) {
      return const Center(
        child: Text('No bag selected'),
      );
    }

    final clubs = bagProvider.getClubsForBag(selectedBag.id, clubProvider);
    
    // Group clubs by type
    final clubsByType = <ClubType, List<Club>>{};
    for (final club in clubs) {
      clubsByType.putIfAbsent(club.type, () => []).add(club);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Selected Bag Info Card
        Card(
          elevation: 3,
          color: Theme.of(context).colorScheme.primaryContainer,
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
                                selectedBag.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (selectedBag.isDefault) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.star,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${clubs.length} clubs',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showBagOptions(selectedBag),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat('Drivers', clubsByType[ClubType.driver]?.length ?? 0),
                    _buildMiniStat('Woods', clubsByType[ClubType.fairwayWood]?.length ?? 0),
                    _buildMiniStat('Irons', clubsByType[ClubType.iron]?.length ?? 0),
                    _buildMiniStat('Wedges', clubsByType[ClubType.wedge]?.length ?? 0),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Empty state or clubs list
        if (clubs.isEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.golf_course,
                    size: 60,
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
                    'Add clubs from the "All Clubs" tab',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _tabController.animateTo(1);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Browse Clubs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Clubs in Bag',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          // Clubs by category
          ...clubsByType.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    Club.getClubTypeDisplayName(entry.key),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ...entry.value.map((club) => _buildClubTile(club, true, selectedBag, bagProvider)),
              ],
            );
          }).toList(),
        ],
        
        const SizedBox(height: 16),
        
        // Other bags section
        if (bagProvider.bags.length > 1) ...[
          const Divider(height: 32),
          Text(
            'Other Bags',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...bagProvider.bags.where((b) => b.id != selectedBag.id).map((bag) {
            final bagClubs = bagProvider.getClubsForBag(bag.id, clubProvider);
            return Card(
              child: ListTile(
                leading: Icon(
                  Icons.backpack,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(bag.name),
                subtitle: Text('${bagClubs.length} clubs'),
                trailing: bag.isDefault 
                    ? const Icon(Icons.star, color: Colors.orange, size: 20)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedBagId = bag.id;
                  });
                },
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
  
  Widget _buildMiniStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAllClubs(ClubProvider clubProvider, Bag? selectedBag, BagProvider bagProvider) {
    if (clubProvider.clubs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final clubsByType = <ClubType, List<Club>>{};
    for (final club in clubProvider.clubs) {
      clubsByType.putIfAbsent(club.type, () => []).add(club);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick actions
        if (selectedBag != null)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap any club to add/remove from ${selectedBag.name}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        
        // All clubs by category
        ...clubsByType.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  Club.getClubTypeDisplayName(entry.key),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ...entry.value.map((club) {
                final isInBag = selectedBag?.clubIds.contains(club.id) ?? false;
                return _buildClubTile(club, isInBag, selectedBag, bagProvider);
              }),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
        
        const SizedBox(height: 16),
        
        // Add custom club button
        Center(
          child: ElevatedButton.icon(
            onPressed: _showAddClubDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Custom Club'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClubTile(Club club, bool isInBag, Bag? selectedBag, BagProvider bagProvider) {
    // Check if this is a default club
    final isDefaultClub = club.brand == 'Standard' && club.name.startsWith('Default');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isInBag ? 2 : 1,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: isInBag
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                _getClubIcon(club.type),
                color: isInBag ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isDefaultClub)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                club.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (isDefaultClub)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            if (club.loft != null) Text('${club.loft}° loft'),
            if (club.brand != null && !isDefaultClub) ...[
              if (club.loft != null) const Text(' • '),
              Text(club.brand!),
            ],
          ],
        ),
        trailing: selectedBag != null
            ? _buildClubAction(club, isInBag, selectedBag, bagProvider)
            : null,
        onTap: () => _showClubDetails(club),
        onLongPress: () => _showClubOptions(club),
      ),
    );
  }
  
  Widget _buildClubAction(Club club, bool isInBag, Bag selectedBag, BagProvider bagProvider) {
    final clubProvider = Provider.of<ClubProvider>(context);
    
    // Get all clubs of the same type
    final sameTypeClubs = clubProvider.clubs
        .where((c) => c.type == club.type)
        .toList();
    
    // Get clubs of same type already in bag
    final sameTypeInBag = sameTypeClubs
        .where((c) => selectedBag.clubIds.contains(c.id))
        .toList();
    
    // If this is in the bag and there are other clubs of same type
    if (isInBag && sameTypeClubs.length > 1) {
      return PopupMenuButton<String>(
        icon: Icon(
          Icons.swap_horiz,
          color: Theme.of(context).colorScheme.primary,
        ),
        tooltip: 'Swap with another ${Club.getClubTypeDisplayName(club.type)}',
        onSelected: (String clubId) async {
          // Remove current club
          await bagProvider.removeClubFromBag(selectedBag.id, club.id);
          // Add selected club
          await bagProvider.addClubToBag(selectedBag.id, clubId);
          
          final swappedClub = clubProvider.getClubById(clubId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Swapped to ${swappedClub?.name ?? 'club'}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        itemBuilder: (context) {
          // Show other clubs of same type not in bag
          final availableClubs = sameTypeClubs
              .where((c) => c.id != club.id && !selectedBag.clubIds.contains(c.id))
              .toList();
          
          if (availableClubs.isEmpty) {
            return [
              const PopupMenuItem<String>(
                enabled: false,
                child: Text('No other clubs available'),
              ),
            ];
          }
          
          return availableClubs.map((c) {
            final isDefault = c.brand == 'Standard' && c.name.startsWith('Default');
            return PopupMenuItem<String>(
              value: c.id,
              child: Row(
                children: [
                  Expanded(
                    child: Text(c.displayName),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                    ),
                ],
              ),
            );
          }).toList();
        },
      );
    }
    
    // Regular add/remove button
    return IconButton(
      icon: Icon(
        isInBag ? Icons.remove_circle : Icons.add_circle,
        color: isInBag ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      onPressed: () async {
        if (isInBag) {
          await bagProvider.removeClubFromBag(selectedBag.id, club.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${club.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          // Check if there's already a club of this type in the bag
          final existingClubOfType = sameTypeInBag.firstOrNull;
          if (existingClubOfType != null) {
            // Show dialog to swap or add
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('${Club.getClubTypeDisplayName(club.type)} Already in Bag'),
                content: Text(
                  'You already have "${existingClubOfType.name}" in this bag. '
                  'Would you like to swap it with "${club.name}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Add Both'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Swap'),
                  ),
                ],
              ),
            );
            
            if (result == null) return; // Cancelled
            
            if (result) {
              // Swap
              await bagProvider.removeClubFromBag(selectedBag.id, existingClubOfType.id);
            }
          }
          
          await bagProvider.addClubToBag(selectedBag.id, club.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${club.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
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

  void _showAddBagDialog() {
    showDialog(
      context: context,
      builder: (context) => const BagFormDialog(),
    ).then((_) {
      // Select the newly created bag if any
      final bagProvider = Provider.of<BagProvider>(context, listen: false);
      if (bagProvider.bags.isNotEmpty && _selectedBagId == null) {
        setState(() {
          _selectedBagId = bagProvider.bags.last.id;
        });
      }
    });
  }

  void _showAddClubDialog() {
    showDialog(
      context: context,
      builder: (context) => const ClubFormDialog(),
    );
  }

  void _showClubDetails(Club club) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClubDetailsSheet(club: club),
    );
  }

  void _showClubOptions(Club club) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Club'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => ClubFormDialog(club: club),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Club', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteClub(club);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBagOptions(Bag bag) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Bag'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => BagFormDialog(bag: bag),
                );
              },
            ),
            if (!bag.isDefault)
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Set as Default'),
                onTap: () {
                  Navigator.pop(context);
                  final bagProvider = Provider.of<BagProvider>(context, listen: false);
                  bagProvider.updateBag(bag.copyWith(isDefault: true));
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Bag', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteBag(bag);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteClub(Club club) {
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
              Provider.of<ClubProvider>(context, listen: false).deleteClub(club.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteBag(Bag bag) {
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
              Provider.of<BagProvider>(context, listen: false).deleteBag(bag.id);
              Navigator.pop(context);
              
              // Select another bag if the deleted one was selected
              if (_selectedBagId == bag.id) {
                final bagProvider = Provider.of<BagProvider>(context, listen: false);
                setState(() {
                  _selectedBagId = bagProvider.bags.isNotEmpty 
                      ? bagProvider.bags.first.id 
                      : null;
                });
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Reuse the existing form dialogs from the previous implementation
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
      title: Text(widget.bag == null ? 'Create Custom Bag' : 'Edit Bag'),
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

// Reuse ClubFormDialog and ClubDetailsSheet from clubs_screen.dart
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
      title: Text(widget.club == null ? 'Add Custom Club' : 'Edit Club'),
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