/// FactoryLink API Client — Connects Flutter app to Node.js backend
/// TRD Section 4: All API calls go through this service

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 127.0.0.1 over USB cable (adb reverse tcp:3000 tcp:3000 is active)
  static const String baseUrl = 'http://127.0.0.1:3000/v1'; 
  // static const String baseUrl = 'http://10.0.2.2:3000/v1'; // Android emulator

  String? _token;
  String? _refreshToken;

  // ─── Auth Headers ──────────────────────────────
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ─── Token Management ─────────────────────────
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> saveTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
  }

  bool get isLoggedIn => _token != null;

  // ─── AUTH APIs ─────────────────────────────────

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return jsonDecode(response.body);
  }

  /// Verify OTP and get JWT token
  Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp, String userType) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        'user_type': userType,
      }),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      await saveTokens(data['jwt_token'], data['refresh_token']);
    }
    return data;
  }

  /// Logout
  Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/auth/logout'), headers: _headers);
    await clearTokens();
  }

  // ─── PRODUCT APIs ──────────────────────────────

  /// Get all products with pool progress
  Future<Map<String, dynamic>> getProducts({
    String? category,
    String? search,
    int page = 1,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      if (category != null) 'category': category,
      if (search != null) 'search': search,
    };
    final uri = Uri.parse('$baseUrl/products')
        .replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  /// Get single product detail with price breakdown
  Future<Map<String, dynamic>> getProductDetail(String productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ─── ORDER APIs ────────────────────────────────

  /// Place a new order (joins pool)
  Future<Map<String, dynamic>> placeOrder({
    required String productId,
    required int qty,
    String? anchorPointId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode({
        'product_id': productId,
        'qty': qty,
        if (anchorPointId != null) 'anchor_point_id': anchorPointId,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Get all customer orders
  Future<Map<String, dynamic>> getOrders({String? status}) async {
    final params = <String, String>{
      if (status != null) 'status': status,
    };
    final uri =
        Uri.parse('$baseUrl/orders').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  /// Get single order details
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  /// Collect order (QR scan)
  Future<Map<String, dynamic>> collectOrder(String orderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/collect'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  /// Rate an order
  Future<Map<String, dynamic>> rateOrder(
      String orderId, int stars, String? review) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/rate'),
      headers: _headers,
      body: jsonEncode({
        'stars': stars,
        if (review != null) 'review': review,
      }),
    );
    return jsonDecode(response.body);
  }

  // ─── FACTORY APIs ──────────────────────────────

  /// Register factory
  Future<Map<String, dynamic>> registerFactory(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/factory/register'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  /// Get pending orders for factory
  Future<Map<String, dynamic>> getFactoryPendingOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/factory/orders/pending'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  /// Accept order
  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/factory/orders/$orderId/accept'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  /// Get trust score
  Future<Map<String, dynamic>> getTrustScore() async {
    final response = await http.get(
      Uri.parse('$baseUrl/factory/trust-score'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ─── ZONE APIs ─────────────────────────────────

  /// Get nearby zones and anchor points
  Future<Map<String, dynamic>> getNearbyZones({
    double? lat,
    double? lng,
  }) async {
    final params = <String, String>{
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
    };
    final uri =
        Uri.parse('$baseUrl/zones/nearby').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  // ─── SUBSCRIPTION APIs ─────────────────────────

  /// Create subscription
  Future<Map<String, dynamic>> createSubscription(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }
}

/// Global singleton
final api = ApiService();
