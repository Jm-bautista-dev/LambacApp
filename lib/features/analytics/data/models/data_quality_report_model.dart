import 'package:equatable/equatable.dart';

/// Data Quality Audit Report Container DTO
class DataQualityReportModel extends Equatable {
  final int totalRecordsProcessed;
  final int validRecordsCount;
  final int corruptedRecordsCount;
  final int duplicateCount;
  final int invalidPriceCount;
  final int invalidQuantityCount;
  final double completenessScorePercent;
  final DateTime auditedAt;
  final int mobileAppCount;
  final int walkInCount;

  const DataQualityReportModel({
    required this.totalRecordsProcessed,
    required this.validRecordsCount,
    required this.corruptedRecordsCount,
    required this.duplicateCount,
    required this.invalidPriceCount,
    required this.invalidQuantityCount,
    required this.completenessScorePercent,
    required this.auditedAt,
    required this.mobileAppCount,
    required this.walkInCount,
  });

  bool get isClean => corruptedRecordsCount == 0;

  factory DataQualityReportModel.fromJson(Map<String, dynamic> json) {
    return DataQualityReportModel(
      totalRecordsProcessed: (json['total_records_processed'] ?? 0) as int,
      validRecordsCount: (json['valid_records_count'] ?? 0) as int,
      corruptedRecordsCount: (json['corrupted_records_count'] ?? 0) as int,
      duplicateCount: (json['duplicate_count'] ?? 0) as int,
      invalidPriceCount: (json['invalid_price_count'] ?? 0) as int,
      invalidQuantityCount: (json['invalid_quantity_count'] ?? 0) as int,
      completenessScorePercent: ((json['completeness_score_percent'] ?? 100.0) as num).toDouble(),
      auditedAt: json['audited_at'] != null
          ? DateTime.tryParse(json['audited_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      mobileAppCount: (json['mobile_app_count'] ?? 0) as int,
      walkInCount: (json['walk_in_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_records_processed': totalRecordsProcessed,
      'valid_records_count': validRecordsCount,
      'corrupted_records_count': corruptedRecordsCount,
      'duplicate_count': duplicateCount,
      'invalid_price_count': invalidPriceCount,
      'invalid_quantity_count': invalidQuantityCount,
      'completeness_score_percent': completenessScorePercent,
      'audited_at': auditedAt.toIso8601String(),
      'mobile_app_count': mobileAppCount,
      'walk_in_count': walkInCount,
    };
  }

  @override
  List<Object?> get props => [
        totalRecordsProcessed,
        validRecordsCount,
        corruptedRecordsCount,
        duplicateCount,
        invalidPriceCount,
        invalidQuantityCount,
        completenessScorePercent,
        auditedAt,
        mobileAppCount,
        walkInCount,
      ];
}
