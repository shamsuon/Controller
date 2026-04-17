import 'package:flutter/material.dart';

enum DeviceType { switchType, buttonType, sliderType }

class SmartDevice {
  final String id;
  final String name;
  final DeviceType type;
  final IconData icon;
  final String category; // 'Lights', 'Doors', 'Fans', 'Tools'
  final String onCommand;
  final String offCommand;
  final String statusOn; // Incoming char that means ON
  final String statusOff; // Incoming char that means OFF
  final String sliderCommandPrefix; // e.g. "S" for S90
  final double minSlider;
  final double maxSlider;

  SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.category,
    this.onCommand = '',
    this.offCommand = '',
    this.statusOn = '',
    this.statusOff = '',
    this.sliderCommandPrefix = '',
    this.minSlider = 0,
    this.maxSlider = 180,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'icon': icon.codePoint,
    'category': category,
    'onCommand': onCommand,
    'offCommand': offCommand,
    'statusOn': statusOn,
    'statusOff': statusOff,
    'sliderCommandPrefix': sliderCommandPrefix,
    'minSlider': minSlider,
    'maxSlider': maxSlider,
  };

  factory SmartDevice.fromJson(Map<String, dynamic> json) => SmartDevice(
    id: json['id'],
    name: json['name'],
    type: DeviceType.values[json['type']],
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
    category: json['category'],
    onCommand: json['onCommand'] ?? '',
    offCommand: json['offCommand'] ?? '',
    statusOn: json['statusOn'] ?? '',
    statusOff: json['statusOff'] ?? '',
    sliderCommandPrefix: json['sliderCommandPrefix'] ?? '',
    minSlider: (json['minSlider'] ?? 0).toDouble(),
    maxSlider: (json['maxSlider'] ?? 180).toDouble(),
  );
}

/// Database-compatible smart device model
class SmartDeviceDB {
  final String id;
  String name;
  String tab; // Tab assignment (e.g., 'Lights', 'Doors', etc.)
  String category; // Device category
  String model; // Device model name
  String onCommand; // Command to turn ON
  String offCommand; // Command to turn OFF
  String onReceive; // Response/char when ON
  String offReceive; // Response/char when OFF
  String rack0Cmd;
  String rack90Cmd;
  String rack180Cmd;
  String rack0Receive;
  String rack90Receive;
  String rack180Receive;
  // RFID Door Lock scenario fields
  String rfidScenario1Cmd;
  String rfidScenario1Msg;
  String rfidScenario2Cmd;
  String rfidScenario2Msg;
  String rfidScenario3Cmd;
  String rfidScenario3Msg;
  String rfidScenario4Cmd;
  String rfidScenario4Msg;
  String rfidScenario5Cmd;
  String rfidScenario5Msg;
  String rfidScenario6Cmd;
  String rfidScenario6Msg;
  String rfidScenario7Cmd;
  String rfidScenario7Msg;
  String rfidLastMessage;
  // Auto Lock Door fields
  String autoLockCommand;
  int autoLockTimer;
  String autoLockState; // 'locked' or 'open'
  String icon; // Icon code as string (e.g., 'lightbulb')
  bool isFavorite;
  bool isOn; // Current ON/OFF state of the device
  int lastAngle; // Last known rack angle (0, 90, 180)
  int order; // Order for drag-to-reorder
  final DateTime createdAt;

  SmartDeviceDB({
    required this.id,
    required this.name,
    required this.tab,
    required this.category,
    required this.model,
    required this.onCommand,
    required this.offCommand,
    required this.onReceive,
    required this.offReceive,
    this.rack0Cmd = '',
    this.rack90Cmd = '',
    this.rack180Cmd = '',
    this.rack0Receive = '',
    this.rack90Receive = '',
    this.rack180Receive = '',
    this.rfidScenario1Cmd = '',
    this.rfidScenario1Msg = '',
    this.rfidScenario2Cmd = '',
    this.rfidScenario2Msg = '',
    this.rfidScenario3Cmd = '',
    this.rfidScenario3Msg = '',
    this.rfidScenario4Cmd = '',
    this.rfidScenario4Msg = '',
    this.rfidScenario5Cmd = '',
    this.rfidScenario5Msg = '',
    this.rfidScenario6Cmd = '',
    this.rfidScenario6Msg = '',
    this.rfidScenario7Cmd = '',
    this.rfidScenario7Msg = '',
    this.rfidLastMessage = '',
    this.autoLockCommand = '',
    this.autoLockTimer = 0,
    this.autoLockState = 'locked',
    required this.icon,
    this.isFavorite = false,
    this.isOn = false,
    this.lastAngle = 0,
    this.order = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tab': tab,
      'category': category,
      'model': model,
      'on_command': onCommand,
      'off_command': offCommand,
      'on_receive': onReceive,
      'off_receive': offReceive,
      'rack_0_cmd': rack0Cmd,
      'rack_90_cmd': rack90Cmd,
      'rack_180_cmd': rack180Cmd,
      'rack_0_recv': rack0Receive,
      'rack_90_recv': rack90Receive,
      'rack_180_recv': rack180Receive,
      'rfid_scenario_1_cmd': rfidScenario1Cmd,
      'rfid_scenario_1_msg': rfidScenario1Msg,
      'rfid_scenario_2_cmd': rfidScenario2Cmd,
      'rfid_scenario_2_msg': rfidScenario2Msg,
      'rfid_scenario_3_cmd': rfidScenario3Cmd,
      'rfid_scenario_3_msg': rfidScenario3Msg,
      'rfid_scenario_4_cmd': rfidScenario4Cmd,
      'rfid_scenario_4_msg': rfidScenario4Msg,
      'rfid_scenario_5_cmd': rfidScenario5Cmd,
      'rfid_scenario_5_msg': rfidScenario5Msg,
      'rfid_scenario_6_cmd': rfidScenario6Cmd,
      'rfid_scenario_6_msg': rfidScenario6Msg,
      'rfid_scenario_7_cmd': rfidScenario7Cmd,
      'rfid_scenario_7_msg': rfidScenario7Msg,
      'rfid_last_message': rfidLastMessage,
      'auto_lock_command': autoLockCommand,
      'auto_lock_timer': autoLockTimer,
      'auto_lock_state': autoLockState,
      'icon': icon,
      'is_favorite': isFavorite ? 1 : 0,
      'is_on': isOn ? 1 : 0,
      'last_angle': lastAngle,
      'device_order': order,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory SmartDeviceDB.fromMap(Map<String, dynamic> map) {
    return SmartDeviceDB(
      id: map['id'] as String,
      name: map['name'] as String,
      tab: map['tab'] as String,
      category: map['category'] as String,
      model: map['model'] as String,
      onCommand: map['on_command'] as String,
      offCommand: map['off_command'] as String,
      onReceive: map['on_receive'] as String,
      offReceive: map['off_receive'] as String,
      rack0Cmd: map['rack_0_cmd'] as String? ?? '',
      rack90Cmd: map['rack_90_cmd'] as String? ?? '',
      rack180Cmd: map['rack_180_cmd'] as String? ?? '',
      rack0Receive: map['rack_0_recv'] as String? ?? '',
      rack90Receive: map['rack_90_recv'] as String? ?? '',
      rack180Receive: map['rack_180_recv'] as String? ?? '',
      rfidScenario1Cmd: map['rfid_scenario_1_cmd'] as String? ?? '',
      rfidScenario1Msg: map['rfid_scenario_1_msg'] as String? ?? '',
      rfidScenario2Cmd: map['rfid_scenario_2_cmd'] as String? ?? '',
      rfidScenario2Msg: map['rfid_scenario_2_msg'] as String? ?? '',
      rfidScenario3Cmd: map['rfid_scenario_3_cmd'] as String? ?? '',
      rfidScenario3Msg: map['rfid_scenario_3_msg'] as String? ?? '',
      rfidScenario4Cmd: map['rfid_scenario_4_cmd'] as String? ?? '',
      rfidScenario4Msg: map['rfid_scenario_4_msg'] as String? ?? '',
      rfidScenario5Cmd: map['rfid_scenario_5_cmd'] as String? ?? '',
      rfidScenario5Msg: map['rfid_scenario_5_msg'] as String? ?? '',
      rfidScenario6Cmd: map['rfid_scenario_6_cmd'] as String? ?? '',
      rfidScenario6Msg: map['rfid_scenario_6_msg'] as String? ?? '',
      rfidScenario7Cmd: map['rfid_scenario_7_cmd'] as String? ?? '',
      rfidScenario7Msg: map['rfid_scenario_7_msg'] as String? ?? '',
      rfidLastMessage: map['rfid_last_message'] as String? ?? '',
      autoLockCommand: map['auto_lock_command'] as String? ?? '',
      autoLockTimer: map['auto_lock_timer'] as int? ?? 0,
      autoLockState: map['auto_lock_state'] as String? ?? 'locked',
      icon: map['icon'] as String,
      isFavorite: (map['is_favorite'] as int?) == 1,
      isOn: (map['is_on'] as int?) == 1,
      lastAngle: (map['last_angle'] as int?) ?? 0,
      order: (map['device_order'] as int?) ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tab': tab,
      'category': category,
      'model': model,
      'onCommand': onCommand,
      'offCommand': offCommand,
      'onReceive': onReceive,
      'offReceive': offReceive,
      'rack0Cmd': rack0Cmd,
      'rack90Cmd': rack90Cmd,
      'rack180Cmd': rack180Cmd,
      'rack0Receive': rack0Receive,
      'rack90Receive': rack90Receive,
      'rack180Receive': rack180Receive,
      'icon': icon,
      'isFavorite': isFavorite,
      'isOn': isOn,
      'lastAngle': lastAngle,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory SmartDeviceDB.fromJson(Map<String, dynamic> json) {
    return SmartDeviceDB(
      id: json['id'] as String,
      name: json['name'] as String,
      tab: json['tab'] as String,
      category: json['category'] as String,
      model: json['model'] as String,
      onCommand: json['onCommand'] as String,
      offCommand: json['offCommand'] as String,
      onReceive: json['onReceive'] as String,
      offReceive: json['offReceive'] as String,
      rack0Cmd: json['rack0Cmd'] as String? ?? '',
      rack90Cmd: json['rack90Cmd'] as String? ?? '',
      rack180Cmd: json['rack180Cmd'] as String? ?? '',
      rack0Receive: json['rack0Receive'] as String? ?? '',
      rack90Receive: json['rack90Receive'] as String? ?? '',
      rack180Receive: json['rack180Receive'] as String? ?? '',
      icon: json['icon'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isOn: json['isOn'] as bool? ?? false,
      lastAngle: json['lastAngle'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Create a copy with new values
  SmartDeviceDB copyWith({
    String? id,
    String? name,
    String? tab,
    String? category,
    String? model,
    String? onCommand,
    String? offCommand,
    String? onReceive,
    String? offReceive,
    String? rack0Cmd,
    String? rack90Cmd,
    String? rack180Cmd,
    String? rack0Receive,
    String? rack90Receive,
    String? rack180Receive,
    String? rfidScenario1Cmd,
    String? rfidScenario1Msg,
    String? rfidScenario2Cmd,
    String? rfidScenario2Msg,
    String? rfidScenario3Cmd,
    String? rfidScenario3Msg,
    String? rfidScenario4Cmd,
    String? rfidScenario4Msg,
    String? rfidScenario5Cmd,
    String? rfidScenario5Msg,
    String? rfidScenario6Cmd,
    String? rfidScenario6Msg,
    String? rfidScenario7Cmd,
    String? rfidScenario7Msg,
    String? rfidLastMessage,
    String? autoLockCommand,
    int? autoLockTimer,
    String? autoLockState,
    String? icon,
    bool? isFavorite,
    bool? isOn,
    int? lastAngle,
    int? order,
  }) {
    return SmartDeviceDB(
      id: id ?? this.id,
      name: name ?? this.name,
      tab: tab ?? this.tab,
      category: category ?? this.category,
      model: model ?? this.model,
      onCommand: onCommand ?? this.onCommand,
      offCommand: offCommand ?? this.offCommand,
      onReceive: onReceive ?? this.onReceive,
      offReceive: offReceive ?? this.offReceive,
      rack0Cmd: rack0Cmd ?? this.rack0Cmd,
      rack90Cmd: rack90Cmd ?? this.rack90Cmd,
      rack180Cmd: rack180Cmd ?? this.rack180Cmd,
      rack0Receive: rack0Receive ?? this.rack0Receive,
      rack90Receive: rack90Receive ?? this.rack90Receive,
      rack180Receive: rack180Receive ?? this.rack180Receive,
      rfidScenario1Cmd: rfidScenario1Cmd ?? this.rfidScenario1Cmd,
      rfidScenario1Msg: rfidScenario1Msg ?? this.rfidScenario1Msg,
      rfidScenario2Cmd: rfidScenario2Cmd ?? this.rfidScenario2Cmd,
      rfidScenario2Msg: rfidScenario2Msg ?? this.rfidScenario2Msg,
      rfidScenario3Cmd: rfidScenario3Cmd ?? this.rfidScenario3Cmd,
      rfidScenario3Msg: rfidScenario3Msg ?? this.rfidScenario3Msg,
      rfidScenario4Cmd: rfidScenario4Cmd ?? this.rfidScenario4Cmd,
      rfidScenario4Msg: rfidScenario4Msg ?? this.rfidScenario4Msg,
      rfidScenario5Cmd: rfidScenario5Cmd ?? this.rfidScenario5Cmd,
      rfidScenario5Msg: rfidScenario5Msg ?? this.rfidScenario5Msg,
      rfidScenario6Cmd: rfidScenario6Cmd ?? this.rfidScenario6Cmd,
      rfidScenario6Msg: rfidScenario6Msg ?? this.rfidScenario6Msg,
      rfidScenario7Cmd: rfidScenario7Cmd ?? this.rfidScenario7Cmd,
      rfidScenario7Msg: rfidScenario7Msg ?? this.rfidScenario7Msg,
      rfidLastMessage: rfidLastMessage ?? this.rfidLastMessage,
      autoLockCommand: autoLockCommand ?? this.autoLockCommand,
      autoLockTimer: autoLockTimer ?? this.autoLockTimer,
      autoLockState: autoLockState ?? this.autoLockState,
      icon: icon ?? this.icon,
      isFavorite: isFavorite ?? this.isFavorite,
      isOn: isOn ?? this.isOn,
      lastAngle: lastAngle ?? this.lastAngle,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
