import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:sms_app/main.dart';
import 'package:sms_app/view/homedetails_view.dart';
import 'package:sms_app/view/send_message_view.dart';
import 'package:sms_app/view/search_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final Telephony telephony = Telephony.instance;
  List<SmsMessage> _messages = [];
  bool _isLoading = true;
  final Set<String> _readSenders = {};
  List<Contact> _contacts = [];

  final ScrollController _scrollController = ScrollController();
  bool _isFabExtended = true;

  @override
  void initState() {
    super.initState();
    _initSmsIntegration();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isFabExtended) {
          setState(() {
            _isFabExtended = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_isFabExtended) {
          setState(() {
            _isFabExtended = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSmsIntegration() async {
    bool smsGranted = await _requestPermissions();
    bool contactsGranted = await FlutterContacts.requestPermission(
      readonly: true,
    );

    if (smsGranted) {
      if (contactsGranted) {
        await _loadContacts();
      }
      await _fetchMessages();
      _listenToIncomingSms();
    } else {
      setState(() {
        _isLoading = false;
      });
      // Optionally show a dialog or snackbar informing user permission is needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission is required to view messages.'),
          ),
        );
      }
    }
  }

  Future<bool> _requestPermissions() async {
    var status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<void> _loadContacts() async {
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (mounted) {
      setState(() {
        _contacts = contacts;
      });
    }
  }

  Future<void> _fetchMessages() async {
    try {
      List<SmsMessage> inboxMessages = await telephony.getInboxSms(
        columns: [
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
          SmsColumn.TYPE,
        ],
      );
      List<SmsMessage> sentMessages = await telephony.getSentSms(
        columns: [
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
          SmsColumn.TYPE,
        ],
      );

      var allMessages = [...inboxMessages, ...sentMessages];
      allMessages.sort((a, b) => (b.date ?? 0).compareTo(a.date ?? 0));

      setState(() {
        _messages = allMessages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to fetch messages: $e')));
      }
    }
  }

  void _listenToIncomingSms() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        // Handle incoming message when app is in foreground
        setState(() {
          _messages.insert(0, message);
          if (message.address != null) {
            _readSenders.remove(message.address);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('New message from ${message.address}')),
          );
        }
      },
      listenInBackground: true,
      onBackgroundMessage: backgroundMessageHandler,
    );
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '';
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Group messages by address to form conversations
    Map<String, List<SmsMessage>> conversations = {};
    for (var msg in _messages) {
      String address = msg.address ?? 'Unknown Sender';
      if (!conversations.containsKey(address)) {
        conversations[address] = [];
      }
      conversations[address]!.add(msg);
    }

    // Convert to a list of grouped entries for ListView
    List<MapEntry<String, List<SmsMessage>>> conversationList = conversations
        .entries
        .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SendMessageView()),
          );
        },
        tooltip: 'Send chat',
        icon: const Icon(Icons.message),
        label: const Text('Send chat'),
        isExtended: _isFabExtended,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final top = constraints.biggest.height;
                final padding = MediaQuery.of(context).padding;
                final collapsedHeight = kToolbarHeight + padding.top;
                final expandedHeight = 120.0 + padding.top;

                double expandRatio =
                    (top - collapsedHeight) /
                    (expandedHeight - collapsedHeight);
                expandRatio = expandRatio.clamp(0.0, 1.0);

                return Stack(
                  children: [
                    Align(
                      alignment: Alignment.lerp(
                        Alignment.bottomCenter,
                        Alignment.bottomLeft,
                        expandRatio,
                      )!,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16.0 * expandRatio,
                          bottom: 16.0,
                        ),
                        child: Text(
                          'Messaging',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14 + (14 * expandRatio), // 14 to 28
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchView(
                        messages: _messages,
                        readSenders: _readSenders,
                        contacts: _contacts,
                      ),
                    ),
                  );
                  setState(() {}); // Refresh read status
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8.0),
                      Text(
                        'Search messages',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (conversationList.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No messages found.')),
            )
          else
            SliverList.builder(
              itemCount: conversationList.length,
              itemBuilder: (context, index) {
                var conversation = conversationList[index];
                var rawSender = conversation.key;
                var thread = conversation.value;
                var latestMsg = thread.first; // First item is the most recent
                var msgCount = thread.length;
                bool isRead = _readSenders.contains(rawSender);

                String displayName = rawSender;
                String normalizedRaw = rawSender.replaceAll(RegExp(r'\D'), '');
                if (normalizedRaw.isNotEmpty) {
                  for (var contact in _contacts) {
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
                        _readSenders.add(rawSender);
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
        ],
      ),
    );
  }
}
