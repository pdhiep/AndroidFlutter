import 'package:flutter/material.dart';

void showTopRightNotification(
  BuildContext context,
  String message, {
  bool isSuccess = true,
}) {
  final overlay = Overlay.of(context);
  // Remove any existing notification overlays to avoid stacking
  // This is a simple approach. For more complex scenarios, you might want to manage overlay entries more carefully.
  final List<OverlayEntry> toRemove = [];
  overlay?.context.visitChildElements((element) {
    if (element.widget is OverlayEntry) {
      toRemove.add(element.widget as OverlayEntry);
    }
  });
  for (var entry in toRemove) {
    entry.remove();
  }

  // Create a new notification overlay

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 80,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0), // Animate from right
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto-remove after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
