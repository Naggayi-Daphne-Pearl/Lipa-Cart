import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../services/category_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/admin/bulk_import_dialog.dart';
import '../../widgets/shimmer_loading.dart';

class AdminCategoriesDesktopScreen extends StatefulWidget {
  const AdminCategoriesDesktopScreen({super.key});

  @override
  State<AdminCategoriesDesktopScreen> createState() =>
      _AdminCategoriesDesktopScreenState();
}

class _AdminCategoriesDesktopScreenState
    extends State<AdminCategoriesDesktopScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('No auth token');

      final results = await CategoryService.getCategories(
        token: token,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _categories = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showCategoryDialog({Category? category}) {
    showDialog<void>(
      context: context,
      builder: (_) => _CategoryFormDialog(
        category: category,
        onSaved: _loadCategories,
      ),
    );
  }

  void _confirmDelete(Category category) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool inFlight = false;
        return StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Category'),
            content: Text(
              'Delete "${category.name}"? Products in this category will not be deleted, but they will lose their category assignment.',
            ),
            actions: [
              TextButton(
                onPressed:
                    inFlight ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: inFlight
                    ? null
                    : () async {
                        final token = context.read<AuthProvider>().token;
                        if (token == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(dialogContext);
                        setDialogState(() => inFlight = true);
                        try {
                          await CategoryService.deleteCategory(
                            category.id,
                            token: token,
                          );
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Category deleted'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          if (mounted) _loadCategories();
                        } catch (e) {
                          setDialogState(() => inFlight = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                child: inFlight
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const ShimmerAdminTable()
                  : _error != null
                      ? _buildErrorState()
                      : _categories.isEmpty
                          ? _buildEmptyState()
                          : _buildCategoriesTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categories',
                style:
                    AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                '${_categories.length} ${_categories.length == 1 ? "category" : "categories"}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _showBulkImportDialog,
              icon: const Icon(Iconsax.document_upload, size: 18),
              label: const Text('Bulk Import'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.grey300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Iconsax.add, size: 18),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBulkImportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminBulkImportDialog(
        dialogTitle: 'Bulk import categories',
        instructions:
            '1. Download the template (.xlsx).\n'
            '2. Fill in rows. To attach an image, name a file in your '
            'images folder (e.g. vegetables.jpg) and put that filename '
            'in the image_filename column.\n'
            '3. Pick the .xlsx, pick the .zip of images, then Import. '
            'Max 200 rows.',
        templateEndpoint: '/categories/xlsx-template',
        exportEndpoint: '/categories/xlsx-export',
        templateFilename: 'categories-template.xlsx',
        exportFilenamePrefix: 'categories-export',
        exportButtonLabel: 'Export Current Categories',
        importFn: CategoryService.bulkImport,
        onComplete: _loadCategories,
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search categories...',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary),
              prefixIcon: const Icon(Iconsax.search_normal,
                  size: 20, color: AppColors.textTertiary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: AppTextStyles.bodySmall,
            onSubmitted: (_) => _loadCategories(),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _loadCategories,
          icon: const Icon(Iconsax.refresh, size: 20),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppColors.grey200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 48, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            'Failed to load categories',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '$_error',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Iconsax.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.trim().isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.category, size: 56, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No matching categories' : 'No categories yet',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search term'
                : 'Add your first category to organise products',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Iconsax.add, size: 18),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.grey50),
            headingTextStyle: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            dataRowMinHeight: 64,
            dataRowMaxHeight: 72,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Colour')),
              DataColumn(label: Text('Products'), numeric: true),
              DataColumn(label: Text('Actions')),
            ],
            rows: _categories.map(_buildCategoryRow).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildCategoryRow(Category category) {
    final swatch = _parseHexColor(category.color) ?? AppColors.primary;
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: category.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: category.image,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.grey100,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.grey100,
                            child: const Icon(Iconsax.image,
                                size: 18, color: AppColors.textTertiary),
                          ),
                        )
                      : Container(
                          color: AppColors.grey100,
                          child: const Icon(Iconsax.image,
                              size: 18, color: AppColors.textTertiary),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  category.name,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          SizedBox(
            width: 280,
            child: Text(
              (category.description ?? '').isEmpty ? '—' : category.description!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey200),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.color,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            '${category.productCount}',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textPrimary),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showCategoryDialog(category: category),
                icon: const Icon(Iconsax.edit, size: 18),
                tooltip: 'Edit',
                color: AppColors.primary,
              ),
              IconButton(
                onPressed: () => _confirmDelete(category),
                icon: const Icon(Iconsax.trash, size: 18),
                tooltip: 'Delete',
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Color? _parseHexColor(String hex) {
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    if (cleaned.length != 8) return null;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : Color(value);
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final Category? category;
  final VoidCallback onSaved;

  const _CategoryFormDialog({required this.category, required this.onSaved});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _colorController;
  late TextEditingController _sortOrderController;
  bool _isActive = true;

  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  Uint8List? _pickedImageBytes;
  int? _uploadedImageId;
  String? _existingImageUrl;

  static const List<String> _presetColors = [
    '#15874B',
    '#F89227',
    '#2ECC71',
    '#E74C3C',
    '#3498DB',
    '#9B59B6',
    '#F39C12',
    '#1ABC9C',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c?.name ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _colorController =
        TextEditingController(text: c?.color ?? _presetColors.first);
    _sortOrderController = TextEditingController(text: '0');
    _existingImageUrl =
        (c?.image.isNotEmpty ?? false) ? c!.image : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImageBytes = bytes;
        _isUploadingImage = true;
      });

      final result = await UploadService.uploadImageBytesWithMeta(
        bytes,
        picked.name,
        token,
      );

      if (!mounted) return;
      setState(() {
        _uploadedImageId = result.id;
        _existingImageUrl = result.url;
        _isUploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
        _pickedImageBytes = null;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Category name is required')),
      );
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    final colorText = _colorController.text.trim();
    final normalizedColor =
        colorText.startsWith('#') ? colorText : '#$colorText';

    setState(() => _isSubmitting = true);
    try {
      final payload = <String, dynamic>{
        'name': name,
        'description': _descriptionController.text.trim(),
        'color': normalizedColor,
        'sort_order': int.tryParse(_sortOrderController.text.trim()) ?? 0,
        'is_active': _isActive,
        if (_uploadedImageId != null) 'image': _uploadedImageId,
      };

      if (widget.category == null) {
        await CategoryService.createCategory(payload, token: token);
      } else {
        await CategoryService.updateCategory(
          widget.category!.id,
          payload,
          token: token,
        );
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.category == null
              ? 'Category created'
              : 'Category updated'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onSaved();
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'Category Name *',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildColorRow(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _sortOrderController,
                      label: 'Sort Order',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Active',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            activeTrackColor: AppColors.primary,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _isUploadingImage ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.category == null ? 'Create' : 'Save changes'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasPicked = _pickedImageBytes != null;
    final hasExisting =
        _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    Widget preview;
    if (hasPicked) {
      preview = Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
    } else if (hasExisting) {
      preview = CachedNetworkImage(
        imageUrl: _existingImageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.grey100),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.grey100,
          child: const Icon(Iconsax.image,
              size: 32, color: AppColors.textTertiary),
        ),
      );
    } else {
      preview = Container(
        color: AppColors.grey100,
        alignment: Alignment.center,
        child: const Icon(Iconsax.gallery,
            size: 36, color: AppColors.textTertiary),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 96, height: 96, child: preview),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Image',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'JPG, PNG or WEBP. Max 10MB.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                icon: _isUploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.gallery_add, size: 18),
                label: Text(
                  _isUploadingImage
                      ? 'Uploading...'
                      : (hasPicked || hasExisting)
                          ? 'Change image'
                          : 'Upload image',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.grey300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorRow() {
    final parsed = _parseHexColor(_colorController.text) ?? AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accent Colour',
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: parsed,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.grey300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _colorController,
                decoration: InputDecoration(
                  hintText: '#15874B',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((hex) {
            final color = _parseHexColor(hex) ?? AppColors.primary;
            final isSelected =
                _colorController.text.toUpperCase() == hex.toUpperCase();
            return GestureDetector(
              onTap: () {
                setState(() => _colorController.text = hex);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.textPrimary : AppColors.grey300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Color? _parseHexColor(String hex) {
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    if (cleaned.length != 8) return null;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : Color(value);
  }
}
