import 'package:flutter/material.dart';

class StaggeredEntry extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final Duration baseDelay;
  final double verticalOffset;

  const StaggeredEntry({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.baseDelay = const Duration(milliseconds: 100),
    this.verticalOffset = 50.0,
  });

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    
    // Convert pixel offset to relative offset (approximate, assuming child height is relevant but SlideTransition uses percentage of child size)
    // Actually SlideTransition offset is relative to child size. 0.1 means 10% of height.
    // Let's use a small relative value.
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    // Use modulo to prevent huge delays for items far down the list
    // But for the first screen, we want a nice sequence.
    // We can assume items are built in order.
    // If we just use a small delay for every item that enters, it looks like they pop in.
    // Let's try a simple delay based on index % columnCount (usually 2).
    // Actually, for the initial load, we want them to cascade.
    // For scrolling, we want them to appear quickly.
    
    // Simple heuristic: delay = base * (index % 5)
    final delay = widget.baseDelay * (widget.index % 10);
    
    // If we want a true "initial load" stagger vs "scroll" stagger, we'd need more context.
    // But this usually works well enough.
    
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
