import 'package:equatable/equatable.dart';

enum InsightType { positive, warning, info }

/// Human-Readable Data-Generated Insight Entity
class BusinessInsightModel extends Equatable {
  final String title;
  final String text;
  final InsightType type;

  const BusinessInsightModel({
    required this.title,
    required this.text,
    this.type = InsightType.info,
  });

  factory BusinessInsightModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? 'info').toString();
    final type = switch (typeStr.toLowerCase()) {
      'positive' => InsightType.positive,
      'warning' => InsightType.warning,
      _ => InsightType.info,
    };

    return BusinessInsightModel(
      title: (json['title'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'text': text,
      'type': type.name,
    };
  }

  @override
  List<Object?> get props => [title, text, type];
}
