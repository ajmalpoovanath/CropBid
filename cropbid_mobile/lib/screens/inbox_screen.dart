import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  final int userId;
  const InboxScreen({super.key, required this.userId});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    final data = await ApiService.getInbox(widget.userId);
    if (mounted) {
      setState(() {
        _conversations = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages 💬"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text("No messages yet."))
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final chat = _conversations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(chat['other_username'][0].toUpperCase(), 
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(chat['other_username'], 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(chat['last_message'], 
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () async {
                          // Open Chat
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                myId: widget.userId,
                                otherId: chat['other_user_id'],
                                otherName: chat['other_username'],
                              ),
                            ),
                          );
                          _loadInbox(); // Refresh when coming back
                        },
                      ),
                    );
                  },
                ),
    );
  }
}