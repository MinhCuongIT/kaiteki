import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kaiteki/app.dart';
import 'package:kaiteki/repositories/account_secret_repository.dart';
import 'package:kaiteki/repositories/client_secret_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kaiteki/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // we need to run this to be able to get access to SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  var preferences = await SharedPreferences.getInstance();

  // fetch async resources e.g. user data
  AccountSecretRepository accountRepository;
  ClientSecretRepository clientRepository;

  try {
    accountRepository = await AccountSecretRepository.getInstance(preferences);
    clientRepository = await ClientSecretRepository.getInstance(preferences);
  } catch (ex) {
    print("Failed to create instances of save data repositories. $ex");
  }

  FlutterLocalNotificationsPlugin notificationsPlugin;

  try {
    notificationsPlugin = await initializeNotifications();
  } catch (e) {
    Logger.exception(message: "Failed to initialize notifications");
  }

  // construct app
  var app = KaitekiApp(
    accountSecrets: accountRepository,
    clientSecrets: clientRepository,
    notifications: notificationsPlugin,
    preferences: preferences,
  );

  // run.
  runApp(app);
}

Future<FlutterLocalNotificationsPlugin> initializeNotifications() async {
  if (kIsWeb) return null;

  var plugin = FlutterLocalNotificationsPlugin();
  var initSettings = InitializationSettings(
    android: AndroidInitializationSettings("@mipmap/ic_kaiteki"),
    iOS: IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    ),
  );

  await plugin.initialize(initSettings);

  return plugin;
}
