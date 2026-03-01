      Future<void> _saveDisplayNamePreference(bool useDisplayName) async {
        setState(() => _isLoading = true);
        try {
          await _apiService.updateUserDisplayNamePreference(useDisplayName);
          await context.read<UserProvider>().login(user?.email ?? '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Display name preference updated')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update preference: $e')),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      }
    bool _showDisplayName = false;
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateUserProfile(
        fname: _fnameController.text,
        lname: _lnameController.text,
        displayName: _displayNameController.text.isEmpty ? null : _displayNameController.text,
      );
      // Optionally refresh user data in provider
      await context.read<UserProvider>().login(user?.email ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'friends_screen.dart';
import 'user_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  int? _pinCount;
  bool _isLoading = true;

  late TextEditingController _fnameController;
  late TextEditingController _lnameController;
  late TextEditingController _displayNameController;
  final bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadPinCount();
    final user = context.read<UserProvider>().currentUser;
    _fnameController = TextEditingController(text: user?.firstName ?? '');
    _lnameController = TextEditingController(text: user?.lastName ?? '');
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
  }

  Future<void> _loadPinCount() async {
    try {
      final count = await _apiService.getMyPinCount();
      if (mounted) {
        setState(() {
          _pinCount = count;
          _isLoading = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    context.read<FriendProvider>().clear();
    await context.read<UserProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final initials = _getInitials(user?.firstName ?? '', user?.lastName ?? '');
    _showDisplayName = user?.useDisplayName ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blue[400],
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Show display name under pins'),
                    Switch(
                      value: _showDisplayName,
                      onChanged: (val) async {
                        setState(() {
                          _showDisplayName = val;
                        });
                        await _saveDisplayNamePreference(val);
                      },
                    ),
                  ],
                ),
                TextField(
                  controller: _fnameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  enabled: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _lnameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  enabled: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name (optional)',
                    border: OutlineInputBorder(),
                  ),
                  enabled: true,
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 32),
                _buildStatCard(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FriendsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('Friends'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.push_pin_outlined, size: 32, color: Colors.blue[400]),
          const SizedBox(height: 8),
          _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  '${_pinCount ?? 0}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            'Pins Created',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getInitials(String first, String last) {
    final f = first.isNotEmpty ? first[0] : '?';
    final l = last.isNotEmpty ? last[0] : '?';
    return '$f$l'.toUpperCase();
  }
}
