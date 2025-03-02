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
      appBar: AppBar(title: const Text("User Info")),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                            .withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          size: isSmallScreen ? 48 : 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Username display
                      Text(
                        "Username: $_username",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Email display if available
                      if (_auth.currentUser?.email != null)
                        Text(
                          "Email: ${_auth.currentUser!.email}",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 14,
                            color: Colors.grey[600],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Edit button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _username = null; // Switch to edit mode
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Username"),
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
                      Text(
                        "Set Your Username",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: "Username",
                          border: const OutlineInputBorder(),
                          errorText: _errorMessage,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: isSmallScreen ? 16.0 : 12.0,
                          ),
                        ),
                        style: TextStyle(fontSize: isSmallScreen ? 16 : 14),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveUsername(),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              onPressed: _saveUsername,
                              icon: const Icon(Icons.save),
                              label: const Text("Save Username"),
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
            ],
          ],
        ),
      ),
    );
  }
}
