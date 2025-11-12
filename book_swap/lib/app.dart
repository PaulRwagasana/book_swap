import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'models/book.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/post_book_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/chat_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
      ],
      child: Consumer<AuthProvider>(builder: (context, auth, _) {
        Widget home;
        
        if (auth.isSignedIn) {
          home = const MainNavigationScreen();
        } else if (auth.isSignedInButUnverified) {
          home = EmailVerificationScreen(email: auth.user?.email ?? '');
        } else {
          home = const AuthScreen();
        }

        return MaterialApp(
          title: 'BookSwap',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              primaryContainer: Color(0xFF42A5F5),
              secondary: Color(0xFF2196F3),
              secondaryContainer: Color(0xFF90CAF9),
              surface: Color(0xFFF5F9FF),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Color(0xFF0D47A1),
              tertiary: Color(0xFF64B5F6),
              error: Color(0xFFD32F2F),
            ),
            scaffoldBackgroundColor: const Color(0xFFE3F2FD),
            // FIXED: Changed from CardTheme to CardThemeData
            cardTheme: CardThemeData(
              elevation: 8,
              shadowColor: const Color(0xFF1976D2).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.zero, // Added to fix any margin issues
            ),
            iconTheme: const IconThemeData(
              color: Color(0xFF1976D2),
              size: 24,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1976D2),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(
                color: Colors.white,
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF2196F3),
              foregroundColor: Colors.white,
              elevation: 12,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF5F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF2196F3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF2196F3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
              ),
            ),
          ),
          home: home,
          routes: {
            '/home': (ctx) => const MainNavigationScreen(),
            '/auth': (ctx) => const AuthScreen(),
            '/verify': (ctx) => EmailVerificationScreen(
              email: auth.user?.email ?? '',
            ),
            '/add-book': (ctx) => const PostBookScreen(),
            '/book-detail': (ctx) => BookDetailScreen(
              book: ModalRoute.of(ctx)!.settings.arguments as Book,
            ),
            '/chat': (ctx) => const ChatScreen(),
          },
        );
      }),
    );
  }
}