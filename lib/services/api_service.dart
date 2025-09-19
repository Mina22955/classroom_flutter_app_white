import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'https://class-room-backend-nodejs.vercel.app';

  // Mock delay to simulate network requests
  Future<void> _mockDelay() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  // Get class files
  Future<List<Map<String, dynamic>>> getClassFiles({
    required String classId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/class/$classId/Allfiles');
      final headers = {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      print('Making API call to: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for class files: $data');

        // Handle the response format: {"files": [...]}
        if (data is Map<String, dynamic>) {
          if (data.containsKey('files')) {
            final files = data['files'] as List<dynamic>;
            print('Extracted files from response: $files');

            // Validate and enhance file data
            final processedFiles = files.map((file) {
              final fileMap = file as Map<String, dynamic>;

              // Check if URL is expired
              final expiresAt = fileMap['expiresAt'];
              final isExpired = expiresAt != null &&
                  DateTime.now().millisecondsSinceEpoch > (expiresAt * 1000);

              return {
                ...fileMap,
                'isExpired': isExpired,
                'expiresAtFormatted': expiresAt != null
                    ? DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
                        .toIso8601String()
                    : null,
              };
            }).toList();

            return processedFiles.cast<Map<String, dynamic>>();
          } else if (data.containsKey('data') && data['data'] is List) {
            final files = data['data'] as List<dynamic>;
            print('Extracted files from data field: $files');
            return files.cast<Map<String, dynamic>>();
          } else {
            print('No files array found in response object');
            print('Available keys: ${data.keys.toList()}');
            return [];
          }
        } else if (data is List) {
          print('Response is direct list: $data');
          return data.cast<Map<String, dynamic>>();
        }
        print('Unexpected response format');
        return [];
      } else if (response.statusCode == 404) {
        print('Class not found: ${response.body}');
        return [];
      } else {
        print(
            'Error fetching class files: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception fetching class files: $e');
      return [];
    }
  }

  // Get class notes
  Future<List<Map<String, dynamic>>> getClassNotes({
    required String classId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/classes/$classId/notes');
      final headers = {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      print('Making API call to: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for class notes: $data');

        // Try different possible response formats
        if (data is Map<String, dynamic>) {
          if (data.containsKey('notes')) {
            final notes = data['notes'] as List<dynamic>;
            print('Extracted notes from response: $notes');
            return notes.cast<Map<String, dynamic>>();
          } else if (data.containsKey('data') && data['data'] is List) {
            final notes = data['data'] as List<dynamic>;
            print('Extracted notes from data field: $notes');
            return notes.cast<Map<String, dynamic>>();
          } else {
            print('No notes array found in response object');
            print('Available keys: ${data.keys.toList()}');
            return [];
          }
        } else if (data is List) {
          print('Response is direct list: $data');
          return data.cast<Map<String, dynamic>>();
        }
        print('Unexpected response format');
        return [];
      } else {
        print(
            'Error fetching class notes: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception fetching class notes: $e');
      return [];
    }
  }

  // Get student's joined classes
  Future<List<Map<String, dynamic>>> getStudentClasses({
    required String studentId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/$studentId/classes');
      final headers = {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for student classes: $data');
        if (data is Map<String, dynamic> && data.containsKey('classes')) {
          final classes = data['classes'] as List<dynamic>;
          print('Extracted classes from response: $classes');
          return classes.cast<Map<String, dynamic>>();
        } else if (data is List) {
          print('Response is direct list: $data');
          return data.cast<Map<String, dynamic>>();
        }
        print('No classes found in response');
        return [];
      } else {
        print(
            'Error fetching student classes: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception fetching student classes: $e');
      return [];
    }
  }

  // Join class by code/id
  Future<Map<String, dynamic>> joinClass({
    required String classId,
    required String studentId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/join-class');
      final headers = {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'classId': classId, 'studentId': studentId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Normalize response to a common shape
        final joinedClass = (data is Map<String, dynamic>)
            ? (data['class'] ?? data['data'] ?? data['classObj'] ?? data)
            : data;
        return {
          'success': true,
          'message': (data is Map<String, dynamic>)
              ? (data['message'] ?? 'تم الانضمام إلى الكلاس بنجاح')
              : 'تم الانضمام إلى الكلاس بنجاح',
          'class': joinedClass,
        };
      } else {
        // Try to extract error from JSON body
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = (errorData is Map<String, dynamic>)
              ? (errorData['message'] ??
                  errorData['error'] ??
                  errorData['msg'] ??
                  'فشل في الانضمام إلى الكلاس')
              : 'فشل في الانضمام إلى الكلاس';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('فشل في الانضمام إلى الكلاس');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Authentication Methods
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceToken': deviceToken,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Try to extract error message from response
      try {
        final errorData = jsonDecode(response.body);
        print('API Service: Login error data: $errorData');

        if (errorData is Map<String, dynamic>) {
          String errorMessage = errorData['message'] ??
              errorData['error'] ??
              errorData['msg'] ??
              'فشل في تسجيل الدخول';

          print('API Service: Extracted login error message: $errorMessage');

          // Clean up the error message if it contains JSON
          if (errorMessage.contains('{') && errorMessage.contains('}')) {
            try {
              final nestedError = jsonDecode(errorMessage);
              if (nestedError is Map<String, dynamic> &&
                  nestedError.containsKey('message')) {
                errorMessage = nestedError['message'];
              }
            } catch (e) {
              errorMessage = 'بيانات تسجيل الدخول غير صحيحة';
            }
          }

          // Translate common login error messages
          if (errorMessage.toLowerCase().contains('invalid credentials') ||
              errorMessage.toLowerCase().contains('wrong password') ||
              errorMessage.toLowerCase().contains('incorrect password')) {
            errorMessage = 'بيانات تسجيل الدخول غير صحيحة';
          } else if (errorMessage.toLowerCase().contains('user not found') ||
              errorMessage.toLowerCase().contains('email not found')) {
            errorMessage = 'المستخدم غير موجود';
          } else if (errorMessage.toLowerCase().contains('login error')) {
            errorMessage = 'خطأ في تسجيل الدخول';
          }

          print('API Service: Final login error message: $errorMessage');
          throw Exception(errorMessage);
        } else {
          throw Exception('فشل في تسجيل الدخول');
        }
      } catch (jsonError) {
        print('API Service: Login JSON parsing error: $jsonError');
        // If JSON parsing fails, provide user-friendly messages based on status code
        if (response.statusCode == 401) {
          throw Exception('بيانات تسجيل الدخول غير صحيحة');
        } else if (response.statusCode == 404) {
          throw Exception('المستخدم غير موجود');
        } else if (response.statusCode == 500) {
          throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
        } else {
          throw Exception('فشل في تسجيل الدخول');
        }
      }
    }
  }

  // Create pending user (new signup flow)
  Future<Map<String, dynamic>> createPendingUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String planId,
  }) async {
    try {
      print('Creating pending user with email: $email');
      print('API URL: $baseUrl/api/auth/pending');

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/pending'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'planId': planId,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Success response data: $responseData');

        // Check if the response actually contains a pendingId
        if (responseData['pendingId'] != null) {
          print(
              'API Service: Success - pendingId found: ${responseData['pendingId']}');
          return responseData; // contains pendingId
        } else {
          // API returned success but no pendingId - this is an error
          print('API Service: Success response but no pendingId found');
          print('API Service: Response keys: ${responseData.keys.toList()}');
          print('API Service: Full response: $responseData');

          String errorMessage = responseData['message'] ??
              responseData['error'] ??
              responseData['msg'] ??
              responseData['errorMessage'] ??
              responseData['details'] ??
              'فشل في إنشاء الحساب المؤقت';

          // Check for specific error patterns that indicate email already exists
          String responseBody = response.body.toLowerCase();
          if (responseBody.contains('email') &&
              (responseBody.contains('already') ||
                  responseBody.contains('exists') ||
                  responseBody.contains('registered') ||
                  responseBody.contains('duplicate'))) {
            errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
            print(
                'API Service: Detected email already exists error from response body');
          } else if (errorMessage.toLowerCase().contains('email') &&
              (errorMessage.toLowerCase().contains('already') ||
                  errorMessage.toLowerCase().contains('exists') ||
                  errorMessage.toLowerCase().contains('registered') ||
                  errorMessage.toLowerCase().contains('duplicate'))) {
            errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
            print(
                'API Service: Detected email already exists in error message');
          }

          print(
              'API Service: 201 response but no pendingId, final error: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        print(
            'Error creating pending user: ${response.statusCode} - ${response.body}');

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          print('API Service: Parsed error data: $errorData');

          if (errorData is Map<String, dynamic>) {
            // Check for different possible error message fields
            String errorMessage = errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                'فشل في إنشاء الحساب المؤقت';

            print('API Service: Extracted error message: $errorMessage');

            // Clean up the error message if it contains JSON
            if (errorMessage.contains('{') && errorMessage.contains('}')) {
              try {
                final nestedError = jsonDecode(errorMessage);
                if (nestedError is Map<String, dynamic> &&
                    nestedError.containsKey('message')) {
                  errorMessage = nestedError['message'];
                }
              } catch (e) {
                // If nested JSON parsing fails, use a generic message
                errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
              }
            }

            // Translate common English error messages to Arabic
            if (errorMessage
                .toLowerCase()
                .contains('error fetching pending payment')) {
              errorMessage = 'خطأ في جلب بيانات الدفع المؤقت';
            } else if (errorMessage.toLowerCase().contains('email already') ||
                errorMessage.toLowerCase().contains('email exists') ||
                errorMessage.toLowerCase().contains('email registered') ||
                errorMessage.toLowerCase().contains('duplicate email')) {
              errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
            } else if (errorMessage.toLowerCase().contains('server error')) {
              errorMessage = 'خطأ في الخادم، يرجى المحاولة لاحقاً';
            }

            // Also check the raw response body for email-related errors
            String responseBody = response.body.toLowerCase();
            if (responseBody.contains('email') &&
                (responseBody.contains('already') ||
                    responseBody.contains('exists') ||
                    responseBody.contains('registered') ||
                    responseBody.contains('duplicate'))) {
              errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
              print(
                  'API Service: Detected email already exists error from raw response body');
            }

            print('API Service: Final error message: $errorMessage');
            throw Exception(errorMessage);
          } else {
            throw Exception('فشل في إنشاء الحساب المؤقت');
          }
        } catch (jsonError) {
          print('API Service: JSON parsing error: $jsonError');
          // If JSON parsing fails, check response body for email errors
          String responseBody = response.body.toLowerCase();
          if (responseBody.contains('email') &&
              (responseBody.contains('already') ||
                  responseBody.contains('exists') ||
                  responseBody.contains('registered') ||
                  responseBody.contains('duplicate'))) {
            throw Exception('البريد الإلكتروني مسجل مسبقاً');
          } else if (response.statusCode == 400) {
            throw Exception('البريد الإلكتروني مسجل مسبقاً');
          } else if (response.statusCode == 500) {
            throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
          } else {
            throw Exception('فشل في إنشاء الحساب المؤقت');
          }
        }
      }
    } catch (e) {
      print('Exception creating pending user: $e');
      rethrow; // Re-throw to let AuthProvider handle the error message
    }
  }

  // Get available plans
  Future<List<dynamic>> getPlans() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/plans'));
      print('Plans API Response Status: ${response.statusCode}');
      print('Plans API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The API returns { "plans": [...] }, so we need to extract the plans array
        if (data is Map<String, dynamic> && data.containsKey('plans')) {
          return data['plans'] as List<dynamic>;
        } else if (data is List) {
          return data;
        }
      }
      print('Error: Invalid response format or status code');
      return [];
    } catch (e) {
      print('Error fetching plans: $e');
      return [];
    }
  }

  // Create Stripe checkout session
  Future<String?> createCheckoutSession({
    required String pendingId,
    required String planId,
  }) async {
    try {
      print(
          'Creating checkout session with pendingId: $pendingId, planId: $planId');
      // NOTE: Backend route per documentation is /api/payment/checkout
      // If your backend uses a different path, adjust here accordingly.
      print('API URL: $baseUrl/api/payment/checkout');

      http.Response response = await http.post(
        Uri.parse('$baseUrl/api/payment/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pendingId': pendingId, 'planId': planId}),
      );

      print('Checkout session response status: ${response.statusCode}');
      print('Checkout session response body: ${response.body}');

      // Fallback to the older endpoint if needed
      if (response.statusCode == 404 || response.statusCode == 405) {
        print('Primary checkout endpoint not found; trying legacy endpoint');
        response = await http.post(
          Uri.parse('$baseUrl/api/payment/create-checkout-session'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'pendingId': pendingId, 'planId': planId}),
        );
        print('Legacy endpoint status: ${response.statusCode}');
        print('Legacy endpoint body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final possibleUrl =
              data['url'] ?? data['checkoutUrl'] ?? data['paymentUrl'];
          if (possibleUrl is String && possibleUrl.isNotEmpty) {
            return possibleUrl;
          }
          if (data.containsKey('data') &&
              data['data'] is Map<String, dynamic>) {
            final inner = data['data'] as Map<String, dynamic>;
            final innerUrl =
                inner['url'] ?? inner['checkoutUrl'] ?? inner['paymentUrl'];
            if (innerUrl is String && innerUrl.isNotEmpty) return innerUrl;
          }
        }
        throw Exception('رابط الدفع غير موجود في استجابة الخادم');
      } else {
        print(
            'Error creating checkout session: ${response.statusCode} - ${response.body}');

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('message')) {
            throw Exception(errorData['message']);
          } else {
            throw Exception('فشل في إنشاء جلسة الدفع');
          }
        } catch (jsonError) {
          // If JSON parsing fails, throw with response body
          throw Exception('فشل في إنشاء جلسة الدفع: ${response.body}');
        }
      }
    } catch (e) {
      print('Exception creating checkout session: $e');
      rethrow; // Re-throw to let AuthProvider handle the error message
    }
  }

  // Check signup status
  Future<Map<String, dynamic>?> checkSignupStatus(String pendingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/status/$pendingId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error: ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      print('Requesting password reset for email: $email');
      print('API URL: $baseUrl/api/auth/forgot-password');

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Password reset response status: ${response.statusCode}');
      print('Password reset response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ??
              'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
        };
      } else {
        print(
            'Error requesting password reset: ${response.statusCode} - ${response.body}');

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            String errorMessage = errorData['message'] ??
                errorData['error'] ??
                'فشل في إرسال رمز التحقق';

            // Handle specific error cases
            if (response.statusCode == 500) {
              errorMessage = 'خطأ في الخادم، يرجى المحاولة لاحقاً';
            } else if (response.statusCode == 404) {
              errorMessage = 'البريد الإلكتروني غير مسجل';
            } else if (response.statusCode == 400) {
              errorMessage = 'البريد الإلكتروني غير صحيح';
            }

            print('API Service: Password reset error message: $errorMessage');
            throw Exception(errorMessage);
          } else {
            throw Exception('فشل في إرسال رمز التحقق');
          }
        } catch (jsonError) {
          print('API Service: Password reset JSON parsing error: $jsonError');
          // If JSON parsing fails, provide user-friendly messages based on status code
          if (response.statusCode == 500) {
            throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
          } else if (response.statusCode == 404) {
            throw Exception('البريد الإلكتروني غير مسجل');
          } else if (response.statusCode == 400) {
            throw Exception('البريد الإلكتروني غير صحيح');
          } else {
            throw Exception('فشل في إرسال رمز التحقق');
          }
        }
      }
    } catch (e) {
      print('Exception requesting password reset: $e');
      rethrow; // Re-throw to let AuthProvider handle the error message
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await _mockDelay();

    if (otp.isEmpty || otp.length != 6) {
      throw Exception('رمز التحقق غير صحيح');
    }

    // Mock OTP verification (accepts 123456)
    if (otp != '123456') {
      throw Exception('رمز التحقق غير صحيح');
    }

    return {
      'success': true,
      'message': 'تم التحقق من الرمز بنجاح',
    };
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _mockDelay();

    if (newPassword.length < 6) {
      throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }

    // Mock password reset
    return {
      'success': true,
      'message': 'تم تغيير كلمة المرور بنجاح',
    };
  }

  // Legacy getPlans method (keeping for backward compatibility)
  Future<List<Map<String, dynamic>>> getPlansLegacy() async {
    await _mockDelay();

    return [
      {
        'id': '1',
        'name': 'الخطة الشهرية',
        'price': 29.99,
        'currency': 'SAR',
        'duration': 'شهر',
        'features': [
          'وصول كامل للمحتوى',
          'دعم فني 24/7',
          'تحديثات مستمرة',
          'إشعارات فورية',
        ],
        'popular': false,
      },
      {
        'id': '2',
        'name': 'الخطة النصف سنوية',
        'price': 149.99,
        'currency': 'SAR',
        'duration': '6 أشهر',
        'features': [
          'وصول كامل للمحتوى',
          'دعم فني 24/7',
          'تحديثات مستمرة',
          'إشعارات فورية',
          'خصم 20%',
        ],
        'popular': true,
      },
      {
        'id': '3',
        'name': 'الخطة السنوية',
        'price': 249.99,
        'currency': 'SAR',
        'duration': 'سنة',
        'features': [
          'وصول كامل للمحتوى',
          'دعم فني 24/7',
          'تحديثات مستمرة',
          'إشعارات فورية',
          'خصم 30%',
          'ميزات حصرية',
        ],
        'popular': false,
      },
    ];
  }

  Future<Map<String, dynamic>> payWithStripe({
    required String planId,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
  }) async {
    await _mockDelay();

    // Mock validation
    if (cardNumber.isEmpty ||
        expiryDate.isEmpty ||
        cvv.isEmpty ||
        cardholderName.isEmpty) {
      throw Exception('جميع بيانات البطاقة مطلوبة');
    }

    if (cardNumber.length < 16) {
      throw Exception('رقم البطاقة غير صحيح');
    }

    if (cvv.length < 3) {
      throw Exception('رمز الأمان غير صحيح');
    }

    // Mock successful payment
    return {
      'success': true,
      'message': 'تم الدفع بنجاح',
      'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'subscriptionId': 'sub_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Logout method
  Future<Map<String, dynamic>> logout({
    required String userId,
    required String deviceToken,
  }) async {
    try {
      print('Making logout API call for userId: $userId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'deviceToken': deviceToken,
        }),
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('API Service: Logout request timeout');
          throw Exception('انتهت مهلة الطلب');
        },
      );

      print('Logout response status: ${response.statusCode}');
      print('Logout response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'تم تسجيل الخروج من الخادم بنجاح',
          'data': data,
        };
      } else {
        print('Logout error: ${response.statusCode} - ${response.body}');

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = (errorData is Map<String, dynamic>)
              ? (errorData['message'] ??
                  errorData['error'] ??
                  'فشل في تسجيل الخروج من الخادم')
              : 'فشل في تسجيل الخروج من الخادم';

          return {
            'success': false,
            'message': errorMessage,
            'statusCode': response.statusCode,
          };
        } catch (jsonError) {
          return {
            'success': false,
            'message': 'فشل في تسجيل الخروج من الخادم',
            'statusCode': response.statusCode,
          };
        }
      }
    } catch (e) {
      print('Logout exception: $e');

      // Handle specific exception types
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'خطأ في الاتصال بالإنترنت أثناء تسجيل الخروج',
          'error': 'network_error',
        };
      } else {
        return {
          'success': false,
          'message': 'حدث خطأ أثناء تسجيل الخروج من الخادم',
          'error': e.toString(),
        };
      }
    }
  }

  // Force logout method (for device conflict resolution)
  Future<Map<String, dynamic>> forceLogout({
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/force-logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Force logout error: ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'Force logout failed'};
      }
    } catch (e) {
      print('Force logout exception: $e');
      return {'success': false, 'message': 'Force logout failed'};
    }
  }

  // ---------------- Dashboard Integration Stubs ----------------
  // These methods model how the app will talk to the teacher dashboard
  // in the future. They currently return mocked responses.

  // Content models
  Future<List<Map<String, dynamic>>> listNotes(
      {required String classId}) async {
    await _mockDelay();
    return [
      {
        'id': 'n1',
        'title': 'ملاحظة عامة',
        'content': 'يرجى مراجعة ملخص الدرس الأول',
        'createdAt': DateTime.now().toIso8601String(),
      }
    ];
  }

  Future<List<Map<String, dynamic>>> listVideos(
      {required String classId}) async {
    await _mockDelay();
    return [
      {
        'id': 'v1',
        'title': 'شرح الوحدة الأولى - الرياضيات',
        'url': 'https://example.com/video1.mp4',
        'durationSec': 1245, // 20:45
      },
      {
        'id': 'v2',
        'title': 'شرح الوحدة الثانية - الفيزياء',
        'url': 'https://example.com/video2.mp4',
        'durationSec': 900, // 15:00
      },
      {
        'id': 'v3',
        'title': 'مراجعة شاملة للفصل الأول',
        'url': 'https://example.com/video3.mp4',
        'durationSec': 1800, // 30:00
      },
      {
        'id': 'v4',
        'title': 'حل التمارين العملية',
        'url': 'https://example.com/video4.mp4',
        'durationSec': 720, // 12:00
      },
      {
        'id': 'v5',
        'title': 'شرح النظريات الأساسية',
        'url': 'https://example.com/video5.mp4',
        'durationSec': 1080, // 18:00
      },
    ];
  }

  Future<List<Map<String, dynamic>>> listExams(
      {required String classId}) async {
    await _mockDelay();
    return [
      {
        'id': 'e1',
        'title': 'امتحان الوحدة 1',
        'pdfUrl': 'https://example.com/exams/e1.pdf',
        'deadline': '2025-12-20',
      }
    ];
  }

  // Upload endpoints (teacher)
  Future<Map<String, dynamic>> uploadPdf({
    required String classId,
    required String filePath,
    required String title,
  }) async {
    await _mockDelay();
    return {
      'success': true,
      'id': 'pdf_${DateTime.now().millisecondsSinceEpoch}',
      'url':
          'https://example.com/pdfs/${DateTime.now().millisecondsSinceEpoch}.pdf',
    };
  }

  Future<Map<String, dynamic>> createExam({
    required String classId,
    required String title,
    required String pdfUrl,
    required String deadline,
  }) async {
    await _mockDelay();
    return {
      'success': true,
      'id': 'e_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Student submission
  Future<Map<String, dynamic>> submitExam({
    required String classId,
    required String examId,
    required String filePath,
  }) async {
    await _mockDelay();
    return {
      'success': true,
      'submissionId': 's_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'received',
    };
  }

  // Get class tasks/exams from backend
  Future<List<Map<String, dynamic>>> getClassTasks({
    required String classId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/class/$classId/tasks');
      final headers = {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      print('Making API call to: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for class tasks: $data');

        // Handle the response format: {"tasks": [...]}
        if (data is Map<String, dynamic>) {
          if (data.containsKey('tasks')) {
            final tasks = data['tasks'] as List<dynamic>;
            print('Extracted tasks from response: $tasks');

            // Process task data to match expected format
            final processedTasks = tasks.map((task) {
              final taskMap = task as Map<String, dynamic>;

              // Format addedAt date
              String formattedDate = 'غير محدد';
              if (taskMap['addedAt'] != null) {
                try {
                  final date = DateTime.parse(taskMap['addedAt']);
                  formattedDate =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                } catch (e) {
                  print('Error parsing addedAt date: $e');
                }
              }

              // Check if task is expired
              final expiresAt = taskMap['expiresAt'];
              final isExpired = expiresAt != null &&
                  DateTime.now().millisecondsSinceEpoch > (expiresAt * 1000);

              return {
                'id': taskMap['_id'],
                'title': taskMap['name'] ?? 'امتحان غير محدد',
                'content': taskMap['description'] ?? 'لا يوجد وصف',
                'pdfUrl': taskMap['url'],
                'expiresAt': expiresAt,
                'isExpired': isExpired,
                'expiresAtFormatted': expiresAt != null
                    ? DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
                        .toIso8601String()
                    : null,
                'addedAt': formattedDate,
                'deadline': formattedDate, // For compatibility with existing UI
              };
            }).toList();

            return processedTasks.cast<Map<String, dynamic>>();
          } else if (data.containsKey('data') && data['data'] is List) {
            final tasks = data['data'] as List<dynamic>;
            print('Extracted tasks from data field: $tasks');
            return tasks.cast<Map<String, dynamic>>();
          } else {
            print('No tasks array found in response object');
            print('Available keys: ${data.keys.toList()}');
            return [];
          }
        } else if (data is List) {
          print('Response is direct list: $data');
          return data.cast<Map<String, dynamic>>();
        }
        print('Unexpected response format');
        return [];
      } else if (response.statusCode == 404) {
        print('Class not found: ${response.body}');
        return [];
      } else {
        print(
            'Error fetching class tasks: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception fetching class tasks: $e');
      return [];
    }
  }

  // Submit task solution
  Future<Map<String, dynamic>> submitTaskSolution({
    required String classId,
    required String taskId,
    required String filePath,
    String? accessToken,
  }) async {
    try {
      // Validate file path
      if (filePath.isEmpty) {
        throw Exception('مسار الملف غير صحيح');
      }

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود');
      }

      // Check file size (limit to 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('حجم الملف كبير جداً (الحد الأقصى 10 ميجابايت)');
      }

      final uri = Uri.parse(
          '$baseUrl/api/student/class/$classId/task/$taskId/solution');

      // Create multipart request for file upload
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Add file with proper content type
      final fileExtension = filePath.split('.').last.toLowerCase();
      String contentType = 'application/octet-stream';

      switch (fileExtension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
      }

      request.files.add(await http.MultipartFile.fromPath(
        'solution',
        filePath,
        contentType:
            MediaType(contentType.split('/')[0], contentType.split('/')[1]),
      ));

      print('Making API call to: $uri');
      print('File path: $filePath');
      print('File size: ${fileSize} bytes');
      print('Content type: $contentType');
      print('Headers: ${request.headers}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for task submission: $data');

        return {
          'success': true,
          'message': data['message'] ?? 'تم تسليم الحل بنجاح',
          'solution': data['solution'],
        };
      } else {
        print(
            'Error submitting task solution: ${response.statusCode} - ${response.body}');

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = (errorData is Map<String, dynamic>)
              ? (errorData['message'] ??
                  errorData['error'] ??
                  errorData['msg'] ??
                  'خطا في تسليم الامتحان')
              : 'خطا في تسليم الامتحان';

          // Translate common error messages to Arabic
          if (errorMessage.toLowerCase().contains('file too large') ||
              errorMessage.toLowerCase().contains('file size')) {
            errorMessage = 'حجم الملف كبير جداً';
          } else if (errorMessage.toLowerCase().contains('invalid file') ||
              errorMessage.toLowerCase().contains('unsupported')) {
            errorMessage = 'نوع الملف غير مدعوم';
          } else if (errorMessage.toLowerCase().contains('unauthorized') ||
              errorMessage.toLowerCase().contains('forbidden')) {
            errorMessage = 'غير مخول لتسليم هذا الامتحان';
          } else if (errorMessage.toLowerCase().contains('not found')) {
            errorMessage = 'الامتحان غير موجود';
          } else if (errorMessage.toLowerCase().contains('expired')) {
            errorMessage = 'انتهت صلاحية الامتحان';
          } else if (errorMessage.toLowerCase().contains('network') ||
              errorMessage.toLowerCase().contains('connection')) {
            errorMessage = 'خطأ في الاتصال بالإنترنت';
          }

          throw Exception(errorMessage);
        } catch (jsonError) {
          // Provide specific error messages based on status code
          if (response.statusCode == 400) {
            throw Exception('بيانات الطلب غير صحيحة');
          } else if (response.statusCode == 401) {
            throw Exception('غير مخول لتسليم هذا الامتحان');
          } else if (response.statusCode == 403) {
            throw Exception('انتهت صلاحية الامتحان');
          } else if (response.statusCode == 404) {
            throw Exception('الامتحان غير موجود');
          } else if (response.statusCode == 413) {
            throw Exception('حجم الملف كبير جداً');
          } else if (response.statusCode == 500) {
            throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
          } else {
            throw Exception('خطا في تسليم الامتحان');
          }
        }
      }
    } catch (e) {
      print('Exception submitting task solution: $e');

      // Handle specific exception types
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception('خطأ في الاتصال بالإنترنت');
      } else if (e.toString().contains('FileSystemException')) {
        throw Exception('خطأ في قراءة الملف');
      } else {
        rethrow; // Re-throw the original exception if it's already in Arabic
      }
    }
  }
}
