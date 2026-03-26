import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:sms_app/view/homedetails_view.dart';

class SearchView extends StatefulWidget {
  final List<SmsMessage> messages;
  final Set<String> readSenders;
  final List<Contact> contacts;

  const SearchView({
    super.key,
    required this.messages,
    required this.readSenders,
    required this.contacts,
  });

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  String _searchQuery = "";
  List<SmsMessage> _filteredMessages = [];

  void _runFilter(String enteredKeyword) {
    if (enteredKeyword.isEmpty) {
      setState(() {
        _searchQuery = "";
        _filteredMessages = [];
      });
      return;
    }
    List<SmsMessage> results = widget.messages
        .where(
          (msg) =>
              (msg.address?.toLowerCase().contains(
                    enteredKeyword.toLowerCase(),
                  ) ??
                  false) ||
              (msg.body?.toLowerCase().contains(enteredKeyword.toLowerCase()) ??
                  false),
        )
        .toList();

    setState(() {
      _searchQuery = enteredKeyword;
      _filteredMessages = results;
    });
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<SmsMessage>> conversations = {};
    for (var msg in _filteredMessages) {
      String address = msg.address ?? 'Unknown Sender';
      if (!conversations.containsKey(address)) {
        conversations[address] = [];
      }
      conversations[address]!.add(msg);
    }

    List<MapEntry<String, List<SmsMessage>>> conversationList = conversations
        .entries
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: (value) => _runFilter(value),
          decoration: InputDecoration(
            hintText: 'Search by sender or body...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
      ),
      body: _searchQuery.isEmpty
          ? const Center(child: Text('Type to search messages.'))
          : conversationList.isEmpty
          ? const Center(child: Text('No messages found.'))
          : ListView.builder(
              itemCount: conversationList.length,
              itemBuilder: (context, index) {
                var conversation = conversationList[index];
                var rawSender = conversation.key;
                var thread = conversation.value;
                var latestMsg = thread.first;
                var msgCount = thread.length;
                bool isRead = widget.readSenders.contains(rawSender);

                String displayName = rawSender;
                String normalizedRaw = rawSender.replaceAll(RegExp(r'\D'), '');
                if (normalizedRaw.isNotEmpty) {
                  for (var contact in widget.contacts) {
                    if (contact.phones.any((p) {
                      String normalizedPhone = p.number.replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      // Match last 10 digits to handle country code variants
                      if (normalizedPhone.length >= 10 &&
                          normalizedRaw.length >= 10) {
                        return normalizedPhone.substring(
                              normalizedPhone.length - 10,
                            ) ==
                            normalizedRaw.substring(normalizedRaw.length - 10);
                      }
                      return normalizedPhone == normalizedRaw;
                    })) {
                      displayName = contact.displayName;
                      break;
                    }
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        widget.readSenders.add(rawSender);
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomedetailsView(
                            sender: displayName,
                            messages: thread,
                          ),
                        ),
                      );
                    },
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(latestMsg.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      latestMsg.body ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (msgCount > 1 && !isRead)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$msgCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
