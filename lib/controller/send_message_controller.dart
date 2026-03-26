import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

class SendMessageController {
  final Telephony telephony = Telephony.instance;

  /// Sends an SMS immediately using the native Android Telephony manager.
  /// Returns a map representing the optimistically sent message, which can
  /// be injected into the UI thread immediately.
  /// Resolves the 'fromMap' member visibility warning from `Telephony`.
  Future<Map<String, dynamic>?> sendSms({
    required BuildContext context,
    required String recipient,
    required String message,
  }) async {
    final body = message.trim();
    if (body.isEmpty || recipient.isEmpty) return null;

    try {
      await telephony.sendSms(to: recipient, message: body);

      return {
        'address': recipient,
        'body': body,
        'date': DateTime.now().millisecondsSinceEpoch,
        // Represents SmsType.MESSAGE_TYPE_SENT
        'type': '2',
      };
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send SMS: $e')));
      }
      return null;
    }
  }
}
