import 'package:flutter/foundation.dart';
import '../models/friend_request.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class FriendProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Core lists
  List<User> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> _outgoingRequests = [];

  // Name resolution cache
  final Map<int, User> _userCache = {};

  // Per-list loading/error state
  bool _friendsLoading = false;
  bool _incomingLoading = false;
  bool _outgoingLoading = false;
  String? _friendsError;
  String? _incomingError;
  String? _outgoingError;

  // Getters
  List<User> get friends => _friends;
  List<FriendRequest> get incomingRequests => _incomingRequests;
  List<FriendRequest> get outgoingRequests => _outgoingRequests;
  Map<int, User> get userCache => _userCache;

  bool get friendsLoading => _friendsLoading;
  bool get incomingLoading => _incomingLoading;
  bool get outgoingLoading => _outgoingLoading;
  String? get friendsError => _friendsError;
  String? get incomingError => _incomingError;
  String? get outgoingError => _outgoingError;

  // Load methods

  Future<void> loadFriends() async {
    _friendsLoading = true;
    _friendsError = null;
    notifyListeners();
    try {
      _friends = await _apiService.getFriends();
    } on ApiException catch (e) {
      _friendsError = e.message;
    } finally {
      _friendsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadIncomingRequests() async {
    _incomingLoading = true;
    _incomingError = null;
    notifyListeners();
    try {
      _incomingRequests = await _apiService.getIncomingRequests();
      // Resolve names for each requester
      await _resolveUsers(_incomingRequests.map((r) => r.userId).toList());
    } on ApiException catch (e) {
      _incomingError = e.message;
    } finally {
      _incomingLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOutgoingRequests() async {
    _outgoingLoading = true;
    _outgoingError = null;
    notifyListeners();
    try {
      _outgoingRequests = await _apiService.getSentRequests();
      // Resolve names for each target user
      await _resolveUsers(
        _outgoingRequests.map((r) => r.targetUserId).toList(),
      );
    } on ApiException catch (e) {
      _outgoingError = e.message;
    } finally {
      _outgoingLoading = false;
      notifyListeners();
    }
  }

  // Name resolution

  Future<void> _resolveUsers(List<int> userIds) async {
    final unresolved = userIds
        .where((id) => !_userCache.containsKey(id))
        .toList();
    if (unresolved.isEmpty) return;
    await Future.wait(unresolved.map((id) => resolveUser(id)));
  }

  Future<User> resolveUser(int userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId]!;
    try {
      final user = await _apiService.getUserById(userId);
      _userCache[userId] = user;
      return user;
    } catch (_) {
      // Fallback so we don't retry failed lookups
      final fallback = User(
        userId: userId,
        firstName: 'User',
        lastName: '#$userId',
        email: '',
        useDisplayName: false,
      );
      _userCache[userId] = fallback;
      return fallback;
    }
  }

  // Action methods

  Future<void> sendRequest(int targetUserId) async {
    await _apiService.sendFriendRequest(targetUserId);
    await loadOutgoingRequests();
  }

  Future<void> acceptRequest(int relId) async {
    await _apiService.updateFriendRequest(relId, 'accepted');
    await loadFriends();
    await loadIncomingRequests();
  }

  Future<void> rejectRequest(int relId) async {
    await _apiService.updateFriendRequest(relId, 'rejected');
    await loadIncomingRequests();
  }

  Future<void> blockRequest(int relId) async {
    await _apiService.updateFriendRequest(relId, 'blocked');
    await loadIncomingRequests();
  }

  Future<void> cancelRequest(int relId) async {
    await _apiService.deleteFriendRequest(relId);
    await loadOutgoingRequests();
  }

  // Clear all state (on logout)

  void clear() {
    _friends = [];
    _incomingRequests = [];
    _outgoingRequests = [];
    _userCache.clear();
    _friendsLoading = false;
    _incomingLoading = false;
    _outgoingLoading = false;
    _friendsError = null;
    _incomingError = null;
    _outgoingError = null;
    notifyListeners();
  }
}
