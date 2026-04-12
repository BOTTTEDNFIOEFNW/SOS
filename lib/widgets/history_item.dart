import 'package:flutter/material.dart';

class HistoryItem extends StatelessWidget {
  final String title;
  final String time;

  const HistoryItem({super.key, required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(time, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}