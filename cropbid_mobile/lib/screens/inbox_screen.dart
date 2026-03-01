import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart'; // 🛠️ Optional: Add 'intl' to pubspec.yaml for date formatting

class InboxScreen extends StatefulWidget {
  final int userId;
  const InboxScreen({super.key, required this.userId});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _inbox = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    final inbox = await ApiService.getInbox(widget.userId);
    if (mounted) {
      setState(() {
        _inbox = inbox;
        _isLoading = false;
      });
    }
  }

  // 🛠️ Helper to make timestamps look clean (e.g., "03:45 PM")
  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundForest,
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.paddyGreen),
            )
          : RefreshIndicator(
              color: AppTheme.paddyGreen,
              onRefresh: _loadInbox,
              child: _inbox.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: _inbox.length,
                      itemBuilder: (context, index) {
                        final chat = _inbox[index];

                        // 🛠️ THE FIX: Strictly use the keys from your new Django InboxView
                        final int otherId =
                            int.tryParse(
                              chat['other_user_id']?.toString() ?? "0",
                            ) ??
                            0;
                        final String otherName =
                            chat['other_username'] ?? "Farmer";
                        final String lastMsg = chat['last_message'] ?? "";
                        final String timeStr = _formatTime(chat['timestamp']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppTheme.surfaceMoss,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppTheme.paddyGreen.withOpacity(
                                0.2,
                              ),
                              child: Text(
                                otherName.isNotEmpty
                                    ? otherName[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: AppTheme.paddyGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            title: Text(
                              otherName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white38,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: AppTheme.paddyGreen,
                                ),
                              ],
                            ),
                            onTap: () async {
                              // 🔑 Using targetId from the specific Inbox item
                              debugPrint(
                                "NAVIGATING: Opening chat with ID $otherId ($otherName)",
                              );

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  settings: RouteSettings(
                                    name: '/chat/$otherId',
                                  ),
                                  builder: (context) => ChatScreen(
                                    key: ValueKey(otherId),
                                    userId: widget.userId,
                                    otherId: otherId,
                                    otherName: otherName,
                                  ),
                                ),
                              );
                              _loadInbox(); // Refresh list on return
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            "No conversations yet",
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
