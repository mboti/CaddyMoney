import 'package:caddymoney/core/enums/transaction_type.dart';
import 'package:caddymoney/core/enums/transaction_status.dart';

class TransactionModel {
  final String id;
  final String transactionReference;
  final String? senderProfileId;
  final String? senderWalletId;
  final String? receiverProfileId;
  final String? receiverMerchantId;
  final String? receiverWalletId;
  final double amount;
  final String currencyCode;
  final String? note;
  final TransactionType type;
  final TransactionStatus status;
  final String? failureReason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  TransactionModel({
    required this.id,
    required this.transactionReference,
    this.senderProfileId,
    this.senderWalletId,
    this.receiverProfileId,
    this.receiverMerchantId,
    this.receiverWalletId,
    required this.amount,
    required this.currencyCode,
    this.note,
    required this.type,
    required this.status,
    this.failureReason,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      transactionReference: json['transaction_reference'] as String,
      senderProfileId: json['sender_profile_id'] as String?,
      senderWalletId: json['sender_wallet_id'] as String?,
      receiverProfileId: json['receiver_profile_id'] as String?,
      receiverMerchantId: json['receiver_merchant_id'] as String?,
      receiverWalletId: json['receiver_wallet_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currency_code'] as String,
      note: json['note'] as String?,
      type: TransactionType.fromString(json['type'] as String),
      status: TransactionStatus.fromString(json['status'] as String),
      failureReason: json['failure_reason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_reference': transactionReference,
      'sender_profile_id': senderProfileId,
      'sender_wallet_id': senderWalletId,
      'receiver_profile_id': receiverProfileId,
      'receiver_merchant_id': receiverMerchantId,
      'receiver_wallet_id': receiverWalletId,
      'amount': amount,
      'currency_code': currencyCode,
      'note': note,
      'type': type.toJson(),
      'status': status.toJson(),
      'failure_reason': failureReason,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? transactionReference,
    String? senderProfileId,
    String? senderWalletId,
    String? receiverProfileId,
    String? receiverMerchantId,
    String? receiverWalletId,
    double? amount,
    String? currencyCode,
    String? note,
    TransactionType? type,
    TransactionStatus? status,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      transactionReference: transactionReference ?? this.transactionReference,
      senderProfileId: senderProfileId ?? this.senderProfileId,
      senderWalletId: senderWalletId ?? this.senderWalletId,
      receiverProfileId: receiverProfileId ?? this.receiverProfileId,
      receiverMerchantId: receiverMerchantId ?? this.receiverMerchantId,
      receiverWalletId: receiverWalletId ?? this.receiverWalletId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      note: note ?? this.note,
      type: type ?? this.type,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
