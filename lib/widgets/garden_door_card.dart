import 'dart:ui';
import 'package:flutter/material.dart';

class GardenDoorCard extends StatelessWidget {
  final bool isOpen;
  final Function(bool) onAction;
  final bool isConnected;

  const GardenDoorCard({
    super.key,
    required this.isOpen,
    required this.onAction,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = isOpen ? Colors.greenAccent : Colors.redAccent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 15),
                      ],
                      border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
                    ),
                    child: Icon(
                      isOpen ? Icons.door_front_door_rounded : Icons.door_back_door_rounded,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
                    ),
                    child: Text(
                      isOpen ? 'OPEN' : 'CLOSED',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Garden Door',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton('OPEN', true, Colors.greenAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton('CLOSE', false, Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, bool targetState, Color color) {
    bool isCurrent = isOpen == targetState;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isConnected ? () => onAction(targetState) : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrent ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              if (isCurrent)
                BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 15),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isCurrent ? Colors.white : Colors.white60,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
