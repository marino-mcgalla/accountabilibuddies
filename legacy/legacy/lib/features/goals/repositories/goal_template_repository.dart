import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_template.dart';

class GoalTemplateRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GoalTemplateRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _goalTemplatesCollection {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('goalTemplates');
  }

  // Create a new goal template
  Future<String?> createGoalTemplate(GoalTemplate template) async {
    try {
      final docRef = await _goalTemplatesCollection.add(template.toFirestore());
      return docRef.id;
    } catch (e) {
      
      return null;
    }
  }

  // Update an existing goal template
  Future<bool> updateGoalTemplate(GoalTemplate template) async {
    try {
      await _goalTemplatesCollection.doc(template.id).update(template.toFirestore());
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Archive a goal template
  Future<bool> archiveGoalTemplate(String templateId) async {
    try {
      await _goalTemplatesCollection.doc(templateId).update({
        'status': GoalStatus.archived.value,
        'archivedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Reactivate an archived goal template
  Future<bool> reactivateGoalTemplate(String templateId) async {
    try {
      await _goalTemplatesCollection.doc(templateId).update({
        'status': GoalStatus.active.value,
        'archivedAt': null,
      });
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Delete a goal template
  Future<bool> deleteGoalTemplate(String templateId) async {
    try {
      await _goalTemplatesCollection.doc(templateId).delete();
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Get a single goal template by ID
  Future<GoalTemplate?> getGoalTemplate(String templateId) async {
    try {
      final doc = await _goalTemplatesCollection.doc(templateId).get();
      if (doc.exists) {
        return GoalTemplate.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      
      return null;
    }
  }

  // Stream all goal templates for the current user
  Stream<List<GoalTemplate>> streamGoalTemplates() {
    return _goalTemplatesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalTemplate.fromFirestore(doc))
            .toList());
  }

  // Stream only active goal templates
  Stream<List<GoalTemplate>> streamActiveGoalTemplates() {
    return _goalTemplatesCollection
        .where('status', isEqualTo: GoalStatus.active.value)
        .orderBy('lastUsedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalTemplate.fromFirestore(doc))
            .toList());
  }

  // Stream only archived goal templates
  Stream<List<GoalTemplate>> streamArchivedGoalTemplates() {
    return _goalTemplatesCollection
        .where('status', isEqualTo: GoalStatus.archived.value)
        .orderBy('archivedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalTemplate.fromFirestore(doc))
            .toList());
  }

  // Stream goal templates by category
  Stream<List<GoalTemplate>> streamGoalTemplatesByCategory(String category) {
    return _goalTemplatesCollection
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: GoalStatus.active.value)
        .orderBy('lastUsedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalTemplate.fromFirestore(doc))
            .toList());
  }

  // Get goal templates for a specific status
  Future<List<GoalTemplate>> getGoalTemplatesByStatus(GoalStatus status) async {
    try {
      final snapshot = await _goalTemplatesCollection
          .where('status', isEqualTo: status.value)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => GoalTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      
      return [];
    }
  }

  // Update usage statistics when a template is used in a challenge
  Future<bool> updateUsageStats(String templateId) async {
    try {
      final templateRef = _goalTemplatesCollection.doc(templateId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(templateRef);
        if (!snapshot.exists) return;
        
        final currentUsage = snapshot.data()?['totalChallengesUsed'] ?? 0;
        
        transaction.update(templateRef, {
          'totalChallengesUsed': currentUsage + 1,
          'lastUsedAt': Timestamp.now(),
        });
      });
      
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Batch operations for multiple templates
  Future<bool> batchArchiveTemplates(List<String> templateIds) async {
    try {
      final batch = _firestore.batch();
      final timestamp = Timestamp.now();
      
      for (final id in templateIds) {
        batch.update(_goalTemplatesCollection.doc(id), {
          'status': GoalStatus.archived.value,
          'archivedAt': timestamp,
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      
      return false;
    }
  }

  Future<bool> batchReactivateTemplates(List<String> templateIds) async {
    try {
      final batch = _firestore.batch();
      
      for (final id in templateIds) {
        batch.update(_goalTemplatesCollection.doc(id), {
          'status': GoalStatus.active.value,
          'archivedAt': null,
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Search goal templates by name or description
  Future<List<GoalTemplate>> searchGoalTemplates(String query) async {
    try {
      // Note: This is a simple client-side search. For production, 
      // consider using Algolia or similar for better search capabilities
      final snapshot = await _goalTemplatesCollection
          .where('status', isEqualTo: GoalStatus.active.value)
          .get();
      
      final templates = snapshot.docs
          .map((doc) => GoalTemplate.fromFirestore(doc))
          .toList();
      
      final lowercaseQuery = query.toLowerCase();
      return templates.where((template) {
        return template.name.toLowerCase().contains(lowercaseQuery) ||
               template.description.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      
      return [];
    }
  }

  // Get template statistics
  Future<Map<String, int>> getTemplateStats() async {
    try {
      final activeSnapshot = await _goalTemplatesCollection
          .where('status', isEqualTo: GoalStatus.active.value)
          .get();
      
      final archivedSnapshot = await _goalTemplatesCollection
          .where('status', isEqualTo: GoalStatus.archived.value)
          .get();
      
      return {
        'total': activeSnapshot.docs.length + archivedSnapshot.docs.length,
        'active': activeSnapshot.docs.length,
        'archived': archivedSnapshot.docs.length,
      };
    } catch (e) {
      
      return {'total': 0, 'active': 0, 'archived': 0};
    }
  }
}