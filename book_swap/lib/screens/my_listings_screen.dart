import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/book_card.dart';
import '../models/book.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});
  
  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}


class _MyListingsScreenState extends State<MyListingsScreen> {
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
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    if (auth.user == null) {
      return const Center(child: Text('Please sign in'));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your listings...',
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
          Expanded(
            child: StreamBuilder<List<Book>>(
              stream: bookProv.myBooks(auth.user!.uid),
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
                          'Error loading your listings',
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
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
                          size: 80,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No books found' : 'No listings yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
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
                      BookCard(book: books[i], meId: auth.user!.uid),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}