import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/imgbb_service.dart';

class ImgBBUploadProvider extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  String? _uploadError;
  List<String> _uploadedUrls = [];

  // Getters
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;
  List<String> get uploadedUrls => _uploadedUrls;

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress to 80%
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      _uploadError = 'Failed to pick from gallery: $e';
      notifyListeners();
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      _uploadError = 'Failed to take photo: $e';
      notifyListeners();
      return null;
    }
  }

  /// Upload a single image
  /// Returns the ImgBB URL or null on failure
  Future<String?> uploadImage(File imageFile) async {
    try {
      _isUploading = true;
      _uploadError = null;
      notifyListeners();

      String? url = await ImgBBService.uploadImage(imageFile);

      if (url != null) {
        _uploadedUrls.add(url);
      }

      _isUploading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _uploadError = e.toString();
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }

  /// Upload multiple images
  Future<List<String>?> uploadMultipleImages(List<File> imageFiles) async {
    try {
      _isUploading = true;
      _uploadError = null;
      _uploadedUrls.clear();
      notifyListeners();

      List<String> urls = await ImgBBService.uploadMultipleImages(imageFiles);

      _uploadedUrls = urls;
      _isUploading = false;
      notifyListeners();

      return urls;
    } catch (e) {
      _uploadError = e.toString();
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear uploaded URLs
  void clearUrls() {
    _uploadedUrls.clear();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _uploadError = null;
    notifyListeners();
  }

  /// Reset everything
  void reset() {
    _isUploading = false;
    _uploadError = null;
    _uploadedUrls.clear();
    notifyListeners();
  }
}
