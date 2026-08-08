import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'util.dart';

/// A small looping animation of connected "blocks" lighting up left to
/// right, used as a lightweight stand-in for a network/blockchain-sync
/// indicator. Pure Flutter (no external asset or package) so it can be
/// dropped in anywhere a brief "working on it" moment needs a visual
/// beyond a plain spinner — e.g. the login-to-home transition, or right
/// after a settings save completes.
class BlockchainAnimation extends StatefulWidget {
  const BlockchainAnimation({super.key, this.blockCount = 4, this.blockSize = 22});

  final int blockCount;
  final double blockSize;

  @override
  State<BlockchainAnimation> createState() => _BlockchainAnimationState();
}

class _BlockchainAnimationState extends State<BlockchainAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.blockCount; i++) ...[
              if (i > 0) _link(),
              _block(i),
            ],
          ],
        );
      },
    );
  }

  Widget _link() {
    return Container(
      width: widget.blockSize * 0.4,
      height: 2,
      color: rootstockCream.withValues(alpha: 0.4),
    );
  }

  Widget _block(int index) {
    // Each block pulses in turn, staggered across the loop so the "charge"
    // visibly travels left to right before the whole thing repeats.
    final start = index / widget.blockCount;
    final end = start + (1 / widget.blockCount);
    final t = Curves.easeInOut.transform(
      Interval(start, end, curve: Curves.easeInOut).transform(_controller.value),
    );
    final pulse = _controller.value >= start && _controller.value <= end ? t : 0.0;
    final scale = 0.85 + (0.15 * pulse);
    final opacity = 0.35 + (0.65 * pulse);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.blockSize,
        height: widget.blockSize,
        decoration: BoxDecoration(
          color: (purple() ?? rootstockCream).withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: rootstockCream.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

/// Shows [BlockchainAnimation] centered in a small non-dismissible overlay
/// for [duration], then closes it automatically. Meant for brief
/// confirmation moments (e.g. right after a database save) rather than
/// blocking navigation.
Future<void> showBlockchainAnimationOverlay(
  BuildContext context, {
  Duration duration = const Duration(milliseconds: 900),
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) => const Center(
      child: BlockchainAnimation(),
    ),
  );
  await Future.delayed(duration);
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
