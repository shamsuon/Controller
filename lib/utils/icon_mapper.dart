import 'package:flutter/material.dart';

class IconMapper {
  static final Map<String, IconData> _iconMap = {
    // Lighting
    'lightbulb': Icons.lightbulb_outline_rounded,
    'fluorescent': Icons.fluorescent_rounded,
    'tungsten': Icons.tungsten_rounded,
    'wb_incandescent': Icons.wb_incandescent_rounded,
    
    // Climate
    'thermostat': Icons.thermostat_rounded,
    'ac_unit': Icons.ac_unit_rounded,
    'air': Icons.air_rounded,
    'wind_power': Icons.air_rounded, // fallback for older key
    'local_fire_department': Icons.local_fire_department_rounded,
    
    // Security & Access
    'lock': Icons.lock_outline_rounded,
    'lock_open': Icons.lock_open_rounded,
    'security': Icons.security_rounded,
    'videocam': Icons.videocam_outlined,
    'sensors': Icons.sensors_rounded,
    'sensor_door': Icons.sensor_door_rounded,
    'sensor_window': Icons.sensor_window_rounded,
    'smoke_free': Icons.smoke_free_rounded,
    'motion_photos_on': Icons.motion_photos_on_rounded,
    'garage': Icons.garage_outlined,
    'gate': Icons.door_sliding_rounded,
    'door_front': Icons.door_front_door_rounded,
    'door_back': Icons.door_back_door_rounded,
    'window': Icons.window_rounded,
    
    // Entertainment
    'tv': Icons.tv_rounded,
    'speaker': Icons.speaker_rounded,
    'speaker_group': Icons.speaker_group_rounded,
    'surround_sound': Icons.surround_sound_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'projector': Icons.image_search_rounded,
    'image_search': Icons.image_search_rounded,
    
    // Appliances
    'kitchen': Icons.kitchen_rounded,
    'blender': Icons.blender_rounded,
    'microwave': Icons.microwave_rounded,
    'local_laundry_service': Icons.local_laundry_service_rounded,
    'coffee': Icons.coffee_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'power': Icons.power_rounded,
    'power_plug': Icons.power_rounded,
    'outlet': Icons.outlet_rounded,
    'electrical_services': Icons.electrical_services_rounded,
    'curtains': Icons.curtains_rounded,
    'blinds': Icons.blinds_rounded,
    
    // Water
    'water_drop': Icons.water_drop_rounded,
    'opacity': Icons.opacity_rounded,
    'grass': Icons.grass_rounded,
    'pool': Icons.pool_rounded,
    
    // Devices
    'computer': Icons.computer_rounded,
    'laptop': Icons.laptop_rounded,
    'phone_android': Icons.phone_android_rounded,
    'router': Icons.router_rounded,
    'device_hub': Icons.device_hub_rounded,
    
    // Misc
    'bolt': Icons.bolt_rounded,
    'battery_charging_full': Icons.battery_charging_full_rounded,
    'notifications': Icons.notifications_active_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,
    'build': Icons.build_rounded,
    'settings_input_component': Icons.settings_input_component_rounded,
    'devices_other': Icons.devices_other_rounded,
  };

  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.devices_other_rounded;
    return _iconMap[iconName.toLowerCase()] ?? Icons.devices_other_rounded;
  }

  static Map<String, IconData> get availableIcons => Map.unmodifiable(_iconMap);
}
