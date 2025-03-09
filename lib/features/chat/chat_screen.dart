import 'dart:convert';
import 'dart:io';

import 'package:auth_test/features/party/providers/party_provider.dart';
import 'package:auth_test/features/party/services/party_members_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  late types.User _currentUser;
  late PartyMembersService _partyMembersService;
  List<String> _partyMembers = [];
  Map<String, types.User> _chatUsers = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _partyId;

  @override
  void initState() {
    super.initState();
    _partyMembersService = PartyMembersService();

    // We'll get the partyId in didChangeDependencies
    // since we need to access the Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get partyId from PartyProvider
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);
    _partyId = partyProvider.partyId;

    if (_partyId == null || _partyId!.isEmpty) {
      // Handle missing partyId
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No party selected')),
      );
      // Navigate back or to party selection screen
      // Navigator.of(context).pop();
    }
  }

  Future<void> _initializeChat() async {
    if (_partyId == null || _partyId!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // First, set up the current user
    final currentUserId = _partyMembersService.currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to chat')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Fetch current user details
    final userDoc =
        await _firestore.collection('users').doc(currentUserId).get();
    if (!userDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not found')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userData = userDoc.data() as Map<String, dynamic>;

    // Create the current user
    _currentUser = types.User(
      id: currentUserId,
      firstName: userData['firstName'] as String?,
      lastName: userData['lastName'] as String?,
      imageUrl: userData['imageUrl'] as String?,
    );

    // Get party members directly from PartyProvider
    final partyProvider = Provider.of<PartyProvider>(context, listen: false);
    _partyMembers = partyProvider.members;

    // Check if current user is a party member
    if (!_partyMembers.contains(currentUserId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not a member of this party')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Use member details from PartyProvider
    final memberDetails = partyProvider.memberDetails;

    // Create chat users from party members
    for (final memberId in _partyMembers) {
      final member = memberDetails[memberId];
      if (member != null) {
        _chatUsers[memberId] = types.User(
          id: memberId,
          firstName: member['firstName'] as String?,
          lastName: member['lastName'] as String?,
          imageUrl: member['imageUrl'] as String?,
        );
      }
    }

    // Load chat messages
    await _loadMessages();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMessages() async {
    try {
      // Get chat messages from Firestore
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('parties')
          .doc(_partyId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final messages = messagesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final authorId = data['authorId'] as String;

        // Get the author from our chat users map
        final author = _chatUsers[authorId] ?? types.User(id: authorId);

        // Handle different message types
        if (data['type'] == 'text') {
          return types.TextMessage(
            author: author,
            id: doc.id,
            text: data['text'] as String,
            createdAt: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
          );
        } else if (data['type'] == 'image') {
          return types.ImageMessage(
            author: author,
            id: doc.id,
            uri: data['uri'] as String,
            name: data['name'] as String? ?? '',
            size: data['size'] as int? ?? 0,
            width: data['width'] as double? ?? 0,
            height: data['height'] as double? ?? 0,
            createdAt: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
          );
        } else if (data['type'] == 'file') {
          return types.FileMessage(
            author: author,
            id: doc.id,
            uri: data['uri'] as String,
            name: data['name'] as String,
            size: data['size'] as int,
            mimeType: data['mimeType'] as String?,
            createdAt: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
          );
        }

        // Default to text message if type is unknown
        return types.TextMessage(
          author: author,
          id: doc.id,
          text: data['text'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
        );
      }).toList();

      setState(() {
        _messages = messages.cast<types.Message>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    }
  }

  void _addMessage(types.Message message) async {
    setState(() {
      _messages.insert(0, message);
    });

    // Save message to Firestore
    try {
      Map<String, dynamic> messageData;

      if (message is types.TextMessage) {
        messageData = {
          'authorId': message.author.id,
          'text': message.text,
          'type': 'text',
          'createdAt': FieldValue.serverTimestamp(),
        };
      } else if (message is types.ImageMessage) {
        messageData = {
          'authorId': message.author.id,
          'uri': message.uri,
          'name': message.name,
          'size': message.size,
          'width': message.width,
          'height': message.height,
          'type': 'image',
          'createdAt': FieldValue.serverTimestamp(),
        };
      } else if (message is types.FileMessage) {
        messageData = {
          'authorId': message.author.id,
          'uri': message.uri,
          'name': message.name,
          'size': message.size,
          'mimeType': message.mimeType,
          'type': 'file',
          'createdAt': FieldValue.serverTimestamp(),
        };
      } else {
        return; // Unsupported message type
      }

      await _firestore
          .collection('parties')
          .doc(_partyId)
          .collection('messages')
          .doc(message.id)
          .set(messageData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      // Upload the file to Firebase Storage and get URL
      // For now, we'll just use the local path
      final message = types.FileMessage(
        author: _currentUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      // Upload the image to Firebase Storage and get URL
      // For now, we'll just use the local path
      final message = types.ImageMessage(
        author: _currentUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
              _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to party provider for changes
    final partyProvider = Provider.of<PartyProvider>(context);
    final String partyName = partyProvider.partyName ?? 'Party Chat';

    return Scaffold(
      appBar: AppBar(
        title: Text(partyName),
      ),
      body: _isLoading || _partyId == null
          ? const Center(child: CircularProgressIndicator())
          : Chat(
              messages: _messages,
              onAttachmentPressed: _handleAttachmentPressed,
              onMessageTap: _handleMessageTap,
              onPreviewDataFetched: _handlePreviewDataFetched,
              onSendPressed: _handleSendPressed,
              showUserAvatars: true,
              showUserNames: true,
              user: _currentUser,
            ),
    );
  }
}
