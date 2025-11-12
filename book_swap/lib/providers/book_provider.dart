import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class BookProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  final StorageService _storage = StorageService();

  Stream<List<Book>> allBooks() => _db.streamAllBooks();
  Stream<List<Book>> myBooks(String uid) => _db.streamUserBooks(uid);

  Future<void> postBook({
    required String ownerId,
    required String title,
    required String author,
    required String condition,
    File? image,
  }) async {
    final id = const Uuid().v4();
    String imageUrl = '';
    
    if (image != null) {
      try {
        imageUrl = await _storage.uploadBookImage(image, id);
      } catch (e) {
        imageUrl = '';
      }
    }
    
    final book = Book(
      id: id,
      ownerId: ownerId,
      title: title,
      author: author,
      condition: condition,
      imageUrl: imageUrl,
      status: 'available',
    );
    
    try {
      await _db.createBook(book);
    } catch (e) {
      throw Exception('Failed to create book: $e');
    }
  }

  Future<void> deleteBook(String id) async => await _db.deleteBook(id);

  Future<void> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String condition,
    File? image,
    String? existingImageUrl,
  }) async {
    String imageUrl = existingImageUrl ?? '';
    
    if (image != null) {
      try {
        imageUrl = await _storage.uploadBookImage(image, bookId);
      } catch (e) {
        imageUrl = existingImageUrl ?? '';
      }
    }
    
    final updateData = {
      'title': title,
      'author': author,
      'condition': condition,
      'imageUrl': imageUrl,
    };
    
    try {
      await _db.updateBook(bookId, updateData);
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  Future<void> updateBookStatus(String bookId, String status) async {
    try {
      await _db.updateBook(bookId, {'status': status});
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update book status: $e');
    }
  }

  Future<void> createSwapOffer({
    required String bookId,
    required String fromUid,
    required String toUid,
  }) async {
    await _db.createSwapOffer(
      bookId: bookId, 
      fromUid: fromUid, 
      toUid: toUid
    );
    notifyListeners();
  }
}