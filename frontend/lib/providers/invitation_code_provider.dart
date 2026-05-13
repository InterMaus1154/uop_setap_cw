import 'package:flutter/foundation.dart';
import '../models/invitation_code.dart';
import '../services/api_service.dart';

class InvitationCodeProvider extends ChangeNotifier {
  final ApiService _apiService;

  // List to store all active invitation codes
  List<InvitationCode> _codes = [];
  bool _isLoading = false;
  String? _errorMessage; // For loadCodes() failures only
  String? _createError; // For createNewCode() failures only (including 429)

  InvitationCodeProvider({required ApiService apiService})
    : _apiService = apiService;

  // Getters - UI reads to know what to display
  List<InvitationCode> get codes => _codes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get createError => _createError;

  /// Fetch all active invitation codes from backend
  /// Called when user opens the invitation codes screen
  Future<void> loadCodes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); 

    try {
      _codes = await _apiService.getInvitationCodes();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();

    }
  }

  /// Create a new invitation code
  /// Adds it to the top of the list if successful
  Future<void> createNewCode() async {
    _isLoading = true;
    _createError = null;
    notifyListeners(); 

    try {
      final newCode = await _apiService.createInvitationCode();
      // Add new code to the front of the list
      _codes.insert(0, newCode);
      _createError = null;
    } on ApiException catch (e) {
      // e.message will contain the 429 message if user hit rate limit
      _createError = e.message;
    } catch (e) {
      _createError = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearCreateError() {
    _createError = null;
    notifyListeners();
  }
}