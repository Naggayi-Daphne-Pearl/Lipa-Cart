import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_recipe_service.dart';
import '../../services/product_service.dart';
import '../../services/upload_service.dart';

class AdminRecipesScreen extends StatefulWidget {
  const AdminRecipesScreen({super.key});

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('No auth token');

      final recipes = await AdminRecipeService.listRecipes(
        token: token,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _recipes = recipes;
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

  Future<void> _openForm({Map<String, dynamic>? recipe}) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RecipeFormDialog(recipe: recipe),
    );

    if (changed == true && mounted) {
      _loadRecipes();
    }
  }

  Future<void> _deleteRecipe(Map<String, dynamic> recipe) async {
    final title = (recipe['title'] ?? recipe['name'] ?? 'Recipe').toString();
    final documentId = recipe['documentId']?.toString() ?? '';
    if (documentId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('No auth token');

      await AdminRecipeService.deleteRecipe(
        token: token,
        recipeDocumentId: documentId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe deleted'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadRecipes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Text('Recipe Management', style: AppTextStyles.h5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search recipes...',
                      prefixIcon: const Icon(Iconsax.search_normal),
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
                    ),
                    onSubmitted: (_) => _loadRecipes(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _loadRecipes,
                  icon: const Icon(Iconsax.refresh),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.grey200),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Iconsax.add),
                  label: const Text('Add Recipe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _recipes.isEmpty
                          ? _buildEmptyState()
                          : _buildRecipesTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Failed to load recipes', style: AppTextStyles.h5),
          const SizedBox(height: 8),
          Text(_error ?? '', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.book_1, size: 56, color: AppColors.grey400),
          const SizedBox(height: 14),
          Text('No recipes yet', style: AppTextStyles.h5),
          const SizedBox(height: 8),
          Text(
            'Create your first recipe to help customers cook with catalog items.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesTable() {
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
            columns: const [
              DataColumn(label: Text('Recipe')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Difficulty')),
              DataColumn(label: Text('Ingredients')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _recipes.map((recipe) {
              final image = recipe['image'];
              final imageUrl = image is Map<String, dynamic>
                  ? (image['url']?.toString() ?? '')
                  : '';
              final title = (recipe['title'] ?? recipe['name'] ?? 'Untitled').toString();
              final category = (recipe['category'] ?? 'Uncategorized').toString();
              final difficulty = (recipe['difficulty'] ?? 'medium').toString();
              final ingredients = (recipe['ingredients'] as List<dynamic>? ?? const []);

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.grey100,
                                      child: const Icon(Iconsax.image),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.grey100,
                                    child: const Icon(Iconsax.image),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(title),
                      ],
                    ),
                  ),
                  DataCell(Text(category)),
                  DataCell(Text(difficulty)),
                  DataCell(Text('${ingredients.length}')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _openForm(recipe: recipe),
                          icon: const Icon(Iconsax.edit, size: 18),
                        ),
                        IconButton(
                          onPressed: () => _deleteRecipe(recipe),
                          icon: const Icon(Iconsax.trash, size: 18),
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _IngredientDraft {
  final TextEditingController name = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController unit = TextEditingController();
  final TextEditingController notes = TextEditingController();
  String? productDocumentId;
  String? productName;
  bool isOptional = false;

  _IngredientDraft();

  _IngredientDraft.fromMap(Map<String, dynamic> map) {
    name.text = (map['name'] ?? '').toString();
    quantity.text = (map['quantity'] ?? '').toString();
    unit.text = (map['unit'] ?? '').toString();
    notes.text = (map['notes'] ?? '').toString();
    productDocumentId = map['product_document_id']?.toString();
    productName = map['product_name']?.toString();
    isOptional = map['is_optional'] == true;
  }

  AdminRecipeIngredientInput toInput() => AdminRecipeIngredientInput(
        name: name.text.trim(),
        quantity: quantity.text.trim().isEmpty
            ? null
            : double.tryParse(quantity.text.trim()),
        unit: unit.text.trim().isEmpty ? null : unit.text.trim(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        isOptional: isOptional,
        productDocumentId: productDocumentId,
        productName: productName,
      );

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
    notes.dispose();
  }
}

class _InstructionDraft {
  final TextEditingController text = TextEditingController();
  final TextEditingController minutes = TextEditingController();

  _InstructionDraft();

  _InstructionDraft.fromMap(Map<String, dynamic> map) {
    text.text = (map['description'] ?? '').toString();
    minutes.text = (map['duration_minutes'] ?? '').toString();
  }

  AdminRecipeInstructionInput toInput(int idx) => AdminRecipeInstructionInput(
        stepNumber: idx + 1,
        description: text.text.trim(),
        durationMinutes:
            minutes.text.trim().isEmpty ? null : int.tryParse(minutes.text.trim()),
      );

  void dispose() {
    text.dispose();
    minutes.dispose();
  }
}

class _RecipeFormDialog extends StatefulWidget {
  final Map<String, dynamic>? recipe;
  const _RecipeFormDialog({this.recipe});

  @override
  State<_RecipeFormDialog> createState() => _RecipeFormDialogState();
}

class _RecipeFormDialogState extends State<_RecipeFormDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorController = TextEditingController();
  final _prepController = TextEditingController(text: '10');
  final _cookController = TextEditingController(text: '20');
  final _servingsController = TextEditingController(text: '4');
  final _tagsController = TextEditingController();
  final _categoryController = TextEditingController();

  String _difficulty = 'medium';
  int? _imageMediaId;
  String? _imageUrl;
  Uint8List? _pickedImageBytes;
  bool _uploadingImage = false;
  bool _saving = false;

  final List<_IngredientDraft> _ingredients = [];
  final List<_InstructionDraft> _instructions = [];
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _hydrate();
    _loadProducts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _prepController.dispose();
    _cookController.dispose();
    _servingsController.dispose();
    _tagsController.dispose();
    _categoryController.dispose();
    for (final item in _ingredients) {
      item.dispose();
    }
    for (final step in _instructions) {
      step.dispose();
    }
    super.dispose();
  }

  void _hydrate() {
    final recipe = widget.recipe;
    if (recipe == null) {
      _ingredients.add(_IngredientDraft());
      _instructions.add(_InstructionDraft());
      return;
    }

    _titleController.text = (recipe['title'] ?? recipe['name'] ?? '').toString();
    _descriptionController.text = (recipe['description'] ?? '').toString();
    _authorController.text = (recipe['author_name'] ?? '').toString();
    _prepController.text = (recipe['prep_time'] ?? 10).toString();
    _cookController.text = (recipe['cook_time'] ?? 20).toString();
    _servingsController.text = (recipe['servings'] ?? 4).toString();
    _difficulty = (recipe['difficulty'] ?? 'medium').toString();
    _categoryController.text = (recipe['category'] ?? '').toString();
    final tags = (recipe['tags'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    _tagsController.text = tags.join(', ');

    final image = recipe['image'];
    if (image is Map<String, dynamic>) {
      final imageId = image['id'];
      if (imageId is int) {
        _imageMediaId = imageId;
      } else if (imageId != null) {
        _imageMediaId = int.tryParse(imageId.toString());
      }
      _imageUrl = image['url']?.toString();
    }

    final ingredients = recipe['ingredients'] as List<dynamic>? ?? const [];
    for (final item in ingredients) {
      _ingredients.add(_IngredientDraft.fromMap(item as Map<String, dynamic>));
    }
    if (_ingredients.isEmpty) {
      _ingredients.add(_IngredientDraft());
    }

    final instructions = recipe['instructions'] as List<dynamic>? ?? const [];
    for (final step in instructions) {
      _instructions.add(_InstructionDraft.fromMap(step as Map<String, dynamic>));
    }
    if (_instructions.isEmpty) {
      _instructions.add(_InstructionDraft());
    }
  }

  Future<void> _loadProducts() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final products = await ProductService.getProducts(token: token);
      if (mounted) {
        setState(() => _products = products);
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('No auth token');

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _uploadingImage = true;
      });

      final uploaded = await UploadService.uploadImageBytesWithMeta(
        bytes,
        picked.name,
        token,
      );

      if (mounted) {
        setState(() {
          _imageMediaId = uploaded.id;
          _imageUrl = uploaded.url;
          _uploadingImage = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
        _pickedImageBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_uploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for image upload to complete')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, description, and category are required')),
      );
      return;
    }

    final cleanedIngredients = _ingredients
        .where((i) => i.name.text.trim().isNotEmpty)
        .toList();
    final cleanedInstructions = _instructions
        .where((i) => i.text.text.trim().isNotEmpty)
        .toList();

    if (cleanedIngredients.isEmpty || cleanedInstructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient and one instruction')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('No auth token');

      final input = AdminRecipeInput(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        authorName: _authorController.text.trim().isEmpty
            ? 'Lipa Cart Kitchen'
            : _authorController.text.trim(),
        prepTime: int.tryParse(_prepController.text.trim()) ?? 0,
        cookTime: int.tryParse(_cookController.text.trim()) ?? 0,
        servings: int.tryParse(_servingsController.text.trim()) ?? 1,
        difficulty: _difficulty,
        tags: _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        ingredients: cleanedIngredients.map((i) => i.toInput()).toList(),
        instructions: cleanedInstructions
            .asMap()
            .entries
            .map((entry) => entry.value.toInput(entry.key))
            .toList(),
        imageMediaId: _imageMediaId,
      );

      final recipe = widget.recipe;
      if (recipe == null) {
        await AdminRecipeService.createRecipe(token: token, input: input);
      } else {
        final docId = recipe['documentId']?.toString() ?? '';
        if (docId.isEmpty) throw Exception('Missing recipe document id');
        await AdminRecipeService.updateRecipe(
          token: token,
          recipeDocumentId: docId,
          input: input,
        );
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(recipe == null ? 'Recipe created' : 'Recipe updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 28),
      child: SizedBox(
        width: 1000,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    widget.recipe == null ? 'Add Recipe' : 'Edit Recipe',
                    style: AppTextStyles.h4,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildBasics(),
                      const SizedBox(height: 16),
                      _buildIngredients(),
                      const SizedBox(height: 16),
                      _buildInstructions(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Recipe'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasics() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Details', style: AppTextStyles.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _authorController,
                  decoration: const InputDecoration(labelText: 'Author Name'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description *'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category *'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                  ],
                  onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prepController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prep Time (min)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cookController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cook Time (min)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _servingsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Servings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'Quick, Dinner, Vegetarian',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _uploadingImage ? null : _pickAndUploadImage,
                icon: _uploadingImage
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.image),
                label: const Text('Upload Cover Image'),
              ),
              const SizedBox(width: 12),
              if (_pickedImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _pickedImageBytes!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_imageUrl != null && _imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredients() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Ingredients', style: AppTextStyles.labelLarge),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _ingredients.add(_IngredientDraft())),
                icon: const Icon(Iconsax.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._ingredients.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: item.name,
                            decoration: InputDecoration(
                              labelText: 'Ingredient ${idx + 1} *',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 130,
                          child: TextField(
                            controller: item.quantity,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: item.unit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                          ),
                        ),
                        IconButton(
                          onPressed: _ingredients.length <= 1
                              ? null
                              : () {
                                  final removed = _ingredients.removeAt(idx);
                                  removed.dispose();
                                  setState(() {});
                                },
                          icon: const Icon(Iconsax.trash, color: AppColors.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: item.productDocumentId,
                            decoration: const InputDecoration(
                              labelText: 'Linked Product (optional)',
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No product link'),
                              ),
                              ..._products.map(
                                (p) => DropdownMenuItem<String?>(
                                  value: p.id,
                                  child: Text(p.name),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              final selected = _products.where((p) => p.id == v).toList();
                              setState(() {
                                item.productDocumentId = v;
                                item.productName = selected.isEmpty ? null : selected.first.name;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: item.notes,
                            decoration: const InputDecoration(labelText: 'Notes'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Checkbox(
                          value: item.isOptional,
                          onChanged: (v) => setState(() => item.isOptional = v ?? false),
                        ),
                        const Text('Optional'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Instructions', style: AppTextStyles.labelLarge),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _instructions.add(_InstructionDraft())),
                icon: const Icon(Iconsax.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._instructions.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: step.text,
                      decoration: InputDecoration(
                        labelText: 'Step ${idx + 1} *',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: step.minutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minutes'),
                    ),
                  ),
                  IconButton(
                    onPressed: _instructions.length <= 1
                        ? null
                        : () {
                            final removed = _instructions.removeAt(idx);
                            removed.dispose();
                            setState(() {});
                          },
                    icon: const Icon(Iconsax.trash, color: AppColors.error),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
