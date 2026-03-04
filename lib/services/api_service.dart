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

  // ─── ORDER LIFECYCLE APIs ─────────────────────
  // Pool Engine: Final payment, factory status updates

  /// Pay remaining 70% balance — TRD C6
  Future<Map<String, dynamic>> payFinalBalance(String orderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/pay-final'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ─── FACTORY MANAGEMENT APIs ──────────────────

  /// Decline order — triggers dual factory backup routing
  Future<Map<String, dynamic>> declineOrder(String orderId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/factory/orders/$orderId/decline'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  /// Update production status: production → ready → dispatched → in_transit
  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/factory/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body);
  }

  /// Update factory availability: full / partial / none
  Future<Map<String, dynamic>> updateFactoryAvailability(
      String availability) async {
    final response = await http.put(
      Uri.parse('$baseUrl/factory/availability'),
      headers: _headers,
      body: jsonEncode({'availability': availability}),
    );
    return jsonDecode(response.body);
  }

  /// Get factory payment history
  Future<Map<String, dynamic>> getFactoryPayments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/factory/payments'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ─── FCM TOKEN APIs ───────────────────────────

  /// Register FCM token for push notifications
  Future<Map<String, dynamic>> registerFcmToken(String fcmToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/fcm-token'),
      headers: _headers,
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    return jsonDecode(response.body);
  }

  /// Refresh expired JWT using refresh token
  Future<Map<String, dynamic>> refreshToken() async {
    if (_refreshToken == null) {
      return {'success': false, 'message': 'No refresh token'};
    }
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': _refreshToken}),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['new_token'] != null) {
      _token = data['new_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
    }
    return data;
  }

  // ─── WALLET APIs ──────────────────────────────

  /// Get wallet balance and recent transactions
  Future<Map<String, dynamic>> getWallet() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  /// Top up wallet
  Future<Map<String, dynamic>> topUpWallet(double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/topup'),
      headers: _headers,
      body: jsonEncode({'amount': amount}),
    );
    return jsonDecode(response.body);
  }

  /// Get wallet transaction history
  Future<Map<String, dynamic>> getWalletTransactions({int page = 1}) async {
    final uri = Uri.parse('$baseUrl/wallet/transactions')
        .replace(queryParameters: {'page': page.toString()});
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  // ─── SUBSCRIPTION MANAGEMENT APIs ─────────────

  /// Get all active subscriptions
  Future<Map<String, dynamic>> getSubscriptions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/subscriptions'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  /// Pause a subscription
  Future<Map<String, dynamic>> pauseSubscription(String subId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/subscriptions/$subId/pause'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  /// Resume a subscription
  Future<Map<String, dynamic>> resumeSubscription(String subId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/subscriptions/$subId/resume'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  /// Cancel a subscription
  Future<Map<String, dynamic>> cancelSubscription(String subId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/subscriptions/$subId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ─── NOTIFICATION APIs ────────────────────────

  /// Get user notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final uri = Uri.parse('$baseUrl/notifications')
        .replace(queryParameters: {'page': page.toString()});
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  /// Mark notification as read
  Future<Map<String, dynamic>> markNotificationRead(String notifId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notifId/read'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ─── PAYMENT (Razorpay) APIs ──────────────────

  /// Create Razorpay order for advance/final payment
  Future<Map<String, dynamic>> createPaymentOrder(
      String orderId, String paymentType) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-order'),
      headers: _headers,
      body: jsonEncode({
        'order_id': orderId,
        'payment_type': paymentType,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Verify advance payment after Razorpay checkout
  Future<Map<String, dynamic>> verifyAdvancePayment({
    required String orderId,
    required String razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify-advance'),
      headers: _headers,
      body: jsonEncode({
        'order_id': orderId,
        'razorpay_payment_id': razorpayPaymentId,
        if (razorpayOrderId != null) 'razorpay_order_id': razorpayOrderId,
        if (razorpaySignature != null) 'razorpay_signature': razorpaySignature,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Verify final payment
  Future<Map<String, dynamic>> verifyFinalPayment({
    required String orderId,
    required String razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify-final'),
      headers: _headers,
      body: jsonEncode({
        'order_id': orderId,
        'razorpay_payment_id': razorpayPaymentId,
        if (razorpayOrderId != null) 'razorpay_order_id': razorpayOrderId,
        if (razorpaySignature != null) 'razorpay_signature': razorpaySignature,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Create Razorpay order for wallet top-up
  Future<Map<String, dynamic>> createTopUpOrder(double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-topup'),
      headers: _headers,
      body: jsonEncode({'amount': amount}),
    );
    return jsonDecode(response.body);
  }
}

/// Global singleton
final api = ApiService();
