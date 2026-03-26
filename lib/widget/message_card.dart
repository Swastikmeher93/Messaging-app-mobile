import 'package:flutter/material.dart';

class MessageCard extends StatelessWidget {
  final String message;
  final bool isSender;
  final String? date;

  const MessageCard({
    super.key,
    required this.message,
    this.isSender = false,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSender
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (date != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                date!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.5,
            ),
            child: Container(
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isSender ? Colors.blue[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(message, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
