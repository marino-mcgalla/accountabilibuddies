import 'proof_model.dart';

class ChallengeData {
  final Map<String, String> completions; // date -> 'pending'|'completed'|'denied'|'skipped'
  final List<Proof> proofs; // For total goals
  final Map<String, Proof> dailyProofs; // For weekly goals (date -> proof)

  const ChallengeData({
    this.completions = const {},
    this.proofs = const [],
    this.dailyProofs = const {},
  });

  ChallengeData copyWith({
    Map<String, String>? completions,
    List<Proof>? proofs,
    Map<String, Proof>? dailyProofs,
  }) {
    return ChallengeData(
      completions: completions ?? this.completions,
      proofs: proofs ?? this.proofs,
      dailyProofs: dailyProofs ?? this.dailyProofs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completions': completions,
      'proofs': proofs.map((proof) => proof.toMap()).toList(),
      'dailyProofs': dailyProofs.map((key, proof) => MapEntry(key, proof.toMap())),
    };
  }

  factory ChallengeData.fromMap(Map<String, dynamic> data) {
    final completions = Map<String, String>.from(data['completions'] ?? {});
    
    // Handle proofs (for total goals)
    final proofsData = data['proofs'] ?? [];
    List<Proof> proofs = [];
    if (proofsData is List) {
      proofs = proofsData.map((proofData) => Proof.fromMap(proofData)).toList();
    }
    
    // Handle daily proofs (for weekly goals)
    final dailyProofsData = data['dailyProofs'] ?? {};
    Map<String, Proof> dailyProofs = {};
    if (dailyProofsData is Map) {
      dailyProofs = dailyProofsData.map((key, proofData) => 
          MapEntry(key, Proof.fromMap(proofData)));
    }

    return ChallengeData(
      completions: completions,
      proofs: proofs,
      dailyProofs: dailyProofs,
    );
  }

  /// Create ChallengeData from legacy challenge format (goal_model.dart)
  factory ChallengeData.fromLegacyMap(Map<String, dynamic> data) {
    final completions = Map<String, String>.from(data['completions'] ?? {});
    
    // Handle legacy proofs format
    final proofsData = data['proofs'];
    List<Proof> proofs = [];
    Map<String, Proof> dailyProofs = {};
    
    if (proofsData is List) {
      // Total goal format - list of proofs
      proofs = proofsData.map((proofData) {
        // Add ID if missing
        if (proofData is Map && proofData['id'] == null) {
          proofData['id'] = 'legacy_${DateTime.now().millisecondsSinceEpoch}';
        }
        return Proof.fromMap(proofData);
      }).toList();
    } else if (proofsData is Map) {
      // Weekly goal format - map of date -> proof
      dailyProofs = proofsData.map((key, proofData) {
        // Add ID if missing
        if (proofData is Map && proofData['id'] == null) {
          proofData['id'] = 'legacy_${key}_${DateTime.now().millisecondsSinceEpoch}';
        }
        return MapEntry(key, Proof.fromMap(proofData));
      });
    }

    return ChallengeData(
      completions: completions,
      proofs: proofs,
      dailyProofs: dailyProofs,
    );
  }

  /// Create ChallengeData from legacy currentWeekCompletions format (goal_model.dart)
  factory ChallengeData.fromLegacyCompletions(Map<String, dynamic> completionsData) {
    final completions = <String, String>{};
    
    // Convert mixed types to consistent string format
    completionsData.forEach((date, value) {
      if (value is bool) {
        completions[date] = value ? 'completed' : 'pending';
      } else if (value is int) {
        completions[date] = value > 0 ? 'completed' : 'pending';
      } else if (value is String) {
        completions[date] = value;
      }
    });

    return ChallengeData(
      completions: completions,
      proofs: [],
      dailyProofs: {},
    );
  }

  // Helper methods
  List<Proof> get pendingProofs {
    List<Proof> pending = [];
    
    // Add pending proofs from total goals
    pending.addAll(proofs.where((proof) => proof.status == ProofStatus.pending));
    
    // Add pending proofs from weekly goals
    pending.addAll(dailyProofs.values.where((proof) => proof.status == ProofStatus.pending));
    
    return pending;
  }

  int get totalCompletions {
    return completions.values.where((status) => status == 'completed').length;
  }

  int get totalDenials {
    return completions.values.where((status) => status == 'denied').length;
  }

  bool hasProofForDate(String date) {
    return dailyProofs.containsKey(date);
  }

  String getCompletionStatus(String date) {
    return completions[date] ?? 'not_attempted';
  }
}