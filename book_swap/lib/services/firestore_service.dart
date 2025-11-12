import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserName(String uid, String name) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> getUserName(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['name'] as String?;
  }

  Stream<List<Book>> streamAllBooks() {
    return _db
        .collection('books')
        .snapshots()
        .map((snap) {
          try {
            final books = snap.docs.map((d) {
              try {
                final book = Book.fromDoc(d);
                return book.status == 'available' ? book : null;
              } catch (e) {
                return null;
              }
            }).whereType<Book>().toList();
            return books;
          } catch (e) {
            return <Book>[];
          }
        });
  }

  Stream<List<Book>> streamUserBooks(String uid) {
    if (uid.isEmpty) return Stream.value(<Book>[]);
    return _db
        .collection('books')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          try {
            return snap.docs.map((d) => Book.fromDoc(d)).toList();
          } catch (e) {
            return <Book>[];
          }
        });
  }

  Future<void> createBook(Book book) async {
    await _db.collection('books').add(book.toMap());
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    await _db.collection('books').doc(id).update(data);
  }

  Future<void> deleteBook(String id) async {
    await _db.collection('books').doc(id).delete();
  }

  Future<void> createSwapOffer({
    required String bookId,
    required String fromUid,
    required String toUid,
  }) async {
    try {
      final swapRef = _db.collection('swapOffers').doc();
      await swapRef.set({
        'id': swapRef.id,
        'bookId': bookId,
        'fromUserId': fromUid,
        'toUserId': toUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await updateBook(bookId, {'status': 'pending'});
      
      // Create chat when swap offer is made
      await createChatIfNotExists(
        chatId: _getChatId(fromUid, toUid),
        participant1: fromUid,
        participant2: toUid,
        bookId: bookId,
      );
    } catch (e) {
      throw Exception('Failed to create swap offer: $e');
    }
  }

  Future<void> createChatIfNotExists({
    required String chatId,
    required String participant1,
    required String participant2,
    String? bookId,
  }) async {
    try {
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        await _db.collection('chats').doc(chatId).set({
          'chatId': chatId,
          'participants': [participant1, participant2],
          'lastMessage': 'Chat started for swap offer',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'bookId': bookId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<List<Map<String, dynamic>>> streamChats(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final chats = snap.docs.map((d) {
            final data = d.data();
            return {
              'id': d.id,
              ...data,
            };
          }).toList();
          
          chats.sort((a, b) {
            final timeA = a['lastMessageTime'] as Timestamp?;
            final timeB = b['lastMessageTime'] as Timestamp?;
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            return timeB.compareTo(timeA);
          });
          
          return chats;
        });
  }

  Stream<List<Map<String, dynamic>>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          try {
            return snap.docs.map((d) {
              final data = d.data();
              return {
                'id': d.id,
                ...data,
              };
            }).toList();
          } catch (e) {
            return <Map<String, dynamic>>[];
          }
        });
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    try {
      await _db.collection('chats').doc(chatId).collection('messages').add({
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      await _db.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  String _getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<Map<String, dynamic>>> streamReceivedSwapOffers(String uid) {
    return _db
        .collection('swapOffers')
        .where('toUserId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          try {
            return snap.docs.map((d) {
              final data = d.data();
              return {
                'id': d.id,
                ...data,
              };
            }).toList();
          } catch (e) {
            return <Map<String, dynamic>>[];
          }
        });
  }

  Stream<List<Map<String, dynamic>>> streamSentSwapOffers(String uid) {
    return _db
        .collection('swapOffers')
        .where('fromUserId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          try {
            return snap.docs.map((d) {
              final data = d.data();
              return {
                'id': d.id,
                ...data,
              };
            }).toList();
          } catch (e) {
            return <Map<String, dynamic>>[];
          }
        });
  }

  Future<Book?> getBook(String bookId) async {
    try {
      final doc = await _db.collection('books').doc(bookId).get();
      if (!doc.exists) return null;
      return Book.fromDoc(doc);
    } catch (e) {
      return null;
    }
  }

  Future<void> acceptSwapOffer(String swapId, String bookId) async {
    try {
      await _db.collection('swapOffers').doc(swapId).update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await updateBook(bookId, {'status': 'swapped'});
    } catch (e) {
      throw Exception('Failed to accept swap offer: $e');
    }
  }

  Future<void> declineSwapOffer(String swapId, String bookId) async {
    try {
      await _db.collection('swapOffers').doc(swapId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await updateBook(bookId, {'status': 'available'});
    } catch (e) {
      throw Exception('Failed to decline swap offer: $e');
    }
  }
}