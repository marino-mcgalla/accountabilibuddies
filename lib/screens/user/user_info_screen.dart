import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(user.uid).get();
      String? fetchedUsername = snapshot['username'];

      if (fetchedUsername != null) {
        _usernameController.text = fetchedUsername;
      }

      setState(() {
        _username = fetchedUsername;
      });
    }
  }

  Future<void> _saveUsername() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _errorMessage = "Username cannot be empty";
        _isLoading = false;
      });
      return;
    }

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set(
          {'username': username},
          SetOptions(merge: true),
        );
        setState(() {
          _username = username;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error saving username: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Header section
            Text(
              "Your Profile",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Set your display name to show to other party members",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (_username != null && _username!.isNotEmpty) ...[
              // Profile display mode
              Card(
                elevation: isSmallScreen ? 2 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 8),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 24.0 : 16.0),
                  child: Column(
                    children: [
                      // Avatar placeholder
                      CircleAvatar(
                        radius: isSmallScreen ? 48 : 40,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                        child: Text(
                          _username!.isNotEmpty ? _username![0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 32 : 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Username display
                      Text(
                        _username!,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Display Name",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Email display if available
                      if (_auth.currentUser?.email != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _auth.currentUser!.email!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 24),

                      // Edit button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _username = null; // Switch to edit mode
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Display Name"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: isSmallScreen ? 12 : 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Edit mode
              Card(
                elevation: isSmallScreen ? 2 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 8),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 24.0 : 16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Set Your Display Name",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "This is how other party members will see you",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: "Display Name",
                          border: const OutlineInputBorder(),
                          errorText: _errorMessage,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: isSmallScreen ? 16.0 : 12.0,
                          ),
                          helperText: "e.g., John, Sarah, Mike123",
                        ),
                        style: TextStyle(fontSize: isSmallScreen ? 16 : 14),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveUsername(),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Row(
                              children: [
                                if (_username != null) ...[
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _username = _usernameController.text.isNotEmpty 
                                              ? _usernameController.text 
                                              : _username;
                                        });
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: _saveUsername,
                                    icon: const Icon(Icons.save),
                                    label: const Text("Save"),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: isSmallScreen ? 12 : 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
