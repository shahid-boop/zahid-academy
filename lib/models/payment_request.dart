enum PaymentStatus { pending, approved, rejected }

/// JazzCash / Easypaisa payment verification request.
class PaymentRequest {
  final String id;
  final String userId;
  final String userEmail;
  final String method; // 'jazzcash' | 'easypaisa'
  final String accountNumber;
  final String reference;
  final String? screenshotUrl;
  final String? note;
  final PaymentStatus status;
  final int createdAtMs;
  final int? reviewedAtMs;
  final String? reviewerId;

  const PaymentRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.method,
    required this.accountNumber,
    required this.reference,
    this.screenshotUrl,
    this.note,
    required this.status,
    required this.createdAtMs,
    this.reviewedAtMs,
    this.reviewerId,
  });

  factory PaymentRequest.fromMap(String id, Map<String, dynamic> map) {
    return PaymentRequest(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      userEmail: (map['userEmail'] ?? '').toString(),
      method: (map['method'] ?? 'jazzcash').toString(),
      accountNumber: (map['accountNumber'] ?? '').toString(),
      reference: (map['reference'] ?? '').toString(),
      screenshotUrl: map['screenshotUrl']?.toString(),
      note: map['note']?.toString(),
      status: _statusFrom(map['status']?.toString()),
      createdAtMs: map['createdAtMs'] is int
          ? map['createdAtMs'] as int
          : int.tryParse(map['createdAtMs']?.toString() ?? '') ?? 0,
      reviewedAtMs: map['reviewedAtMs'] is int
          ? map['reviewedAtMs'] as int
          : int.tryParse(map['reviewedAtMs']?.toString() ?? ''),
      reviewerId: map['reviewerId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userEmail': userEmail,
        'method': method,
        'accountNumber': accountNumber,
        'reference': reference,
        'screenshotUrl': screenshotUrl,
        'note': note,
        'status': status.name,
        'createdAtMs': createdAtMs,
        'reviewedAtMs': reviewedAtMs,
        'reviewerId': reviewerId,
      };

  static PaymentStatus _statusFrom(String? value) {
    switch (value) {
      case 'approved':
        return PaymentStatus.approved;
      case 'rejected':
        return PaymentStatus.rejected;
      default:
        return PaymentStatus.pending;
    }
  }

  PaymentRequest copyWith({
    PaymentStatus? status,
    int? reviewedAtMs,
    String? reviewerId,
  }) {
    return PaymentRequest(
      id: id,
      userId: userId,
      userEmail: userEmail,
      method: method,
      accountNumber: accountNumber,
      reference: reference,
      screenshotUrl: screenshotUrl,
      note: note,
      status: status ?? this.status,
      createdAtMs: createdAtMs,
      reviewedAtMs: reviewedAtMs ?? this.reviewedAtMs,
      reviewerId: reviewerId ?? this.reviewerId,
    );
  }

  String get dateLabel {
    final date = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    return '${date.day}/${date.month}/${date.year}';
  }
}
