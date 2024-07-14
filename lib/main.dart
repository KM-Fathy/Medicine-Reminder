import 'package:flutter/material.dart';
import 'Notification/flutter_local_notifications.dart';
import 'pages/home_page.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Future.wait([
    requestNotificationPermission(),
    LocalNotificationService.init(),
  ]);
  runApp(const MyApp());
}

Future<void> requestNotificationPermission() async {
  await Permission.notification.request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            timePickerTheme: const TimePickerThemeData(
                dayPeriodBorderSide:
                    BorderSide(color: Colors.white, width: 0.5),
                backgroundColor: Color(0xff201f1d),
                elevation: 0,
                dayPeriodTextColor: Colors.white,
                dialBackgroundColor: Color(0xff282724),
                dialTextColor: Colors.white,
                helpTextStyle: TextStyle(color: Colors.white),
                entryModeIconColor: Colors.white),
            colorScheme:
                ColorScheme.fromSwatch(primarySwatch: Colors.lightGreen)
                    .copyWith(secondary: Colors.lightGreenAccent)),
        home: const HomePage());
  }
}



