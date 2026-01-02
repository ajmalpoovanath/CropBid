import 'dart:async'; // For the timer
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int myId;
  final int otherId;
  final String otherName; // Display name (e.g., "Farmer John")

  const ChatScreen({
    super.key, 
    required this.myId, 
    required this.otherId, 
    required this.otherName
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  List<dynamic> _messages = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Auto-refresh chat every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop refreshing when we leave the screen
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final msgs = await ApiService.getMessages(widget.myId, widget.otherId);
    if (mounted) {
      setState(() {
        _messages = msgs;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.isEmpty) return;

    final success = await ApiService.sendMessage(
      widget.myId, 
      widget.otherId, 
      _msgController.text
    );

    if (success) {
      _msgController.clear();
      _fetchMessages(); // Refresh immediately
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.otherName}"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // 1. Message List
          Expanded(
            child: _messages.isEmpty 
                ? const Center(child: Text("No messages yet. Say Hi! 👋")) 
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender'] == widget.myId;
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            msg['message'],
                            style: TextStyle(color: isMe ? Colors.white : Colors.black),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 2. Input Box
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}