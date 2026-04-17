/// Predefined smart home device models organized by category
/// Users can select from these models when adding a new device

class PredefinedDevice {
  final String name;
  final String category;
  final String iconSuggestion; // Icon name from FontAwesome or MaterialIcons
  final String? description;

  const PredefinedDevice({
    required this.name,
    required this.category,
    required this.iconSuggestion,
    this.description,
  });
}

class DeviceCategories {
  // Category names
  static const String lighting = 'Lighting';
  static const String doors = 'Doors & Locks';
  static const String fans = 'Fans';
  static const String refrigerators = 'Refrigerators';
  static const String airConditioners = 'Air Conditioners';
  static const String toolsAppliances = 'Tools & Appliances';
  static const String entertainment = 'Entertainment';
  static const String security = 'Security';
  static const String heating = 'Heating';
  static const String irrigation = 'Irrigation';

  // All devices organized by category
  static const Map<String, List<PredefinedDevice>> allDevices = {
    lighting: [
      PredefinedDevice(
        name: 'LED Strip',
        category: 'Lighting',
        iconSuggestion: 'lightbulb',
        description: 'Flexible RGB LED light strips',
      ),
      PredefinedDevice(
        name: 'Ceiling Light',
        category: 'Lighting',
        iconSuggestion: 'lightbulb',
        description: 'Overhead ceiling light fixture',
      ),
      PredefinedDevice(
        name: 'Smart Bulb',
        category: 'Lighting',
        iconSuggestion: 'lightbulb',
        description: 'WiFi/Bluetooth enabled light bulb',
      ),
      PredefinedDevice(
        name: 'Desk Lamp',
        category: 'Lighting',
        iconSuggestion: 'lightbulb',
        description: 'Adjustable desk lamp with smart control',
      ),
      PredefinedDevice(
        name: 'Wall Light',
        category: 'Lighting',
        iconSuggestion: 'lightbulb',
        description: 'Wall-mounted light fixture',
      ),
      PredefinedDevice(
        name: 'Floor Lamp',
        category: 'Lighting',
        iconSuggestion: 'lightbulb',
        description: 'Standalone floor lamp',
      ),
    ],
    doors: [
      PredefinedDevice(
        name: 'Smart Door Lock',
        category: 'Doors & Locks',
        iconSuggestion: 'lock',
        description: 'Electronic smart lock for main entry doors',
      ),
      PredefinedDevice(
        name: 'Gate Controller',
        category: 'Doors & Locks',
        iconSuggestion: 'gate',
        description: 'Automated gate control system',
      ),
      PredefinedDevice(
        name: 'Garage Door',
        category: 'Doors & Locks',
        iconSuggestion: 'garage',
        description: 'Automatic garage door opener',
      ),
      PredefinedDevice(
        name: 'Sliding Door',
        category: 'Doors & Locks',
        iconSuggestion: 'door_back',
        description: 'Smart sliding door control',
      ),
      PredefinedDevice(
        name: 'Window Lock',
        category: 'Doors & Locks',
        iconSuggestion: 'window',
        description: 'Smart window lock and sensor',
      ),
      PredefinedDevice(
        name: 'Access Control',
        category: 'Doors & Locks',
        iconSuggestion: 'security',
        description: 'Keypad or card-based access control',
      ),
      PredefinedDevice(
        name: 'RFID Door Lock',
        category: 'Doors & Locks',
        iconSuggestion: 'lock',
        description: 'RFID-based door lock with scenario handling',
      ),
      PredefinedDevice(
        name: 'Auto Lock Door',
        category: 'Doors & Locks',
        iconSuggestion: 'door_front',
        description: 'Door that auto-locks after timer expires',
      ),
    ],
    fans: [
      PredefinedDevice(
        name: 'Ceiling Fan',
        category: 'Fans',
        iconSuggestion: 'wind_power',
        description: 'Overhead ceiling-mounted fan',
      ),
      PredefinedDevice(
        name: 'Exhaust Fan',
        category: 'Fans',
        iconSuggestion: 'wind_power',
        description: 'Bathroom or ventilation exhaust fan',
      ),
      PredefinedDevice(
        name: 'Tower Fan',
        category: 'Fans',
        iconSuggestion: 'wind_power',
        description: 'Tall oscillating tower fan',
      ),
      PredefinedDevice(
        name: 'Pedestal Fan',
        category: 'Fans',
        iconSuggestion: 'wind_power',
        description: 'Standing pedestal fan',
      ),
      PredefinedDevice(
        name: 'Table Fan',
        category: 'Fans',
        iconSuggestion: 'wind_power',
        description: 'Compact table-top fan',
      ),
      PredefinedDevice(
        name: 'Industrial Fan',
        category: 'Fans',
        iconSuggestion: 'wind_power',
        description: 'Heavy-duty industrial cooling fan',
      ),
    ],
    refrigerators: [
      PredefinedDevice(
        name: 'Smart Fridge',
        category: 'Refrigerators',
        iconSuggestion: 'kitchen',
        description: 'Connected refrigerator with smart features',
      ),
      PredefinedDevice(
        name: 'Mini Fridge',
        category: 'Refrigerators',
        iconSuggestion: 'kitchen',
        description: 'Compact mini refrigerator',
      ),
      PredefinedDevice(
        name: 'Deep Freezer',
        category: 'Refrigerators',
        iconSuggestion: 'kitchen',
        description: 'Large capacity freezer',
      ),
      PredefinedDevice(
        name: 'Wine Cooler',
        category: 'Refrigerators',
        iconSuggestion: 'kitchen',
        description: 'Temperature-controlled wine storage',
      ),
      PredefinedDevice(
        name: 'Water Cooler',
        category: 'Refrigerators',
        iconSuggestion: 'local_drink',
        description: 'Smart water cooling dispenser',
      ),
    ],
    airConditioners: [
      PredefinedDevice(
        name: 'Split AC',
        category: 'Air Conditioners',
        iconSuggestion: 'ac_unit',
        description: 'Split-unit air conditioning system',
      ),
      PredefinedDevice(
        name: 'Window AC',
        category: 'Air Conditioners',
        iconSuggestion: 'ac_unit',
        description: 'Window-mounted air conditioner',
      ),
      PredefinedDevice(
        name: 'Central AC',
        category: 'Air Conditioners',
        iconSuggestion: 'ac_unit',
        description: 'Central air conditioning system',
      ),
      PredefinedDevice(
        name: 'Smart Thermostat',
        category: 'Air Conditioners',
        iconSuggestion: 'thermostat',
        description: 'Programmable temperature controller',
      ),
      PredefinedDevice(
        name: 'Portable AC',
        category: 'Air Conditioners',
        iconSuggestion: 'ac_unit',
        description: 'Mobile portable air conditioner',
      ),
    ],
    toolsAppliances: [
      PredefinedDevice(
        name: 'Laundry Rack',
        category: 'Tools & Appliances',
        iconSuggestion: 'dry_cleaning',
        description: 'Motorized clothes drying rack (0°/90°/180°)',
      ),
      PredefinedDevice(
        name: 'Smart Plug',
        category: 'Tools & Appliances',
        iconSuggestion: 'power',
        description: 'WiFi-enabled smart power outlet',
      ),
      PredefinedDevice(
        name: 'Power Strip',
        category: 'Tools & Appliances',
        iconSuggestion: 'power',
        description: 'Multi-outlet power strip with control',
      ),
      PredefinedDevice(
        name: 'Washing Machine',
        category: 'Tools & Appliances',
        iconSuggestion: 'local_laundry_service',
        description: 'Smart-enabled washing machine',
      ),
      PredefinedDevice(
        name: 'Microwave',
        category: 'Tools & Appliances',
        iconSuggestion: 'kitchen',
        description: 'Smart microwave oven',
      ),
      PredefinedDevice(
        name: 'Coffee Maker',
        category: 'Tools & Appliances',
        iconSuggestion: 'local_cafe',
        description: 'Smart coffee machine with scheduling',
      ),
      PredefinedDevice(
        name: 'Dishwasher',
        category: 'Tools & Appliances',
        iconSuggestion: 'local_drink',
        description: 'Smart dishwashing machine',
      ),
      PredefinedDevice(
        name: 'TV',
        category: 'Tools & Appliances',
        iconSuggestion: 'tv',
        description: 'Smart television',
      ),
      PredefinedDevice(
        name: 'Electric Kettle',
        category: 'Tools & Appliances',
        iconSuggestion: 'local_cafe',
        description: 'Smart electric water kettle',
      ),
    ],
    entertainment: [
      PredefinedDevice(
        name: 'Smart Speaker',
        category: 'Entertainment',
        iconSuggestion: 'speaker',
        description: 'WiFi speaker system',
      ),
      PredefinedDevice(
        name: 'Projector',
        category: 'Entertainment',
        iconSuggestion: 'image_search',
        description: 'Smart projector system',
      ),
      PredefinedDevice(
        name: 'Sound System',
        category: 'Entertainment',
        iconSuggestion: 'speaker',
        description: 'Multi-speaker audio system',
      ),
      PredefinedDevice(
        name: 'Gaming Console',
        category: 'Entertainment',
        iconSuggestion: 'sports_esports',
        description: 'Smart gaming device',
      ),
    ],
    security: [
      PredefinedDevice(
        name: 'Security Camera',
        category: 'Security',
        iconSuggestion: 'videocam',
        description: 'WiFi/IP security camera',
      ),
      PredefinedDevice(
        name: 'Motion Sensor',
        category: 'Security',
        iconSuggestion: 'sensors',
        description: 'Movement detection sensor',
      ),
      PredefinedDevice(
        name: 'Door Sensor',
        category: 'Security',
        iconSuggestion: 'sensor_door',
        description: 'Door open/close detection',
      ),
      PredefinedDevice(
        name: 'Smoke Detector',
        category: 'Security',
        iconSuggestion: 'smoke_free',
        description: 'Smart smoke detection',
      ),
      PredefinedDevice(
        name: 'Alarm System',
        category: 'Security',
        iconSuggestion: 'security',
        description: 'Integrated security alarm',
      ),
    ],
    heating: [
      PredefinedDevice(
        name: 'Electric Heater',
        category: 'Heating',
        iconSuggestion: 'local_fire_department',
        description: 'Smart electric heater',
      ),
      PredefinedDevice(
        name: 'Heat Pump',
        category: 'Heating',
        iconSuggestion: 'local_fire_department',
        description: 'Efficient heat pump system',
      ),
      PredefinedDevice(
        name: 'Boiler',
        category: 'Heating',
        iconSuggestion: 'local_fire_department',
        description: 'Smart water heater/boiler',
      ),
    ],
    irrigation: [
      PredefinedDevice(
        name: 'Garden Watering',
        category: 'Irrigation',
        iconSuggestion: 'grass',
        description: 'Automated garden irrigation system',
      ),
      PredefinedDevice(
        name: 'Sprinkler System',
        category: 'Irrigation',
        iconSuggestion: 'water_drop',
        description: 'Smart sprinkler control',
      ),
      PredefinedDevice(
        name: 'Soil Moisture Monitor',
        category: 'Irrigation',
        iconSuggestion: 'opacity',
        description: 'Soil humidity sensor',
      ),
    ],
  };

  /// Get all category names
  static List<String> get allCategories => allDevices.keys.toList();

  /// Get devices for a specific category
  static List<PredefinedDevice> getDevicesForCategory(String category) {
    return allDevices[category] ?? [];
  }

  /// Get device names for a category
  static List<String> getDeviceNamesByCategory(String category) {
    return getDevicesForCategory(
      category,
    ).map((device) => device.name).toList();
  }

  /// Find a device by name and category
  static PredefinedDevice? findDevice(String name, String category) {
    final devices = getDevicesForCategory(category);
    try {
      return devices.firstWhere((device) => device.name == name);
    } catch (e) {
      return null;
    }
  }
}
