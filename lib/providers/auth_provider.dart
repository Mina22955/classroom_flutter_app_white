import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
  String? _deviceToken;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  String? get error => _error;
  String? get pendingId => _pendingId;
  String? get deviceToken => _deviceToken;

  // Generate unique device token
  Future<String> _generateDeviceToken() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      try {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = '${androidInfo.model}_${androidInfo.id}';
      } catch (e) {
        try {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = '${iosInfo.model}_${iosInfo.identifierForVendor}';
        } catch (e) {
          deviceId = 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      // Create a unique token combining device info and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final deviceToken = '${deviceId}_$timestamp';

      print('AuthProvider: Generated device token: $deviceToken');
      return deviceToken;
    } catch (e) {
      print('AuthProvider: Error generating device token: $e');
      // Fallback to timestamp-based token
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Generate device token
      _deviceToken = await _generateDeviceToken();

      final response = await _apiService.login(
        email: email,
        password: password,
        deviceToken: _deviceToken,
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
        // Check for device conflict
        if (response['code'] == 'DEVICE_CONFLICT') {
          _setError('DEVICE_CONFLICT');
          _setLoading(false);
          return false;
        }

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

  // Get student's joined classes
  Future<List<Map<String, dynamic>>> getStudentClasses() async {
    if (_user == null) {
      print('AuthProvider: User is null, cannot fetch classes');
      _setError('يرجى تسجيل الدخول أولاً');
      return [];
    }

    try {
      final rawUserId = _user!['id'] ?? _user!['_id'] ?? _user!['userId'];
      print('AuthProvider: User data: $_user');
      print('AuthProvider: Extracted user ID: $rawUserId');
      print('AuthProvider: Token: ${_token?.substring(0, 10)}...');

      if (rawUserId == null) {
        print('AuthProvider: No user ID found in user data');
        _setError('معرف الطالب غير متوفر');
        return [];
      }

      print(
          'AuthProvider: Calling API to fetch classes for student: $rawUserId');
      final classes = await _apiService.getStudentClasses(
        studentId: rawUserId.toString(),
        accessToken: _token,
      );
      print('AuthProvider: Received classes: $classes');
      return classes;
    } catch (e) {
      print('AuthProvider: Error fetching classes: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _setError(errorMessage);
      return [];
    }
  }

  // Join class by id/code
  Future<Map<String, dynamic>?> joinClassById(String classId) async {
    if (_user == null) {
      _setError('يرجى تسجيل الدخول أولاً');
      return null;
    }

    try {
      final rawUserId = _user!['id'] ?? _user!['_id'] ?? _user!['userId'];
      if (rawUserId == null) {
        _setError('معرف الطالب غير متوفر');
        return null;
      }
      final response = await _apiService.joinClass(
        classId: classId,
        studentId: rawUserId.toString(),
        accessToken: _token,
      );
      return response;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _setError(errorMessage);
      return null;
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
        print('AuthProvider: Token: ${token.substring(0, 10)}...');
        print('AuthProvider: User: ${_user?['name'] ?? 'Unknown'}');
        notifyListeners();
      } else {
        print('AuthProvider: No valid stored login data found');
      }
    } catch (e) {
      print('AuthProvider: Error loading stored login data: $e');
      // Clear invalid data
      await _clearStoredLoginData();
    }
  }

  // Validate current session and clear if invalid
  Future<bool> validateSession() async {
    if (!_isAuthenticated || _token == null || _user == null) {
      print('AuthProvider: No active session to validate');
      return false;
    }

    try {
      // Try to fetch user classes to validate the session
      final classes = await getStudentClasses();
      print(
          'AuthProvider: Session validation successful, found ${classes.length} classes');
      return true;
    } catch (e) {
      print('AuthProvider: Session validation failed: $e');
      // Clear invalid session
      await forceClearAuthState();
      return false;
    }
  }

  // Clear stored login data
  Future<void> _clearStoredLoginData() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_data');
    await _secureStorage.delete(key: 'is_authenticated');
    print('AuthProvider: Stored login data cleared');
  }

  // Force clear all authentication state (for debugging or force logout)
  Future<void> forceClearAuthState() async {
    print('AuthProvider: Force clearing all authentication state...');

    // Clear stored data
    await _clearStoredLoginData();

    // Clear memory state
    _token = null;
    _user = null;
    _deviceToken = null;
    _isAuthenticated = false;
    _error = null;
    _pendingId = null;

    // Notify listeners
    notifyListeners();

    print('AuthProvider: All authentication state cleared');
  }

  // Quick logout - just clear local state without server call
  Future<Map<String, dynamic>> quickLogout() async {
    print('AuthProvider: Performing quick logout (local only)...');

    try {
      // Clear loading state first
      _setLoading(false);

      // Clear all authentication state
      _token = null;
      _user = null;
      _deviceToken = null;
      _isAuthenticated = false;
      _error = null;
      _pendingId = null;

      // Clear stored data
      await _clearStoredLoginData();

      // Notify listeners immediately
      notifyListeners();

      print('AuthProvider: Quick logout completed successfully');

      return {
        'success': true,
        'message': 'تم تسجيل الخروج محلياً',
        'serverLogoutSuccess': false,
      };
    } catch (e) {
      print('AuthProvider: Quick logout error: $e');

      // Even if there's an error, clear the state
      _token = null;
      _user = null;
      _deviceToken = null;
      _isAuthenticated = false;
      _error = null;
      _pendingId = null;
      _setLoading(false);
      notifyListeners();

      return {
        'success': true,
        'message': 'تم تسجيل الخروج محلياً',
        'serverLogoutSuccess': false,
      };
    }
  }

  // Force login (for device conflict resolution)
  Future<bool> forceLogin({
    required String email,
    required String password,
    required String userId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // First, force logout from other device
      await _apiService.forceLogout(userId: userId);

      // Generate new device token
      _deviceToken = await _generateDeviceToken();

      // Try login again
      final response = await _apiService.login(
        email: email,
        password: password,
        deviceToken: _deviceToken,
      );

      if (response['accessToken'] != null && response['user'] != null) {
        _token = response['accessToken'];
        _user = response['user'];
        _isAuthenticated = true;

        // Save login data to secure storage
        await _saveLoginData();

        _setLoading(false);
        print('AuthProvider: Force login successful');
        return true;
      } else {
        String errorMessage =
            response['message'] ?? response['error'] ?? 'فشل في تسجيل الدخول';
        _setError(errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    _setLoading(true);
    _clearError();

    try {
      bool serverLogoutSuccess = false;
      String logoutMessage = 'تم تسجيل الخروج بنجاح';

      // Attempt server logout if we have user data
      if (_user != null && _deviceToken != null) {
        try {
          print('AuthProvider: Attempting server logout...');
          print('AuthProvider: User ID: ${_user!['id'] ?? _user!['_id']}');
          print(
              'AuthProvider: Device Token: ${_deviceToken!.substring(0, 10)}...');

          final logoutResult = await _apiService
              .logout(
            userId: _user!['id'] ?? _user!['_id'],
            deviceToken: _deviceToken!,
          )
              .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              print('AuthProvider: Server logout timeout after 3 seconds');
              return {
                'success': false,
                'message': 'انتهت مهلة تسجيل الخروج من الخادم',
              };
            },
          );

          print('AuthProvider: Server logout result: $logoutResult');

          if (logoutResult['success'] == true) {
            serverLogoutSuccess = true;
            logoutMessage =
                logoutResult['message'] ?? 'تم تسجيل الخروج من الخادم بنجاح';
            print('AuthProvider: Server logout successful');
          } else {
            logoutMessage =
                logoutResult['message'] ?? 'تم تسجيل الخروج محلياً فقط';
            print(
                'AuthProvider: Server logout failed: ${logoutResult['message']}');
          }
        } catch (e) {
          print('AuthProvider: Server logout error: $e');
          logoutMessage = 'تم تسجيل الخروج محلياً (خطأ في الخادم)';
        }
      } else {
        print('AuthProvider: No user data or device token, local logout only');
        print('AuthProvider: User: $_user');
        print('AuthProvider: Device Token: $_deviceToken');
        logoutMessage = 'تم تسجيل الخروج محلياً';
      }

      // Always clear local data regardless of server response
      print('AuthProvider: Clearing local data...');
      await forceClearAuthState();
      _setLoading(false);

      print(
          'AuthProvider: Authentication state cleared, notifying listeners...');

      return {
        'success': true,
        'message': logoutMessage,
        'serverLogoutSuccess': serverLogoutSuccess,
      };
    } catch (e) {
      print('AuthProvider: Logout error: $e');

      // Even if there's an error, clear local data
      await forceClearAuthState();
      _setLoading(false);

      return {
        'success': false,
        'message': 'حدث خطأ أثناء تسجيل الخروج',
        'error': e.toString(),
      };
    }
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
