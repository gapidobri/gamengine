import 'package:flutter/material.dart';
import 'package:gamengine/src/render/debug/debug_stats.dart';

class DebugOverlay extends StatelessWidget {
  final DebugStats stats;

  const DebugOverlay({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: stats,
      builder: (context, _) {
        final lines = <String>[
          'FPS: ${stats.fps.toStringAsFixed(1)}',
          'Drawn/Scene: ${stats.drawnItems}/${stats.sceneItems}',
          ...stats.lines.entries.map((entry) => '${entry.key}: ${entry.value}'),
        ];

        return IgnorePointer(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xB0000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    lines.join('\n'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
