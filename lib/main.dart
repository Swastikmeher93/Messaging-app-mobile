import 'package:flutter/material.dart';
import 'package:sms_app/view/homeview.dart';
import 'package:telephony/telephony.dart';

// Top-level function for background SMS handling
@pragma('vm:entry-point')
backgroundMessageHandler(SmsMessage message) async {
  // Handle background message here
  // For example, you can show a local notification or save it to a local DB.
  print("Background message received: ${message.body}");
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}
