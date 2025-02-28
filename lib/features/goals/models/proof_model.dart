class Proof {
  final String proofText;
  final DateTime submissionDate;
  final String status; // 'pending', 'approved', 'denied'

  Proof({
    required this.proofText,
    required this.submissionDate,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'proofText': proofText,
      'submissionDate': submissionDate.toIso8601String(),
      'status': status,
    };
  }

  factory Proof.fromMap(Map<String, dynamic> data) {
    return Proof(
      proofText: data['proofText'],
      submissionDate: DateTime.parse(data['submissionDate']),
      status: data['status'] ?? 'pending',
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
      default:
        return null;
    }
  }
}
