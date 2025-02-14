import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text("User Info")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_username != null && _username!.isNotEmpty) ...[
              Text("Username: $_username",
                  style: Theme.of(context).textTheme.titleLarge),
            ] else ...[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  errorText: _errorMessage,
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveUsername,
                      child: const Text("Save"),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
