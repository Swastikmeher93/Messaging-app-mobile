import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:intl/intl.dart';
import 'package:sms_app/widget/message_card.dart';
import 'package:sms_app/controller/send_message_controller.dart';

class HomedetailsView extends StatefulWidget {
  final String sender;
  final List<SmsMessage> messages;

  const HomedetailsView({
    super.key,
    required this.sender,
    required this.messages,
  });

  @override
  State<HomedetailsView> createState() => _HomedetailsViewState();
}

class _HomedetailsViewState extends State<HomedetailsView> {
  final TextEditingController _messageController = TextEditingController();
  final SendMessageController _messageControllerAPI = SendMessageController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var now = DateTime.now();
    var timeFormat = DateFormat('h:mm a');

    // Create dates stripped of time to compare full days
    var today = DateTime(now.year, now.month, now.day);
    var messageDate = DateTime(date.year, date.month, date.day);

    var difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      return "Today, ${timeFormat.format(date)}";
    } else if (difference == 1) {
      return "Yesterday, ${timeFormat.format(date)}";
    } else if (difference >= 2 && difference < 7) {
      return "${DateFormat('EEEE').format(date)}, ${timeFormat.format(date)}";
    } else {
      return "${DateFormat('MMM d').format(date)}, ${timeFormat.format(date)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reverse the list to show newest messages at the bottom
    final chatMessages = widget.messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sender),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = chatMessages[index];
                  return MessageCard(
                    message: msg.body ?? '',
                    isSender: msg.type == SmsType.MESSAGE_TYPE_SENT,
                    date: _formatTimestamp(msg.date),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Text message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () async {
                        final body = _messageController.text.trim();
                        if (body.isEmpty) return;

                        final status = await _messageControllerAPI.sendSms(
                          context: context,
                          recipient: widget.sender,
                          message: body,
                        );

                        if (status != null) {
                          _messageController.clear();

                          // To update the UI safely with restricted `SmsMessage` models,
                          // we query the native telephony database again for the newly pushed record.
                          final sentMessages = await Telephony.instance
                              .getSentSms(
                                columns: [
                                  SmsColumn.ADDRESS,
                                  SmsColumn.BODY,
                                  SmsColumn.DATE,
                                  SmsColumn.TYPE,
                                ],
                              );

                          if (sentMessages.isNotEmpty) {
                            setState(() {
                              widget.messages.insert(0, sentMessages.first);
                            });
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
