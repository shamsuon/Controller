import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';

enum BluetoothStateEnum { disconnected, connecting, connected, error }

enum TerminalDirection { tx, rx }

class TerminalEntry {
  final String message;
  final TerminalDirection direction;
  final DateTime time;
  final bool isError;
  final bool isManual;
  TerminalEntry({
    required this.message,
    required this.direction,
    required this.time,
    this.isError = false,
    this.isManual = false,
  });
}

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;

  BluetoothService._internal() {
    _initPluginStreams();
  }

  final BluetoothClassic _bluetooth = BluetoothClassic();
  String? _connectedAddress;
  BluetoothStateEnum _state = BluetoothStateEnum.disconnected;

  final _stateController = StreamController<BluetoothStateEnum>.broadcast();
  final _dataController = StreamController<String>.broadcast();
  final _discoveryController = StreamController<Device>.broadcast();
  final _terminalController = StreamController<TerminalEntry>.broadcast();

  final List<TerminalEntry> terminalLog = [];

  Stream<BluetoothStateEnum> get stateStream => _stateController.stream;
  BluetoothStateEnum get currentState => _state;
  Stream<String> get dataStream => _dataController.stream;
  Stream<Device> get discoveryStream => _discoveryController.stream;
  Stream<TerminalEntry> get terminalStream => _terminalController.stream;

  bool get isConnected => _state == BluetoothStateEnum.connected;
  String? get connectedAddress => _connectedAddress;

  // Persistent State is now managed by DeviceStateManager and DatabaseService.


  void _updateState(BluetoothStateEnum newState, [String? debugInfo]) {
    _state = newState;
    _stateController.add(newState);
    if (debugInfo != null) {
      print('[BluetoothService] State changed to $newState: $debugInfo');
    } else {
      print('[BluetoothService] State changed to $newState');
    }
  }

  void _initPluginStreams() {
    _bluetooth.onDeviceDiscovered().listen(
      (device) => _discoveryController.add(device),
    );
    _bluetooth.onDeviceDataReceived().listen((Uint8List data) {
      String incoming = utf8.decode(data, allowMalformed: true);
      _dataController.add(incoming);
      _logTerminal(incoming, TerminalDirection.rx);
    });
  }

  void _logTerminal(String msg, TerminalDirection dir,
      {bool isError = false, bool isManual = false}) {
    final entry = TerminalEntry(
      message: msg,
      direction: dir,
      time: DateTime.now(),
      isError: isError,
      isManual: isManual,
    );
    terminalLog.add(entry);
    if (terminalLog.length > 100) terminalLog.removeAt(0);
    _terminalController.add(entry);
  }

  void logTerminalError(String msg) {
    _logTerminal(msg, TerminalDirection.rx, isError: true);
  }



  Future<void> connect(String address) async {
    // Use SPP (Serial Port Profile) UUID for Bluetooth Classic RFCOMM
    const String sppUuid = "00001101-0000-1000-8000-00805F9B34FB";
    const int maxRetries = 3;
    const Duration retryDelay = Duration(milliseconds: 500);
    const Duration postConnectionDelay = Duration(milliseconds: 800);

    _updateState(BluetoothStateEnum.connecting, 'Connecting to $address');

    try {
      // Ensure no active scans before connecting
      try {
        await _bluetooth.stopScan();
      } catch (e) {
        print("[BluetoothService] Warning: Failed to stop scan: $e");
      }

      // Wait for Bluetooth stack to be ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Attempt connection with retries
      bool connected = false;
      int attempts = 0;

      while (attempts < maxRetries && !connected) {
        attempts++;
        try {
          print(
            "[BluetoothService] Connection attempt $attempts/$maxRetries to $address",
          );
          connected = await _bluetooth.connect(address, sppUuid);

          if (connected) {
            print(
              "[BluetoothService] Connection successful on attempt $attempts",
            );
            _connectedAddress = address;
            // Wait for socket to fully establish
            await Future.delayed(postConnectionDelay);
            _updateState(BluetoothStateEnum.connected, 'Connected to $address');
            return;
          } else {
            print("[BluetoothService] Connection failed on attempt $attempts");
            if (attempts < maxRetries) {
              await Future.delayed(retryDelay);
            }
          }
        } catch (e) {
          final errorMsg =
              "[BluetoothService] Connection error on attempt $attempts: $e";
          print(errorMsg);
          _updateState(BluetoothStateEnum.error, errorMsg);
          if (attempts < maxRetries) {
            await Future.delayed(retryDelay);
          }
        }
      }

      // All retries exhausted
      _connectedAddress = null;
      _updateState(
        BluetoothStateEnum.error,
        'Failed to connect to $address after $maxRetries attempts',
      );
    } catch (e) {
      print("[BluetoothService] Connection flow error: $e");
      _connectedAddress = null;
      _updateState(BluetoothStateEnum.error, 'Exception during connection: $e');
    }
  }

  Future<void> startDiscovery() async {
    try {
      await _bluetooth.startScan();
    } catch (e) {
      print("Error starting discovery: $e");
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _bluetooth.stopScan();
    } catch (e) {
      print("Error stopping discovery: $e");
    }
  }

  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (e) {
      print("Error during disconnect: $e");
    } finally {
      _connectedAddress = null;
      _updateState(BluetoothStateEnum.disconnected);
    }
  }

  Future<List<Device>> getBondedDevices() async {
    try {
      return await _bluetooth.getPairedDevices();
    } catch (e) {
      print("Error getting paired devices: $e");
      return [];
    }
  }

  Future<void> sendCommand(String cmd, {bool isManual = false}) async {
    if (_state != BluetoothStateEnum.connected) {
      print(
        "[BluetoothService] Warning: Attempted to send command while not connected (state: $_state)",
      );
      return;
    }

    if (cmd.isEmpty) {
      print("[BluetoothService] Warning: Attempted to send empty command");
      return;
    }

    try {
      // Send command with newline for line-based protocol
      final commandWithNewline = '$cmd\n';
      await _bluetooth.write(commandWithNewline);
      _logTerminal(cmd, TerminalDirection.tx, isManual: isManual);
      print("[BluetoothService] Command sent: $cmd");
    } catch (e) {
      print("[BluetoothService] Error sending command: $e");
      // On send error, assume connection is lost
      _updateState(BluetoothStateEnum.error, 'Send command failed: $e');
    }
  }
}
