import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';

class PostBookScreen extends StatefulWidget {
  const PostBookScreen({super.key});
  @override
  State<PostBookScreen> createState() => _PostBookScreenState();
}

class _PostBookScreenState extends State<PostBookScreen> {
  final _title = TextEditingController();
  final _author = TextEditingController();
  String condition = 'Used';
  File? _image;
  bool _isPosting = false;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  Future pickImage() async {
    try {
      final p = ImagePicker();
      final x = await p.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (x != null) {
        final file = File(x.path);
        if (await file.exists()) {
          setState(() => _image = file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookProv = Provider.of<BookProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Book'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter book title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _author,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  hintText: 'Enter author name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: condition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  prefixIcon: Icon(Icons.star_outline_rounded),
                ),
                onChanged: (v) => setState(() => condition = v ?? 'Used'),
                items: const [
                  DropdownMenuItem(value: 'New', child: Text('New')),
                  DropdownMenuItem(value: 'Like New', child: Text('Like New')),
                  DropdownMenuItem(value: 'Good', child: Text('Good')),
                  DropdownMenuItem(value: 'Used', child: Text('Used')),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Book Cover',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _image == null
                  ? Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: InkWell(
                        onTap: pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add image',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _image!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => setState(() => _image = null),
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : () async {
                    if (_title.text.trim().isEmpty || _author.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in all fields')),
                      );
                      return;
                    }
                    
                    setState(() => _isPosting = true);
                    
                    try {
                      await bookProv.postBook(
                        ownerId: auth.user!.uid,
                        title: _title.text.trim(),
                        author: _author.text.trim(),
                        condition: condition,
                        image: _image,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Book posted successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error posting book: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isPosting = false);
                    }
                  },
                  child: _isPosting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Post Book',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}