import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device_model.dart';
import '../models/device_state_manager.dart';
import '../services/database_service.dart';
import '../services/bluetooth_service.dart';

class RfidDoorLockCard extends StatefulWidget {
  final SmartDeviceDB device;
  final bool isConnected;
  final VoidCallback onFavoriteToggled;
  final VoidCallback onDelete;

  const RfidDoorLockCard({
    super.key,
    required this.device,
    required this.isConnected,
    required this.onFavoriteToggled,
    required this.onDelete,
  });

  @override
  State<RfidDoorLockCard> createState() => _RfidDoorLockCardState();
}

class _RfidDoorLockCardState extends State<RfidDoorLockCard> {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _toggleFavorite(bool currentFavorite) async {
    final newFavorite = !currentFavorite;
    widget.device.isFavorite = newFavorite; // Update object in-place for immediate filtering
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

  @override
  Widget build(BuildContext context) {
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
                color: Colors.cyanAccent.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {}, // Maintain visual feedback on tap
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
                              color: Colors.cyanAccent.withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.cyanAccent,
                            size: 24,
                          ),
                        ),
                        Consumer<DeviceStateManager>(
                          builder: (context, stateManager, _) {
                            final state = stateManager.getDevice(widget.device.id);
                            final isFavorite = state?.isFavorite ?? widget.device.isFavorite;
                            return IconButton(
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
                            );
                          },
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
                      'RFID Card Reader',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Last message display
                    Consumer<DeviceStateManager>(
                      builder: (context, stateManager, _) {
                        final state = stateManager.getDevice(widget.device.id);
                        final displayMsg = state?.rfidLastMessage ?? 
                                         widget.device.rfidLastMessage;
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Event:',
                                style: TextStyle(
                                  color: Colors.cyanAccent[200],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                displayMsg.isNotEmpty
                                    ? displayMsg
                                    : 'No event yet',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

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
  }
}
