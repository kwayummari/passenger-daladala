import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository repository;

  ProfileProvider({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _currentProfile;
  User? get currentProfile => _currentProfile;

  // Simple getProfile method that just clears loading state
  Future<void> getProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // For now, we'll just clear the loading state
      // since you're getting profile from AuthProvider
      await Future.delayed(const Duration(milliseconds: 100));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update profile method - returns bool for simplicity
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.updateProfile(
        profileData,
        profileImage: null, // Handle image separately if needed
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (user) {
          _currentProfile = user;
          _errorMessage = null;
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
