import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:sms_app/view/homedetails_view.dart';
import 'package:sms_app/controller/send_message_controller.dart';

class SendMessageView extends StatefulWidget {
  const SendMessageView({super.key});

  @override
  State<SendMessageView> createState() => _SendMessageViewState();
}

class _SendMessageViewState extends State<SendMessageView> {
  List<Contact>? _contacts;
  List<Contact> _filteredContacts = [];
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final SendMessageController _messageControllerAPI = SendMessageController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (await FlutterContacts.requestPermission(readonly: true)) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() => _contacts = contacts);
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'New message',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Row(
              children: [
                const Text(
                  'To: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _recipientController,
                    decoration: const InputDecoration(
                      hintText: 'Type a name, phone number, or email',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (_contacts == null) return;
                      setState(() {
                        if (value.isEmpty) {
                          _filteredContacts = [];
                        } else {
                          final query = value.toLowerCase();
                          _filteredContacts = _contacts!.where((contact) {
                            return contact.displayName.toLowerCase().contains(
                              query,
                            );
                          }).toList();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable contacts area could be optionally restored here
          Expanded(
            child: _filteredContacts.isNotEmpty
                ? ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final phones = contact.phones;
                      if (phones.isEmpty) return const SizedBox.shrink();

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName
                                      .substring(0, 1)
                                      .toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(contact.displayName),
                        subtitle: Text(phones.first.number),
                        onTap: () {
                          setState(() {
                            _recipientController.text = phones.first.number;
                          });
                        },
                      );
                    },
                  )
                : const SizedBox.shrink(),
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
                        final number = _recipientController.text.trim();
                        final body = _messageController.text.trim();
                        if (number.isEmpty) return;

                        final status = await _messageControllerAPI.sendSms(
                          context: context,
                          recipient: number,
                          message: body,
                        );

                        if (status != null) {
                          _messageController.clear();
                          _recipientController.clear();
                          if (mounted) Navigator.pop(context);
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
