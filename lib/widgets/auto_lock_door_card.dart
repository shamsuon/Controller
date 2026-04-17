import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device_model.dart';
import '../models/device_state_manager.dart';
import '../services/database_service.dart';
import '../services/bluetooth_service.dart';

class AutoLockDoorCard extends StatefulWidget {
  final SmartDeviceDB device;
  final bool isConnected;
  final VoidCallback onFavoriteToggled;
  final VoidCallback onDelete;

  const AutoLockDoorCard({
    super.key,
    required this.device,
    required this.isConnected,
    required this.onFavoriteToggled,
    required this.onDelete,
  });

  @override
  State<AutoLockDoorCard> createState() => _AutoLockDoorCardState();
}

class _AutoLockDoorCardState extends State<AutoLockDoorCard> {
  late int _remainingSeconds;
  Timer? _countdownTimer;

  final DatabaseService _databaseService = DatabaseService();
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 0;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleFavorite(bool currentFavorite) async {
    final newFavorite = !currentFavorite;
    widget.device.isFavorite = newFavorite;
    await _databaseService.toggleFavorite(widget.device.id, newFavorite);

    final stateManager = Provider.of<DeviceStateManager>(
      context,
      listen: false,
    );
    stateManager.updateDevice(widget.device.id, isFavorite: newFavorite);

    widget.onFavoriteToggled();
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Remove "${widget.device.name}" from your home?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _databaseService.deleteDevice(widget.device.id);
              Navigator.pop(ctx);
              widget.onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendDoorCommand() async {
    if (!widget.isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device not connected')));
      return;
    }

    try {
      _bluetoothService.sendCommand(widget.device.autoLockCommand);

      final stateManager = Provider.of<DeviceStateManager>(
        context,
        listen: false,
      );

      // Update local state immediately (optimistic update)
      setState(() {
        _remainingSeconds = widget.device.autoLockTimer;
      });
      stateManager.updateDevice(widget.device.id, isOn: true);

      // Start countdown timer
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) {
              _remainingSeconds = 0;
              stateManager.updateDevice(widget.device.id, isOn: false);
              timer.cancel();
            }
          });
        } else {
          timer.cancel();
        }
      });

      // Update database
      final updated = widget.device.copyWith(
        autoLockState: 'open',
        autoLockTimer: widget.device.autoLockTimer,
      );
      await _databaseService.updateDevice(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _lockDoor() async {
    final stateManager = Provider.of<DeviceStateManager>(
      context,
      listen: false,
    );
    
    setState(() {
      _remainingSeconds = 0;
    });
    stateManager.updateDevice(widget.device.id, isOn: false);

    _countdownTimer?.cancel();

    final updated = widget.device.copyWith(
      autoLockState: 'locked',
      autoLockTimer: widget.device.autoLockTimer,
    );
    await _databaseService.updateDevice(updated);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Door manually locked')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceStateManager>(
      builder: (context, stateManager, _) {
        final state = stateManager.getDevice(widget.device.id);
        final isOpen = state?.isOn ?? (widget.device.autoLockState == 'open');
        final isFavorite = state?.isFavorite ?? widget.device.isFavorite;
        
        final isCountingDown = isOpen && _remainingSeconds > 0;
        final countdownPercent = _remainingSeconds / widget.device.autoLockTimer;

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isOpen
                        ? Colors.orangeAccent.withOpacity(0.15)
                        : Colors.cyanAccent.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with icon and favorite button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isOpen
                                      ? Colors.orangeAccent.withOpacity(0.5)
                                      : Colors.cyanAccent.withOpacity(0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                isOpen ? Icons.lock_open : Icons.lock,
                                color: isOpen
                                    ? Colors.orangeAccent
                                    : Colors.cyanAccent,
                                size: 24,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _toggleFavorite(isFavorite),
                              icon: Icon(
                                isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: isFavorite ? Colors.amber : Colors.white70,
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Device name
                        Text(
                          widget.device.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart Auto-Lock Door',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status and countdown
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? Colors.orangeAccent.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOpen
                                  ? Colors.orangeAccent.withOpacity(0.3)
                                  : Colors.green.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isOpen ? 'Status: Unlocked' : 'Status: Locked',
                                    style: TextStyle(
                                      color: isOpen
                                          ? Colors.orangeAccent[200]
                                          : Colors.green[200],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (isCountingDown)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_remainingSeconds}s',
                                        style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (isCountingDown) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: countdownPercent,
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Colors.orangeAccent,
                                    ),
                                    minHeight: 3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isOpen ? null : _sendDoorCommand,
                                icon: const Icon(Icons.lock_open, size: 18),
                                label: const Text('Unlock'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isOpen
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.orangeAccent,
                                  foregroundColor: isOpen
                                      ? Colors.white.withOpacity(0.4)
                                      : Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            if (isOpen) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _lockDoor,
                                  icon: const Icon(Icons.lock, size: 18),
                                  label: const Text('Lock Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyanAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Connection status and Delete Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.isConnected
                                        ? Colors.greenAccent
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.isConnected ? 'Connected' : 'Disconnected',
                                  style: TextStyle(
                                    color: widget.isConnected
                                        ? Colors.greenAccent
                                        : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent.withOpacity(0.5),
                                size: 18,
                              ),
                              onPressed: _showDeleteConfirm,
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
