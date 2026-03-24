import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final int otherId;
  final String otherName;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.otherId,
    required this.otherName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resetAndLoad();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🛡️ If the screen stays open but the farmer changes, force a refresh
    if (oldWidget.otherId != widget.otherId) {
      _resetAndLoad();
    }
  }

  void _resetAndLoad() {
    if (!mounted) return;
    setState(() {
      _messages = [];
      _isLoading = true;
    });
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      // 🕵️ DEBUG: Check your terminal for these IDs!
      // If Suni Kuttan's chat shows Bob Martin's otherId, the problem is in the Navigator.
      debugPrint(
        "FETCHING CHAT: Me(${widget.userId}) ↔ Farmer(${widget.otherId}) Name: ${widget.otherName}",
      );

      final msgs = await ApiService.getMessages(widget.userId, widget.otherId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading messages: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // 📡 Ensure the receiver ID is exactly what the widget was initialized with
    final success = await ApiService.sendMessage(
      widget.userId,
      widget.otherId,
      text,
    );

    if (success) {
      _loadMessages();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send message"),
            backgroundColor: AppTheme.clayRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundForest,
      appBar: AppBar(
        title: Text(
          widget.otherName, // 🛠️ Uses the name provided during navigation
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.surfaceMoss,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.paddyGreen,
                    ),
                  )
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      "No messages yet 🌿",
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[(_messages.length - 1) - index];
                      bool isMe = msg['sender'] == widget.userId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppTheme.paddyGreen
                                : AppTheme.surfaceMoss,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft: Radius.circular(isMe ? 15 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 15),
                            ),
                          ),
                          child: Text(
                            msg['message'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            color: AppTheme.surfaceMoss,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Message ${widget.otherName}...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppTheme.backgroundForest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: AppTheme.paddyGreen,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
