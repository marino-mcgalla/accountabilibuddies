import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProofEvent {
  final String type; // 'submitted', 'approved', 'denied', 'appealed'
  final String userId;
  final String goalId;
  final String? proofDate;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  ProofEvent({
    required this.type,
    required this.userId,
    required this.goalId,
    this.proofDate,
    required this.data,
    required this.timestamp,
  });
}

class ProofStreamManager {
  final FirebaseFirestore _firestore;
  
  ProofStreamManager({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Real-time stream of proof events for a party
  /// This ensures all party members see proof submissions/approvals immediately
  Stream<ProofEvent> getPartyProofEventsStream(String partyId) {
    return _firestore
        .collection('parties')
        .doc(partyId)
        .collection('proofEvents')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .asyncExpand((snapshot) {
      // Convert document changes to proof events
      return Stream.fromIterable(
        snapshot.docChanges
            .where((change) => change.type == DocumentChangeType.added)
            .map((change) {
          final data = change.doc.data()!;
          return ProofEvent(
            type: data['type'],
            userId: data['userId'],
            goalId: data['goalId'],
            proofDate: data['proofDate'],
            data: data['data'] ?? {},
            timestamp: (data['timestamp'] as Timestamp).toDate(),
          );
        }),
      );
    });
  }

  /// Emit a proof event that all party members will receive
  Future<void> emitProofEvent(String partyId, ProofEvent event) async {
    await _firestore
        .collection('parties')
        .doc(partyId)
        .collection('proofEvents')
        .add({
      'type': event.type,
      'userId': event.userId,
      'goalId': event.goalId,
      'proofDate': event.proofDate,
      'data': event.data,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream for pending proofs that need approval (for party members)
  Stream<List<Map<String, dynamic>>> getPendingProofsStream(String partyId, List<String> memberIds) async* {
    if (memberIds.isEmpty) {
      yield [];
      return;
    }

    // Listen to real-time changes for all members' goals
    final StreamController<List<Map<String, dynamic>>> controller = StreamController<List<Map<String, dynamic>>>();
    
    final List<StreamSubscription> subscriptions = [];
    
    for (String memberId in memberIds) {
      final subscription = _firestore
          .collection('userGoals')
          .doc(memberId)
          .snapshots()
          .listen((snapshot) async {
        // Collect pending proofs from all members whenever any member's goals change
        List<Map<String, dynamic>> allProofs = [];
        
        for (String userId in memberIds) {
          final userProofs = await _getUserPendingProofs(userId);
          allProofs.addAll(userProofs);
        }
        
        controller.add(allProofs);
      });
      
      subscriptions.add(subscription);
    }

    yield* controller.stream;
    
    // Clean up subscriptions when stream is cancelled
    controller.onCancel = () {
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
    };
  }

  Future<List<Map<String, dynamic>>> _getUserPendingProofs(String userId) async {
    try {
      
      final userGoalsDoc = await _firestore.collection('userGoals').doc(userId).get();
      
      
      if (!userGoalsDoc.exists) {
        
        return [];
      }
      
      final data = userGoalsDoc.data();
      
      
      
      if (data == null) {
        
        return [];
      }
      
      if (!data.containsKey('goals')) {
        
        return [];
      }
      
      List<Map<String, dynamic>> pendingProofs = [];
      final goals = data['goals'] as List<dynamic>;
      
      
      for (int i = 0; i < goals.length; i++) {
        final goalData = goals[i];
        ');
        
        final challenge = goalData['challenge'];
        
        
        if (challenge == null) {
          
          continue;
        }
        
        // Check for pending proofs in weekly goals
        if (goalData['goalType'] == 'weekly') {
          
          if (challenge['proofs'] is Map) {
            final proofs = challenge['proofs'] as Map;
            
            proofs.forEach((date, proof) {
              
              if (proof is Map && proof['status'] == 'pending') {
                
                pendingProofs.add({
                  'userId': userId,
                  'goalId': goalData['id'],
                  'goalName': goalData['goalName'],
                  'proofDate': date,
                  'proof': proof,
                  'goalType': 'weekly',
                });
              } else {
                
              }
            });
          } else {
            
          }
        }
        
        // Check for pending proofs in total goals
        if (goalData['goalType'] == 'total') {
          
          if (challenge['proofs'] is List) {
            final proofs = challenge['proofs'] as List;
            
            for (int j = 0; j < proofs.length; j++) {
              final proof = proofs[j];
              
              if (proof is Map && proof['status'] == 'pending') {
                
                pendingProofs.add({
                  'userId': userId,
                  'goalId': goalData['id'],
                  'goalName': goalData['goalName'],
                  'proofDate': null,
                  'proof': proof,
                  'goalType': 'total',
                });
              } else {
                
              }
            }
          } else {
            
          }
        }
      }
      
      
      return pendingProofs;
    } catch (e) {
      
      
      return [];
    }
  }

  /// Clean up old proof events (run periodically)
  Future<void> cleanupOldProofEvents(String partyId, {int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    final oldEvents = await _firestore
        .collection('parties')
        .doc(partyId)
        .collection('proofEvents')
        .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();
    
    final batch = _firestore.batch();
    for (var doc in oldEvents.docs) {
      batch.delete(doc.reference);
    }
    
    if (oldEvents.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}