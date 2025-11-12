import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final firestore = FirestoreService();
    
    if (auth.user == null) {
      return const Center(child: Text('Please sign in to view chats'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        elevation: 0,
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: firestore.streamChats(auth.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Chat stream error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          final chats = snapshot.data ?? [];
          
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 80,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Request a swap to start chatting',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat['participants'] ?? []);
              String otherUserId = '';
              for (final id in participants) {
                if (id != auth.user!.uid && id.isNotEmpty) {
                  otherUserId = id;
                  break;
                }
              }
              
              if (otherUserId.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return _ChatTile(
                chatId: chat['id'],
                otherUserId: otherUserId,
                lastMessage: chat['lastMessage'] ?? 'No messages yet',
                lastMessageTime: chat['lastMessageTime'],
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String lastMessage;
  final dynamic lastMessageTime;

  const _ChatTile({
    required this.chatId,
    required this.otherUserId,
    required this.lastMessage,
    this.lastMessageTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestore = FirestoreService();
    
    return FutureBuilder<String?>(
      future: firestore.getUserName(otherUserId),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'User';
        final lastTime = _formatLastMessageTime(lastMessageTime);
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              radius: 24,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              userName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                if (lastTime.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    lastTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () async {
              final actualName = await firestore.getUserName(otherUserId);
              final finalName = actualName ?? 'User';
              
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      chatId: chatId,
                      otherUserId: otherUserId,
                      otherUserName: finalName,
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  String _formatLastMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final time = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inMinutes < 1) return 'Now';
      if (difference.inHours < 1) return '${difference.inMinutes}m ago';
      if (difference.inDays < 1) return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      
      return '${time.day}/${time.month}/${time.year}';
    } catch (e) {
      return '';
    }
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final firestore = FirestoreService();
    
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    
    _messageController.clear();
    
    try {
      await firestore.sendMessage(
        widget.chatId,
        auth.user!.uid,
        messageText,
      );
      
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      // Restore message if failed to send
      _messageController.text = messageText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            Text(
              'Online',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 60,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == auth.user!.uid;
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == 0 ? 8 : 12,
                      ),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['text'] ?? '',
                                  style: TextStyle(
                                    color: isMe
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatMessageTime(data['timestamp']),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: (isMe
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant).withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: theme.colorScheme.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final time = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}