import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/database_service.dart';

class AutoLockDoorForm extends StatefulWidget {
  final SmartDeviceDB? editingDevice;
  final VoidCallback onDeviceSaved;

  const AutoLockDoorForm({
    Key? key,
    this.editingDevice,
    required this.onDeviceSaved,
  }) : super(key: key);

  @override
  State<AutoLockDoorForm> createState() => _AutoLockDoorFormState();
}

class _AutoLockDoorFormState extends State<AutoLockDoorForm> {
  late TextEditingController _nameController;
  late TextEditingController _commandController;
  late TextEditingController _timerController;

  final DatabaseService _databaseService = DatabaseService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.editingDevice?.name ?? 'Auto-Lock Door',
    );
    _commandController = TextEditingController(
      text: widget.editingDevice?.autoLockCommand ?? '',
    );
    _timerController = TextEditingController(
      text: widget.editingDevice?.autoLockTimer.toString() ?? '30',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device name is required')));
      return;
    }

    if (_commandController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open door command is required')),
      );
      return;
    }

    final timerSeconds = int.tryParse(_timerController.text) ?? 30;
    if (timerSeconds < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timer must be at least 5 seconds')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.editingDevice != null) {
        // Update existing device
        final updated = widget.editingDevice!.copyWith(
          name: _nameController.text,
          autoLockCommand: _commandController.text,
          autoLockTimer: timerSeconds,
        );
        await _databaseService.updateDevice(updated);
      } else {
        // Create new device
        final device = SmartDeviceDB(
          id: 'autolock_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text,
          tab: 'Doors',
          category: 'Doors & Locks',
          model: 'Auto-Lock Door',
          onCommand: '',
          offCommand: '',
          onReceive: '',
          offReceive: '',
          autoLockCommand: _commandController.text,
          autoLockTimer: timerSeconds,
          autoLockState: 'locked',
          icon: 'lock',
        );
        await _databaseService.createDevice(device);
      }

      if (mounted) {
        widget.onDeviceSaved();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving device: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          Text(
            'Auto-Lock Door Configuration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Device Name',
              hintText: 'e.g., Front Door Auto-Lock',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Door Control Settings',
                  style: TextStyle(
                    color: Colors.cyanAccent[200],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _commandController,
                  decoration: InputDecoration(
                    labelText: 'Open Door Command',
                    hintText: 'e.g., UNLOCK_ALL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _timerController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Auto-Lock Timer (seconds)',
                    hintText: '30',
                    helperText:
                        'Door will automatically lock after this duration',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffix: const Text('sec'),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ℹ️ How it works',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'When the open door command is received, the door unlocks and a countdown timer starts. The door will automatically lock once the timer expires or when manually locked.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveDevice,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Device',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
