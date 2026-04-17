import 'package:flutter/foundation.dart';
import 'device_model.dart';

class DeviceState {
  final String id;
  final String name;
  bool isOn;
  bool isFavorite;
  int? rackAngle; // For Laundry Rack
  String rfidLastMessage; // For RFID Door Lock

  DeviceState({
    required this.id,
    required this.name,
    required this.isOn,
    this.isFavorite = false,
    this.rackAngle,
    this.rfidLastMessage = '',
  });
}

class DeviceStateManager extends ChangeNotifier {
  final Map<String, DeviceState> _deviceStates = {};
  final Map<String, SmartDeviceDB> _deviceDefinitions = {};

  List<DeviceState> get devices => _deviceStates.values.toList();
  List<SmartDeviceDB> get definitions => _deviceDefinitions.values.toList();

  DeviceState? getDevice(String id) => _deviceStates[id];
  SmartDeviceDB? getDefinition(String id) => _deviceDefinitions[id];

  void updateDevice(String id,
      {bool? isOn,
      bool? isFavorite,
      int? rackAngle,
      String? rfidLastMessage,
      String? name}) {
    if (_deviceStates.containsKey(id)) {
      final device = _deviceStates[id]!;
      bool changed = false;

      if (isOn != null && device.isOn != isOn) {
        device.isOn = isOn;
        changed = true;
      }
      if (isFavorite != null && device.isFavorite != isFavorite) {
        device.isFavorite = isFavorite;
        changed = true;
      }
      if (rackAngle != null && device.rackAngle != rackAngle) {
        device.rackAngle = rackAngle;
        changed = true;
      }
      if (rfidLastMessage != null && device.rfidLastMessage != rfidLastMessage) {
        device.rfidLastMessage = rfidLastMessage;
        changed = true;
      }

      if (changed) {
        notifyListeners();
      }
    }
  }

  void addOrUpdateDevice(SmartDeviceDB device, DeviceState state) {
    _deviceDefinitions[device.id] = device;
    _deviceStates[device.id] = state;
    notifyListeners();
  }

  void removeDevice(String id) {
    _deviceDefinitions.remove(id);
    _deviceStates.remove(id);
    notifyListeners();
  }

  void clear() {
    _deviceDefinitions.clear();
    _deviceStates.clear();
    notifyListeners();
  }
}
