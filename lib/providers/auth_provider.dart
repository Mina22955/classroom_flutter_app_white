import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _token;
  String? _error;
  String? _pendingId;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  String? get error => _error;
  String? get pendingId => _pendingId;

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      // Check if login was successful based on API response structure
      if (response['accessToken'] != null && response['user'] != null) {
        _token = response['accessToken'];
        _user = response['user'];
        _isAuthenticated = true;

        // Save login data to secure storage
        await _saveLoginData();

        _setLoading(false);
        print(
            'AuthProvider: Login successful, token: ${_token?.substring(0, 10)}...');
        return true;
      } else {
        // Login failed - extract error message
        String errorMessage =
            response['message'] ?? response['error'] ?? 'فشل في تسجيل الدخول';
        print('AuthProvider: Login failed - $errorMessage');
        _setError(errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Legacy signup method (for backward compatibility)
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Use the new pending user flow (with default plan)
      final response = await _apiService.createPendingUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
        planId: '68c480b976422a6a54f3fa72', // Default plan ID
      );

      if (response['pendingId'] != null) {
        _pendingId = response['pendingId'];
        await _secureStorage.write(key: 'pendingId', value: _pendingId!);
        _setLoading(false);
        return true;
      } else {
        String errorMsg = response['message'] ??
            response['error'] ??
            response['msg'] ??
            'فشل في إنشاء الحساب المؤقت';
        _setError(errorMsg);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Create pending user (new signup flow)
  Future<bool> createPendingUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String planId,
    bool manageLoading =
        true, // New parameter to control loading state management
  }) async {
    if (manageLoading) {
      _setLoading(true);
    }
    _clearError();

    try {
      print('AuthProvider: Creating pending user...');
      final response = await _apiService.createPendingUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
        planId: planId,
      );

      print('AuthProvider: Response received: $response');
      print('AuthProvider: Response type: ${response.runtimeType}');
      print(
          'AuthProvider: Has pendingId: ${response.containsKey('pendingId')}');
      print('AuthProvider: PendingId value: ${response['pendingId']}');

      if (response['pendingId'] != null) {
        _pendingId = response['pendingId'];
        await _secureStorage.write(key: 'pendingId', value: _pendingId!);
        print('AuthProvider: Pending ID stored: $_pendingId');
        if (manageLoading) {
          _setLoading(false);
        }
        return true;
      } else {
        // If no pendingId in response, check for error message
        String errorMsg = response['message'] ??
            response['error'] ??
            response['msg'] ??
            'فشل في إنشاء الحساب المؤقت';
        print('AuthProvider: No pendingId found, error message: $errorMsg');
        print(
            'AuthProvider: Available keys in response: ${response.keys.toList()}');
        _setError(errorMsg);
        if (manageLoading) {
          _setLoading(false);
        }
        return false;
      }
    } catch (e) {
      print('AuthProvider: Exception caught - $e');
      print('AuthProvider: Exception type - ${e.runtimeType}');
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      print('AuthProvider: Final error message - $errorMessage');
      _setError(errorMessage);
      if (manageLoading) {
        _setLoading(false);
      }
      return false;
    }
  }

  // Get plans
  Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final plans = await _apiService.getPlans();
      return plans.cast<Map<String, dynamic>>();
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      return [];
    }
  }

  // Create checkout session
  Future<String?> createCheckoutSession(String planId) async {
    if (_pendingId == null) {
      _setError('معرف المستخدم المؤقت غير موجود');
      return null;
    }

    try {
      return await _apiService.createCheckoutSession(
        pendingId: _pendingId!,
        planId: planId,
      );
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      return null;
    }
  }

  // Check signup status
  Future<bool> checkSignupStatus() async {
    if (_pendingId == null) {
      _setError('معرف المستخدم المؤقت غير موجود');
      return false;
    }

    try {
      final response = await _apiService.checkSignupStatus(_pendingId!);
      if (response != null && response['activated'] == true) {
        // User is activated, clear pending ID and redirect to login
        await _secureStorage.delete(key: 'pendingId');
        _pendingId = null;
        return true;
      }
      return false;
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      return false;
    }
  }

  // Load pending ID from storage
  Future<void> loadPendingId() async {
    _pendingId = await _secureStorage.read(key: 'pendingId');
    notifyListeners();
  }

  // Request Password Reset
  Future<bool> requestPasswordReset({
    required String email,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.requestPasswordReset(email: email);

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'فشل في إرسال رمز التحقق');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.verifyOtp(
        email: email,
        otp: otp,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'رمز التحقق غير صحيح');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'فشل في تغيير كلمة المرور');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Update Profile (mock local update)
  Future<void> updateProfile({
    String? name,
    String? phone,
  }) async {
    // In real app, call _apiService.updateProfile and await response
    _user = {
      ...?_user,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    };
    notifyListeners();
  }

  // Save login data to secure storage
  Future<void> _saveLoginData() async {
    if (_token != null && _user != null) {
      await _secureStorage.write(key: 'auth_token', value: _token!);
      await _secureStorage.write(key: 'user_data', value: jsonEncode(_user!));
      await _secureStorage.write(key: 'is_authenticated', value: 'true');
      print('AuthProvider: Login data saved to secure storage');
    }
  }

  // Load login data from secure storage
  Future<void> loadStoredLoginData() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final userDataString = await _secureStorage.read(key: 'user_data');
      final isAuthenticatedString =
          await _secureStorage.read(key: 'is_authenticated');

      if (token != null &&
          userDataString != null &&
          isAuthenticatedString == 'true') {
        _token = token;
        _user = jsonDecode(userDataString);
        _isAuthenticated = true;
        print('AuthProvider: Login data loaded from secure storage');
        notifyListeners();
      }
    } catch (e) {
      print('AuthProvider: Error loading stored login data: $e');
      // Clear invalid data
      await _clearStoredLoginData();
    }
  }

  // Clear stored login data
  Future<void> _clearStoredLoginData() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_data');
    await _secureStorage.delete(key: 'is_authenticated');
    print('AuthProvider: Stored login data cleared');
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _apiService.logout();
    } catch (e) {
      // Ignore logout errors
    }

    // Clear stored login data
    await _clearStoredLoginData();

    _token = null;
    _user = null;
    _isAuthenticated = false;
    _clearError();
    _setLoading(false);
  }

  // Public method to set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
