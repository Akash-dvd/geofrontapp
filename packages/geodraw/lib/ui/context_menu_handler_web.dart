import 'dart:js_interop';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web-specific implementation to prevent browser context menu
/// Only prevents context menu when clicking within the canvas area
/// The Flutter GestureDetector will handle right-clicks and show our custom menu
void preventBrowserContextMenuInCanvas(GlobalKey canvasKey) {
  web.window.document.addEventListener(
    'contextmenu',
    ((web.Event event) {
      // Check if the event target is within the canvas widget
      final target = event.target;
      if (target != null && _isWithinCanvas(canvasKey, event)) {
        // Prevent default context menu only in canvas area
        // Our Flutter menu will handle it
        event.preventDefault();
      }
      // Otherwise, allow default browser context menu
    }).toJS,
  );
}

bool _isWithinCanvas(GlobalKey canvasKey, web.Event event) {
  try {
    final renderObject = canvasKey.currentContext?.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) return false;
    
    // Get the canvas bounds
    final box = renderObject;
    final canvasTopLeft = box.localToGlobal(Offset.zero);
    final canvasSize = box.size;
    final canvasRect = Rect.fromLTWH(
      canvasTopLeft.dx,
      canvasTopLeft.dy,
      canvasSize.width,
      canvasSize.height,
    );
    
    // Check if the event coordinates are within canvas bounds
    // Context menu events are always MouseEvent
    if (event is! web.MouseEvent) return false;
    
    final mouseEvent = event;
    final clickPoint = Offset(
      mouseEvent.clientX.toDouble(),
      mouseEvent.clientY.toDouble(),
    );
    
    return canvasRect.contains(clickPoint);
  } catch (e) {
    // If we can't determine, be safe and don't prevent
    // This allows default browser behavior in uncertain cases
    return false;
  }
}

