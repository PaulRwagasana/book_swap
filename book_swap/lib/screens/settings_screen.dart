import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool emailUpdates = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  auth.user?.email ?? 'N/A',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Receive swap notifications'),
                    value: notifications,
                    onChanged: (v) => setState(() => notifications = v),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                  SwitchListTile(
                    title: const Text('Email Updates'),
                    subtitle: const Text('Get email notifications about activity'),
                    value: emailUpdates,
                    onChanged: (v) => setState(() => emailUpdates = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.error,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}