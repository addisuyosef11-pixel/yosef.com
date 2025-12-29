import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.164.11.115:8000/api";

  // ==========================
  // HELPER METHODS
  // ==========================
  
  static Map<String, String> _authHeader(String token) {
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Map<String, String> _authHeaderWithoutType(String token) {
    return {
      'Authorization': token,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<Map<String, String>> _getHeaders() async {
    // This method assumes token is stored somewhere accessible
    // For now, we'll use a placeholder - you should replace with your token retrieval logic
    final token = ''; // Get token from SharedPreferences or other storage
    return _authHeader(token);
  }

  static Future<Map<String, String>> _getHeadersForFileUpload() async {
    final token = ''; // Get token from SharedPreferences
    return {
      'Authorization': 'Token $token',
    };
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseBody = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw Exception(responseBody['detail'] ?? responseBody['message'] ?? responseBody['error'] ?? 'Request failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to parse response: $e');
    }
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    
    return 0.0;
  }

  // ==========================
  // VIDEO ENDPOINTS
  // ==========================

  /// 🔹 GET VIDEO LIST
  static Future<List<dynamic>> getVideoList({
    String? token,
    int? page,
    int? pageSize,
    String? search,
    String? category,
    bool? featured,
    String? ordering,
  }) async {
    try {
      final headers = token != null ? _authHeader(token) : {'Content-Type': 'application/json'};
      final params = <String, String>{};

      if (page != null) params['page'] = page.toString();
      if (pageSize != null) params['page_size'] = pageSize.toString();
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (category != null && category.isNotEmpty) params['category'] = category;
      if (featured != null) params['featured'] = featured.toString();
      if (ordering != null && ordering.isNotEmpty) params['ordering'] = ordering;

      final uri = Uri.parse('$baseUrl/videos/').replace(queryParameters: params);
      print('📹 Fetching videos from: $uri');
      
      final response = await http.get(uri, headers: headers);
      print('📹 Videos Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Handle different response formats
        if (result.containsKey('results')) {
          return result['results'] as List<dynamic>;
        } else if (result is List) {
          return result;
        } else if (result.containsKey('videos')) {
          return result['videos'] as List<dynamic>;
        } else if (result.containsKey('data')) {
          return result['data'] as List<dynamic>;
        }
        
        print('⚠️ Unusual video list format: $result');
        return [];
      } else {
        print('❌ Failed to load videos: ${response.statusCode}');
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Video list error: $e');
      rethrow;
    }
  }

  /// 🔹 GET VIDEO DETAIL
  static Future<Map<String, dynamic>> getVideoDetail({
    required String token,
    required int videoId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/videos/$videoId/');
      print('📹 Fetching video detail from: $url');
      
      final response = await http.get(url, headers: _authHeader(token));
      print('📹 Video Detail Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to load video detail: ${response.statusCode}');
        throw Exception('Failed to load video detail: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Video detail error: $e');
      rethrow;
    }
  }

  /// 🔹 INCREMENT VIDEO VIEWS
  static Future<Map<String, dynamic>> incrementVideoViews({
    required String token,
    required int videoId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/videos/$videoId/views/');
      print('👁️ Incrementing views for video: $videoId');
      
      final response = await http.post(url, headers: _authHeader(token));
      print('👁️ Views Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to increment views: ${response.statusCode}');
        throw Exception('Failed to increment views: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Increment views error: $e');
      rethrow;
    }
  }

  /// 🔹 LIKE VIDEO
  static Future<Map<String, dynamic>> likeVideo({
    required String token,
    required int videoId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/videos/$videoId/like/');
      print('👍 Liking video: $videoId');
      
      final response = await http.post(url, headers: _authHeader(token));
      print('👍 Like Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to like video: ${response.statusCode}');
        throw Exception('Failed to like video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Like video error: $e');
      rethrow;
    }
  }

  /// 🔹 DISLIKE VIDEO
  static Future<Map<String, dynamic>> dislikeVideo({
    required String token,
    required int videoId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/videos/$videoId/dislike/');
      print('👎 Disliking video: $videoId');
      
      final response = await http.post(url, headers: _authHeader(token));
      print('👎 Dislike Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to dislike video: ${response.statusCode}');
        throw Exception('Failed to dislike video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Dislike video error: $e');
      rethrow;
    }
  }

  /// 🔹 UPLOAD VIDEO
  static Future<Map<String, dynamic>> uploadVideo({
    required String token,
    required File videoFile,
    required String title,
    required String description,
    String? category,
    List<String>? tags,
    bool? isPrivate,
    File? thumbnailFile,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/videos/upload/');
      print('📤 Uploading video: $title');
      
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Token $token';
      
      // Add video file
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
        ),
      );

      // Add thumbnail if provided
      if (thumbnailFile != null && thumbnailFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'thumbnail',
            thumbnailFile.path,
          ),
        );
      }

      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      if (category != null) request.fields['category'] = category;
      if (tags != null && tags.isNotEmpty) request.fields['tags'] = tags.join(',');
      if (isPrivate != null) request.fields['is_private'] = isPrivate.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📤 Upload Response Status: ${response.statusCode}');
      print('📤 Upload Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to upload video: ${response.statusCode}');
        throw Exception('Failed to upload video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Upload video error: $e');
      rethrow;
    }
  }

  /// 🔹 APPROVE VIDEO (Admin only)
  static Future<Map<String, dynamic>> approveVideo({
    required String token,
    required int videoId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/videos/$videoId/approve/');
      print('✅ Approving video: $videoId');
      
      final response = await http.post(url, headers: _authHeader(token));
      print('✅ Approve Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to approve video: ${response.statusCode}');
        throw Exception('Failed to approve video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Approve video error: $e');
      rethrow;
    }
  }

  /// 🔹 REJECT VIDEO (Admin only)
  static Future<Map<String, dynamic>> rejectVideo({
    required String token,
    required int videoId,
    String? reason,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/videos/$videoId/reject/');
      print('❌ Rejecting video: $videoId');
      
      final body = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }
      
      final response = await http.post(
        url,
        headers: _authHeader(token),
        body: json.encode(body),
      );
      
      print('❌ Reject Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to reject video: ${response.statusCode}');
        throw Exception('Failed to reject video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Reject video error: $e');
      rethrow;
    }
  }

  /// 🔹 FEATURE VIDEO (Admin only)
  static Future<Map<String, dynamic>> featureVideo({
    required String token,
    required int videoId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/videos/$videoId/feature/');
      print('⭐ Featuring video: $videoId');
      
      final response = await http.post(url, headers: _authHeader(token));
      print('⭐ Feature Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to feature video: ${response.statusCode}');
        throw Exception('Failed to feature video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Feature video error: $e');
      rethrow;
    }
  }

  /// 🔹 UNFEATURE VIDEO (Admin only)
  static Future<Map<String, dynamic>> unfeatureVideo({
    required String token,
    required int videoId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/videos/$videoId/unfeature/');
      print('🔽 Unfeaturing video: $videoId');
      
      final response = await http.post(url, headers: _authHeader(token));
      print('🔽 Unfeature Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to unfeature video: ${response.statusCode}');
        throw Exception('Failed to unfeature video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Unfeature video error: $e');
      rethrow;
    }
  }

  /// 🔹 SEARCH VIDEOS
  static Future<List<dynamic>> searchVideos({
    String? token,
    required String query,
    int? page,
  }) async {
    return await getVideoList(
      token: token,
      search: query,
      page: page,
    );
  }

  /// 🔹 GET FEATURED VIDEOS
  static Future<List<dynamic>> getFeaturedVideos({
    String? token,
    int? page,
  }) async {
    return await getVideoList(
      token: token,
      featured: true,
      page: page,
    );
  }

  /// 🔹 GET VIDEOS BY CATEGORY
  static Future<List<dynamic>> getVideosByCategory({
    String? token,
    required String category,
    int? page,
  }) async {
    return await getVideoList(
      token: token,
      category: category,
      page: page,
    );
  }

  /// 🔹 GET MY VIDEOS
  static Future<List<dynamic>> getMyVideos({
    required String token,
    int? page,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/videos/my/');
      print('📹 Fetching my videos');
      
      final response = await http.get(url, headers: _authHeader(token));
      print('📹 My Videos Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result.containsKey('results')) {
          return result['results'] as List<dynamic>;
        } else if (result is List) {
          return result;
        } else if (result.containsKey('videos')) {
          return result['videos'] as List<dynamic>;
        }
        
        return [];
      } else {
        print('❌ Failed to load my videos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ My videos error: $e');
      return [];
    }
  }

  /// 🔹 UPDATE VIDEO
  static Future<Map<String, dynamic>> updateVideo({
    required String token,
    required int videoId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    bool? isPrivate,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/videos/$videoId/');
      print('✏️ Updating video: $videoId');
      
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (tags != null) body['tags'] = tags;
      if (isPrivate != null) body['is_private'] = isPrivate;
      
      final response = await http.patch(
        url,
        headers: _authHeader(token),
        body: json.encode(body),
      );
      
      print('✏️ Update Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to update video: ${response.statusCode}');
        throw Exception('Failed to update video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Update video error: $e');
      rethrow;
    }
  }

  /// 🔹 DELETE VIDEO
  static Future<bool> deleteVideo({
    required String token,
    required int videoId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/videos/$videoId/');
      print('🗑️ Deleting video: $videoId');
      
      final response = await http.delete(url, headers: _authHeader(token));
      print('🗑️ Delete Response Status: ${response.statusCode}');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Delete video error: $e');
      return false;
    }
  }

  // ==========================
  // EXISTING METHODS (keep all your existing methods below)
  // ==========================

  /// 🔹 VERIFY OTP
  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final url = Uri.parse('$baseUrl/verify-otp/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "phone": phone,
        "otp": otp,
      }),
    );
    return jsonDecode(response.body);
  }
  
  /// 🔹 GET REFERRAL DATA
  static Future<Map<String, dynamic>> getReferralData({required String token}) async {
    final url = Uri.parse("$baseUrl/invite/referrals/");
    final res = await http.get(
      url,
      headers: {"Authorization": "Token $token"},
    );

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } else {
      throw Exception("Failed to fetch referral data: ${res.body}");
    }
  }
  
  /// 🔹 GET RECHARGE HISTORY
  static Future<List<Map<String, dynamic>>> getRechargeHistory(String token) async {
    try {
      print('📥 Fetching recharge history...');
      final url = Uri.parse('$baseUrl/recharge/history/');
      
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📥 Recharge History Status: ${res.statusCode}');
      print('📥 Recharge History Response: ${res.body}');

      if (res.statusCode == 200) {
        final dynamic data = jsonDecode(res.body);
        
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          if (data['results'] is List) {
            return List<Map<String, dynamic>>.from(data['results']);
          } else if (data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data']);
          } else if (data['history'] is List) {
            return List<Map<String, dynamic>>.from(data['history']);
          } else if (data['recharges'] is List) {
            return List<Map<String, dynamic>>.from(data['recharges']);
          } else if (data['success'] == true && data['recharges'] is List) {
            return List<Map<String, dynamic>>.from(data['recharges']);
          }
        }
        
        print('⚠️ Unusual recharge history format: $data');
        return [];
      } else {
        print('❌ Failed to load recharge history: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Recharge history error: $e');
      return [];
    }
  }
  
  /// 🔹 RECHARGE / DEPOSIT
  static Future<Map<String, dynamic>> recharge({
    required String token,
    required String amount,
    String? paymentMethod,
    File? proof,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/recharge/');
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_authHeaderWithoutType(token));

      request.fields['amount'] = amount;
      if (paymentMethod != null) request.fields['payment_method'] = paymentMethod;

      if (proof != null && proof.existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('proof', proof.path));
      }

      var response = await request.send();
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Recharge successful', 'data': data};
      }
      return {'success': false, 'message': data['error'] ?? 'Recharge failed', 'data': data};
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  /// 🔹 RESEND OTP
  static Future<Map<String, dynamic>> resendOtp(String username) async {
    final url = Uri.parse('$baseUrl/resend-otp/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username}),
    );
    return jsonDecode(response.body);
  }
  
  /// 🔹 GET AVIATOR HISTORY
  static Future<List<Map<String, dynamic>>> aviatorHistory(String token) async {
    final url = Uri.parse("$baseUrl/aviator/history/");
    final res = await http.get(
      url,
      headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception("Failed to fetch aviator history (${res.statusCode})");
  }
  
  // Signup with all options
  static Future<Map<String, dynamic>> signup({
    String? username,
    String? email,
    String? phone,
    required String password,
    String? refcode,
    String? firstName,
    String? lastName,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup/');
    
    if (username == null && email == null && phone == null) {
      throw Exception('At least one of username, email, or phone is required');
    }
    
    String finalUsername = username ?? '';
    if (finalUsername.isEmpty) {
      if (phone != null) {
        finalUsername = 'user_${phone.replaceAll(RegExp(r'[^0-9]'), '')}';
      } else if (email != null) {
        finalUsername = 'user_${email.split('@')[0]}';
      }
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (finalUsername.isNotEmpty) "username": finalUsername,
        if (email != null && email.isNotEmpty) "email": email,
        if (phone != null && phone.isNotEmpty) "phone": phone,
        "password": password,
        if (refcode != null && refcode.isNotEmpty) "refcode": refcode,
        if (firstName != null && firstName.isNotEmpty) "first_name": firstName,
        if (lastName != null && lastName.isNotEmpty) "last_name": lastName,
      }),
    );

    return jsonDecode(response.body);
  }
  
  static Future<Map<String, dynamic>> login({
    String? username,
    String? email,
    String? phone,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/auth/login/");
    
    final identifier = username ?? email ?? phone;
    
    print("🔍 Login Attempt:");
    print("  URL: $url");
    print("  Identifier: $identifier");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "username": identifier,
          "password": password,
        }),
      );

      print("📦 Response Status: ${response.statusCode}");
      print("📦 Response Body: ${response.body}");

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print("✅ Login successful - Full response: $data");
        return data;
      } else {
        print("❌ Login failed with status ${response.statusCode}");
        return data;
      }
    } catch (e) {
      print("⚠️ Network error during login: $e");
      return {'error': e.toString()};
    }
  }
  
  /// 🔹 GET BALANCE
  static Future<Map<String, dynamic>> getBalance(String token) async {
    try {
      print('💰 Fetching balance...');
      final url = Uri.parse("$baseUrl/balance/");
      
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print('💰 Balance Response Status: ${res.statusCode}');
      print('💰 Balance Response Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        if (data is Map) {
          return {
            'success': true,
            'total': _parseAmount(data['balance'] ?? data['total_balance'] ?? data['total'] ?? 0),
            'available': _parseAmount(data['available_balance'] ?? data['available'] ?? data['avail_balance'] ?? 0),
            'frozen': _parseAmount(data['frozen_balance'] ?? data['frozen'] ?? data['locked_balance'] ?? 0),
            'raw': data,
          };
        } else if (data is num) {
          return {
            'success': true,
            'total': _parseAmount(data),
            'available': _parseAmount(data),
            'frozen': 0,
            'raw': data,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
            'total': 0,
            'available': 0,
            'frozen': 0,
          };
        }
      } else if (res.statusCode == 401) {
        return {
          'success': false,
          'error': 'Unauthorized - Invalid token',
          'total': 0,
          'available': 0,
          'frozen': 0,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch balance: ${res.statusCode}',
          'total': 0,
          'available': 0,
          'frozen': 0,
        };
      }
    } catch (e) {
      print('❌ Balance fetch error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
        'total': 0,
        'available': 0,
        'frozen': 0,
      };
    }
  }
  
  /// 🔹 PROFILE + BALANCE
  static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final profileUrl = Uri.parse("$baseUrl/profile/");
      final balanceUrl = Uri.parse("$baseUrl/balance/");
      
      print('👤 Fetching profile...');
      final profileRes = await http.get(
        profileUrl, 
        headers: {"Authorization": "Token $token", "Content-Type": "application/json"}
      );
      
      print('💰 Fetching balance for profile...');
      final balanceRes = await http.get(
        balanceUrl, 
        headers: {"Authorization": "Token $token", "Content-Type": "application/json"}
      );

      print('👤 Profile Status: ${profileRes.statusCode}');
      print('💰 Balance Status: ${balanceRes.statusCode}');

      if (profileRes.statusCode == 200 && balanceRes.statusCode == 200) {
        final profileData = jsonDecode(profileRes.body);
        final balanceData = jsonDecode(balanceRes.body);
        
        return {
          ...profileData,
          'balance': _parseAmount(balanceData['balance'] ?? 0),
          'available_balance': _parseAmount(balanceData['available_balance'] ?? 0),
          'frozen_balance': _parseAmount(balanceData['frozen_balance'] ?? 0),
        };
      } else {
        print('⚠️ Profile or balance fetch failed');
        if (profileRes.statusCode == 200) {
          final profileData = jsonDecode(profileRes.body);
          return {
            ...profileData,
            'balance': 0,
            'available_balance': 0,
            'frozen_balance': 0,
          };
        } else if (balanceRes.statusCode == 200) {
          final balanceData = jsonDecode(balanceRes.body);
          return {
            'balance': _parseAmount(balanceData['balance'] ?? 0),
            'available_balance': _parseAmount(balanceData['available_balance'] ?? 0),
            'frozen_balance': _parseAmount(balanceData['frozen_balance'] ?? 0),
          };
        }
        throw Exception("Failed to fetch profile (${profileRes.statusCode}) or balance (${balanceRes.statusCode})");
      }
    } catch (e) {
      print('⚠️ Network error fetching profile/balance: $e');
      throw Exception("⚠️ Network error fetching profile/balance: $e");
    }
  }

  /// 🔹 GET VIP PRODUCTS
  static Future<List<Map<String, dynamic>>> getVipProducts(String token) async {
    final url = Uri.parse("$baseUrl/vip-packages/");
    final res = await http.get(
      url,
      headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception("Failed to fetch VIP products (${res.statusCode})");
  }

  /// 🔹 BUY VIP PRODUCT
  static Future<String> buyVipProduct(String token, int vipId) async {
    final url = Uri.parse("$baseUrl/vip/buy/");
    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
        body: jsonEncode({"vip_id": vipId}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['message'] != null) return "success";
        if (data['error'] != null) {
          if (data['error'].toString().contains("Insufficient balance")) return "insufficient";
          return "failed: ${data['error']}";
        }
        return "failed";
      } else if (res.statusCode == 400 && res.body.contains("Insufficient balance")) {
        return "insufficient";
      } else {
        return "failed";
      }
    } catch (e) {
      return "failed: $e";
    }
  }

  /// 🔹 CLAIM VIP INCOME
  static Future<Map<String, dynamic>> claimVipIncome(String token) async {
    final url = Uri.parse("$baseUrl/vip/claim/");
    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      if (res.statusCode == 200) return {"success": true, "claimed": true, "message": data["message"] ?? "Claim successful"};
      if (res.statusCode == 400 && data["error"]?.contains("24 hours") == true) {
        return {"success": false, "claimed": false, "error": data["error"] ?? "You can only claim once every 24 hours"};
      }
      return {"success": false, "claimed": false, "error": data["error"] ?? "Claim failed"};
    } catch (e) {
      return {"success": false, "claimed": false, "error": "Network error: $e"};
    }
  }

  /// 🔹 COMMISSIONS
  static Future<List<Map<String, dynamic>>> getCommissions(String token) async {
    final url = Uri.parse("$baseUrl/commissions/");
    final res = await http.get(url, headers: {"Authorization": "Token $token"});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception("Failed to fetch commissions (${res.statusCode})");
  }

  /// 🔹 GET WITHDRAWALS
  static Future<List<Map<String, dynamic>>> getWithdrawals(String token) async {
    try {
      print('📤 Fetching withdrawal history...');
      
      final endpoints = [
        "$baseUrl/withdraw/history/",
        "$baseUrl/withdraw-history/",
        "$baseUrl/withdrawals/",
        "$baseUrl/withdrawal/history/",
        "$baseUrl/user/withdrawals/",
      ];
      
      for (final endpoint in endpoints) {
        try {
          print('🔄 Trying endpoint: $endpoint');
          final url = Uri.parse(endpoint);
          final res = await http.get(
            url,
            headers: {
              "Authorization": "Token $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          ).timeout(Duration(seconds: 5));

          print('📤 Withdrawal Response Status: ${res.statusCode}');
          
          if (res.statusCode == 200) {
            print('📤 Withdrawal Response Body: ${res.body.length > 200 ? res.body.substring(0, 200) + '...' : res.body}');
            
            final dynamic data = jsonDecode(res.body);
            
            if (data is List) {
              print('✅ Found ${data.length} withdrawals (list format)');
              return List<Map<String, dynamic>>.from(data);
            } else if (data is Map) {
              if (data['results'] is List) {
                final results = List<Map<String, dynamic>>.from(data['results']);
                print('✅ Found ${results.length} withdrawals (results format)');
                return results;
              } else if (data['data'] is List) {
                final results = List<Map<String, dynamic>>.from(data['data']);
                print('✅ Found ${results.length} withdrawals (data format)');
                return results;
              } else if (data['history'] is List) {
                final results = List<Map<String, dynamic>>.from(data['history']);
                print('✅ Found ${results.length} withdrawals (history format)');
                return results;
              } else if (data['withdrawals'] is List) {
                final results = List<Map<String, dynamic>>.from(data['withdrawals']);
                print('✅ Found ${results.length} withdrawals (withdrawals format)');
                return results;
              } else if (data['success'] == true && data['withdrawals'] is List) {
                final results = List<Map<String, dynamic>>.from(data['withdrawals']);
                print('✅ Found ${results.length} withdrawals (success-withdrawals format)');
                return results;
              } else if (data['transactions'] is List) {
                final results = List<Map<String, dynamic>>.from(data['transactions']);
                print('✅ Found ${results.length} withdrawals (transactions format)');
                return results;
              }
            }
            
            print('⚠️ Unusual withdrawal history format for $endpoint');
          } else if (res.statusCode == 404) {
            print('❌ Endpoint not found: $endpoint');
            continue;
          }
        } catch (e) {
          print('⚠️ Endpoint $endpoint failed: ${e.toString().split('\n').first}');
          continue;
        }
      }
      
      print('❌ All withdrawal endpoints failed');
      return [];
    } catch (e) {
      print('❌ Withdrawal history error: $e');
      return [];
    }
  }

  /// 🔹 WHEEL WINNINGS
  static Future<bool> recordWinning(String token, double amount) async {
    final url = Uri.parse("$baseUrl/wheel/win/");
    final res = await http.post(
      url,
      headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
      body: jsonEncode({"amount": amount}),
    );
    return res.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getRecentWinnings(String token) async {
    final url = Uri.parse("$baseUrl/wheel/recent/");
    final res = await http.get(url, headers: {"Authorization": "Token $token", "Content-Type": "application/json"});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception("Failed to fetch recent winnings (${res.statusCode})");
  }

  /// 🔹 SETTINGS
  static Future<Map<String, dynamic>> getSettings(String token) async {
    final url = Uri.parse("$baseUrl/settings/");
    final res = await http.get(url, headers: {"Authorization": "Token $token", "Content-Type": "application/json"});
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to fetch settings: ${res.body}");
  }

   /// 🔹 UPDATE ACCOUNT NUMBER
  static Future<bool> accountnumberUpdate({
    required String token,
    required String merchantName,
    required String bankType,
    required String newAccountNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/account_number/update/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'merchant_name': merchantName,
          'bank_type': bankType,
          'account_number': newAccountNumber,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update account: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating account: $e');
      return false;
    }
  }

  /// 🔹 SET WITHDRAW PASSWORD
  static Future<bool> setWithdrawPassword({required String token, required String withdrawPassword}) async {
    final url = Uri.parse("$baseUrl/set_withdraw_password/");
    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
        body: jsonEncode({"withdraw_password": withdrawPassword}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  
  /// 🔹 GET INVITE CODE
  static Future<String> getInviteCode({required String token}) async {
    final url = Uri.parse("$baseUrl/invite/my-code/");
    final res = await http.get(url, headers: {"Authorization": "Token $token"});
    if (res.statusCode == 200) {
      final data = Map<String, dynamic>.from(jsonDecode(res.body));
      return data['invite_code'] ?? '';
    }
    throw Exception("Failed to fetch invite code");
  }
  
  /// 🔹 REDEEM GIFT CODE
  static Future<Map<String, dynamic>> redeemGiftCode({required String token, required String code}) async {
    final url = Uri.parse("$baseUrl/gift/redeem/");
    final res = await http.post(
      url,
      headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
      body: jsonEncode({"code": code}),
    );

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } else {
      return {
        "success": false,
        "message": jsonDecode(res.body)["message"] ?? "Failed to redeem code",
      };
    }
  }
  
  /// 🔹 CHANGE WITHDRAW PASSWORD
  static Future<bool> changeWithdrawPassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse("$baseUrl/withdraw_password/change/");
    final res = await http.post(
      url,
      headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
      body: jsonEncode({
        "old_withdraw_password": oldPassword,
        "new_withdraw_password": newPassword,
      }),
    );
    return res.statusCode == 200;
  }

  /// 🔹 SEND MESSAGE
  static Future<Map<String, dynamic>> sendMessage({
    required String token, 
    required String message, 
    required String sender
  }) async {
    try {
      final url = Uri.parse("$baseUrl/chat/save/");
      print('📨 Sending chat message to: $url');
      print('📨 Message: $message');
      print('📨 Sender: $sender');
      
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "content": message,
        }),
      );

      print('📨 Chat Send Response Status: ${res.statusCode}');
      print('📨 Chat Send Response Body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(res.body);
          return {
            "success": true,
            "message": responseData['message'] ?? "Message sent successfully",
            "message_id": responseData['message_id'] ?? responseData['id'] ?? '',
            "data": responseData['data'] ?? responseData,
          };
        } catch (e) {
          return {
            "success": true,
            "message": "Message sent successfully",
          };
        }
      } else {
        return {
          "success": false,
          "message": "Failed to send message: ${res.statusCode}",
          "response_body": res.body,
        };
      }
    } catch (e) {
      print('❌ Chat send error: $e');
      return {
        "success": false,
        "message": "Network error: $e",
      };
    }
  }

  static Future<List<Map<String, dynamic>>> fetchChatHistory({
    required String token
  }) async {
    try {
      final url = Uri.parse("$baseUrl/chat/");
      print('📨 Fetching chat history from: $url');
      
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      print('📨 Chat History Response Status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(res.body);
          
          if (responseData['success'] == true) {
            final messages = responseData['messages'] ?? responseData['data'] ?? [];
            
            if (messages is List) {
              print('✅ Found ${messages.length} chat messages');
              
              final parsedMessages = messages.map<Map<String, dynamic>>((msg) {
                return {
                  'id': msg['id']?.toString() ?? '',
                  'content': msg['content']?.toString() ?? '',
                  'sender': msg['sender']?.toString() ?? 'user',
                  'timestamp': msg['timestamp'] != null 
                      ? DateTime.parse(msg['timestamp'].toString())
                      : DateTime.now(),
                  'is_support': msg['is_support'] ?? false,
                  'type': msg['message_type'] ?? 'text',
                  'image_url': msg['image_url'],
                  'server_id': msg['id']?.toString() ?? '',
                };
              }).toList();
              
              parsedMessages.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
              
              return parsedMessages;
            }
          }
        } catch (e) {
          print('❌ Error parsing chat history: $e');
          print('Raw response: ${res.body}');
        }
      }
      
      print('⚠️ No chat history available or API error');
      return [];
      
    } catch (e) {
      print('❌ Chat history fetch error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> deleteMessage({
    required String token,
    required String messageId,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/chat/delete/$messageId/");
      print('🗑️ Deleting message: $messageId');
      
      final res = await http.delete(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      print('🗑️ Delete Response Status: ${res.statusCode}');
      print('🗑️ Delete Response Body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 204) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(res.body);
          return {
            "success": true,
            "message": responseData['message'] ?? "Message deleted successfully",
          };
        } catch (e) {
          return {
            "success": true,
            "message": "Message deleted successfully",
          };
        }
      } else {
        return {
          "success": false,
          "message": "Failed to delete message: ${res.statusCode}",
          "response_body": res.body,
        };
      }
    } catch (e) {
      print('❌ Delete message error: $e');
      return {
        "success": false,
        "message": "Network error: $e",
      };
    }
  }
  
  /// 🔹 PROCESS WITHDRAWAL
  static Future<String> processWithdrawal(String token, double amount) async {
    try {
      final url = Uri.parse('$baseUrl/withdraw/');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['status']?.toString() ?? 'success';
      } else if (response.statusCode == 400) {
        final errorMsg = data['error']?.toString() ?? data['message']?.toString() ?? '';
        if (errorMsg.toLowerCase().contains('insufficient')) {
          return 'insufficient';
        }
        if (errorMsg.toLowerCase().contains('password')) {
          return 'withdraw_password_required';
        }
        if (errorMsg.toLowerCase().contains('minimum')) {
          return 'minimum_amount_not_met';
        }
        return 'withdrawal_failed: $errorMsg';
      } else {
        return 'withdrawal_failed: ${response.statusCode}';
      }
    } catch (e) {
      return 'error: $e';
    }
  }
    

  static Future<List<dynamic>> getPaymentMethods(String token) async {
    final url = Uri.parse("$baseUrl/payment-methods/");
    try {
      final res = await http.get(url, headers: _authHeader(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["methods"] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// 🔹 GET FEATURED PROJECTS
  static Future<List<Map<String, dynamic>>> getFeaturedProjects() async {
    final url = Uri.parse("$baseUrl/main-projects/featured/");
    final res = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );
  
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['projects']);
      }
    }
    throw Exception("Failed to fetch featured projects");
  }
  
  /// 🔹 GET MAIN PROJECTS
  static Future<List<Map<String, dynamic>>> getMainProjects(String token) async {
    try {
      final url = Uri.parse("$baseUrl/main-projects/");
      print('🔍 Fetching main projects from: $url');
      
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print('📊 Main Projects Response Status: ${res.statusCode}');
      print('📊 Main Projects Response Body: ${res.body}');
      
      if (res.statusCode == 200) {
        final dynamic data = jsonDecode(res.body);
        
        if (data is Map && data['success'] == true) {
          if (data['projects'] is List) {
            final List projects = data['projects'];
            print('✅ Found ${projects.length} main projects');
            return List<Map<String, dynamic>>.from(projects);
          }
        }
        
        if (data is List) {
          print('✅ Found ${data.length} main projects (direct list)');
          return List<Map<String, dynamic>>.from(data);
        }
        
        print('⚠️ Unexpected response format: $data');
        return [];
      } else {
        print('❌ API Error ${res.statusCode}: ${res.body}');
        return [];
      }
    } catch (e) {
      print('❌ Main projects fetch error: $e');
      return [];
    }
  }

  /// 🔹 INVEST IN MAIN PROJECT
  static Future<Map<String, dynamic>> investInMainProject({
    required String token,
    required int projectId,
    int units = 1,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/main-projects/invest/");
      
      print('💰 Sending investment request to: $url');
      print('  - Project ID: $projectId');
      print('  - Units: $units');
      
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'project_id': projectId,
          'units': units,
        }),
      );

      print('💰 Investment Response Status: ${res.statusCode}');
      print('💰 Investment Response Body: ${res.body}');
      
      if (res.body.trim().startsWith('<!DOCTYPE') || 
          res.body.trim().startsWith('<html')) {
        print('❌ Server returned HTML error page');
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
          'error': 'HTML_RESPONSE',
          'status_code': res.statusCode,
        };
      }
      
      try {
        final dynamic data = jsonDecode(res.body);
        print('💰 Parsed Response: $data');
        
        if (res.statusCode == 200 || res.statusCode == 201) {
          if (data['success'] == true || 
              data['status'] == 'success' || 
              data['message']?.toString().toLowerCase().contains('success') == true) {
            
            double newBalance = data['user']?['new_balance']?.toDouble() ?? 
                              data['balance']?.toDouble() ?? 
                              data['available_balance']?.toDouble() ?? 0.0;
            
            return {
              'success': true,
              'message': data['message'] ?? 'Investment successful!',
              'investment_id': data['investment']?['id'] ?? data['investment_id'],
              'new_balance': newBalance,
              'data': data,
            };
          } else {
            return {
              'success': false,
              'message': data['message'] ?? data['error'] ?? 'Investment failed',
              'error': data['error'] ?? 'INVESTMENT_FAILED',
            };
          }
        } 
        else if (res.statusCode == 400) {
          String errorMsg = data['message']?.toString() ?? 
                           data['error']?.toString() ?? 
                           'Bad request';
          
          if (errorMsg.toLowerCase().contains('insufficient') || 
              errorMsg.toLowerCase().contains('balance') ||
              errorMsg.toLowerCase().contains('required') ||
              errorMsg.toLowerCase().contains('available')) {
            
            double requiredAmount = 0.0;
            double availableAmount = 0.0;
            
            try {
              final regex = RegExp(r'Required:\s*([\d\.]+).*?Available:\s*([\d\.]+)');
              final match = regex.firstMatch(errorMsg);
              if (match != null) {
                requiredAmount = double.tryParse(match.group(1)!) ?? 0.0;
                availableAmount = double.tryParse(match.group(2)!) ?? 0.0;
              }
            } catch (_) {}
            
            return {
              'success': false,
              'message': 'Insufficient balance',
              'error': 'INSUFFICIENT_BALANCE',
              'details': errorMsg,
              'required_amount': requiredAmount,
              'available_amount': availableAmount,
              'difference': requiredAmount - availableAmount,
            };
          } else if (errorMsg.toLowerCase().contains('units') || 
                     errorMsg.toLowerCase().contains('available')) {
            return {
              'success': false,
              'message': 'Not enough units available',
              'error': 'UNITS_UNAVAILABLE',
              'details': errorMsg,
            };
          } else if (errorMsg.toLowerCase().contains('already invested')) {
            return {
              'success': false,
              'message': 'You already invested in this project',
              'error': 'ALREADY_INVESTED',
              'details': errorMsg,
            };
          } else {
            return {
              'success': false,
              'message': errorMsg,
              'error': 'VALIDATION_ERROR',
              'details': errorMsg,
            };
          }
        }
        else if (res.statusCode == 401) {
          return {
            'success': false,
            'message': 'Authentication failed. Please login again.',
            'error': 'UNAUTHORIZED',
          };
        }
        else if (res.statusCode == 404) {
          return {
            'success': false,
            'message': 'Project not found',
            'error': 'PROJECT_NOT_FOUND',
          };
        }
        else if (res.statusCode == 403) {
          return {
            'success': false,
            'message': 'You do not have permission to invest',
            'error': 'FORBIDDEN',
          };
        }
        else {
          return {
            'success': false,
            'message': 'Server error: ${res.statusCode}',
            'error': 'SERVER_ERROR',
            'status_code': res.statusCode,
            'details': data.toString(),
          };
        }
      } catch (e) {
        print('❌ Failed to parse JSON response: $e');
        return {
          'success': false,
          'message': 'Invalid server response format',
          'error': 'INVALID_JSON',
          'raw_response': res.body.length > 200 ? res.body.substring(0, 200) + '...' : res.body,
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  /// 🔹 TEST ALL ENDPOINTS
  static Future<void> testAllEndpoints(String token) async {
    print('🧪 Testing all API endpoints...');
    
    final endpoints = [
      '$baseUrl/balance/',
      '$baseUrl/recharge/history/',
      '$baseUrl/withdraw/history/',
      '$baseUrl/withdraw-history/',
      '$baseUrl/profile/',
      '$baseUrl/vip-packages/',
    ];
    
    for (final endpoint in endpoints) {
      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: 5));
        
        print('${response.statusCode} - $endpoint');
        if (response.statusCode == 200) {
          print('✅ Working');
        } else {
          print('❌ Failed: ${response.body}');
        }
      } catch (e) {
        print('❌ Error: $endpoint - ${e.toString().split('\n').first}');
      }
    }
  }

  /// 🔹 GET USER INVESTMENTS
  static Future<List<Map<String, dynamic>>> getUserInvestments(String token) async {
    try {
      print('📊 Fetching user investments...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/investments/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      print('📊 Investments Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('📊 Investments Response Body: ${response.body}');
        
        final dynamic data = json.decode(response.body);
        List<Map<String, dynamic>> investments = [];
        
        if (data is Map) {
          if (data['vips'] is List) {
            for (var vip in data['vips']) {
              final vipMap = Map<String, dynamic>.from(vip);
              investments.add({
                'id': vipMap['id'] ?? 0,
                'title': vipMap['title'] ?? 'VIP Package',
                'price': _parseAmount(vipMap['price']),
                'dailyEarnings': _parseAmount(vipMap['daily_income']),
                'validityDays': vipMap['income_days'] ?? 30,
                'totalIncome': _parseAmount(vipMap['total_income'] ?? 
                            ((vipMap['daily_income'] ?? 0) * (vipMap['income_days'] ?? 30))),
                'purchase_date': vipMap['purchase_date']?.toString() ?? '',
                'last_claim_time': vipMap['last_claim_time']?.toString() ?? '',
                'status': _normalizeStatus(vipMap['status']?.toString()),
                'type': 'vip',
                'image': vipMap['image_url'] ?? 'assets/images/vip_1.jpg',
              });
            }
          }
          
          if (data['main_projects'] is List) {
            for (var project in data['main_projects']) {
              final projectMap = Map<String, dynamic>.from(project);
              investments.add({
                'id': projectMap['id'] ?? 0,
                'title': projectMap['title'] ?? 'Main Project',
                'price': _parseAmount(projectMap['price']),
                'daily_income': _parseAmount(projectMap['daily_income']),
                'cycle_days': projectMap['cycle_days'] ?? projectMap['income_days'] ?? 30,
                'total_income': _parseAmount(projectMap['total_income'] ?? 
                            ((projectMap['daily_income'] ?? 0) * (projectMap['cycle_days'] ?? 30))),
                'purchase_date': projectMap['purchase_date']?.toString() ?? '',
                'units': projectMap['units'] ?? 1,
                'available_units': projectMap['available_units'] ?? 0,
                'last_claim_time': projectMap['last_claim_time']?.toString() ?? '',
                'status': _normalizeStatus(projectMap['status']?.toString()),
                'type': 'main_project',
                'image': projectMap['image_url'] ?? 'images/car_1.jpg',
              });
            }
          }
          
          if (investments.isEmpty && data['investments'] is List) {
            investments = List<Map<String, dynamic>>.from(data['investments']);
          }
        }
        
        print('✅ Found ${investments.length} investments');
        return investments;
      } 
      else if (response.statusCode == 401) {
        print('❌ Authentication failed');
        throw Exception('Authentication failed. Please login again.');
      }
      else {
        print('❌ API Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting user investments: $e');
      return [];
    }
  }

  /// 🔹 NORMALIZE STATUS
  static String _normalizeStatus(String? status) {
    if (status == null) return 'active';
    
    status = status.toLowerCase();
    
    if (status == 'complete' || status == 'completed' || status == 'finished' || status == 'ended') {
      return 'completed';
    }
    
    if (status == 'active' || status == 'running' || status == 'ongoing') {
      return 'active';
    }
    
    return 'active';
  }

  /// 🔹 CLAIM INVESTMENT INCOME
  static Future<Map<String, dynamic>> claimInvestmentIncome(String token, int investmentId, String type) async {
    try {
      print('💰 Claiming income for $type ID: $investmentId');
      
      Map<String, dynamic> body;
      String endpoint;
      
      if (type == 'vip') {
        endpoint = '$baseUrl/vip/claim/';
        body = {
          'vip_id': investmentId,
        };
      } else if (type == 'main_project') {
        endpoint = '$baseUrl/main-projects/claim/';
        body = {
          'project_id': investmentId,
        };
      } else {
        throw Exception('Invalid investment type: $type');
      }
      
      print('📤 Sending request to: $endpoint');
      print('📤 Request body: $body');
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      print('💰 Claim Response Status: ${response.statusCode}');
      print('💰 Claim Response Body (RAW): ${response.body}');
      print('💰 Response Body Length: ${response.body.length} chars');
      
      dynamic data;
      try {
        data = json.decode(response.body);
        print('💰 Parsed Response Data: $data');
      } catch (e) {
        print('💰 Failed to parse JSON: $e');
        data = response.body;
      }
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Income claimed successfully',
          'amount': (data['amount'] ?? data['daily_income'] ?? 0).toDouble(),
          'data': data,
        };
      } 
      else if (response.statusCode == 400) {
        print('❌ 400 Error Details:');
        print('   - Body: ${response.body}');
        print('   - Headers: ${response.headers}');
        
        String errorMsg;
        if (data is Map && data.containsKey('error')) {
          errorMsg = data['error'].toString();
        } else if (data is Map && data.containsKey('message')) {
          errorMsg = data['message'].toString();
        } else if (data is String) {
          errorMsg = data;
        } else {
          errorMsg = 'Bad request (400)';
        }
        
        return {
          'success': false,
          'error': errorMsg,
          'code': 'bad_request',
          'raw_response': response.body,
        };
      }
      else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication failed. Please login again.',
          'code': 'auth_failed',
        };
      }
      else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'code': 'server_error',
        };
      }
    } catch (e) {
      print('❌ Network error claiming income: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
        'code': 'network_error',
      };
    }
  }

  /// 🔹 GET ALL INVESTMENTS
  static Future<Map<String, dynamic>> getAllInvestments(String token) async {
    try {
      print('📈 Fetching all investments...');
      
      final availableFuture = getMainProjects(token);
      final purchasedFuture = getUserInvestments(token);
      
      final results = await Future.wait([availableFuture, purchasedFuture], eagerError: true);
      
      return {
        'success': true,
        'available_projects': results[0],
        'purchased_investments': results[1],
      };
    } catch (e) {
      print('❌ Error getting all investments: $e');
      return {
        'success': false,
        'error': e.toString(),
        'available_projects': [],
        'purchased_investments': [],
      };
    }
  }

  // ======================
  // TEAM API METHODS
  // ======================

  /// 🔹 GET TEAM MEMBERS
  static Future<Map<String, dynamic>> getTeamMembers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/team/members/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('👥 Team Members Response Status: ${response.statusCode}');
      print('👥 Team Members Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to load team data. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Team members error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// 🔹 SEND INVITATION
  static Future<Map<String, dynamic>> sendInvitation({
    required String token,
    required String phone,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/team/invite/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'message': message ?? 'Join me on this amazing platform!',
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to send invitation. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// 🔹 GET COMMISSION HISTORY
  static Future<Map<String, dynamic>> getCommissionHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/team/commissions/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to load commission history. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// 🔹 GET TEAM STATS
  static Future<Map<String, dynamic>> getTeamStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/team/stats/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to load team stats. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// 🔹 SHARE REFERRAL LINK
  static Future<Map<String, dynamic>> shareReferralLink(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/team/share/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to generate share content. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// 🔹 CHECK IF RESPONSE IS SUCCESSFUL
  static bool isSuccess(Map<String, dynamic> response) {
    return response['success'] == true;
  }

  /// 🔹 GET ERROR MESSAGE FROM RESPONSE
  static String getErrorMessage(Map<String, dynamic> response) {
    return response['message'] ?? 'An unknown error occurred';
  }
}
