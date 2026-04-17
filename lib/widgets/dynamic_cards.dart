import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/device_model.dart';

class GenericToggleCard extends StatelessWidget {
  final SmartDevice device;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  const GenericToggleCard({
    super.key,
    required this.device,
    required this.isOn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      icon: device.icon,
      title: device.name,
      subtitle: isOn ? 'Status: ON' : 'Status: OFF',
      isActive: isOn,
      child: Switch(
        value: isOn,
        onChanged: onChanged,
        activeColor: const Color(0xFF00E5FF),
      ),
    );
  }
}

class GenericTriggerCard extends StatelessWidget {
  final SmartDevice device;
  final VoidCallback onTap;

  const GenericTriggerCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      icon: device.icon,
      title: device.name,
      subtitle: 'Tap to Trigger',
      isActive: false,
      onTap: onTap,
      child: const Icon(Icons.touch_app, color: Colors.white24),
    );
  }
}

class GenericSliderCard extends StatelessWidget {
  final SmartDevice device;
  final double value;
  final ValueChanged<double> onChanged;

  const GenericSliderCard({
    super.key,
    required this.device,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      icon: device.icon,
      title: device.name,
      subtitle: 'Value: ${value.toInt()}°',
      isActive: true,
      // Pass null to child to use the bottom slot for the slider
      child: const SizedBox.shrink(),
      bottom: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        ),
        child: Slider(
          value: value,
          min: device.minSlider,
          max: device.maxSlider,
          divisions: (device.maxSlider - device.minSlider).toInt(),
          activeColor: const Color(0xFF00E5FF),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? bottom; // New slot for sliders or large widgets
  final bool isActive;
  final VoidCallback? onTap;

  const _BaseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottom,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF00E5FF);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.5) : Colors.white10,
            width: 1.5,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: activeColor.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive ? activeColor.withOpacity(0.2) : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: isActive ? activeColor : Colors.white70, size: 20),
                      ),
                      Flexible(child: child),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (bottom != null) bottom!
                  else ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
