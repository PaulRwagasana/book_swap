# BookSwap - Textbook Exchange Platform

A Flutter-based marketplace where students can exchange textbooks with real-time updates, authentication, and chat functionality.

## 🎓 Project Overview

BookSwap is a mobile application developed as part of Individual Assignment 2, demonstrating mastery of Flutter development with Firebase integration. The app provides a platform for students to list, browse, and exchange textbooks with real-time updates and secure authentication.

## 🚀 Features

- **🔐 User Authentication** - Secure sign up, login, and email verification with Firebase Auth
- **📚 Book Management** - Full CRUD operations for book listings (Create, Read, Update, Delete)
- **🔄 Swap System** - Request, accept, or decline book swaps with real-time status updates
- **💬 Real-time Chat** - Instant messaging between users for swap coordination
- **🖼️ Image Upload** - Book cover images with base64 encoding fallback
- **🎯 State Management** - Provider pattern for reactive UI updates
- **🔍 Search Functionality** - Find books by title or author
- **📱 Responsive Design** - Beautiful Material Design interface

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.0+, Dart
- **Backend**: Firebase (Authentication, Firestore, Security Rules)
- **State Management**: Provider
- **Image Handling**: Image Picker with base64 encoding
- **Navigation**: Flutter Navigator with BottomNavigationBar

## 📱 App Architecture

```
lib/
├── models/                 # Data models
│   ├── book.dart          # Book data structure
│   └── user.dart          # User data structure
├── providers/             # State management
│   ├── auth_provider.dart # Authentication state
│   └── book_provider.dart # Book and swap operations
├── services/              # Firebase services
│   ├── auth_service.dart  # Authentication operations
│   ├── firestore_service.dart # Database operations
│   └── storage_service.dart   # Image handling
├── screens/               # UI screens
│   ├── auth_screen.dart   # Login/Signup
│   ├── browse_screen.dart # Book listings
│   ├── my_listings_screen.dart # User's books
│   ├── offers_screen.dart # Swap offers management
│   ├── chat_screen.dart   # Messaging interface
│   ├── settings_screen.dart # User settings
│   ├── post_book_screen.dart # Add new book
│   ├── edit_book_screen.dart # Modify book details
│   ├── book_detail_screen.dart # Book details view
│   └── email_verification_screen.dart # Email verification
├── widgets/               # Reusable components
│   ├── book_card.dart     # Book display card
│   ├── modern_book_card.dart # Enhanced book card
│   ├── quick_action_card.dart # Action buttons
│   └── stats_card.dart    # Statistics display
└── main.dart              # App entry point
```

## 🔧 Setup Instructions

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extension
- Firebase account
- Physical device or emulator

### Firebase Configuration

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create new project "BookSwap"
   - Enable Analytics (optional)

2. **Configure Authentication**
   - Go to Authentication → Sign-in method
   - Enable Email/Password provider
   - Configure email templates for verification

3. **Setup Firestore Database**
   - Go to Firestore Database → Create database
   - Start in test mode (we'll update rules later)
   - Create collections: `users`, `books`, `swapOffers`, `chats`

4. **Add Android App**
   - Click "Add app" → Android
   - Android package name: `com.example.book_swap`
   - Download `google-services.json`
   - Place in `android/app/` directory

5. **Configure Security Rules**
   - Replace Firestore rules with provided `firestore_rules.txt`
   - Test rules using Rules Playground

### Installation Steps

1. **Clone Repository**
   ```bash
   git clone https://github.com/your-username/book_swap.git
   cd book_swap
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment**
   - Ensure `google-services.json` is in `android/app/`
   - Verify Firebase configuration

4. **Run the Application**
   ```bash
   flutter run
   ```

## 🔐 Firebase Security Rules

The app uses comprehensive security rules to protect user data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Books: anyone can read, owners can modify
    match /books/{bookId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
        && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null 
        && resource.data.ownerId == request.auth.uid;
    }
    
    // Swap offers: participants can access
    match /swapOffers/{offerId} {
      allow read: if request.auth != null 
        && (resource.data.fromUserId == request.auth.uid 
            || resource.data.toUserId == request.auth.uid);
      allow create: if request.auth != null 
        && request.resource.data.fromUserId == request.auth.uid;
      allow update: if request.auth != null 
        && resource.data.toUserId == request.auth.uid;
    }
    
    // Chats: only participants can access
    match /chats/{chatId} {
      allow read, write: if request.auth != null 
        && request.auth.uid in resource.data.participants;
      allow create: if request.auth != null 
        && request.auth.uid in request.resource.data.participants;
    }
    
    // Messages: only chat participants can access
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null 
        && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    }
  }
}
```

## 📊 Database Schema

### Collections Structure

**Users Collection**
```javascript
{
  "uid": "string",           // Firebase Auth UID
  "email": "string",         // User email
  "displayName": "string",   // Optional display name
  "createdAt": "timestamp",  // Account creation
  "emailVerified": "boolean" // Verification status
}
```

**Books Collection**
```javascript
{
  "id": "string",            // Document ID
  "title": "string",         // Book title
  "author": "string",        // Author name
  "condition": "string",     // New/Like New/Good/Used
  "status": "string",        // available/pending/swapped
  "ownerId": "string",       // Owner user ID
  "imageUrl": "string",      // Base64 encoded image
  "createdAt": "timestamp",  // Listing date
  "updatedAt": "timestamp"   // Last update
}
```

**SwapOffers Collection**
```javascript
{
  "id": "string",            // Document ID
  "bookId": "string",        // Target book reference
  "fromUserId": "string",    // Requester user ID
  "toUserId": "string",      // Book owner user ID
  "status": "string",        // pending/accepted/rejected
  "createdAt": "timestamp",  // Offer creation
  "updatedAt": "timestamp"   // Status update
}
```

**Chats Collection**
```javascript
{
  "chatId": "string",        // user1_user2 composite ID
  "participants": "array",   // [user1, user2]
  "lastMessage": "string",   // Message preview
  "lastMessageTime": "timestamp", // Last activity
  "bookId": "string"         // Related book (optional)
}
```

## 🎯 Key Features Demonstrated

### State Management with Provider
- **AuthProvider**: Manages user authentication state and email verification
- **BookProvider**: Handles book operations, swaps, and real-time updates
- **Reactive UI**: Automatic updates when data changes in Firestore

### Real-time Operations
- Live book listings updates
- Instant swap status changes
- Real-time chat messaging
- Immediate UI feedback

### Error Handling
- Network error management
- Permission denied handling
- User-friendly error messages
- Image upload fallbacks

## 🎥 Demo Video

A comprehensive demo video (7-12 minutes) showcases:

- User authentication flow with Firebase Console
- Complete CRUD operations for books
- Swap functionality with real-time updates
- Chat system between users
- Navigation and settings
- Concurrent Firebase Console demonstration

## 📝 Assignment Requirements Met

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| **State Management** | ✅ | Provider pattern with reactive updates |
| **Authentication** | ✅ | Firebase Auth with email verification |
| **CRUD Operations** | ✅ | Full book lifecycle management |
| **Swap Functionality** | ✅ | Request, accept, decline with real-time updates |
| **Navigation** | ✅ | BottomNavigationBar with 5 screens |
| **Settings** | ✅ | User preferences and profile management |
| **Firebase Integration** | ✅ | All data persists in Firestore |
| **Chat Feature** | ✅ | Real-time messaging between users |

## 🐛 Troubleshooting

### Common Issues

1. **Firebase Permission Errors**
   - Verify security rules are correctly set
   - Check user authentication status
   - Ensure document ownership

2. **Image Upload Issues**
   - Check storage permissions
   - Verify image size limits
   - Ensure base64 encoding works

3. **Authentication Problems**
   - Verify email is confirmed
   - Check Firebase Auth configuration
   - Ensure internet connectivity

### Development Commands

```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Run tests
flutter test

# Build APK
flutter build apk
```

## 👨‍💻 Developer

**Paul Rwagasana**    
- Course: Mobile App Dev  
- Institution: ALU  

## 📄 License

This project is developed for educational purposes as part of Individual_assignment 2. All rights reserved.

## 🔗 Links

- [GitHub Repository](https://github.com/your-username/book_swap)
- [Firebase Console](https://console.firebase.google.com)
- [Flutter Documentation](https://flutter.dev/docs)

---

**Note**: This application is a demonstration of Flutter and Firebase integration capabilities for academic purposes.
