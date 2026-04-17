import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/terminal_screen.dart';
import 'services/bluetooth_service.dart';
import 'package:provider/provider.dart';
import 'models/device_state_manager.dart';
import 'models/door_lock_models.dart';
import 'services/database_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceStateManager()),
        ChangeNotifierProvider(create: (_) => NotificationManager()),
      ],
      child: const SmartHomeApp(),
    ),
  );
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
          surface: Colors.white.withOpacity(0.05),
        ),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  StreamSubscription? _btStateSub;
  StreamSubscription? _btDataSub;
  StreamSubscription? _btTerminalSub;
  BluetoothStateEnum _btState = BluetoothStateEnum.disconnected;
  String _rxBuffer = "";
  Timer? _flushTimer;

  @override
  void initState() {
    super.initState();
    _btState = BluetoothService().currentState;
    _btStateSub = BluetoothService().stateStream.listen((state) {
      if (mounted) setState(() => _btState = state);
    });

    // Load persisted notifications on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationManager>(context, listen: false)
          .loadNotificationsFromStorage();
    });

    _setupBluetoothListeners();
  }

  void _setupBluetoothListeners() {
    _btDataSub = BluetoothService().dataStream.listen((data) {
      _rxBuffer += data;

      // Reset/Start flush timer for hardware that doesn't send \n
      _flushTimer?.cancel();
      _flushTimer = Timer(const Duration(milliseconds: 300), () {
        if (_rxBuffer.isNotEmpty) {
          debugPrint(
            '[Bluetooth] Flush Timer triggered for buffer: "$_rxBuffer"',
          );
          _processBuffer(force: true);
        }
      });

      if (_rxBuffer.contains('\n')) {
        _processBuffer(force: false);
      }
    });

    _btTerminalSub = BluetoothService().terminalStream.listen((entry) {
      if (entry.direction == TerminalDirection.tx && entry.isManual) {
        // ONLY sync UI state when commands are sent MANUALLY through the Terminal
        // This prevents "trembling" during automated button presses.
        _syncDeviceState(entry.message, isCommand: true);
      }
    });
  }

  void _processBuffer({bool force = false}) {
    if (force) {
      if (_rxBuffer.isNotEmpty) {
        _syncDeviceState(_rxBuffer.trim(), isCommand: false);
        _rxBuffer = "";
      }
      return;
    }

    final lines = _rxBuffer.split('\n');
    // Keep the last part (if it doesn't end with \n) in the buffer
    _rxBuffer = lines.last;
    // Process all complete lines
    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        _syncDeviceState(line, isCommand: false);
      }
    }
  }

  Future<void> _syncDeviceState(String msg, {bool isCommand = false}) async {
    if (!mounted || msg.isEmpty) return;

    final stateManager = Provider.of<DeviceStateManager>(
      context,
      listen: false,
    );
    final normalizedMsg = msg.trim();
    final definitions = stateManager.definitions;

    bool foundAnyMatch = false;

    for (final device in definitions) {
      final onMatch = (isCommand ? device.onCommand : device.onReceive).trim();
      final offMatch = (isCommand ? device.offCommand : device.offReceive).trim();
      final m0 = (isCommand ? device.rack0Cmd : device.rack0Receive).trim();
      final m90 = (isCommand ? device.rack90Cmd : device.rack90Receive).trim();
      final m180 = (isCommand ? device.rack180Cmd : device.rack180Receive).trim();

      // RFID Scenarios
      final r1 = device.rfidScenario1Cmd.trim();
      final r2 = device.rfidScenario2Cmd.trim();
      final r3 = device.rfidScenario3Cmd.trim();
      final r4 = device.rfidScenario4Cmd.trim();
      final r5 = device.rfidScenario5Cmd.trim();
      final r6 = device.rfidScenario6Cmd.trim();
      final r7 = device.rfidScenario7Cmd.trim();

      bool deviceMatched = false;

      // UNIVERSAL SYNC ENGINE: Check all possible signal fields for this device
      
      // 1. Check RFID Scenarios (Trigger Notifications)
      String? rfidMatchMsg;
      if (r1.isNotEmpty && normalizedMsg == r1) rfidMatchMsg = device.rfidScenario1Msg;
      else if (r2.isNotEmpty && normalizedMsg == r2) rfidMatchMsg = device.rfidScenario2Msg;
      else if (r3.isNotEmpty && normalizedMsg == r3) rfidMatchMsg = device.rfidScenario3Msg;
      else if (r4.isNotEmpty && normalizedMsg == r4) rfidMatchMsg = device.rfidScenario4Msg;
      else if (r5.isNotEmpty && normalizedMsg == r5) rfidMatchMsg = device.rfidScenario5Msg;
      else if (r6.isNotEmpty && normalizedMsg == r6) rfidMatchMsg = device.rfidScenario6Msg;
      else if (r7.isNotEmpty && normalizedMsg == r7) rfidMatchMsg = device.rfidScenario7Msg;

      if (rfidMatchMsg != null) {
        stateManager.updateDevice(device.id, rfidLastMessage: rfidMatchMsg);
        DatabaseService().updateRfidLastMessage(device.id, rfidMatchMsg);
        
        // Trigger local notification in the center
        final notificationManager = Provider.of<NotificationManager>(context, listen: false);
        notificationManager.addNotification(DoorNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          deviceId: device.id,
          message: "${device.name}: $rfidMatchMsg",
          timestamp: DateTime.now(),
        ));
        notificationManager.saveNotifications();
        deviceMatched = true;
      }

      // 2. Check specialized states (Rack angles) first to avoid overlaps with ON/OFF if codes are similar.

      if (m0.isNotEmpty && normalizedMsg == m0) {
        final state = stateManager.getDevice(device.id);
        if (state?.rackAngle != 0) {
          stateManager.updateDevice(device.id, rackAngle: 0);
          DatabaseService().updateRackAngle(device.id, 0);
        }
        deviceMatched = true;
      } else if (m90.isNotEmpty && normalizedMsg == m90) {
        final state = stateManager.getDevice(device.id);
        if (state?.rackAngle != 90) {
          stateManager.updateDevice(device.id, rackAngle: 90);
          DatabaseService().updateRackAngle(device.id, 90);
        }
        deviceMatched = true;
      } else if (m180.isNotEmpty && normalizedMsg == m180) {
        final state = stateManager.getDevice(device.id);
        if (state?.rackAngle != 180) {
          stateManager.updateDevice(device.id, rackAngle: 180);
          DatabaseService().updateRackAngle(device.id, 180);
        }
        deviceMatched = true;
      } else if (onMatch.isNotEmpty && normalizedMsg == onMatch) {
        final state = stateManager.getDevice(device.id);
        if (state == null || !state.isOn) {
          stateManager.updateDevice(device.id, isOn: true);
          DatabaseService().updateDeviceState(device.id, true);
        }
        deviceMatched = true;
      } else if (offMatch.isNotEmpty && normalizedMsg == offMatch) {
        final state = stateManager.getDevice(device.id);
        if (state == null || state.isOn) {
          stateManager.updateDevice(device.id, isOn: false);
          DatabaseService().updateDeviceState(device.id, false);
        }
        deviceMatched = true;
      }

      if (deviceMatched) foundAnyMatch = true;
    }

    if (!foundAnyMatch && !isCommand) {
      BluetoothService().logTerminalError('Unknown: "$msg" (No matching device found)');
    }
  }

  @override
  void dispose() {
    _btStateSub?.cancel();
    _btDataSub?.cancel();
    _btTerminalSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = _currentIndex == 0
        ? const HomeScreen()
        : const TerminalScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: currentScreen),

            // Simplified Solid Bottom Nav
            Container(
              margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(child: _navPill(0, Icons.home_rounded, 'Control')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _navPill(
                      1,
                      Icons.terminal_rounded,
                      'Terminal',
                      showDot: _btState == BluetoothStateEnum.connected,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navPill(
    int index,
    IconData icon,
    String label, {
    bool showDot = false,
  }) {
    final bool active = _currentIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active
                  ? Colors.white.withOpacity(0.35)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: active ? Colors.white : Colors.white54,
                  ),
                  if (showDot)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NeonGridPainter extends CustomPainter {
  final Color color;
  NeonGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
