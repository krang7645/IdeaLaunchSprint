// services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final supabase = Supabase.instance.client;

  // Stream controller for handling notification click events
  final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  // Initialization
  Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS foreground notification
      },
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        selectNotificationStream.add(response.payload);
      },
    );

    // Initialize Firebase Messaging
    await _initFirebaseMessaging();

    // Set up listener for Supabase notifications
    _setupSupabaseNotificationListener();
  }

  // Firebase Messaging initialization
  Future<void> _initFirebaseMessaging() async {
    // Request permission for iOS
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      // Save token to Supabase
      await _saveDeviceToken(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveDeviceToken);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'LaunchPad Notification',
        body: message.notification?.body ?? '',
        payload: message.data['ideaId'],
      );
    });

    // Handle notification click when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      selectNotificationStream.add(message.data['ideaId']);
    });

    // Check for initial message (app opened from terminated state)
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(seconds: 1), () {
        selectNotificationStream.add(initialMessage.data['ideaId']);
      });
    }
  }

  // Save FCM token to Supabase
  Future<void> _saveDeviceToken(String token) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.from('devices').upsert({
        'user_id': user.id,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Setup Supabase realtime notifications
  void _setupSupabaseNotificationListener() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .eq('read', false)
          .listen((notifications) {
            for (final notification in notifications) {
              _showNotification(
                id: notification['id'].hashCode,
                title: 'LaunchPad Notification',
                body: notification['message'],
                payload: notification['idea_id'],
              );
              
              // Mark as delivered
              supabase
                  .from('notifications')
                  .update({'delivered': true})
                  .eq('id', notification['id']);
            }
          });
    }
  }

  // Show local notification
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'launchpad_channel',
      'LaunchPad Notifications',
      channelDescription: 'Notifications from LaunchPad Notebook',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Schedule a local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'launchpad_channel',
          'LaunchPad Notifications',
          channelDescription: 'Notifications from LaunchPad Notebook',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get unread notifications from Supabase
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('read', false)
          .order('created_at', ascending: false);
      return response;
    }
    return [];
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('user_id', user.id)
          .eq('read', false);
    }
  }

  // Schedule idea expiration notification
  Future<void> scheduleIdeaExpirationReminders(
      String ideaId, String ideaTitle, DateTime expireAt) async {
    // Schedule 24 hours before expiration
    final oneDayBefore = expireAt.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: ideaId.hashCode + 1,
        title: 'Idea Expiring Soon',
        body: '"$ideaTitle" will expire in 24 hours. Take action to extend it!',
        scheduledDate: oneDayBefore,
        payload: ideaId,
      );
    }

    // Schedule 1 hour before expiration
    final oneHourBefore = expireAt.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: ideaId.hashCode + 2,
        title: 'Urgent: Idea Expiring Soon',
        body: '"$ideaTitle" will expire in 1 hour. Take action now!',
        scheduledDate: oneHourBefore,
        payload: ideaId,
      );
    }
  }

  // Dispose
  void dispose() {
    selectNotificationStream.close();
  }
}

// Firebase Messaging background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This function will be called when the app is in the background or terminated
  await Firebase.initializeApp();
}

// screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/notification_service.dart';
import '../utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getUnreadNotifications();
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.markAllNotificationsAsRead();
      setState(() {
        _notifications = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notifications as read: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No new notifications',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Dismissible(
            key: Key(notification['id']),
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(
                Icons.done,
                color: Colors.white,
              ),
            ),
            secondaryBackground: Container(
              color: AppConstants.dangerColor,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            confirmDismiss: (direction) async {
              return true; // Allow dismissal in both directions
            },
            onDismissed: (direction) {
              _markAsRead(notification['id']);
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppConstants.primaryColor,
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                ),
              ),
              title: Text(
                notification['message'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                timeago.format(DateTime.parse(notification['created_at'])),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              onTap: () {
                // Navigate to the idea if available
                if (notification['idea_id'] != null) {
                  // Navigate to idea details
                  // TODO: Implement navigation to idea details
                }
                _markAsRead(notification['id']);
              },
            ),
          );
        },
      ),
    );
  }
}