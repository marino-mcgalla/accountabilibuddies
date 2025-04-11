class Proof {
  final String proofText;
  final DateTime submissionDate;
  final String status; // 'pending', 'approved', 'denied'
  final String? imageUrl; // URL to the uploaded image in Firebase Storage

  Proof({
    required this.proofText,
    required this.submissionDate,
    this.status = 'pending',
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'proofText': proofText,
      'submissionDate': submissionDate.toIso8601String(),
      'status': status,
      'imageUrl': imageUrl, // Include imageUrl in the map
    };
  }

  factory Proof.fromMap(Map<String, dynamic> data) {
    return Proof(
      proofText: data['proofText'],
      submissionDate: DateTime.parse(data['submissionDate']),
      status: data['status'] ?? 'pending',
      imageUrl: data['imageUrl'], // Extract imageUrl from the map
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
