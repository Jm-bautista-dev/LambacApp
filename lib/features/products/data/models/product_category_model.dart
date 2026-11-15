import 'package:equatable/equatable.dart';

/// Product Category Model
class ProductCategoryModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? iconName;
  final String? description;
  final int sortOrder;

  const ProductCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconName,
    this.description,
    this.sortOrder = 0,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      iconName: json['icon']?.toString() ?? json['icon_name']?.toString(),
      description: json['description']?.toString(),
      sortOrder: (json['sort_order'] ?? json['order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (iconName != null) 'icon_name': iconName,
      if (description != null) 'description': description,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, name, slug, iconName, description, sortOrder];
}
