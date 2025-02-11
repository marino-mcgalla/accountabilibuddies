import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'week_view_grid.dart';

class GoalCard extends StatelessWidget {
  final String goalId;
  final String goalName;
  final int goalFrequency;
  final String goalCriteria;

  const GoalCard({
    required this.goalId,
    required this.goalName,
    required this.goalFrequency,
    required this.goalCriteria,
    Key? key,
  }) : super(key: key);

  Future<void> _submitProof(BuildContext context) async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    DocumentReference goalRef =
        FirebaseFirestore.instance.collection('goals').doc(goalId);
    DocumentSnapshot goalDoc = await goalRef.get();
    if (goalDoc.exists) {
      List<dynamic> weekStatus = goalDoc['weekStatus'];
      int index = weekStatus.indexWhere((day) => day['date'] == today);
      if (index != -1) {
        weekStatus[index]['status'] = 'pending';
        weekStatus[index]['updatedBy'] = currentUserId;
        weekStatus[index]['updatedAt'] = Timestamp.now();
        await goalRef.update({'weekStatus': weekStatus});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proof submitted for today")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goals')
          .doc(goalId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return const Center(child: Text("Goal not found"));
        }
        var goal = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> weekStatus = goal['weekStatus'];
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        int index = weekStatus.indexWhere((day) => day['date'] == today);
        bool isProofSubmittedToday =
            index != -1 && weekStatus[index]['status'] == 'pending';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goalName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Frequency: $goalFrequency times per week"),
                const SizedBox(height: 10),
                Text("Criteria: $goalCriteria"),
                const SizedBox(height: 20),
                WeekViewGrid(goalId: goalId),
                const SizedBox(height: 20),
                if (!isProofSubmittedToday)
                  ElevatedButton(
                    onPressed: () => _submitProof(context),
                    child: const Text("Submit Proof"),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
