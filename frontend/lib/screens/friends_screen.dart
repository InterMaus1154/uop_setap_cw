import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/friend_provider.dart';
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
    final provider = context.read<FriendProvider>();
    provider.loadFriends();
    provider.loadIncomingRequests();
    provider.loadOutgoingRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
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
          IconButton(
            icon: const Icon(Icons.search),
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
        return _UserTile(user: friend);
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
      return const Center(
        child: Text(
          'No pending requests',
          style: TextStyle(color: Colors.grey),
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
      return const Center(
        child: Text(
          'No outgoing requests',
          style: TextStyle(color: Colors.grey),
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

// --- Shared Widgets ---

class _UserTile extends StatelessWidget {
  final User user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = (user.useDisplayName && user.displayName != null)
        ? user.displayName!
        : user.fullName;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[400],
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(name),
      subtitle: Text(user.email, style: TextStyle(color: Colors.grey[600])),
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
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
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
