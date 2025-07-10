enum ProofStatus {
  pending,
  approved,
  denied;

  static ProofStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return ProofStatus.approved;
      case 'denied':
        return ProofStatus.denied;
      case 'pending':
      default:
        return ProofStatus.pending;
    }
  }

  String get name {
    switch (this) {
      case ProofStatus.pending:
        return 'pending';
      case ProofStatus.approved:
        return 'approved';
      case ProofStatus.denied:
        return 'denied';
    }
  }
}

class Proof {
  final String id;
  final String proofText;
  final DateTime submissionDate;
  final ProofStatus status;
  final String? imageUrl; // URL to the uploaded image in Firebase Storage

  const Proof({
    required this.id,
    required this.proofText,
    required this.submissionDate,
    this.status = ProofStatus.pending,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proofText': proofText,
      'submissionDate': submissionDate.toIso8601String(),
      'status': status.name,
      'imageUrl': imageUrl,
    };
  }

  factory Proof.fromMap(Map<String, dynamic> data) {
    return Proof(
      id: data['id'] ?? '',
      proofText: data['proofText'] ?? '',
      submissionDate: DateTime.parse(data['submissionDate']),
      status: ProofStatus.fromString(data['status'] ?? 'pending'),
      imageUrl: data['imageUrl'],
    );
  }

  Proof copyWith({
    String? id,
    String? proofText,
    DateTime? submissionDate,
    ProofStatus? status,
    String? imageUrl,
  }) {
    return Proof(
      id: id ?? this.id,
      proofText: proofText ?? this.proofText,
      submissionDate: submissionDate ?? this.submissionDate,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Add operator[] to support the existing code
  dynamic operator [](String key) {
    switch (key) {
      case 'proofText':
        return proofText;
      case 'submissionDate':
        return submissionDate.toIso8601String();
      case 'status':
        return status;
      case 'imageUrl':
        return imageUrl;
      default:
        return null;
    }
  }
}
