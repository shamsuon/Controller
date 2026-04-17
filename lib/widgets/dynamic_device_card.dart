import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/bluetooth_service.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import '../models/device_state_manager.dart';

class DynamicDeviceCard extends StatelessWidget {
  final SmartDeviceDB device;
  final bool isConnected;
  final VoidCallback onFavoriteToggled;
  final VoidCallback onDelete;

  const DynamicDeviceCard({
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
    final iconData = _getIconForCategory(device.category);
    final state = deviceStateManager.getDevice(device.id);
    final isOn = state?.isOn ?? device.isOn;
    final isFavorite = state?.isFavorite ?? device.isFavorite;

    Future<void> toggleDevice(bool newState) async {
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connect to a device first'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      deviceStateManager.updateDevice(device.id, isOn: newState);
      await _databaseService.updateDeviceState(device.id, newState);
      final command = newState ? device.onCommand : device.offCommand;
      await _bluetoothService.sendCommand(command);
    }

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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _databaseService.deleteDevice(device.id);
        onDelete();
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isConnected ? () => toggleDevice(!isOn) : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOn 
                ? Colors.cyanAccent.withOpacity(0.08) 
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOn 
                  ? Colors.cyanAccent.withOpacity(0.5) 
                  : Colors.white.withOpacity(0.15),
              width: isOn ? 1.5 : 1,
            ),
            boxShadow: isOn
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
                      color: isOn 
                          ? Colors.cyanAccent.withOpacity(0.2) 
                          : Colors.cyanAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      iconData, 
                      color: isOn ? Colors.cyanAccent : Colors.white54, 
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
                            fontWeight: isOn ? FontWeight.w900 : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          device.model,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  //Favorite Button
                  GestureDetector(
                    onTap: () {
                      // Prevent parent onTap (toggle) when clicking favorite
                      toggleFavorite();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isFavorite ? Colors.amber : Colors.white38,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
  
              // Toggle Switch / Status
              Row(
                children: [
                   Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOn ? Colors.greenAccent : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: isOn ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.5),
                          blurRadius: 4,
                        )
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOn ? 'ACTIVE' : 'OFFLINE',
                      style: TextStyle(
                        color: isOn ? Colors.greenAccent : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  // We keep the switch visible for visual cue, but the entire card is clickable
                  Switch(
                    value: isOn,
                    activeColor: Colors.cyanAccent,
                    activeTrackColor: Colors.cyanAccent.withOpacity(0.3),
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white.withOpacity(0.1),
                    onChanged: isConnected ? toggleDevice : null,
                  ),
                  const SizedBox(width: 4),
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
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'lighting':
        return Icons.lightbulb_outline_rounded;
      case 'doors & locks':
        return Icons.lock_outline_rounded;
      case 'fans':
        return Icons.air_rounded;
      case 'refrigerators':
        return Icons.kitchen_rounded;
      case 'air conditioners':
        return Icons.ac_unit_rounded;
      case 'tools & appliances':
        return Icons.electrical_services_rounded;
      case 'entertainment':
        return Icons.speaker_notes_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'heating':
        return Icons.local_fire_department_rounded;
      case 'irrigation':
        return Icons.water_drop_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }
}
