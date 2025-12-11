import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔧 YAHA APNA BACKEND URL DALO
  static const String baseUrl = 'https://fastapi-app-130321581049.asia-south1.run.app';  // Local testing
  // Production: 'https://your-domain.com'

  static const String fcmEndpoint = '/fcm';

  // ============================================================================
  // Token Management
  // ============================================================================

  /// Register FCM token with backend
  static Future<Map<String, dynamic>> registerToken({
    required String token,
    String? userId,
    String deviceType = 'web',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$fcmEndpoint/token/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'user_id': userId,
          'device_type': deviceType,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Token registered with backend');
        return jsonDecode(response.body);
      } else {
        print('❌ Token registration failed: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to register token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registering token: $e');
      rethrow;
    }
  }

  /// Unregister FCM token from backend
  static Future<bool> unregisterToken(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$fcmEndpoint/token/unregister/$token'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error unregistering token: $e');
      return false;
    }
  }

  /// Get all registered tokens (for testing)
  static Future<Map<String, dynamic>> getAllTokens() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$fcmEndpoint/tokens'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get tokens');
    } catch (e) {
      print('❌ Error getting tokens: $e');
      rethrow;
    }
  }

  // ============================================================================
  // Send Notifications (for testing)
  // ============================================================================

  /// Send test notification to self
  static Future<Map<String, dynamic>> sendTestNotification({
    required String token,
    required String title,
    required String body,
    String route = '/page1',
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$fcmEndpoint/notification/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'route': route,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Test notification sent');
        return jsonDecode(response.body);
      } else {
        print('❌ Failed to send notification: ${response.statusCode}');
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      rethrow;
    }
  }

  /// Send notification to multiple users
  static Future<Map<String, dynamic>> sendBulkNotification({
    required List<String> tokens,
    required String title,
    required String body,
    String route = '/page1',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$fcmEndpoint/notification/send-bulk'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tokens': tokens,
          'title': title,
          'body': body,
          'route': route,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Bulk notification failed');
    } catch (e) {
      print('❌ Error sending bulk notification: $e');
      rethrow;
    }
  }

  // ============================================================================
  // Health Check
  // ============================================================================

  /// Check if backend is running
  static Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$fcmEndpoint/health'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ Backend is healthy');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Backend health check failed: $e');
      return false;
    }
  }

  // ============================================================================
  // Webhook Simulation (for testing)
  // ============================================================================

  /// Simulate webhook event
  static Future<void> triggerWebhook({
    required String eventType,
    required List<String> userTokens,
    required String title,
    required String body,
    required String route,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$fcmEndpoint/webhook/notify'),
        headers: {
          'Content-Type': 'application/json',
          'x-webhook-secret': 'your_secret_key_here', // Optional
        },
        body: jsonEncode({
          'event_type': eventType,
          'user_tokens': userTokens,
          'title': title,
          'body': body,
          'route': route,
          'priority': 'high',
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Webhook triggered successfully');
      } else {
        print('❌ Webhook failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Webhook error: $e');
    }
  }
}