import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/book.dart';
import 'chat_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final firestore = FirestoreService();
    final theme = Theme.of(context);

    if (auth.user == null) {
      return const Center(child: Text('Please sign in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Swap Offers'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.streamReceivedSwapOffers(auth.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final offers = snapshot.data ?? [];

          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 80,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No swap offers yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _buildOfferCard(offer, auth, firestore, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(
    Map<String, dynamic> offer,
    AuthProvider auth,
    FirestoreService firestore,
    ThemeData theme,
  ) {
    return FutureBuilder<Book?>(
      future: firestore.getBook(offer['bookId']),
      builder: (context, bookSnapshot) {
        if (bookSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading...'),
            ),
          );
        }

        final book = bookSnapshot.data;
        if (book == null) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.error),
              title: Text('Book not found'),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Info
                Row(
                  children: [
                    book.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              book.imageUrl,
                              width: 60,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildBookPlaceholder(theme);
                              },
                            ),
                          )
                        : _buildBookPlaceholder(theme),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By ${book.author}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<String?>(
                            future: firestore.getUserName(offer['fromUserId']),
                            builder: (context, userSnapshot) {
                              final userName = userSnapshot.data ?? 'User';
                              return Text(
                                'From: $userName',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(offer['status'], theme).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(offer['status'], theme),
                        ),
                      ),
                      child: Text(
                        offer['status'].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(offer['status'], theme),
                        ),
                      ),
                    ),

                    // Action Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chat Button - Always visible
                        IconButton(
                          icon: Icon(Icons.chat_rounded, color: theme.colorScheme.primary),
                          onPressed: () => _openChat(context, offer['fromUserId'], firestore, auth),
                          tooltip: 'Chat with requester',
                        ),

                        // Accept/Decline buttons - only for pending offers
                        if (offer['status'] == 'pending') ...[
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _handleAcceptOffer(offer['id'], book.id),
                            tooltip: 'Accept offer',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _handleDeclineOffer(offer['id'], book.id),
                            tooltip: 'Decline offer',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookPlaceholder(ThemeData theme) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.book, color: theme.colorScheme.primary),
    );
  }

  Future<void> _openChat(
    BuildContext context,
    String otherUserId,
    FirestoreService firestore,
    AuthProvider auth,
  ) async {
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to chat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get chat ID
      final chatId = _getChatId(auth.user!.uid, otherUserId);
      
      // Get other user's name
      final otherUserName = await firestore.getUserName(otherUserId) ?? 'User';

      // SIMPLE APPROACH: Just navigate to chat, let the chat screen handle it
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: chatId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  void _handleAcceptOffer(String swapId, String bookId) async {
    final firestore = FirestoreService();
    try {
      await firestore.acceptSwapOffer(swapId, bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Swap offer accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDeclineOffer(String swapId, String bookId) async {
    final firestore = FirestoreService();
    try {
      await firestore.declineSwapOffer(swapId, bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Swap offer declined'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }
}