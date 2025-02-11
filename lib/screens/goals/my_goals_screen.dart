import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/goal_card.dart';

class MyGoalsScreen extends StatelessWidget {
  const MyGoalsScreen({super.key});

  Future<void> _toggleStatus(BuildContext context, String docId, String date,
      String currentStatus) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    DocumentReference docRef =
        FirebaseFirestore.instance.collection('goals').doc(docId);
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

    return Scaffold(
      appBar: AppBar(title: const Text("My Goals")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('goals')
            .where('ownerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No goals found'));
          }
          var goals = snapshot.data!.docs;

          return ListView.builder(
            itemCount: goals.length,
            itemBuilder: (context, index) {
              var goalData = goals[index].data() as Map<String, dynamic>;
              String goalId = goals[index].id;
              String goalName = goalData['goalName'];
              int goalFrequency = goalData['goalFrequency'];
              String goalCriteria = goalData['goalCriteria'];
              List<dynamic> weekStatus = goalData['weekStatus'] ?? [];

              return GoalCard(
                goalId: goalId,
                goalName: goalName,
                goalFrequency: goalFrequency,
                goalCriteria: goalCriteria,
                weekStatus: weekStatus,
                toggleStatus: _toggleStatus,
              );
            },
          );
        },
      ),
    );
  }
}
