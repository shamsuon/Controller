import 'dart:ui';
import 'package:flutter/material.dart';

class FanCard extends StatelessWidget {
  final bool isOn;
  final Function(bool) onChanged;
  final bool isConnected;

  const FanCard({
    super.key,
    required this.isOn,
    required this.onChanged,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isOn ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(isOn ? 0.5 : 0.3),
              width: 1.0,
            ),
            boxShadow: [
              if (isOn)
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isConnected ? () => onChanged(!isOn) : null,
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isOn ? 0.25 : 0.08),
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (isOn) BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15),
                            ],
                            border: Border.all(
                              color: isOn ? Colors.cyanAccent.withOpacity(0.5) : Colors.white10,
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            isOn ? Icons.toys_rounded : Icons.toys_outlined,
                            color: isOn ? Colors.cyanAccent : Colors.white70,
                            size: 28,
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isOn,
                            activeColor: Colors.cyanAccent,
                            onChanged: isConnected ? onChanged : null,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isOn ? Colors.cyanAccent : Colors.white).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10, width: 0.5),
                          ),
                          child: Text(
                            isOn ? 'RUNNING' : 'STOPPED',
                            style: TextStyle(
                              color: isOn ? Colors.cyanAccent : Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
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
        ),
      ),
    );
  }
}
