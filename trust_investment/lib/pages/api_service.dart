import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.164.10.181:8000/api";

  /// 🔹 SIGNUP
  static Future<Map<String, dynamic>> signup(
      String username, String email, String password, String phone, String? refcode) async {
    final url = Uri.parse('$baseUrl/signup/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "phone": phone,
        "refcode": refcode,
      }),
    );
    return jsonDecode(response.body);
  }

  /// 🔹 VERIFY OTP
  static Future<Map<String, dynamic>> verifyOtp(String username, String otp) async {
    final url = Uri.parse('$baseUrl/verify-otp/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": username,
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
/// 🔹 GET WITHDRAW HISTORY
static Future<List<Map<String, dynamic>>> getWithdrawHistory(String token) async {
  // You already have getWithdrawals, but we can alias it
  return await getWithdrawals(token);
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

  /// 🔹 LOGIN — returns user token
  static Future<String?> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/auth/login/");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['token'] as String?;
      }
      print("❌ Login failed (${res.statusCode}): ${res.body}");
      return null;
    } catch (e) {
      print("⚠️ Network error during login: $e");
      return null;
    }
  }


  /// 🔹 PROFILE + BALANCE
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final profileUrl = Uri.parse("$baseUrl/profile/");
    final balanceUrl = Uri.parse("$baseUrl/balance/");
    try {
      final responses = await Future.wait([
        http.get(profileUrl, headers: {"Authorization": "Token $token", "Content-Type": "application/json"}),
        http.get(balanceUrl, headers: {"Authorization": "Token $token", "Content-Type": "application/json"}),
      ]);

      final profileRes = responses[0];
      final balanceRes = responses[1];

      if (profileRes.statusCode == 200 && balanceRes.statusCode == 200) {
        final profileData = jsonDecode(profileRes.body);
        final balanceData = jsonDecode(balanceRes.body);
        return {
          ...profileData,
          'balance': balanceData['balance'] ?? 0,
          'available_balance': balanceData['available_balance'] ?? 0,
          'frozen_balance': balanceData['frozen_balance'] ?? 0,
        };
      }
      throw Exception(
        "Failed to fetch profile (${profileRes.statusCode}) or balance (${balanceRes.statusCode})",
      );
    } catch (e) {
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

  /// 🔹 WITHDRAWALS
  static Future<List<Map<String, dynamic>>> getWithdrawals(String token) async {
    final url = Uri.parse("$baseUrl/withdraw_history/");
    final res = await http.get(url, headers: {"Authorization": "Token $token"});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception("Failed to fetch withdrawals (${res.statusCode})");
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
  static Future<bool> updateAccountNumber({required String token, required String newAccountNumber}) async {
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
 
  /// 🔹 FETCH CHAT HISTORY
  static Future<List<Map<String, dynamic>>> fetchChatHistory({required String token}) async {
    final url = Uri.parse("$baseUrl/chat/");
    final res = await http.get(
      url,
      headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map<Map<String, dynamic>>((e) => {
        "sender": e['sender'],
        "message": e['message'],
      }).toList();
    } else {
      return [];
    }
  }

  /// 🔹 SEND / SAVE CHAT MESSAGE
  static Future<Map<String, dynamic>> sendMessage({required String token, required String message, required String sender}) async {
    final url = Uri.parse("$baseUrl/chat/save/");
    final res = await http.post(
      url,
      headers: {"Authorization": "Token $token", "Content-Type": "application/json"},
      body: jsonEncode({"message": message, "sender": sender}),
    );

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } else {
      return {
        "success": false,
        "message": jsonDecode(res.body)["message"] ?? "Failed to send message",
      };
    }
  }
}

