import 'package:flutter/material.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';

class PulseFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;

  const PulseFloatingActionButton({
    super.key, 
    required this.onPressed,
    this.color = AppColors.primary,
  });

  @override
  State<PulseFloatingActionButton> createState() => _PulseFloatingActionButtonState();
}

class _PulseFloatingActionButtonState extends State<PulseFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Ring
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.5).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.6, end: 0.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.4),
                ),
              ),
            ),
          ),
          // Main Button
          SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: widget.color,
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
