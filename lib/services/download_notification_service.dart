import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadNotificationService {
  static final DownloadNotificationService _instance =
      DownloadNotificationService._internal();
  factory DownloadNotificationService() => _instance;
  DownloadNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) return;

    try {
      // 1. Minta izin notifikasi runtime di Android 13+ (API 33+)
      if (Platform.isAndroid) {
        try {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            await Permission.notification.request();
          }
        } catch (e) {
          debugPrint('Izin notifikasi via permission_handler: $e');
        }
      }

      // 2. Inisialisasi flutter_local_notifications dengan drawable valid
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/ic_launcher_foreground');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Gagal inisialisasi DownloadNotificationService: $e');
    }
  }

  /// Menampilkan notifikasi di status bar HP saat proses penyimpanan/unduhan sedang berjalan
  Future<void> showDownloadStart({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await initialize();

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'download_channel_progress',
        'Proses Unduhan FitLife',
        channelDescription: 'Status proses penyimpanan file FitLife',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        indeterminate: true,
        icon: '@drawable/ic_launcher_foreground',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('Error showDownloadStart: $e');
    }
  }

  /// Menampilkan notifikasi di status bar HP saat proses unduh/simpan selesai berhasil
  Future<void> showDownloadComplete({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    await initialize();

    try {
      // Bersihkan notifikasi progress
      await _notificationsPlugin.cancel(id);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'download_channel_completed',
        'Unduhan Selesai FitLife',
        channelDescription: 'Notifikasi saat file berhasil disimpan ke perangkat',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        icon: '@drawable/ic_launcher_foreground',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error showDownloadComplete: $e');
    }
  }

  /// Menampilkan notifikasi di status bar HP jika proses unduh gagal
  Future<void> showDownloadFailed({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await initialize();

    try {
      await _notificationsPlugin.cancel(id);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'download_channel_failed',
        'Unduhan Gagal FitLife',
        channelDescription: 'Notifikasi saat unduhan file gagal',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        icon: '@drawable/ic_launcher_foreground',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('Error showDownloadFailed: $e');
    }
  }
}
