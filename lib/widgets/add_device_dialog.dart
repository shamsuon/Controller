import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../utils/icon_mapper.dart';

class AddDeviceDialog extends StatefulWidget {
  final Function(SmartDevice) onAdd;

  const AddDeviceDialog({super.key, required this.onAdd});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _nameController = TextEditingController();
  final _onCommandController = TextEditingController();
  final _offCommandController = TextEditingController();
  final _statusOnController = TextEditingController();
  final _statusOffController = TextEditingController();
  final _prefixController = TextEditingController();
  
  bool _showAdvanced = false;
  DeviceType _selectedType = DeviceType.switchType;
  String _selectedCategory = 'Lights';
  IconData _selectedIcon = Icons.lightbulb_outline;

  final Map<String, IconData> _availableIcons = IconMapper.availableIcons;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Material(
              color: Colors.black.withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildTextField('Device Name', _nameController, Icons.label_outline),
                      const SizedBox(height: 20),
                      _buildCategoryPicker(),
                      const SizedBox(height: 20),
                      _buildTypePicker(),
                      const SizedBox(height: 20),
                      _buildCommandInputs(),
                      const SizedBox(height: 20),
                      _buildAdvancedSync(),
                      const SizedBox(height: 24),
                      _buildIconPicker(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Add New Device',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Inter'),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white54),
        )
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            hintText: 'e.g. Living Room',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    final categories = ['Lights', 'Doors', 'Fans', 'Tools'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category (Tab)', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: categories.map((cat) {
            bool isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: Colors.cyanAccent.withOpacity(0.3),
              backgroundColor: Colors.white.withOpacity(0.05),
              labelStyle: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white60, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Widget Type', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            _typeCard(DeviceType.switchType, 'Switch', Icons.toggle_on_outlined),
            const SizedBox(width: 8),
            _typeCard(DeviceType.buttonType, 'Button', Icons.touch_app_outlined),
            const SizedBox(width: 8),
            _typeCard(DeviceType.sliderType, 'Slider', Icons.linear_scale),
          ],
        ),
      ],
    );
  }

  Widget _typeCard(DeviceType type, String label, IconData icon) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? Colors.cyanAccent.withOpacity(0.5) : Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white54, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandInputs() {
    if (_selectedType == DeviceType.sliderType) {
      return _buildTextField('Send Prefix (e.g. S)', _prefixController, Icons.code);
    }
    return Column(
      children: [
        _buildTextField('Send ON Char', _onCommandController, Icons.login),
        if (_selectedType == DeviceType.switchType) ...[
          const SizedBox(height: 16),
          _buildTextField('Send OFF Char', _offCommandController, Icons.logout),
        ],
      ],
    );
  }

  Widget _buildAdvancedSync() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(
            children: [
              Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 4),
              const Text('Advanced (Sync Settings)', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 16),
          Text(
            'Use these if the hardware sends a different character for status than the one used to trigger it.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
          ),
          const SizedBox(height: 12),
          _buildTextField('Status ON Char (Optional)', _statusOnController, Icons.sync),
          if (_selectedType == DeviceType.switchType) ...[
            const SizedBox(height: 16),
            _buildTextField('Status OFF Char (Optional)', _statusOffController, Icons.sync_disabled),
          ],
        ],
      ],
    );
  }

  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Icon', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _availableIcons.entries.map((entry) {
              bool isSelected = _selectedIcon == entry.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = entry.value),
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.transparent),
                  ),
                  child: Icon(entry.value, color: isSelected ? Colors.cyanAccent : Colors.white38, size: 24),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 10,
          shadowColor: Colors.cyanAccent.withOpacity(0.5),
        ),
        child: const Text('CREATE DEVICE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
      ),
    );
  }

  void _submit() {
    if (_nameController.text.isEmpty) return;
    
    final device = SmartDevice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      type: _selectedType,
      category: _selectedCategory,
      icon: _selectedIcon,
      onCommand: _onCommandController.text,
      offCommand: _offCommandController.text,
      statusOn: _statusOnController.text,
      statusOff: _statusOffController.text,
      sliderCommandPrefix: _prefixController.text,
    );
    
    widget.onAdd(device);
    Navigator.pop(context);
  }
}
