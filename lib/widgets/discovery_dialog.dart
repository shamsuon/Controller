import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bluetooth_classic/models/device.dart';
import '../services/bluetooth_service.dart';

enum DiscoveryAction { connect, disconnectOnly, forgetOnly }

class DiscoveryResult {
  final DiscoveryAction action;
  final Device? device;

  const DiscoveryResult({required this.action, this.device});
}

class DiscoveryDialog extends StatefulWidget {
  const DiscoveryDialog({super.key});

  @override
  State<DiscoveryDialog> createState() => _DiscoveryDialogState();
}

class _DiscoveryDialogState extends State<DiscoveryDialog> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<Device> _bondedDevices = [];
  List<Device> _discoveryResults = [];
  bool _isDiscovering = false;
  String? _connectingAddress;
  Timer? _scanTimer;
  StreamSubscription<Device>? _discoveryStreamSubscription;
  StreamSubscription<BluetoothStateEnum>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _loadBondedDevices();
    _startDiscovery();
    _stateSubscription = _bluetoothService.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();
    _stateSubscription?.cancel();
    _bluetoothService.stopDiscovery();
    super.dispose();
  }

  Future<void> _loadBondedDevices() async {
    final devices = await _bluetoothService.getBondedDevices();
    if (!mounted) return;
    setState(() => _bondedDevices = devices);
  }

  void _startDiscovery() {
    if (_isDiscovering) return;
    setState(() {
      _isDiscovering = true;
      _discoveryResults.clear();
    });

    _discoveryStreamSubscription = _bluetoothService.discoveryStream.listen((
      device,
    ) {
      if (!mounted) return;
      setState(() {
        final existingIndex = _discoveryResults.indexWhere(
          (element) => element.address == device.address,
        );
        if (existingIndex == -1) _discoveryResults.add(device);
      });
    });

    _bluetoothService.startDiscovery();
    _scanTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || !_isDiscovering) return;
      _bluetoothService.stopDiscovery();
      setState(() => _isDiscovering = false);
    });
  }

  Future<void> _connect(Device device) async {
    setState(() => _connectingAddress = device.address);
    _scanTimer?.cancel();
    await _bluetoothService.stopDiscovery();
    await Future.delayed(const Duration(milliseconds: 500));

    // Attempt connection
    await _bluetoothService.connect(device.address);

    if (!mounted) return;

    // Check final state after connection attempt
    if (_bluetoothService.isConnected) {
      Navigator.pop(
        context,
        DiscoveryResult(action: DiscoveryAction.connect, device: device),
      );
    } else {
      // Connection failed - show error and allow retry
      setState(() => _connectingAddress = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Connection failed. Check server status and try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent.withOpacity(0.7),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _disconnectOnly(Device device) async {
    await _bluetoothService.disconnect();
    if (!mounted) return;
    Navigator.pop(
      context,
      DiscoveryResult(action: DiscoveryAction.disconnectOnly, device: device),
    );
  }

  Future<void> _forgetOnly(Device device) async {
    if (_bluetoothService.isConnected &&
        _bluetoothService.connectedAddress == device.address) {
      await _bluetoothService.disconnect();
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      DiscoveryResult(action: DiscoveryAction.forgetOnly, device: device),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectedAddress = _bluetoothService.connectedAddress ?? '';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Device',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (_isDiscovering)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.cyanAccent,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              onPressed: _startDiscovery,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.cyanAccent,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isDiscovering) ...[
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyanAccent.withOpacity(0.0),
                              Colors.cyanAccent,
                              Colors.cyanAccent.withOpacity(0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    ],
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          if (_bondedDevices.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(24, 20, 24, 10),
                              child: Text(
                                'PAIRED DEVICES',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            ..._bondedDevices.map((device) {
                              final isCurrent =
                                  _bluetoothService.isConnected &&
                                  connectedAddress == device.address;
                              return _DeviceTile(
                                device: device,
                                isPaired: true,
                                isConnecting:
                                    _connectingAddress == device.address,
                                isConnected: isCurrent,
                                onTap: isCurrent
                                    ? null
                                    : () => _connect(device),
                                onDisconnect: isCurrent
                                    ? () => _disconnectOnly(device)
                                    : null,
                                onForget: () => _forgetOnly(device),
                              );
                            }),
                          ],
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 20, 24, 10),
                            child: Text(
                              'AVAILABLE DEVICES',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          if (_discoveryResults.isEmpty && _isDiscovering)
                            const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(
                                child: Text(
                                  'Scanning for devices...',
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else if (_discoveryResults.isEmpty && !_isDiscovering)
                            const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(
                                child: Text(
                                  'No devices found',
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._discoveryResults.map((device) {
                              final isCurrent =
                                  _bluetoothService.isConnected &&
                                  connectedAddress == device.address;
                              return _DeviceTile(
                                device: device,
                                isConnecting:
                                    _connectingAddress == device.address,
                                isConnected: isCurrent,
                                onTap: isCurrent
                                    ? null
                                    : () => _connect(device),
                                onDisconnect: isCurrent
                                    ? () => _disconnectOnly(device)
                                    : null,
                                onForget: () => _forgetOnly(device),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final Device device;
  final bool isPaired;
  final bool isConnecting;
  final bool isConnected;
  final VoidCallback? onTap;
  final VoidCallback? onDisconnect;
  final VoidCallback? onForget;

  const _DeviceTile({
    required this.device,
    this.isPaired = false,
    this.isConnecting = false,
    this.isConnected = false,
    required this.onTap,
    this.onDisconnect,
    this.onForget,
  });

  @override
  Widget build(BuildContext context) {
    final actionText = isConnected ? 'CONNECTED' : 'CONNECT';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnecting ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.cyanAccent.withOpacity(0.08)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected
                    ? Colors.cyanAccent.withOpacity(0.4)
                    : Colors.white.withOpacity(0.1),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.cyanAccent.withOpacity(0.15)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.cyanAccent,
                            ),
                          ),
                        )
                      : Icon(
                          isConnected
                              ? Icons.bluetooth_connected_rounded
                              : (isPaired
                                    ? Icons.devices_other_rounded
                                    : Icons.bluetooth_audio_rounded),
                          color: isConnected
                              ? Colors.cyanAccent
                              : Colors.white70,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name ?? 'Unknown Device',
                        style: TextStyle(
                          color: isConnected
                              ? Colors.white
                              : Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.address,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isConnected) ...[
                  IconButton(
                    onPressed: onDisconnect,
                    icon: Icon(
                      Icons.link_off_rounded,
                      color: Colors.orangeAccent.withOpacity(0.8),
                      size: 20,
                    ),
                    tooltip: 'Disconnect',
                  ),
                  IconButton(
                    onPressed: onForget,
                    icon: Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.redAccent.withOpacity(0.8),
                      size: 20,
                    ),
                    tooltip: 'Forget',
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.cyanAccent.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isConnected
                            ? Colors.cyanAccent.withOpacity(0.5)
                            : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      actionText,
                      style: TextStyle(
                        color: isConnected
                            ? Colors.cyanAccent
                            : Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
