import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../models/device_categories.dart';
import '../services/database_service.dart';
import '../utils/icon_mapper.dart';

class AddDeviceBottomSheet extends StatefulWidget {
  final VoidCallback onDeviceAdded;

  const AddDeviceBottomSheet({Key? key, required this.onDeviceAdded})
    : super(key: key);

  @override
  State<AddDeviceBottomSheet> createState() => _AddDeviceBottomSheetState();
}

class _AddDeviceBottomSheetState extends State<AddDeviceBottomSheet> {
  // Laundry Rack specific fields
  String _rack0Cmd = '';
  String _rack90Cmd = '';
  String _rack180Cmd = '';
  String _rack0Receive = '';
  String _rack90Receive = '';
  String _rack180Receive = '';

  // RFID Door Lock specific fields
  String _rfidScenario1Cmd = '';
  String _rfidScenario1Msg = '';
  String _rfidScenario2Cmd = '';
  String _rfidScenario2Msg = '';
  String _rfidScenario3Cmd = '';
  String _rfidScenario3Msg = '';
  String _rfidScenario4Cmd = '';
  String _rfidScenario4Msg = '';
  String _rfidScenario5Cmd = '';
  String _rfidScenario5Msg = '';
  String _rfidScenario6Cmd = '';
  String _rfidScenario6Msg = '';
  String _rfidScenario7Cmd = '';
  String _rfidScenario7Msg = '';

  // Auto Lock Door specific fields
  String _autoLockCommand = '';
  String _autoLockTimer = '';
  String _autoLockState = 'locked';

  final _formKey = GlobalKey<FormState>();

  // RFID Scenarios as a dynamic list
  final List<Map<String, String>> _rfidScenarios = [
    {'cmd': '', 'msg': ''}
  ];

  final DatabaseService _databaseService = DatabaseService();
  final _scrollController = ScrollController();

  // Form fields
  String _cardName = '';
  String _selectedTab = 'Lights';
  String _selectedCategory = DeviceCategories.lighting;
  String _selectedModel = '';
  String _onCommand = '';
  String _offCommand = '';
  String _onReceive = '';
  String _offReceive = '';
  String _selectedIcon = 'lightbulb';

  bool _isLoading = false;

  // Available tabs
  final List<String> _tabs = [
    'Lights',
    'Doors',
    'Fans',
    'Tools',
    'Climate',
    'Security',
    'Other',
  ];

  // Common device icons
  final List<String> _deviceIconKeys = [
    'lightbulb',
    'lock',
    'air',
    'kitchen',
    'power',
    'tv',
    'videocam',
    'speaker',
    'thermostat',
    'door_front',
    'garage',
    'security',
    'ac_unit',
    'sensors',
    'water_drop',
    'local_cafe',
    'sports_esports',
    'router',
    'bolt',
    'cleaning_services',
    'wb_incandescent',
    'laptop',
  ];

  // Category-specific icon mappings
  final Map<String, List<String>> _categoryIconMap = {
    'Lighting': ['lightbulb', 'fluorescent', 'tungsten', 'wb_incandescent'],
    'Doors & Locks': [
      'lock',
      'lock_open',
      'door_front',
      'door_back',
      'garage',
      'window',
    ],
    'Fans': ['air', 'wind_power'],
    'Refrigerators': ['kitchen', 'local_cafe', 'power'],
    'Air Conditioners': ['ac_unit', 'thermostat', 'air'],
    'Tools & Appliances': [
      'power',
      'electrical_services',
      'microwave',
      'blender',
      'kitchen',
    ],
    'Entertainment': [
      'tv',
      'speaker',
      'speaker_group',
      'sports_esports',
      'projector',
    ],
    'Security': [
      'security',
      'videocam',
      'sensors',
      'motion_photos_on',
      'smoke_free',
    ],
    'Heating': ['local_fire_department', 'thermostat'],
    'Irrigation': ['water_drop', 'grass', 'pool'],
  };

  List<String> _getIconsForCategory(String category) {
    return _categoryIconMap[category] ?? _deviceIconKeys;
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = DeviceCategories.allCategories.first;
    _updateDeviceModels();
  }

  void _updateDeviceModels() {
    final devices = DeviceCategories.getDeviceNamesByCategory(
      _selectedCategory,
    );
    if (devices.isNotEmpty) {
      if (!devices.contains(_selectedModel)) {
        _selectedModel = devices.first;
      }

      // Auto-update icon based on selected model
      final modelData = DeviceCategories.findDevice(
        _selectedModel,
        _selectedCategory,
      );
      if (modelData != null) {
        _selectedIcon = modelData.iconSuggestion;
      }
    }
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_selectedModel == 'Laundry Rack') {
      if (_cardName.isEmpty ||
          _rack0Cmd.isEmpty ||
          _rack90Cmd.isEmpty ||
          _rack180Cmd.isEmpty ||
          _rack0Receive.isEmpty ||
          _rack90Receive.isEmpty ||
          _rack180Receive.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all 6 commands for the Rack'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    } else if (_selectedModel == 'RFID Door Lock') {
      if (_cardName.isEmpty ||
          _rfidScenarios[0]['cmd']!.isEmpty ||
          _rfidScenarios[0]['msg']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill at least the first Scenario fields'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      // Populate the static fields from the dynamic list for DB saving
      _rfidScenario1Cmd = _rfidScenarios[0]['cmd']!;
      _rfidScenario1Msg = _rfidScenarios[0]['msg']!;
      if (_rfidScenarios.length > 1) {
        _rfidScenario2Cmd = _rfidScenarios[1]['cmd']!;
        _rfidScenario2Msg = _rfidScenarios[1]['msg']!;
      }
      if (_rfidScenarios.length > 2) {
        _rfidScenario3Cmd = _rfidScenarios[2]['cmd']!;
        _rfidScenario3Msg = _rfidScenarios[2]['msg']!;
      }
      if (_rfidScenarios.length > 3) {
        _rfidScenario4Cmd = _rfidScenarios[3]['cmd']!;
        _rfidScenario4Msg = _rfidScenarios[3]['msg']!;
      }
      if (_rfidScenarios.length > 4) {
        _rfidScenario5Cmd = _rfidScenarios[4]['cmd']!;
        _rfidScenario5Msg = _rfidScenarios[4]['msg']!;
      }
      if (_rfidScenarios.length > 5) {
        _rfidScenario6Cmd = _rfidScenarios[5]['cmd']!;
        _rfidScenario6Msg = _rfidScenarios[5]['msg']!;
      }
      if (_rfidScenarios.length > 6) {
        _rfidScenario7Cmd = _rfidScenarios[6]['cmd']!;
        _rfidScenario7Msg = _rfidScenarios[6]['msg']!;
      }
    } else if (_selectedModel == 'Auto Lock Door') {
      if (_cardName.isEmpty ||
          _autoLockCommand.isEmpty ||
          _autoLockTimer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill Auto Lock command and timer fields'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    } else {
      if (_cardName.isEmpty ||
          _onCommand.isEmpty ||
          _offCommand.isEmpty ||
          _onReceive.isEmpty ||
          _offReceive.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all command fields'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final device = SmartDeviceDB(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _cardName,
        tab: _selectedTab,
        category: _selectedCategory,
        model: _selectedModel,
        onCommand: _onCommand,
        offCommand: _offCommand,
        onReceive: _onReceive,
        offReceive: _offReceive,
        rack0Cmd: _rack0Cmd,
        rack90Cmd: _rack90Cmd,
        rack180Cmd: _rack180Cmd,
        rack0Receive: _rack0Receive,
        rack90Receive: _rack90Receive,
        rack180Receive: _rack180Receive,
        rfidScenario1Cmd: _rfidScenario1Cmd,
        rfidScenario1Msg: _rfidScenario1Msg,
        rfidScenario2Cmd: _rfidScenario2Cmd,
        rfidScenario2Msg: _rfidScenario2Msg,
        rfidScenario3Cmd: _rfidScenario3Cmd,
        rfidScenario3Msg: _rfidScenario3Msg,
        rfidScenario4Cmd: _rfidScenario4Cmd,
        rfidScenario4Msg: _rfidScenario4Msg,
        rfidLastMessage: '',
        autoLockCommand: _autoLockCommand,
        autoLockTimer: int.tryParse(_autoLockTimer) ?? 0,
        autoLockState: _autoLockState,
        icon: _selectedIcon,
        isFavorite: false,
        order: await _databaseService.getDeviceCount(),
      );

      await _databaseService.createDevice(device);

      if (mounted) {
        widget.onDeviceAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device added successfully!'),
            backgroundColor: Colors.greenAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding device: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight * 0.75; // Use 75% of screen height

    return Container(
      height: availableHeight + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Device',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Card Name
                    _buildFormSection(
                      label: '1. Card Name',
                      child: TextFormField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('e.g., Living Room Light'),
                        onSaved: (value) => _cardName = value ?? '',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Card name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Tab Assignment
                    _buildFormSection(
                      label: '2. Tab Assignment',
                      child: DropdownButtonFormField<String>(
                        value: _selectedTab,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[900],
                        decoration: _inputDecoration('Select tab'),
                        items: _tabs.map((tab) {
                          return DropdownMenuItem(value: tab, child: Text(tab));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTab = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Device Category
                    _buildFormSection(
                      label: '3. Device Category',
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[900],
                        decoration: _inputDecoration('Select category'),
                        items: DeviceCategories.allCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                              _updateDeviceModels();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Device Model
                    _buildFormSection(
                      label: '4. Device Model',
                      child: DropdownButtonFormField<String>(
                        value: _selectedModel.isEmpty
                            ? DeviceCategories.getDeviceNamesByCategory(
                                _selectedCategory,
                              ).firstOrNull
                            : _selectedModel,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[900],
                        decoration: _inputDecoration('Select device model'),
                        items:
                            DeviceCategories.getDeviceNamesByCategory(
                              _selectedCategory,
                            ).map((model) {
                              return DropdownMenuItem(
                                value: model,
                                child: Text(model),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedModel = value;
                              // Update icon suggestion when model changes
                              final modelData = DeviceCategories.findDevice(
                                _selectedModel,
                                _selectedCategory,
                              );
                              if (modelData != null) {
                                _selectedIcon = modelData.iconSuggestion;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Device Specific Fields
                    if (_selectedModel == 'Laundry Rack') ...[
                      _buildFormSection(
                        label: 'Angle 0° Command (Send)',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., R0_ON'),
                          onSaved: (value) => _rack0Cmd = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFormSection(
                        label: 'Angle 0° Response (Receive)',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., RACK_0'),
                          onSaved: (value) => _rack0Receive = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildFormSection(
                        label: 'Angle 90° Command (Send)',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., R90_ON'),
                          onSaved: (value) => _rack90Cmd = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFormSection(
                        label: 'Angle 90° Response (Receive)',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., RACK_90'),
                          onSaved: (value) => _rack90Receive = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildFormSection(
                        label: 'Angle 180° Command (Send)',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., R180_ON'),
                          onSaved: (value) => _rack180Cmd = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFormSection(
                        label: 'Angle 180° Response (Receive)',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., RACK_180'),
                          onSaved: (value) => _rack180Receive = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else if (_selectedModel == 'RFID Door Lock') ...[
                      for (int i = 0; i < _rfidScenarios.length; i++) ...[
                        _buildFormSection(
                          label: 'Scenario ${i + 1} - RFID Command',
                          child: TextFormField(
                            initialValue: _rfidScenarios[i]['cmd'],
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('e.g., RFID_0${i + 1}'),
                            onChanged: (val) => _rfidScenarios[i]['cmd'] = val,
                            validator: (value) => (i == 0 && (value == null || value.isEmpty))
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormSection(
                          label: 'Scenario ${i + 1} - Response Message',
                          child: TextFormField(
                            initialValue: _rfidScenarios[i]['msg'],
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('e.g., Welcome Home'),
                            onChanged: (val) => _rfidScenarios[i]['msg'] = val,
                            validator: (value) => (i == 0 && (value == null || value.isEmpty))
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_rfidScenarios.length < 7)
                        Center(
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _rfidScenarios.add({'cmd': '', 'msg': ''});
                            }),
                            icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
                            label: const Text(
                              'Add Scenario',
                              style: TextStyle(color: Colors.cyanAccent),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ] else if (_selectedModel == 'Auto Lock Door') ...[
                      _buildFormSection(
                        label: 'Auto Lock Command',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., LOCK_AUTO'),
                          onSaved: (value) => _autoLockCommand = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFormSection(
                        label: 'Auto Lock Timer (seconds)',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., 300'),
                          keyboardType: TextInputType.number,
                          onSaved: (value) => _autoLockTimer = value ?? '',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Timer is required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Must be a number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFormSection(
                        label: 'Initial State',
                        child: DropdownButtonFormField<String>(
                          value: _autoLockState,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: Colors.grey[900],
                          decoration: _inputDecoration('Select initial state'),
                          items: const [
                            DropdownMenuItem(
                              value: 'locked',
                              child: Text('Locked'),
                            ),
                            DropdownMenuItem(
                              value: 'open',
                              child: Text('Open'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _autoLockState = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Standard ON/OFF fields for all other models
                      _buildFormSection(
                        label: '5. ON Command Character',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., a'),
                          maxLength: 3,
                          onSaved: (value) => _onCommand = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFormSection(
                        label: '6. OFF Command Character',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., A'),
                          maxLength: 3,
                          onSaved: (value) => _offCommand = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFormSection(
                        label: '7. ON Response Character',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., L1_ON'),
                          maxLength: 20,
                          onSaved: (value) => _onReceive = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFormSection(
                        label: '8. OFF Response Character',
                        child: TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., L1_OFF'),
                          maxLength: 20,
                          onSaved: (value) => _offReceive = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 9. Card Icon
                    _buildFormSection(
                      label: '9. Device Icon',
                      child: SizedBox(
                        height: 60,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _deviceIconKeys.map((iconKey) {
                              final isSelected = _selectedIcon == iconKey;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedIcon = iconKey);
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.cyanAccent.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.cyanAccent
                                            : Colors.white.withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      IconMapper.getIcon(iconKey),
                                      color: isSelected
                                          ? Colors.cyanAccent
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveDevice,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              _isLoading ? 'Adding...' : 'Add Device',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    );
  }
}
