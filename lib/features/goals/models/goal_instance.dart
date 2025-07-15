import 'challenge_data.dart';
import 'proof_model.dart';
import 'goal_template.dart';

/// Goal Instance - A goal created from a template for a specific challenge
/// This is separate from Goal templates and contains challenge-specific data
class GoalInstance {
  final String id;
  final String templateId;
  final String partyId;
  final String challengeId;
  final String ownerId;
  final GoalType type;
  final int frequency;
  final String name;
  final String description;
  final String category;
  final DateTime createdAt;
  final ChallengeData challengeData;

  const GoalInstance({
    required this.id,
    required this.templateId,
    required this.partyId,
    required this.challengeId,
    required this.ownerId,
    required this.type,
    required this.frequency,
    required this.name,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.challengeData,
  });

  /// Create goal instance from template
  factory GoalInstance.fromTemplate({
    required GoalTemplate template,
    required String partyId,
    required String challengeId,
    required String ownerId,
    int? customFrequency,
  }) {
    final now = DateTime.now();
    return GoalInstance(
      id: '${template.id}_${partyId}_${challengeId}_${now.millisecondsSinceEpoch}',
      templateId: template.id,
      partyId: partyId,
      challengeId: challengeId,
      ownerId: ownerId,
      type: template.type,
      frequency: customFrequency ?? template.defaultFrequency,
      name: template.name,
      description: template.description,
      category: template.category,
      createdAt: now,
      challengeData: const ChallengeData(),
    );
  }

  /// Create from Firestore map
  factory GoalInstance.fromMap(Map<String, dynamic> data) {
    return GoalInstance(
      id: data['id'] as String,
      templateId: data['templateId'] as String,
      partyId: data['partyId'] as String,
      challengeId: data['challengeId'] as String,
      ownerId: data['ownerId'] as String,
      type: GoalType.fromString(data['type'] as String? ?? 'daily'),
      frequency: data['frequency'] as int,
      name: data['name'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      challengeData: data['challengeData'] != null
          ? ChallengeData.fromMap(data['challengeData'] as Map<String, dynamic>)
          : const ChallengeData(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'partyId': partyId,
      'challengeId': challengeId,
      'ownerId': ownerId,
      'type': type.value,
      'frequency': frequency,
      'name': name,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'challengeData': challengeData.toMap(),
    };
  }

  /// Add proof to this goal instance
  GoalInstance addProof(String proofText, String? imageUrl, DateTime date) {
    final dateKey = date.toIso8601String().split('T')[0];
    
    final proof = Proof(
      id: '${id}_${dateKey}_${DateTime.now().millisecondsSinceEpoch}',
      proofText: proofText,
      imageUrl: imageUrl,
      submissionDate: date,
      status: ProofStatus.pending,
    );

    final updatedChallengeData = type == GoalType.daily
        ? _addDailyProof(proof, dateKey)
        : _addTotalProof(proof);

    return copyWith(challengeData: updatedChallengeData);
  }

  /// Add proof for daily-type goals
  ChallengeData _addDailyProof(Proof proof, String dateKey) {
    final updatedDailyProofs = Map<String, Proof>.from(challengeData.dailyProofs);
    final updatedCompletions = Map<String, String>.from(challengeData.completions);
    
    updatedDailyProofs[dateKey] = proof;
    
    // Don't override if already completed
    if (updatedCompletions[dateKey] != 'completed') {
      updatedCompletions[dateKey] = 'pending';
    }

    return challengeData.copyWith(
      dailyProofs: updatedDailyProofs,
      completions: updatedCompletions,
    );
  }

  /// Add proof for total-type goals
  ChallengeData _addTotalProof(Proof proof) {
    final updatedProofs = List<Proof>.from(challengeData.proofs);
    updatedProofs.add(proof);

    return challengeData.copyWith(proofs: updatedProofs);
  }

  /// Approve a proof
  GoalInstance approveProof(String proofId, String? date) {
    if (type == GoalType.daily && date != null) {
      return _approveDailyProof(date);
    } else {
      return _approveTotalProof(proofId);
    }
  }

  /// Approve daily proof
  GoalInstance _approveDailyProof(String date) {
    final updatedCompletions = Map<String, String>.from(challengeData.completions);
    final updatedDailyProofs = Map<String, Proof>.from(challengeData.dailyProofs);
    
    updatedCompletions[date] = 'completed';
    
    // Update proof status
    if (updatedDailyProofs[date] != null) {
      updatedDailyProofs[date] = updatedDailyProofs[date]!.copyWith(
        status: ProofStatus.approved
      );
    }

    return copyWith(
      challengeData: challengeData.copyWith(
        completions: updatedCompletions,
        dailyProofs: updatedDailyProofs,
      ),
    );
  }

  /// Approve total proof
  GoalInstance _approveTotalProof(String proofId) {
    final updatedProofs = challengeData.proofs.map((proof) {
      if (proof.id == proofId) {
        return proof.copyWith(status: ProofStatus.approved);
      }
      return proof;
    }).toList();

    return copyWith(
      challengeData: challengeData.copyWith(
        proofs: updatedProofs,
      ),
    );
  }

  /// Deny a proof
  GoalInstance denyProof(String proofId, String? date) {
    if (type == GoalType.daily && date != null) {
      return _denyDailyProof(date);
    } else {
      return _denyTotalProof(proofId);
    }
  }

  /// Deny daily proof
  GoalInstance _denyDailyProof(String date) {
    final updatedCompletions = Map<String, String>.from(challengeData.completions);
    final updatedDailyProofs = Map<String, Proof>.from(challengeData.dailyProofs);
    
    updatedCompletions[date] = 'denied';
    
    // Update proof status
    if (updatedDailyProofs[date] != null) {
      updatedDailyProofs[date] = updatedDailyProofs[date]!.copyWith(
        status: ProofStatus.denied
      );
    }

    return copyWith(
      challengeData: challengeData.copyWith(
        completions: updatedCompletions,
        dailyProofs: updatedDailyProofs,
      ),
    );
  }

  /// Deny total proof
  GoalInstance _denyTotalProof(String proofId) {
    final updatedProofs = challengeData.proofs.map((proof) {
      if (proof.id == proofId) {
        return proof.copyWith(status: ProofStatus.denied);
      }
      return proof;
    }).toList();

    return copyWith(
      challengeData: challengeData.copyWith(proofs: updatedProofs),
    );
  }

  /// Get completion status for a specific date (daily goals)
  String? getCompletionStatus(String date) {
    return challengeData.completions[date];
  }

  /// Get pending proofs
  List<Proof> get pendingProofs {
    if (type == GoalType.daily) {
      return challengeData.dailyProofs.values
          .where((proof) => proof.status == ProofStatus.pending)
          .toList();
    } else {
      return challengeData.proofs
          .where((proof) => proof.status == ProofStatus.pending)
          .toList();
    }
  }

  /// Check if goal is completed
  bool get isCompleted {
    return challengeData.totalCompletions >= frequency;
  }

  /// Get completion progress (0.0 to 1.0)
  double get completionProgress {
    return frequency > 0 ? (challengeData.totalCompletions / frequency).clamp(0.0, 1.0) : 0.0;
  }

  /// Copy with new values
  GoalInstance copyWith({
    String? id,
    String? templateId,
    String? partyId,
    String? challengeId,
    String? ownerId,
    GoalType? type,
    int? frequency,
    String? name,
    String? description,
    String? category,
    DateTime? createdAt,
    ChallengeData? challengeData,
  }) {
    return GoalInstance(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      partyId: partyId ?? this.partyId,
      challengeId: challengeId ?? this.challengeId,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      challengeData: challengeData ?? this.challengeData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalInstance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GoalInstance(id: $id, name: $name, type: $type, partyId: $partyId)';
  }
}