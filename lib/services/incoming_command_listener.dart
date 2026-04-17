import 'dart:async';
import 'bluetooth_service.dart';
import 'database_service.dart';
import '../models/device_model.dart';
import '../models/device_state_manager.dart';
import '../models/door_lock_models.dart';

/// Listens to incoming Bluetooth commands and updates device state accordingly.
/// This listener runs continuously independent of UI navigation.
class IncomingCommandListener {
  static final IncomingCommandListener _instance =
      IncomingCommandListener._internal();
  factory IncomingCommandListener() => _instance;

  IncomingCommandListener._internal();

  final BluetoothService _bluetoothService = BluetoothService();
  final DatabaseService _databaseService = DatabaseService();

  StreamSubscription? _dataSubscription;
  bool _isListening = false;

  /// Start listening to incoming Bluetooth commands.
  /// This method should be called once during app initialization.
  Future<void> startListening({
    required DeviceStateManager deviceStateManager,
    required NotificationManager notificationManager,
  }) async {
    if (_isListening) {
      print(
        '[IncomingCommandListener] Already listening, ignoring duplicate start request',
      );
      return;
    }

    _isListening = true;
    print(
      '[IncomingCommandListener] Started listening to incoming Bluetooth commands',
    );

    _dataSubscription = _bluetoothService.dataStream.listen(
      (String incomingData) async {
        try {
          await _handleIncomingData(
            incomingData,
            deviceStateManager,
            notificationManager,
          );
        } catch (e) {
          print('[IncomingCommandListener] Error handling incoming data: $e');
        }
      },
      onError: (error) {
        print('[IncomingCommandListener] Stream error: $error');
      },
      onDone: () {
        print(
          '[IncomingCommandListener] Stream closed, will reconnect when Bluetooth reconnects',
        );
        _isListening = false;
      },
    );
  }

  /// Stop listening to incoming commands.
  void stopListening() {
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _isListening = false;
    print('[IncomingCommandListener] Stopped listening');
  }

  /// Handle incoming data from the Bluetooth device.
  /// Parses the data and updates device state accordingly.
  Future<void> _handleIncomingData(
    String data,
    DeviceStateManager deviceStateManager,
    NotificationManager notificationManager,
  ) async {
    // Trim whitespace and skip empty messages
    final trimmedData = data.trim();
    if (trimmedData.isEmpty) return;

    print('[IncomingCommandListener] Received: $trimmedData');

    // Parse the incoming data
    final parts = trimmedData.split(':');
    if (parts.isEmpty) return;

    final deviceId = parts[0].trim();
    final command = parts.length > 1 ? parts[1].trim() : '';
    final value = parts.length > 2 ? parts[2].trim() : '';

    // Load all devices from database to find matching device
    final devices = await _databaseService.getAllDevices();
    SmartDeviceDB? targetDevice;

    for (final device in devices) {
      if (device.id.toLowerCase() == deviceId.toLowerCase()) {
        targetDevice = device;
        break;
      }
    }

    if (targetDevice == null) {
      print(
        '[IncomingCommandListener] Warning: Device "$deviceId" not found. Skipping update.',
      );
      return;
    }

    // Route to appropriate handler based on device category/model
    switch (targetDevice.category.toLowerCase()) {
      case 'light':
      case 'switch':
        await _handleToggleDevice(
          targetDevice,
          command,
          value,
          deviceStateManager,
        );
        break;
      case 'laundry_rack':
        await _handleRackDevice(
          targetDevice,
          command,
          value,
          deviceStateManager,
        );
        break;
      case 'rfid_door_lock':
        await _handleRfidDoorLock(
          targetDevice,
          command,
          value,
          deviceStateManager,
          notificationManager,
        );
        break;
      case 'auto_lock_door':
        await _handleAutoLockDoor(
          targetDevice,
          command,
          value,
          deviceStateManager,
        );
        break;
      default:
        print(
          '[IncomingCommandListener] Unknown device category: ${targetDevice.category}',
        );
    }
  }

  /// Handle toggle devices (lights, switches, etc.)
  Future<void> _handleToggleDevice(
    SmartDeviceDB device,
    String command,
    String value,
    DeviceStateManager deviceStateManager,
  ) async {
    final commandLower = command.toLowerCase();

    // Determine if device is on or off based on command
    bool? newState;

    if (commandLower == device.onCommand.toLowerCase() ||
        commandLower == 'on' ||
        value.toLowerCase() == 'on') {
      newState = true;
    } else if (commandLower == device.offCommand.toLowerCase() ||
        commandLower == 'off' ||
        value.toLowerCase() == 'off') {
      newState = false;
    }

    if (newState != null) {
      // Update in-memory state
      deviceStateManager.updateDevice(device.id, isOn: newState);

      // Update database
      final updatedDevice = device.copyWith(isOn: newState);
      await _databaseService.updateDevice(updatedDevice);

      print(
        '[IncomingCommandListener] Updated ${device.name} to ${newState ? 'ON' : 'OFF'}',
      );
    }
  }

  /// Handle rack devices (laundry racks with angle control)
  Future<void> _handleRackDevice(
    SmartDeviceDB device,
    String command,
    String value,
    DeviceStateManager deviceStateManager,
  ) async {
    int? angle;

    if (command.toLowerCase() == device.rack0Cmd.toLowerCase() ||
        value.toLowerCase() == '0') {
      angle = 0;
    } else if (command.toLowerCase() == device.rack90Cmd.toLowerCase() ||
        value.toLowerCase() == '90') {
      angle = 90;
    } else if (command.toLowerCase() == device.rack180Cmd.toLowerCase() ||
        value.toLowerCase() == '180') {
      angle = 180;
    }

    if (angle != null) {
      // Update in-memory state
      deviceStateManager.updateDevice(device.id, rackAngle: angle);

      // Update database
      final updatedDevice = device.copyWith(lastAngle: angle);
      await _databaseService.updateDevice(updatedDevice);

      print(
        '[IncomingCommandListener] Updated ${device.name} angle to $angle°',
      );
    }
  }

  /// Handle RFID door lock devices
  Future<void> _handleRfidDoorLock(
    SmartDeviceDB device,
    String command,
    String value,
    DeviceStateManager deviceStateManager,
    NotificationManager notificationManager,
  ) async {
    final commandLower = command.toLowerCase();

    // Check which scenario this command matches
    String? scenarioMessage;

    if (commandLower == device.rfidScenario1Cmd.toLowerCase() &&
        device.rfidScenario1Cmd.isNotEmpty) {
      scenarioMessage = device.rfidScenario1Msg;
    } else if (commandLower == device.rfidScenario2Cmd.toLowerCase() &&
        device.rfidScenario2Cmd.isNotEmpty) {
      scenarioMessage = device.rfidScenario2Msg;
    } else if (commandLower == device.rfidScenario3Cmd.toLowerCase() &&
        device.rfidScenario3Cmd.isNotEmpty) {
      scenarioMessage = device.rfidScenario3Msg;
    } else if (commandLower == device.rfidScenario4Cmd.toLowerCase() &&
        device.rfidScenario4Cmd.isNotEmpty) {
      scenarioMessage = device.rfidScenario4Msg;
    }

    if (scenarioMessage != null && scenarioMessage.isNotEmpty) {
      // Update last message in database
      final updatedDevice = device.copyWith(rfidLastMessage: scenarioMessage);
      await _databaseService.updateDevice(updatedDevice);

      // Create notification
      final notification = DoorNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: device.id,
        message: scenarioMessage,
        timestamp: DateTime.now(),
      );

      // Add to notification manager (updates UI)
      notificationManager.addNotification(notification);

      // Persist notification
      await notificationManager.saveNotifications();

      print(
        '[IncomingCommandListener] RFID event: ${device.name} - $scenarioMessage',
      );
    }
  }

  /// Handle auto lock door devices
  Future<void> _handleAutoLockDoor(
    SmartDeviceDB device,
    String command,
    String value,
    DeviceStateManager deviceStateManager,
  ) async {
    final commandLower = command.toLowerCase();

    // Check if this is the open door command
    if (commandLower == device.autoLockCommand.toLowerCase() &&
        device.autoLockCommand.isNotEmpty) {
      // Update database with current timer value and 'open' state
      final updatedDevice = device.copyWith(
        autoLockState: 'open',
        autoLockTimer: device.autoLockTimer, // Reset or keep current
      );
      await _databaseService.updateDevice(updatedDevice);

      // Update in-memory state
      deviceStateManager.updateDevice(
        device.id,
        isOn: true,
      ); // 'open' = isOn true

      print(
        '[IncomingCommandListener] Auto-lock door opened: ${device.name}, timer starts: ${device.autoLockTimer}s',
      );
    }
  }

  bool get isListening => _isListening;
}
