import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';

class FocusModeCard extends StatelessWidget {
  const FocusModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.cyan, size: 40),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Focus Mode", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("25-minute deep work session", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HomeBloc>().add(const PauseBlocking(25));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Focus Mode activated for 25 min!"), backgroundColor: Colors.cyan),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text("Start"),
          ),
        ],
      ),
    );
  }
}