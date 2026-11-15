import 'package:equatable/equatable.dart';

/// Pickup Location Model for Lambac Roastery Locations
class PickupLocationModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String city;
  final String operatingHours;
  final String phoneNumber;
  final bool isDefault;
  final int openHour;
  final int openMinute;
  final int closeHour;
  final int closeMinute;
  final int prepBufferMinutes;
  final int slotIntervalMinutes;
  final int maxAdvanceDays;

  const PickupLocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.operatingHours,
    required this.phoneNumber,
    this.isDefault = false,
    this.openHour = 7,
    this.openMinute = 0,
    this.closeHour = 21,
    this.closeMinute = 0,
    this.prepBufferMinutes = 60,
    this.slotIntervalMinutes = 30,
    this.maxAdvanceDays = 7,
  });

  static const PickupLocationModel flagship = PickupLocationModel(
    id: 'loc_flagship_baguio',
    name: 'Lambac Flagship Roastery Bar',
    address: 'Session Road, Upper Level',
    city: 'Baguio City, Philippines',
    operatingHours: 'Daily 7:00 AM – 9:00 PM',
    phoneNumber: '+63 917 123 4567',
    isDefault: true,
    openHour: 7,
    openMinute: 0,
    closeHour: 21,
    closeMinute: 0,
    prepBufferMinutes: 60,
    slotIntervalMinutes: 30,
    maxAdvanceDays: 7,
  );

  factory PickupLocationModel.fromJson(Map<String, dynamic> json) {
    return PickupLocationModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      operatingHours: (json['operating_hours'] ?? '').toString(),
      phoneNumber: (json['phone_number'] ?? '').toString(),
      isDefault: (json['is_default'] ?? false) as bool,
      openHour: json['open_hour'] is int ? json['open_hour'] as int : 7,
      openMinute: json['open_minute'] is int ? json['open_minute'] as int : 0,
      closeHour: json['close_hour'] is int ? json['close_hour'] as int : 21,
      closeMinute: json['close_minute'] is int ? json['close_minute'] as int : 0,
      prepBufferMinutes: json['prep_buffer_minutes'] is int ? json['prep_buffer_minutes'] as int : 60,
      slotIntervalMinutes: json['slot_interval_minutes'] is int ? json['slot_interval_minutes'] as int : 30,
      maxAdvanceDays: json['max_advance_days'] is int ? json['max_advance_days'] as int : 7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'operating_hours': operatingHours,
      'phone_number': phoneNumber,
      'is_default': isDefault,
      'open_hour': openHour,
      'open_minute': openMinute,
      'close_hour': closeHour,
      'close_minute': closeMinute,
      'prep_buffer_minutes': prepBufferMinutes,
      'slot_interval_minutes': slotIntervalMinutes,
      'max_advance_days': maxAdvanceDays,
    };
  }

  Duration get prepBuffer => Duration(minutes: prepBufferMinutes);
  Duration get slotInterval => Duration(minutes: slotIntervalMinutes);

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        city,
        operatingHours,
        phoneNumber,
        isDefault,
        openHour,
        openMinute,
        closeHour,
        closeMinute,
        prepBufferMinutes,
        slotIntervalMinutes,
        maxAdvanceDays,
      ];
}
