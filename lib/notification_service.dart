import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show window;
import 'dart:js' as js;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _currentToken;

  Future<void> initialize() async {
    print('🔔 Initializing Notification Service...');

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('✅ Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
      await getAndRegisterToken();
    }
  }

  Future<String?> getToken() async {
    try {
      print('🔑 Getting FCM token...');

      if (kIsWeb) {
        // On web, check if Firebase Messaging is already initialized in HTML
        try {
          // Wait a bit for service worker to be fully ready
          await Future.delayed(const Duration(seconds: 1));

          print('🌐 Using pre-initialized Firebase Messaging');
          final token = await _firebaseMessaging.getToken();

          _currentToken = token;
          if (token != null) {
            print('✅ FCM Token: ${token.substring(0, 20)}...');
          }
          return token;
        } catch (e) {
          print('⚠️ Web token error: $e');
          // Fallback: try with longer wait
          await Future.delayed(const Duration(seconds: 2));
          final token = await _firebaseMessaging.getToken();
          _currentToken = token;
          return token;
        }
      } else {
        // Mobile
        final token = await _firebaseMessaging.getToken(
          vapidKey: 'BKWZ1OVQMCWrCdwKJBK5k1av_AjwtwKr-1Xnkn9yJID7Y9G9CSefNMfF0CrVPLdZlwNGB3h8Io5B6dZ2lmccBSg',        );
        _currentToken = token;
        return token;
      }
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  Future<String?> getAndRegisterToken({String? userId}) async {
    try {
      final token = await getToken();

      if (token != null) {
        print('📡 Registering with backend...');

        try {
          await ApiService.registerToken(
            token: token,
            userId: userId,
            deviceType: 'web',
          );
          print('✅ Registered with backend');
        } catch (e) {
          print('⚠️ Backend registration failed: $e');
        }

        return token;
      }

      return null;
    } catch (e) {
      print('❌ Error in getAndRegisterToken: $e');
      return null;
    }
  }

  Future<void> unregisterToken() async {
    if (_currentToken != null) {
      await ApiService.unregisterToken(_currentToken!);
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Subscribed to: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  String? get currentToken => _currentToken;
}

