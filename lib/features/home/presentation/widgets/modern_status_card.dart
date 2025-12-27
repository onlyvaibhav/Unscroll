import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernStatusCard extends StatelessWidget {
  final dynamic state; // HomeState

  const ModernStatusCard({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusItem(
                icon: Icons.security,
                label: "Blocking",
                value: state.isServiceRunning ? "Active" : "Off",
                color: state.isServiceRunning ? Colors.green : Colors.red,
              ),
              _StatusItem(
                icon: Icons.shield_moon,
                label: "Strict Mode",
                value: state.isStrictMode ? "ON" : "OFF",
                color: state.isStrictMode ? Colors.cyan : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}