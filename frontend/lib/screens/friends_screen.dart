import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/friend_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FriendProvider>();
      provider.loadFriends();
      provider.loadIncomingRequests();
      provider.loadOutgoingRequests();
      // Load location permissions so the share toggles show correct state
      context.read<LocationProvider>().refreshPermissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),

        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue[400],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue[400],
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              'Add Friend',
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              final currentUserId =
                  context.read<UserProvider>().currentUser?.userId ?? 0;
              showSearch(
                context: context,
                delegate: UserSearchDelegate(
                  context.read<FriendProvider>(),
                  currentUserId: currentUserId,
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FriendsListTab(),
          _IncomingRequestsTab(),
          _OutgoingRequestsTab(),
        ],
      ),
    );
  }
}

// --- Friends List Tab ---

class _FriendsListTab extends StatelessWidget {
  const _FriendsListTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    // Watch location provider so toggles update when permissions change
    final locationProvider = context.watch<LocationProvider>();

    if (provider.friendsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.friendsError != null) {
      return _ErrorRetry(
        message: provider.friendsError!,
        onRetry: () => context.read<FriendProvider>().loadFriends(),
      );
    }
    if (provider.friends.isEmpty) {
      return const Center(
        child: Text('No friends yet', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: provider.friends.length,
      itemBuilder: (context, index) {
        final friend = provider.friends[index];
        // Check if we're currently sharing location with this friend
        final isSharing = locationProvider.permissions.any(
          (p) => p.userId == friend.userId,
        );
        final sharingExpiry =
            locationProvider.permissionExpiryFor(friend.userId) ??
            locationProvider.myLocation?.sharingExpiresAt;
        return _UserTile(
          user: friend,
          isSharingLocation: isSharing,
          sharingExpiry: sharingExpiry,
          onToggleSharing: (value) async {
            if (value) {
              final expiry = await _showLocationFilterDialog(
                context,
                locationProvider,
                friend,
              );
              await locationProvider.grantPermission(friend.userId, expiry);
              if (expiry != null) {
                await locationProvider.setSharingExpiry(expiry);
              }
            } else {
              await locationProvider.revokePermission(friend.userId);
            }
            // Show error if the toggle failed
            if (context.mounted && locationProvider.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(locationProvider.error!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }
}

// --- Incoming Requests Tab ---

class _IncomingRequestsTab extends StatelessWidget {
  const _IncomingRequestsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();

    if (provider.incomingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.incomingError != null) {
      return _ErrorRetry(
        message: provider.incomingError!,
        onRetry: () => context.read<FriendProvider>().loadIncomingRequests(),
      );
    }
    if (provider.incomingRequests.isEmpty) {
      return Center(
        child: Text(
          'No pending requests',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
    }
    return ListView.builder(
      itemCount: provider.incomingRequests.length,
      itemBuilder: (context, index) {
        final request = provider.incomingRequests[index];
        final user = provider.userCache[request.userId];
        return _RequestTile(
          name: _displayName(user),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                tooltip: 'Accept',
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                onPressed: () => _handleAction(
                  context,
                  () => context.read<FriendProvider>().acceptRequest(
                    request.userRelId,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Reject',
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                onPressed: () => _handleAction(
                  context,
                  () => context.read<FriendProvider>().rejectRequest(
                    request.userRelId,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.block, color: Colors.grey),
                tooltip: 'Block',
                iconSize: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                onPressed: () => _handleAction(
                  context,
                  () => context.read<FriendProvider>().blockRequest(
                    request.userRelId,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Outgoing Requests Tab ---

class _OutgoingRequestsTab extends StatelessWidget {
  const _OutgoingRequestsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();

    if (provider.outgoingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.outgoingError != null) {
      return _ErrorRetry(
        message: provider.outgoingError!,
        onRetry: () => context.read<FriendProvider>().loadOutgoingRequests(),
      );
    }
    if (provider.outgoingRequests.isEmpty) {
      return Center(
        child: Text(
          'No outgoing requests',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
    }
    return ListView.builder(
      itemCount: provider.outgoingRequests.length,
      itemBuilder: (context, index) {
        final request = provider.outgoingRequests[index];
        final user = provider.userCache[request.targetUserId];
        return _RequestTile(
          name: _displayName(user),
          trailing: TextButton(
            onPressed: () => _handleAction(
              context,
              () => context.read<FriendProvider>().cancelRequest(
                request.userRelId,
              ),
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        );
      },
    );
  }
}

String? selectedOption;
final TextEditingController _customTimeController = TextEditingController();
DateTime? _customDateTime;
Future<DateTime?> _showLocationFilterDialog(
  BuildContext outerContext,
  LocationProvider locationProvider,
  User friend,
) async {
  return showDialog<DateTime?>(
    context: outerContext,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Location filtering',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How long do you want to share your location for',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioGroup<String>(
                        groupValue: selectedOption,
                        onChanged: (String? newValue) {
                          setDialogState(() => selectedOption = newValue);
                        },
                        child: Column(
                          children: [
                            RadioListTile(
                              value: '1hour',
                              title: const Text('1 hour'),
                            ),
                            RadioListTile(
                              value: '2hour',
                              title: const Text('2 hours'),
                            ),
                            RadioListTile(
                              value: '3hour',
                              title: const Text('3 hours'),
                            ),
                            ListTile(
                              leading: Radio<String>(value: 'custom'),
                              title: TextField(
                                controller: _customTimeController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  hintText: 'Select date and time',
                                ),
                                onTap: () async {
                                  final now = DateTime.now();
                                  final initialDateTime =
                                      _customDateTime ??
                                      now.add(const Duration(hours: 1));

                                  final pickedDate = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: initialDateTime,
                                    firstDate: now,
                                    lastDate: DateTime(now.year + 2),
                                  );
                                  if (pickedDate == null) return;

                                  final pickedTime = await showTimePicker(
                                    context: dialogContext,
                                    initialTime: TimeOfDay.fromDateTime(
                                      initialDateTime,
                                    ),
                                  );
                                  if (pickedTime == null) return;

                                  final selectedDateTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );

                                  setDialogState(() {
                                    _customDateTime = selectedDateTime;
                                    _customTimeController.text =
                                        '${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')} '
                                        '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                                    selectedOption = selectedDateTime
                                        .toIso8601String();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, null),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      DateTime? expiry;
                      if (selectedOption == '1hour') {
                        expiry = DateTime.now().add(const Duration(seconds: 5));
                      } else if (selectedOption == '2hour') {
                        expiry = DateTime.now().add(const Duration(hours: 2));
                      } else if (selectedOption == '3hour') {
                        expiry = DateTime.now().add(const Duration(hours: 3));
                      } else if (selectedOption != null) {
                        try {
                          expiry = DateTime.parse(selectedOption!);
                        } catch (_) {
                          expiry = _customDateTime;
                        }
                      }

                      Navigator.of(dialogContext).pop(expiry);
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// --- Shared Widgets ---

class _UserTile extends StatelessWidget {
  final User user;
  final bool isSharingLocation;
  final ValueChanged<bool>? onToggleSharing;

  const _UserTile({
    required this.user,
    this.isSharingLocation = false,
    this.onToggleSharing,
    this.sharingExpiry,
  });

  final DateTime? sharingExpiry;
  @override
  Widget build(BuildContext context) {
    final name = (user.useDisplayName && user.displayName != null)
        ? user.displayName!
        : user.fullName;
    Widget? subtitleWidget;
    if (isSharingLocation && sharingExpiry != null) {
      final expiryLocal = sharingExpiry!.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      final expiryText =
          '${expiryLocal.year}-${two(expiryLocal.month)}-${two(expiryLocal.day)} '
          '${two(expiryLocal.hour)}:${two(expiryLocal.minute)}';
      subtitleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Expires at $expiryText',
            style: TextStyle(color: Colors.green[700], fontSize: 12),
          ),
        ],
      );
    } else {
      subtitleWidget = Text(
        user.email,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[400],
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
      ),
      title: Text(name),
      subtitle: subtitleWidget,
      // Location sharing toggle — lets you choose who can see your location
      trailing: onToggleSharing != null
          ? Tooltip(
              message: isSharingLocation
                  ? 'Stop sharing location with $name'
                  : 'Share location with $name',
              child: Switch(
                value: isSharingLocation,
                activeThumbColor: Colors.teal,
                onChanged: onToggleSharing,
              ),
            )
          : null,
    );
  }
}

class _RequestTile extends StatelessWidget {
  final String name;
  final Widget trailing;
  const _RequestTile({required this.name, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[400],
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
      ),
      title: Text(name),
      trailing: trailing,
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// --- Helpers ---

String _displayName(User? user) {
  if (user == null) return 'Unknown';
  if (user.useDisplayName && user.displayName != null) return user.displayName!;
  return user.fullName;
}

Future<void> _handleAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on Exception catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

// --- UserSearchDelegate ---

class UserSearchDelegate extends SearchDelegate<User?> {
  final FriendProvider friendProvider;
  final ApiService _apiService = ApiService();
  final int _currentUserId;

  UserSearchDelegate(this.friendProvider, {required int currentUserId})
    : _currentUserId = currentUserId;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return const Center(
        child: Text(
          'Type at least 3 characters to search',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.length < 3) {
      return const Center(
        child: Text(
          'Type at least 3 characters to search',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<List<User>>(
      future: _apiService.searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final results = (snapshot.data ?? [])
            .where((u) => u.userId != _currentUserId)
            .toList();
        if (results.isEmpty) {
          return const Center(
            child: Text('No users found', style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index];
            return _SearchResultTile(
              user: user,
              friendProvider: friendProvider,
            );
          },
        );
      },
    );
  }
}

class _SearchResultTile extends StatefulWidget {
  final User user;
  final FriendProvider friendProvider;
  const _SearchResultTile({required this.user, required this.friendProvider});

  @override
  State<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<_SearchResultTile> {
  bool _sent = false;
  String? _message;

  Future<void> _sendRequest() async {
    try {
      await widget.friendProvider.sendRequest(widget.user.userId);
      if (mounted) {
        setState(() {
          _sent = true;
          _message = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _message = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.user.useDisplayName && widget.user.displayName != null)
        ? widget.user.displayName!
        : widget.user.fullName;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[400],
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(name),
      subtitle: _message != null
          ? Text(_message!, style: const TextStyle(color: Colors.orange))
          : Text(widget.user.email, style: TextStyle(color: Colors.grey[600])),
      trailing: _sent
          ? const Icon(Icons.check, color: Colors.green)
          : TextButton(
              onPressed: _sendRequest,
              child: const Text('Add Friend'),
            ),
    );
  }
}
