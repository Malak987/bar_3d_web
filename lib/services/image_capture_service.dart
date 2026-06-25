import 'dart:convert';

/// 🎨 Image Capture Service
///
/// Captures the final 3D cake design as an image
/// This is the "Final Render Image" that represents the completed cake design
///
/// Note: The actual capture is done in the JS layer (cake_designer.js)
/// This service provides helper functions for Dart side processing

/// Captures the current 3D canvas as a data URL string
/// For use in image upload
String? captureCakeDesignAsDataUrl() {
  try {
    // Call the JS function via the CakeCanvasView controller
    // The actual implementation is in web/js/cake_designer.js
    // which exposes window.CakeScene.captureImage()
    return null;
  } catch (e) {
    print('[ImageCapture] Failed to capture as data URL: $e');
    return null;
  }
}

/// Converts data URL to base64 string
String? dataUrlToBase64(String? dataUrl) {
  if (dataUrl == null || dataUrl.isEmpty) return null;

  try {
    if (dataUrl.contains(',')) {
      return dataUrl.split(',').last;
    }
    return dataUrl;
  } catch (e) {
    print('[ImageCapture] Failed to convert dataUrl to base64: $e');
    return null;
  }
}

/// Converts base64 string to bytes (for upload)
List<int>? base64ToBytes(String? base64Data) {
  if (base64Data == null || base64Data.isEmpty) return null;

  try {
    return base64Decode(base64Data);
  } catch (e) {
    print('[ImageCapture] Failed to decode base64: $e');
    return null;
  }
}

/// Resizes image to specified dimensions
/// Returns resized image bytes
/// Note: This would typically be done in JS for better performance
List<int>? resizeImageBytes(List<int> imageBytes, int maxWidth, int maxHeight) {
  // For now, return original - resizing should be done in JS
  return imageBytes;
}

/// Compresses image to reduce file size
/// quality: 0.0 to 1.0 (1.0 = no compression)
/// Note: Compression should be done in JS for better performance
List<int>? compressImageBytes(List<int> imageBytes, double quality) {
  // For now, return original - compression should be done in JS
  return imageBytes;
}