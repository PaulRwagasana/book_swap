import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/book_card.dart';
import '../models/book.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookProv = Provider.of<BookProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Books'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Books List
          Expanded(
            child: StreamBuilder<List<Book>>(
              stream: bookProv.allBooks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
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
                          'Error loading books',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  );
                }

                var books = snapshot.data ?? [];
                
                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  books = books.where((book) {
                    return book.title.toLowerCase().contains(_searchQuery) ||
                        book.author.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.menu_book_rounded,
                          size: 80,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No books found' : 'No books available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_searchQuery.isEmpty)
                          Text(
                            'Be the first to post a book!',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: books.length,
                  itemBuilder: (context, i) =>
                      BookCard(book: books[i], meId: auth.user?.uid ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}