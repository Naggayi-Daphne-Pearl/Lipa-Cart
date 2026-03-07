import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/imgbb_upload_provider.dart';
import 'app_loading_indicator.dart';

class ImgBBUploadWidget extends StatefulWidget {
  /// Callback when single image is uploaded - receives the ImgBB URL
  final Function(String imageUrl) onImageUploaded;

  /// Callback when multiple images are uploaded
  final Function(List<String> urls)? onMultipleImagesUploaded;

  /// Show existing image
  final String? initialImageUrl;

  /// Allow picking multiple images
  final bool allowMultiple;

  /// Hint text
  final String? hint;

  const ImgBBUploadWidget({
    super.key,
    required this.onImageUploaded,
    this.onMultipleImagesUploaded,
    this.initialImageUrl,
    this.allowMultiple = false,
    this.hint,
  });

  @override
  State<ImgBBUploadWidget> createState() => _ImgBBUploadWidgetState();
}

class _ImgBBUploadWidgetState extends State<ImgBBUploadWidget> {
  File? _selectedImage;
  final List<File> _selectedImages = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<ImgBBUploadProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // IMAGE PREVIEW
            if (!widget.allowMultiple)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : widget.initialImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.initialImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.hint ?? 'No image selected',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              )
            else
            // MULTIPLE IMAGES PREVIEW
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.file(
                              _selectedImages[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(
                                    () => _selectedImages.removeAt(index),
                                  );
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('No images selected')),
              ),

            const SizedBox(height: 16),

            // PICK IMAGE BUTTONS
            if (!provider.isUploading)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      File? image = await provider.pickImageFromGallery();
                      if (image != null) {
                        if (widget.allowMultiple) {
                          setState(() => _selectedImages.add(image));
                        } else {
                          setState(() => _selectedImage = image);
                        }
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Gallery'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      File? image = await provider.pickImageFromCamera();
                      if (image != null) {
                        if (widget.allowMultiple) {
                          setState(() => _selectedImages.add(image));
                        } else {
                          setState(() => _selectedImage = image);
                        }
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // UPLOAD BUTTON
            if ((widget.allowMultiple && _selectedImages.isNotEmpty) ||
                (!widget.allowMultiple && _selectedImage != null))
              if (!provider.isUploading)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    if (widget.allowMultiple) {
                      await _handleMultipleUpload(context, provider);
                    } else {
                      await _handleSingleUpload(context, provider);
                    }
                  },
                  child: Text(
                    widget.allowMultiple
                        ? 'Upload ${_selectedImages.length} Images'
                        : 'Upload Image',
                  ),
                ),

            // LOADING STATE
            if (provider.isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const AppLoadingIndicator(),
                    const SizedBox(height: 12),
                    const Text('Uploading to ImgBB...'),
                  ],
                ),
              ),

            // ERROR MESSAGE
            if (provider.uploadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.uploadError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: provider.clearError,
                      ),
                    ],
                  ),
                ),
              ),

            // SUCCESS MESSAGE
            if (provider.uploadedUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            '✅ Upload successful!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...provider.uploadedUrls.map((url) {
                        return GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('URL copied!')),
                            );
                          },
                          child: Text(
                            url,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleSingleUpload(
    BuildContext context,
    ImgBBUploadProvider provider,
  ) async {
    String? url = await provider.uploadImage(_selectedImage!);

    if (url != null && mounted) {
      widget.onImageUploaded(url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Image uploaded!')));
      setState(() => _selectedImage = null);
    }
  }

  Future<void> _handleMultipleUpload(
    BuildContext context,
    ImgBBUploadProvider provider,
  ) async {
    List<String>? urls = await provider.uploadMultipleImages(_selectedImages);

    if (urls != null && mounted) {
      widget.onMultipleImagesUploaded?.call(urls);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${urls.length} images uploaded!')),
      );
      setState(() => _selectedImages.clear());
    }
  }
}
