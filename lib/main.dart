import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import 'firebase_options.dart';
import 'dart:html' as html;

import 'notification_service.dart';


// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Web Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/page1': (context) => const Page1(),
        '/page2': (context) => const Page2(),
        '/page3': (context) => const Page3(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  String? _fcmToken;
  List<RemoteMessage> _messages = [];
  bool _backendConnected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    setState(() => _isLoading = true);

    _backendConnected = await ApiService.checkBackendHealth();
    await _notificationService.initialize();

    final token = await _notificationService.getAndRegisterToken(
      userId: 'user_123',
    );

    setState(() {
      _fcmToken = token;
      _isLoading = false;
    });

    print('🔔 Setting up message listeners...');

    // Listen to foreground messages (data-only format)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('========================================');
      print('📬 FOREGROUND MESSAGE');
      print('Data: ${message.data}');
      print('========================================');

      // Extract from data (backend sends data-only now)
      final title = message.data['title'] ?? 'New Message';
      final body = message.data['body'] ?? '';
      final route = message.data['route'] ?? '/';

      // Add to list
      setState(() {
        _messages.insert(0, message);
      });

      // Show SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, route),
            ),
          ),
        );
      }
    });

    // CRITICAL: Listen to service worker messages too!
    if (kIsWeb) {
      print('🌐 Setting up service worker message listener...');

      html.window.addEventListener('message', (html.Event event) {
        final messageEvent = event as html.MessageEvent;
        final data = messageEvent.data;

        if (data is Map && data['type'] == 'FCM_MESSAGE') {
          print('========================================');
          print('📬 MESSAGE FROM SERVICE WORKER');
          print('Data: ${data['data']}');
          print('========================================');

          final fcmData = data['data'] as Map<String, dynamic>;
          final title = fcmData['title']?.toString() ?? 'New Message';
          final body = fcmData['body']?.toString() ?? '';
          final route = fcmData['route']?.toString() ?? '/';

          // Create RemoteMessage-like object
          final fakeMessage = RemoteMessage(
            data: Map<String, String>.from(fcmData),
            messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          );

          // Add to list
          if (mounted) {
            setState(() {
              _messages.insert(0, fakeMessage);
            });

            // Show SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(body),
                  ],
                ),
                backgroundColor: Colors.deepPurple,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () => Navigator.pushNamed(context, route),
                ),
              ),
            );
          }
        } else if (data is Map && data['type'] == 'NOTIFICATION_CLICK') {
          print('🖱️ Notification click from SW');
          final route = data['route']?.toString() ?? '/';
          Navigator.pushNamed(context, route);
        }
      });
    }

    // Handle notification click (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🖱️ Notification clicked!');
      _handleNotificationClick(message);
    });

    // Check initial message
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🚀 App opened from notification');
        _handleNotificationClick(message);
      }
    });

    print('✅ FCM setup complete');
  }

  void _showInAppNotification(String title, String body, String route, Map<String, dynamic> data) {
    if (!mounted) return;

    // Extract custom options from data
    final priority = data['priority'] ?? 'normal';
    final icon = data['icon'] ?? '🔔';

    // Customize based on priority
    Color backgroundColor;
    IconData leadingIcon;

    switch (priority) {
      case 'high':
        backgroundColor = Colors.red.shade700;
        leadingIcon = Icons.priority_high;
        break;
      case 'urgent':
        backgroundColor = Colors.orange.shade700;
        leadingIcon = Icons.warning_amber_rounded;
        break;
      default:
        backgroundColor = Colors.deepPurple;
        leadingIcon = Icons.notifications_active;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                leadingIcon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, route),
        ),
      ),
    );
  }

  void _handleNotificationClick(RemoteMessage message) {
    if (message.data.containsKey('route')) {
      final route = message.data['route'];
      Navigator.pushNamed(context, route);
    }
  }

  void _copyToken() {
    if (_fcmToken != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('FCM Token'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                _fcmToken!,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              Text(
                'Backend: ${_backendConnected ? "✅ Connected" : "❌ Disconnected"}',
                style: TextStyle(
                  color: _backendConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  // Send test notification to self
  Future<void> _sendTestNotification() async {
    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No FCM token available')),
      );
      return;
    }

    try {
      await ApiService.sendTestNotification(
        token: _fcmToken!,
        title: 'Test Notification 🧪',
        body: 'This is a test from Flutter app!',
        route: '/page1',
        data: {'test': 'true', 'timestamp': DateTime.now().toString()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test notification!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('🔔 FCM Web Demo'),
        centerTitle: true,
        actions: [
          // Backend status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _backendConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _backendConnected ? 'Backend ✅' : 'Backend ❌',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Backend Status Card
            Card(
              color: _backendConnected ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _backendConnected ? Icons.check_circle : Icons.error,
                          color: _backendConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _backendConnected
                              ? 'Backend Connected'
                              : 'Backend Disconnected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _backendConnected ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _backendConnected
                          ? 'Backend is running on ${ApiService.baseUrl}'
                          : 'Make sure backend is running: uvicorn main:app --reload',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FCM Token Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.vpn_key, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'FCM Token:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_fcmToken != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _fcmToken!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _copyToken,
                              icon: const Icon(Icons.copy),
                              label: const Text('View Token'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sendTestNotification,
                              icon: const Icon(Icons.send),
                              label: const Text('Test Notify'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Navigation Pages
            const Text(
              'Navigation Pages (Deep Linking):',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/page1'),
              icon: const Icon(Icons.looks_one),
              label: const Text('Go to Page 1'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/page2'),
              icon: const Icon(Icons.looks_two),
              label: const Text('Go to Page 2'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/page3'),
              icon: const Icon(Icons.looks_3),
              label: const Text('Go to Page 3'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Received Messages
            const Text(
              'Received Messages:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_messages.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No messages yet\n\nClick "Test Notify" button to send a test notification!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ..._messages.map((message) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.notifications),
                  ),
                  title: Text(
                    message.notification?.title ?? 'No Title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.notification?.body ?? 'No Body'),
                      if (message.data.isNotEmpty)
                        Text(
                          'Data: ${message.data}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: Text(
                    DateTime.now().toString().substring(11, 19),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// Page 1, 2, 3 same as before...
class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page 1'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.looks_one, size: 100, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'This is Page 1',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Opened via deep link: /page1'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page 2'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.looks_two, size: 100, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'This is Page 2',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Opened via deep link: /page2'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page 3'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.looks_3, size: 100, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'This is Page 3',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Opened via deep link: /page3'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}