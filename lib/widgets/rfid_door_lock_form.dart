import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/database_service.dart';

class RfidDoorLockForm extends StatefulWidget {
  final SmartDeviceDB? editingDevice;
  final VoidCallback onDeviceSaved;

  const RfidDoorLockForm({
    Key? key,
    this.editingDevice,
    required this.onDeviceSaved,
  }) : super(key: key);

  @override
  State<RfidDoorLockForm> createState() => _RfidDoorLockFormState();
}

class _RfidDoorLockFormState extends State<RfidDoorLockForm> {
  late TextEditingController _nameController;
  late TextEditingController _scenario1CmdController;
  late TextEditingController _scenario1MsgController;
  late TextEditingController _scenario2CmdController;
  late TextEditingController _scenario2MsgController;
  late TextEditingController _scenario3CmdController;
  late TextEditingController _scenario3MsgController;
  late TextEditingController _scenario4CmdController;
  late TextEditingController _scenario4MsgController;

  final DatabaseService _databaseService = DatabaseService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.editingDevice?.name ?? 'RFID Door Lock',
    );
    _scenario1CmdController = TextEditingController(
      text: widget.editingDevice?.rfidScenario1Cmd ?? '',
    );
    _scenario1MsgController = TextEditingController(
      text: widget.editingDevice?.rfidScenario1Msg ?? '',
    );
    _scenario2CmdController = TextEditingController(
      text: widget.editingDevice?.rfidScenario2Cmd ?? '',
    );
    _scenario2MsgController = TextEditingController(
      text: widget.editingDevice?.rfidScenario2Msg ?? '',
    );
    _scenario3CmdController = TextEditingController(
      text: widget.editingDevice?.rfidScenario3Cmd ?? '',
    );
    _scenario3MsgController = TextEditingController(
      text: widget.editingDevice?.rfidScenario3Msg ?? '',
    );
    _scenario4CmdController = TextEditingController(
      text: widget.editingDevice?.rfidScenario4Cmd ?? '',
    );
    _scenario4MsgController = TextEditingController(
      text: widget.editingDevice?.rfidScenario4Msg ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scenario1CmdController.dispose();
    _scenario1MsgController.dispose();
    _scenario2CmdController.dispose();
    _scenario2MsgController.dispose();
    _scenario3CmdController.dispose();
    _scenario3MsgController.dispose();
    _scenario4CmdController.dispose();
    _scenario4MsgController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device name is required')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.editingDevice != null) {
        // Update existing device
        final updated = widget.editingDevice!.copyWith(
          name: _nameController.text,
          rfidScenario1Cmd: _scenario1CmdController.text,
          rfidScenario1Msg: _scenario1MsgController.text,
          rfidScenario2Cmd: _scenario2CmdController.text,
          rfidScenario2Msg: _scenario2MsgController.text,
          rfidScenario3Cmd: _scenario3CmdController.text,
          rfidScenario3Msg: _scenario3MsgController.text,
          rfidScenario4Cmd: _scenario4CmdController.text,
          rfidScenario4Msg: _scenario4MsgController.text,
        );
        await _databaseService.updateDevice(updated);
      } else {
        // Create new device
        final device = SmartDeviceDB(
          id: 'rfid_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text,
          tab: 'Doors',
          category: 'Doors & Locks',
          model: 'RFID Door Lock',
          onCommand: '',
          offCommand: '',
          onReceive: '',
          offReceive: '',
          rfidScenario1Cmd: _scenario1CmdController.text,
          rfidScenario1Msg: _scenario1MsgController.text,
          rfidScenario2Cmd: _scenario2CmdController.text,
          rfidScenario2Msg: _scenario2MsgController.text,
          rfidScenario3Cmd: _scenario3CmdController.text,
          rfidScenario3Msg: _scenario3MsgController.text,
          rfidScenario4Cmd: _scenario4CmdController.text,
          rfidScenario4Msg: _scenario4MsgController.text,
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
            'RFID Door Lock Configuration',
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
              hintText: 'e.g., Front Door RFID',
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
          Text(
            'RFID Scenarios (Card/Tag Configurations)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildScenarioFields(1),
          const SizedBox(height: 16),
          ..._buildScenarioFields(2),
          const SizedBox(height: 16),
          ..._buildScenarioFields(3),
          const SizedBox(height: 16),
          ..._buildScenarioFields(4),
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

  List<Widget> _buildScenarioFields(int scenarioNum) {
    late TextEditingController cmdController;
    late TextEditingController msgController;

    switch (scenarioNum) {
      case 1:
        cmdController = _scenario1CmdController;
        msgController = _scenario1MsgController;
        break;
      case 2:
        cmdController = _scenario2CmdController;
        msgController = _scenario2MsgController;
        break;
      case 3:
        cmdController = _scenario3CmdController;
        msgController = _scenario3MsgController;
        break;
      case 4:
        cmdController = _scenario4CmdController;
        msgController = _scenario4MsgController;
        break;
    }

    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scenario #$scenarioNum',
              style: TextStyle(
                color: Colors.cyanAccent[200],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cmdController,
              decoration: InputDecoration(
                labelText: 'Incoming Command',
                hintText: 'e.g., CARD_001',
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
            const SizedBox(height: 8),
            TextField(
              controller: msgController,
              decoration: InputDecoration(
                labelText: 'Display Message',
                hintText: 'e.g., VIP Access Granted',
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
          ],
        ),
      ),
    ];
  }
}
