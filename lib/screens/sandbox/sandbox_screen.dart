import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SandboxScreen extends StatelessWidget {
  const SandboxScreen({super.key});

  Future<void> _toggleStatus(BuildContext context, String docId, String date,
      String currentStatus) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    DocumentReference docRef =
        FirebaseFirestore.instance.collection('sandbox').doc(docId);
    DocumentSnapshot docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      List<dynamic> weekStatus = docSnapshot['weekStatus'] ?? [];
      int index = weekStatus.indexWhere((day) => day['date'] == date);
      if (index != -1) {
        String newStatus = currentStatus == 'skipped' ? 'blank' : 'skipped';
        weekStatus[index]['status'] = newStatus;
        weekStatus[index]['updatedBy'] = currentUserId;
        weekStatus[index]['updatedAt'] = Timestamp.now();
        await docRef.update({'weekStatus': weekStatus});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text("Sandbox")),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sandbox')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData ||
                snapshot.data == null ||
                !snapshot.data!.exists) {
              return ElevatedButton(
                onPressed: () async {
                  DateTime now = DateTime.now();
                  DateTime monday =
                      now.subtract(Duration(days: now.weekday - 1));
                  List<Map<String, dynamic>> weekStatus =
                      List.generate(7, (index) {
                    DateTime date = monday.add(Duration(days: index));
                    return {
                      'date': DateFormat('yyyy-MM-dd').format(date),
                      'status': 'blank',
                    };
                  });
                  await FirebaseFirestore.instance
                      .collection('sandbox')
                      .doc(user.uid)
                      .set({'weekStatus': weekStatus});
                },
                child: const Text("Initialize"),
              );
            }
            var data = snapshot.data!.data() as Map<String, dynamic>;
            List<dynamic> weekStatus = data['weekStatus'] ?? [];
            var dayStatus = weekStatus.firstWhere((day) => day['date'] == today,
                orElse: () => {'status': 'blank'});
            String status = dayStatus['status'];

            Color buttonColor = Colors.white;
            IconData? iconData;
            switch (status) {
              case 'skipped':
                buttonColor = Colors.grey;
                iconData = Icons.block;
                break;
              case 'pending':
                buttonColor = Colors.yellow;
                iconData = Icons.warning;
                break;
              case 'approved':
                buttonColor = Colors.green;
                iconData = Icons.check;
                break;
              case 'denied':
                buttonColor = Colors.red;
                iconData = Icons.close;
                break;
              default:
                buttonColor = Colors.white;
                iconData = null;
            }

            return Container(
              decoration: BoxDecoration(
                border: status == 'today'
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: ElevatedButton(
                onPressed: () =>
                    _toggleStatus(context, user.uid, today, status),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                ),
                child: iconData != null
                    ? Icon(iconData, color: Colors.black)
                    : const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }
}
