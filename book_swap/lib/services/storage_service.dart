import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class StorageService {
  // Maximum size for base64 image (900KB to stay under Firestore's 1MB limit)
  static const int _maxBase64Size = 900 * 1024;

  /// Uploads an image by compressing it and converting to a base64 data URL
  /// This is a fallback when Firebase Storage is not available
  Future<String> uploadBookImage(File file, String bookId) async {
    if (!await file.exists()) {
      throw Exception('Image file does not exist');
    }

    try {
      // Compress the image and convert to base64
      final compressedBytes = await _compressImage(file);
      if (compressedBytes.length > _maxBase64Size) {
        throw Exception('Image too large even after compression. Skipping image.');
      }
      
      final base64String = base64Encode(compressedBytes);
      // Return base64 data URL for direct storage in Firestore
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  Future<Uint8List> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    
    // If image is already small enough, return as is
    if (bytes.length <= _maxBase64Size) {
      return bytes;
    }

    // Decode the image
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 800,  // Reduced dimensions for compression
      targetHeight: 1200,
    );
    final frame = await codec.getNextFrame();
    
    // Convert to JPEG bytes with quality setting
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('Failed to compress image');
    }
    
    var compressedBytes = byteData.buffer.asUint8List();
    
    // If still too large, try more aggressive compression
    if (compressedBytes.length > _maxBase64Size) {
      final moreCompressedCodec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 600,
        targetHeight: 900,
      );
      final moreCompressedFrame = await moreCompressedCodec.getNextFrame();
      final moreCompressedByteData = await moreCompressedFrame.image.toByteData(format: ui.ImageByteFormat.png);
      
      if (moreCompressedByteData == null) {
        throw Exception('Failed to compress image');
      }
      
      compressedBytes = moreCompressedByteData.buffer.asUint8List();
    }
    
    return compressedBytes;
  }
}