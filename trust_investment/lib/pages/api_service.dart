import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.164.11.61:8000/api";

  // 🔹 HELPER: Get auth headers with "Token " prefix
  static Map<String, String> _authHeader(String token) {
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // 🔹 HELPER: Get auth headers without "Token " prefix
  static Map<String, String> _authHeaderWithoutType(String token) {
    return {
      'Authorization': token, // Just the token without "Token " prefix
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Helper to parse amount from dynamic value
  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove currency symbols and parse
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    
    return 0.0;
  }

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
    final url = Uri.parse("$baseUrl/invite/referrals/"); // adjust to your backend endpoint
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
  
  /// 🔹 GET RECHARGE (DEPOSIT) HISTORY - FIXED VERSION
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
        
        // Handle different response formats
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          // Check common response structures
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
    final url = Uri.parse("$baseUrl/aviator/history/"); // Adjust endpoint if needed
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
    
    // Validate that at least one identifier is provided
    if (username == null && email == null && phone == null) {
      throw Exception('At least one of username, email, or phone is required');
    }
    
    // If no username provided, generate one
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
  
  /// 🔹 GET BALANCE - COMPLETE FIXED VERSION
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
        
        // Handle different response formats
        if (data is Map) {
          return {
            'success': true,
            'total': _parseAmount(data['balance'] ?? data['total_balance'] ?? data['total'] ?? 0),
            'available': _parseAmount(data['available_balance'] ?? data['available'] ?? data['avail_balance'] ?? 0),
            'frozen': _parseAmount(data['frozen_balance'] ?? data['frozen'] ?? data['locked_balance'] ?? 0),
            'raw': data,
          };
        } else if (data is num) {
          // If API returns just a number
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
  
  /// 🔹 PROFILE + BALANCE (Alternative method)
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
        // Try to get at least one
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

  /// 🔹 GET WITHDRAWALS - COMPLETE FIXED VERSION
  static Future<List<Map<String, dynamic>>> getWithdrawals(String token) async {
    try {
      print('📤 Fetching withdrawal history...');
      
      // Try multiple possible endpoints
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
            
            // Handle different response formats
            if (data is List) {
              print('✅ Found ${data.length} withdrawals (list format)');
              return List<Map<String, dynamic>>.from(data);
            } else if (data is Map) {
              // Check common response structures
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
            continue; // Try next endpoint
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
  static Future<bool> accountnumberUpdate({required String token, required String newAccountNumber}) async {
    final url = Uri.parse("$baseUrl/account_number/update/");
    final res = await http.post(
      url,
      headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
      body: jsonEncode({"account_number": newAccountNumber}),
    );
    return res.statusCode == 200;
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
  
  // 🔹 CHANGE WITHDRAW PASSWORD
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
  
  // 🔹 SEND / SAVE CHAT MESSAGE
  static Future<Map<String, dynamic>> sendMessage({required String token, required String message, required String sender}) async {
    try {
      final url = Uri.parse("$baseUrl/chat/save/");
      print('📨 Sending chat message to: $url');
      print('📨 Message: $message');
      
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
        return {
          "success": true,
          "message": "Message sent successfully",
        };
      } else if (res.statusCode == 400) {
        // Try alternative field names
        final Map<String, Map<String, dynamic>> attempts = {
          'message': {"message": message},
          'text': {"text": message},
          'content_with_sender': {"content": message, "sender": sender},
        };
        
        for (final entry in attempts.entries) {
          print('🔄 Trying with: ${entry.key}');
          final res2 = await http.post(
            url,
            headers: {
              "Authorization": "Token $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode(entry.value),
          );
          
          if (res2.statusCode == 200 || res2.statusCode == 201) {
            return {
              "success": true,
              "message": "Message sent",
            };
          }
        }
        
        return {
          "success": false,
          "message": "Bad request: ${res.body}",
        };
      } else {
        return {
          "success": false,
          "message": "Failed to send message: ${res.statusCode}",
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

  // 🔹 FETCH CHAT HISTORY
  static Future<List<Map<String, dynamic>>> fetchChatHistory({required String token}) async {
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
        print('📨 Chat History Response Body: ${res.body}');
        
        try {
          final dynamic data = jsonDecode(res.body);
          
          // Handle different response formats
          if (data is List) {
            print('✅ Found ${data.length} chat messages');
            return _parseChatMessages(data);
          } else if (data is Map) {
            // Check for common response structures
            if (data.containsKey('messages') && data['messages'] is List) {
              return _parseChatMessages(data['messages']);
            } else if (data.containsKey('results') && data['results'] is List) {
              return _parseChatMessages(data['results']);
            } else if (data.containsKey('data') && data['data'] is List) {
              return _parseChatMessages(data['data']);
            } else {
              // Assume it's a single message or empty
              return _parseChatMessages([data]);
            }
          }
        } catch (e) {
          print('❌ Error parsing chat history: $e');
          // Try parsing as plain text
          if (res.body.isNotEmpty) {
            return [{
              "content": "Raw response: ${res.body}",
              "sender": "system",
              "timestamp": DateTime.now().toIso8601String(),
            }];
          }
        }
      } else if (res.statusCode == 404) {
        print('❌ Chat endpoint not found (404). Checking /api/chat/save/ for GET...');
        
        // Try /api/chat/save/ with GET method (some APIs use same endpoint for both)
        final url2 = Uri.parse("$baseUrl/chat/save/");
        final res2 = await http.get(
          url2,
          headers: {
            "Authorization": "Token $token",
            "Content-Type": "application/json",
          },
        );
        
        if (res2.statusCode == 200) {
          return _parseChatMessages(jsonDecode(res2.body));
        }
      }
      
      print('⚠️ No chat history available');
      return [];
    } catch (e) {
      print('❌ Chat history fetch error: $e');
      return [];
    }
  }

  // Helper to parse chat messages
  static List<Map<String, dynamic>> _parseChatMessages(List<dynamic> messages) {
    return messages.map<Map<String, dynamic>>((item) {
      if (item is Map) {
        // Extract fields with fallbacks
        final content = item['content']?.toString() ?? 
                       item['message']?.toString() ?? 
                       item['text']?.toString() ?? '';
        
        final sender = item['sender']?.toString() ?? 
                      (item['is_support'] == true ? 'support' : 'user') ??
                      'user';
        
        final timestamp = item['timestamp']?.toString() ?? 
                         item['created_at']?.toString() ?? 
                         item['date']?.toString() ?? 
                         DateTime.now().toIso8601String();
        
        return {
          "id": item['id']?.toString(),
          "content": content,
          "sender": sender,
          "timestamp": timestamp,
          "is_support": item['is_support'] ?? sender == 'support',
        };
      }
      
      // Fallback for non-map items
      return {
        "content": item.toString(),
        "sender": "system",
        "timestamp": DateTime.now().toIso8601String(),
        "is_support": false,
      };
    }).toList();
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
        
        // Handle other response formats
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
    final url = Uri.parse("$baseUrl/main-projects/invest/");
    final res = await http.post(
      url,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        'project_id': projectId,
        'units': units,
      }),
    );
  
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? "Investment failed");
    }
  }

  static Future<Map<String, dynamic>> submitPaymentProof({
    required String token,
    required String transactionId,
    required String referenceNumber,
    String? imagePath,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/recharge/submit-proof/');
      
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Token $token';
      
      // Add fields
      request.fields['transaction_id'] = transactionId;
      request.fields['reference_number'] = referenceNumber;
      
      // Add image if provided
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'payment_proof',
          imagePath,
        ));
      }
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Payment proof submitted successfully',
          'recharge_id': data['recharge_id'],
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'error': data['error'] ?? data['message'] ?? 'Failed to submit proof',
        };
      } else {
        throw Exception('Failed to submit proof: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting payment proof: $e');
    }
  }
  
  /// 🔹 TEST ALL ENDPOINTS (For debugging)
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
}