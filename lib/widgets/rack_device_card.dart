import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/bluetooth_service.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import '../models/device_state_manager.dart';
import '../utils/icon_mapper.dart';

class RackDeviceCard extends StatelessWidget {
  final SmartDeviceDB device;
  final bool isConnected;
  final VoidCallback onFavoriteToggled;
  final VoidCallback onDelete;

  const RackDeviceCard({
    Key? key,
    required this.device,
    required this.isConnected,
    required this.onFavoriteToggled,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceStateManager = Provider.of<DeviceStateManager>(context);
    final _bluetoothService = BluetoothService();
    final _databaseService = DatabaseService();
    final iconData = IconMapper.getIcon(device.icon);
    
    final state = deviceStateManager.getDevice(device.id);
    final currentAngle = state?.rackAngle ?? 0;
    final isFavorite = state?.isFavorite ?? device.isFavorite;

    Future<void> toggleFavorite() async {
      final newFavoriteState = !isFavorite;
      device.isFavorite = newFavoriteState; // Update object property for immediate filtering
      await _databaseService.toggleFavorite(device.id, newFavoriteState);
      deviceStateManager.updateDevice(device.id, isFavorite: newFavoriteState);
      onFavoriteToggled();
    }

    Future<void> deleteDevice() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Delete Device?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${device.name}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _databaseService.deleteDevice(device.id);
        onDelete();
      }
    }

    Future<void> setAngle(int angle) async {
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connect to a device first'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      deviceStateManager.updateDevice(device.id, rackAngle: angle);
      await _databaseService.updateRackAngle(device.id, angle);
      
      String command = '';
      if (angle == 0) command = device.rack0Cmd;
      else if (angle == 90) command = device.rack90Cmd;
      else if (angle == 180) command = device.rack180Cmd;

      if (command.isNotEmpty) {
        await _bluetoothService.sendCommand(command);
      }
    }

    Widget angleButton(int angle) {
      final isActive = currentAngle == angle;
      return Expanded(
        child: InkWell(
          onTap: isConnected ? () => setAngle(angle) : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isActive 
                  ? Colors.cyanAccent.withOpacity(0.25) 
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive 
                    ? Colors.cyanAccent 
                    : Colors.white.withOpacity(0.1),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  blurRadius: 10,
                )
              ] : null,
            ),
            child: Center(
              child: Text(
                '$angle°',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: currentAngle > 0 
              ? Colors.cyanAccent.withOpacity(0.08) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: currentAngle > 0 
                ? Colors.cyanAccent.withOpacity(0.5) 
                : Colors.white.withOpacity(0.15),
            width: currentAngle > 0 ? 1.5 : 1,
          ),
          boxShadow: currentAngle > 0
              ? [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Header: Icon, Name, Favorite Button
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentAngle > 0 
                        ? Colors.cyanAccent.withOpacity(0.2) 
                        : Colors.cyanAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    iconData, 
                    color: currentAngle > 0 ? Colors.cyanAccent : Colors.white54, 
                    size: 24
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: currentAngle > 0 ? FontWeight.w900 : FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Laundry Rack • Mode: $currentAngle°',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Favorite Button
                GestureDetector(
                  onTap: toggleFavorite,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFavorite ? Colors.amber : Colors.white38,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 3-State Angles Selector
            Row(
              children: [
                angleButton(0),
                const SizedBox(width: 10),
                angleButton(90),
                const SizedBox(width: 10),
                angleButton(180),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.greenAccent : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'READY' : 'OFFLINE',
                      style: TextStyle(
                        color: isConnected ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent.withOpacity(0.4),
                    size: 18,
                  ),
                  onPressed: deleteDevice,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
