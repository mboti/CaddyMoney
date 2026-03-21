import 'package:caddymoney/core/enums/merchant_status.dart';

class MerchantModel {
  final String id;
  final String profileId;
  final String uniqueMerchantId;
  final String businessName;
  final String ownerName;
  final String businessEmail;
  final String? businessPhone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postalCode;
  final String? countryCode;
  final String? businessCategory;
  final String? registrationNumber;
  final String? taxNumber;
  final MerchantStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedReason;
  final String? suspendedReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  MerchantModel({
    required this.id,
    required this.profileId,
    required this.uniqueMerchantId,
    required this.businessName,
    required this.ownerName,
    required this.businessEmail,
    this.businessPhone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postalCode,
    this.countryCode,
    this.businessCategory,
    this.registrationNumber,
    this.taxNumber,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectedReason,
    this.suspendedReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      uniqueMerchantId: json['unique_merchant_id'] as String,
      businessName: json['business_name'] as String,
      ownerName: json['owner_name'] as String,
      businessEmail: json['business_email'] as String,
      businessPhone: json['business_phone'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      countryCode: json['country_code'] as String?,
      businessCategory: json['business_category'] as String?,
      registrationNumber: json['registration_number'] as String?,
      taxNumber: json['tax_number'] as String?,
      status: MerchantStatus.fromString(json['status'] as String),
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at'] as String) : null,
      rejectedReason: json['rejected_reason'] as String?,
      suspendedReason: json['suspended_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'unique_merchant_id': uniqueMerchantId,
      'business_name': businessName,
      'owner_name': ownerName,
      'business_email': businessEmail,
      'business_phone': businessPhone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'postal_code': postalCode,
      'country_code': countryCode,
      'business_category': businessCategory,
      'registration_number': registrationNumber,
      'tax_number': taxNumber,
      'status': status.toJson(),
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_reason': rejectedReason,
      'suspended_reason': suspendedReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MerchantModel copyWith({
    String? id,
    String? profileId,
    String? uniqueMerchantId,
    String? businessName,
    String? ownerName,
    String? businessEmail,
    String? businessPhone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    String? countryCode,
    String? businessCategory,
    String? registrationNumber,
    String? taxNumber,
    MerchantStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedReason,
    String? suspendedReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      uniqueMerchantId: uniqueMerchantId ?? this.uniqueMerchantId,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      countryCode: countryCode ?? this.countryCode,
      businessCategory: businessCategory ?? this.businessCategory,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      taxNumber: taxNumber ?? this.taxNumber,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      suspendedReason: suspendedReason ?? this.suspendedReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
