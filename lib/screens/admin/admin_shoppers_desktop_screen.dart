import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_user_service.dart';
import '../../services/shopper_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/app_loading_indicator.dart';
import 'admin_kyc_review_screen.dart';

class AdminShoppersDesktopScreen extends StatefulWidget {
  const AdminShoppersDesktopScreen({super.key});

  @override
  State<AdminShoppersDesktopScreen> createState() =>
      _AdminShoppersDesktopScreenState();
}

class _AdminShoppersDesktopScreenState
    extends State<AdminShoppersDesktopScreen> {
  late List<Map<String, dynamic>> _shoppers = [];
  Map<String, dynamic>? _selectedShopper;
  Map<String, dynamic>? _selectedShopperDetails;
  bool _selectedShopperLoading = false;
  String? _selectedShopperError;
  bool _isLoading = true;
  String? _error;
  String? _selectedKycStatus;
  bool? _selectedActiveStatus;
  final _searchController = TextEditingController();

  final List<String> _kycStatuses = [
    'All',
    'not_submitted',
    'pending_review',
    'more_info_requested',
    'approved',
    'rejected',
  ];

  Future<void> _openKycReview(Map<String, dynamic> shopper) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminKycReviewScreen(role: KycRole.shopper, applicant: shopper),
      ),
    );
    if (result == true) {
      _loadShoppers();
    }
  }

  String? _extractShopperProfileId(Map<String, dynamic> shopper) {
    final nested = shopper['shopper'];
    if (nested is Map<String, dynamic>) {
      final nestedDocId = nested['documentId']?.toString();
      if (nestedDocId != null && nestedDocId.isNotEmpty) return nestedDocId;
      final nestedId = nested['id']?.toString();
      if (nestedId != null && nestedId.isNotEmpty) return nestedId;
      final data = nested['data'];
      if (data is Map<String, dynamic>) {
        final dataDocId = data['documentId']?.toString();
        if (dataDocId != null && dataDocId.isNotEmpty) return dataDocId;
        final dataId = data['id']?.toString();
        if (dataId != null && dataId.isNotEmpty) return dataId;
      }
    }
    final direct = shopper['shopper_document_id']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    return null;
  }

  Future<void> _selectShopper(Map<String, dynamic> shopper) async {
    setState(() {
      _selectedShopper = shopper;
      _selectedShopperLoading = true;
      _selectedShopperError = null;
      _selectedShopperDetails = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('No auth token');
      final profileId = _extractShopperProfileId(shopper);
      Map<String, dynamic>? details;

      if (profileId != null) {
        try {
          details = await ShopperService.getShopperProfileById(
            profileId,
            token: token,
          );
        } catch (_) {
          details = null;
        }
      }

      details ??= await ShopperService.getShopperProfileByUser(
        token: token,
        userDocumentId: shopper['documentId']?.toString(),
        userId: shopper['id'],
        phone: shopper['phone']?.toString(),
        email: shopper['email']?.toString(),
      );

      if (details == null || details.isEmpty) {
        throw Exception('Shopper profile not found');
      }

      if (!mounted) return;
      setState(() {
        final resolvedKyc = details?['kyc_status']?.toString();
        if (resolvedKyc != null && resolvedKyc.isNotEmpty) {
          _shoppers = _shoppers.map((row) {
            if (row['id']?.toString() == shopper['id']?.toString()) {
              return {...row, 'kyc_status': resolvedKyc};
            }
            return row;
          }).toList();
        }
        _selectedShopperDetails = {...shopper, ...details!, 'shopper': details};
        _selectedShopperLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedShopperLoading = false;
        _selectedShopperError = e.toString();
        _selectedShopperDetails = shopper;
      });
    }
  }

  String _selectedShopperKycId() {
    final details = _selectedShopperDetails;
    final nested = details?['shopper'];
    if (nested is Map<String, dynamic>) {
      final nestedDocId = nested['documentId']?.toString();
      if (nestedDocId != null && nestedDocId.isNotEmpty) return nestedDocId;
      final data = nested['data'];
      if (data is Map<String, dynamic>) {
        final dataDocId = data['documentId']?.toString();
        if (dataDocId != null && dataDocId.isNotEmpty) return dataDocId;
      }
    }

    final profileDocId = details?['documentId']?.toString();
    if (profileDocId != null && profileDocId.isNotEmpty) return profileDocId;
    final selectedDocId = _selectedShopper?['documentId']?.toString();
    if (selectedDocId != null && selectedDocId.isNotEmpty) return selectedDocId;
    return '';
  }

  String _rowKycStatus(Map<String, dynamic> shopper) {
    String? nestedStatus;
    final nested = shopper['shopper'];
    if (nested is Map<String, dynamic>) {
      nestedStatus = nested['kyc_status']?.toString();
      final data = nested['data'];
      if ((nestedStatus == null || nestedStatus.isEmpty) &&
          data is Map<String, dynamic>) {
        nestedStatus = data['kyc_status']?.toString();
        final attrs = data['attributes'];
        if ((nestedStatus == null || nestedStatus.isEmpty) &&
            attrs is Map<String, dynamic>) {
          nestedStatus = attrs['kyc_status']?.toString();
        }
      }
    }

    final selectedId = _selectedShopper?['id']?.toString();
    final rowId = shopper['id']?.toString();
    if (selectedId != null && selectedId == rowId) {
      final selectedStatus = _selectedShopperDetails?['kyc_status']?.toString();
      if (selectedStatus != null && selectedStatus.isNotEmpty) {
        return selectedStatus;
      }
    }

    return shopper['kyc_status']?.toString() ?? nestedStatus ?? 'not_submitted';
  }

  @override
  void initState() {
    super.initState();
    _loadShoppers();
  }

  Future<void> _loadShoppers() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No auth token');
      }

      final shoppers = await ShopperService.getShoppers(
        token: token,
        kycStatus: _selectedKycStatus == 'All' ? null : _selectedKycStatus,
        isActive: _selectedActiveStatus,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
      );

      if (mounted) {
        setState(() {
          _shoppers = shoppers;
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

  void _showEditDialog(Map<String, dynamic> shopper) {
    final nameController = TextEditingController(text: shopper['name'] ?? '');
    final phoneController = TextEditingController(text: shopper['phone'] ?? '');
    final emailController = TextEditingController(text: shopper['email'] ?? '');
    final businessNameController = TextEditingController(
      text: shopper['business_name'] ?? '',
    );
    final authProvider = context.read<AuthProvider>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Shopper Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);

                      try {
                        final token = authProvider.token;

                        if (token == null) throw Exception('No auth token');

                        final shopperId =
                            shopper['id'] ?? shopper['documentId'];
                        if (shopperId == null)
                          throw Exception('Shopper ID not found');

                        final updateData = {
                          'name': nameController.text,
                          'phone': phoneController.text,
                          'email': emailController.text,
                          'business_name': businessNameController.text,
                        };

                        await ShopperService.updateShopper(
                          shopperId,
                          updateData,
                          token: token,
                        );

                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Shopper profile updated successfully',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadShoppers();
                        }
                      } catch (e) {
                        setState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const AppLoadingIndicator.small()
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectKycDialog(Map<String, dynamic> shopper) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reject KYC'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Shopper: ${shopper['name'] ?? "Unknown"}'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (reasonController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide a rejection reason'),
                          ),
                        );
                        return;
                      }

                      setState(() => isSubmitting = true);

                      try {
                        final authProvider = context.read<AuthProvider>();
                        final token = authProvider.token;

                        if (token == null) throw Exception('No auth token');

                        await ShopperService.rejectKyc(
                          shopper['documentId'],
                          token: token,
                          reason: reasonController.text,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('KYC rejected successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadShoppers();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        if (mounted) {
                          setState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const AppLoadingIndicator.small()
                  : const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveKyc(String shopperId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) throw Exception('No auth token');

      await ShopperService.approveKyc(shopperId, token: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadShoppers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCreateShopperDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Shopper Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty ||
                          phoneController.text.trim().isEmpty ||
                          passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Name, phone, and password are required',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() => isSubmitting = true);
                      try {
                        final token = this.context.read<AuthProvider>().token;
                        if (token == null) throw Exception('No auth token');

                        await AdminUserService.createStaff(
                          phone: phoneController.text.trim(),
                          password: passwordController.text.trim(),
                          name: nameController.text.trim(),
                          email: emailController.text.trim().isEmpty
                              ? null
                              : emailController.text.trim(),
                          userType: 'shopper',
                          token: token,
                        );

                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Shopper account created successfully',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadShoppers();
                      } catch (e) {
                        setState(() => isSubmitting = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Create failed: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const AppLoadingIndicator.small()
                  : const Text('Create Shopper'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoppers Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showCreateShopperDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Create Shopper'),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left: Shoppers List
          SizedBox(
            width: 360,
            child: Column(
              children: [
                // Filters
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    spacing: 12,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) => _loadShoppers(),
                      ),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedKycStatus ?? 'All',
                        decoration: InputDecoration(
                          labelText: 'KYC Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _kycStatuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedKycStatus = value ?? 'All');
                          _loadShoppers();
                        },
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool?>(
                          segments: const [
                            ButtonSegment<bool?>(
                              value: true,
                              label: Text('Active'),
                              icon: Icon(Icons.check_circle_outline),
                            ),
                            ButtonSegment<bool?>(
                              value: false,
                              label: Text('Inactive'),
                              icon: Icon(Icons.cancel_outlined),
                            ),
                            ButtonSegment<bool?>(
                              value: null,
                              label: Text('All'),
                              icon: Icon(Icons.list_alt),
                            ),
                          ],
                          selected: {_selectedActiveStatus},
                          onSelectionChanged: (selection) {
                            final selected = selection.first;
                            setState(() => _selectedActiveStatus = selected);
                            _loadShoppers();
                          },
                          showSelectedIcon: false,
                        ),
                      ),
                    ],
                  ),
                ),
                // Shoppers list
                Expanded(
                  child: _isLoading
                      ? const AppLoadingPage()
                      : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $_error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadShoppers,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _shoppers.isEmpty
                      ? const Center(child: Text('No shoppers found'))
                      : ListView.builder(
                          itemCount: _shoppers.length,
                          itemBuilder: (context, index) {
                            final shopper = _shoppers[index];
                            final isSelected =
                                _selectedShopper?['id'] == shopper['id'];
                            final kycStatus = _rowKycStatus(shopper);

                            Color kycColor = AppColors.accent;
                            if (kycStatus == 'approved') {
                              kycColor = AppColors.primary;
                            } else if (kycStatus == 'rejected') {
                              kycColor = AppColors.error;
                            } else if (kycStatus == 'pending_review') {
                              kycColor = AppColors.info;
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              elevation: isSelected ? 4 : 1,
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : null,
                              child: ListTile(
                                onTap: () => _selectShopper(shopper),
                                leading: CircleAvatar(
                                  child: Text(
                                    (shopper['name'] as String?)?.isNotEmpty ==
                                            true
                                        ? shopper['name'][0].toUpperCase()
                                        : '?',
                                  ),
                                ),
                                title: Text(shopper['name'] ?? 'Unknown'),
                                subtitle: Text(shopper['phone'] ?? 'N/A'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Chip(
                                          label: Text(
                                            kycStatus
                                                .replaceAllMapped(
                                                  RegExp(r'_'),
                                                  (match) => ' ',
                                                )
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.textWhite,
                                              fontSize: 10,
                                            ),
                                          ),
                                          backgroundColor: kycColor,
                                        ),
                                        if (shopper['is_active'] == false)
                                          const Text(
                                            'INACTIVE',
                                            style: TextStyle(
                                              color: AppColors.error,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    IconButton(
                                      tooltip: 'Review KYC',
                                      icon: const Icon(
                                        Icons.fact_check_outlined,
                                      ),
                                      onPressed: () => _openKycReview(shopper),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Right: Shopper Details
          Expanded(
            child: _selectedShopper == null
                ? const Center(child: Text('Select a shopper to view details'))
                : _selectedShopperLoading
                ? const Center(child: AppLoadingIndicator.small())
                : _selectedShopperError != null &&
                      _selectedShopperDetails == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Failed to load profile details',
                          style: TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _selectShopper(_selectedShopper!),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _ShopperDetailsView(
                    shopper: _selectedShopperDetails ?? _selectedShopper!,
                    onApproveKyc: () => _approveKyc(_selectedShopperKycId()),
                    onRejectKyc: () => _showRejectKycDialog(
                      _selectedShopperDetails ?? _selectedShopper!,
                    ),
                    onRefresh: _loadShoppers,
                    onEdit: _showEditDialog,
                    onOpenKycReview: () => _openKycReview(
                      _selectedShopperDetails ?? _selectedShopper!,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ShopperDetailsView extends StatefulWidget {
  final Map<String, dynamic> shopper;
  final VoidCallback onApproveKyc;
  final VoidCallback onRejectKyc;
  final VoidCallback onRefresh;
  final Function(Map<String, dynamic>) onEdit;
  final VoidCallback onOpenKycReview;

  const _ShopperDetailsView({
    required this.shopper,
    required this.onApproveKyc,
    required this.onRejectKyc,
    required this.onRefresh,
    required this.onEdit,
    required this.onOpenKycReview,
  });

  @override
  State<_ShopperDetailsView> createState() => _ShopperDetailsViewState();
}

class _ShopperDetailsViewState extends State<_ShopperDetailsView> {
  int _activeTab = 0;
  bool _showEmptyFields = false;

  Map<String, dynamic> _shopperProfile(Map<String, dynamic> shopper) {
    final nested = shopper['shopper'];
    if (nested is Map<String, dynamic>) {
      if (nested['data'] is Map<String, dynamic>) {
        final data = nested['data'] as Map<String, dynamic>;
        final attrs = data['attributes'];
        if (attrs is Map<String, dynamic>) {
          return {...data, ...attrs};
        }
        return data;
      }
      final attrs = nested['attributes'];
      if (attrs is Map<String, dynamic>) {
        return {...nested, ...attrs};
      }
      return nested;
    }
    return const {};
  }

  dynamic _pickValue(Map<String, dynamic> shopper, String key) {
    final direct = shopper[key];
    if (direct != null && direct.toString().isNotEmpty) {
      return direct;
    }
    final profile = _shopperProfile(shopper);
    final nested = profile[key];
    if (nested != null && nested.toString().isNotEmpty) {
      return nested;
    }
    return null;
  }

  Color _getKycStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.primary;
      case 'rejected':
        return AppColors.error;
      case 'pending_review':
        return AppColors.info;
      default:
        return AppColors.accent;
    }
  }

  String _formatKycStatus(String status) {
    return status.replaceAllMapped(RegExp(r'_'), (match) => ' ').toUpperCase();
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    final text = value.toString();
    if (text.isEmpty) return 'N/A';
    if (text.contains('T')) return text.split('T').first;
    return text.split(' ').first;
  }

  String _formatRate(Map<String, dynamic> user) {
    final raw = _pickValue(user, 'rating');
    final rate = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '0') ?? 0;
    return '⭐ ${rate.toStringAsFixed(1)}/5.0';
  }

  String? _extractUrlFromValue(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && trimmed.startsWith('http')) return trimmed;
    }
    if (value is Map<String, dynamic>) {
      final direct = value['url'];
      if (direct is String && direct.isNotEmpty) return direct;
      final data = value['data'];
      if (data is Map<String, dynamic>) {
        final dataUrl = data['url'];
        if (dataUrl is String && dataUrl.isNotEmpty) return dataUrl;
        final attrs = data['attributes'];
        if (attrs is Map<String, dynamic>) {
          final attrUrl = attrs['url'];
          if (attrUrl is String && attrUrl.isNotEmpty) return attrUrl;
        }
      }
      final attrs = value['attributes'];
      if (attrs is Map<String, dynamic>) {
        final attrUrl = attrs['url'];
        if (attrUrl is String && attrUrl.isNotEmpty) return attrUrl;
      }
    }
    return null;
  }

  String? _resolveDocumentUrl(Map<String, dynamic> shopper, List<String> keys) {
    for (final key in keys) {
      final value = _pickValue(shopper, key);
      final url = _extractUrlFromValue(value);
      if (url != null) return url;
    }
    return null;
  }

  void _openImagePreview(String label, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: AppColors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      'Failed to load $label',
                      style: const TextStyle(color: AppColors.textWhite),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textWhite),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String label,
    required String? url,
    String? uploadedAt,
  }) {
    final missing = url == null || url.isEmpty;

    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: missing ? AppColors.warning : AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                missing ? 'Missing' : 'Uploaded',
                style: TextStyle(
                  color: missing ? AppColors.warning : AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!missing)
            Text(
              uploadedAt == null || uploadedAt.isEmpty
                  ? 'Upload date unavailable'
                  : 'Uploaded ${_formatDate(uploadedAt)}',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: missing ? null : () => _openImagePreview(label, url),
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: missing
                  ? Center(
                      child: Text(
                        'Not yet uploaded',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  'Unable to preview',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_in,
                                    size: 14,
                                    color: AppColors.textWhite,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Preview',
                                    style: TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDynamicValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is List) {
      if (value.isEmpty) return 'N/A';
      return value.map((e) => e.toString()).join(', ');
    }
    if (value is Map<String, dynamic>) {
      if (value.isEmpty) return 'N/A';
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? 'N/A' : text;
  }

  @override
  Widget build(BuildContext context) {
    final shopper = widget.shopper;
    final kycStatus =
        _pickValue(shopper, 'kyc_status')?.toString() ?? 'not_submitted';
    final accountActive = shopper['is_active'] == true;
    final canApprove = kycStatus == 'pending_review';
    final canReject =
        kycStatus == 'pending_review' || kycStatus == 'not_submitted';
    final idFrontUrl = _resolveDocumentUrl(shopper, [
      'id_front_url',
      'idFrontUrl',
      'id_photo_url',
      'id_photo',
    ]);
    final idBackUrl = _resolveDocumentUrl(shopper, [
      'id_back_url',
      'idBackUrl',
      'national_id_back_url',
      'id_back_photo_url',
    ]);
    final selfieUrl = _resolveDocumentUrl(shopper, [
      'selfie_url',
      'selfieUrl',
      'face_photo_url',
      'face_photo',
    ]);

    final kycContent = [
      _buildSection('KYC Documents', [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 190,
          ),
          itemCount: 3,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _buildDocumentCard(
                  label: 'ID Document',
                  url: idFrontUrl,
                  uploadedAt: _pickValue(
                    shopper,
                    'kyc_submitted_at',
                  )?.toString(),
                );
              case 1:
                return _buildDocumentCard(
                  label: 'ID Back',
                  url: idBackUrl,
                  uploadedAt: _pickValue(
                    shopper,
                    'kyc_submitted_at',
                  )?.toString(),
                );
              default:
                return _buildDocumentCard(
                  label: 'Face Photo',
                  url: selfieUrl,
                  uploadedAt: _pickValue(
                    shopper,
                    'kyc_submitted_at',
                  )?.toString(),
                );
            }
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onOpenKycReview,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Open Document Review'),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      _buildSection('KYC Information', [
        Row(
          children: [
            Text(
              'Show empty fields',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Switch(
              value: _showEmptyFields,
              onChanged: (value) => setState(() => _showEmptyFields = value),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSubHeader('Identity'),
        ...[
          _buildMaybeInfoRow('Status', _formatKycStatus(kycStatus)),
          _buildMaybeInfoRow(
            'Submitted Date',
            _formatDate(_pickValue(shopper, 'kyc_submitted_at')),
          ),
          _buildMaybeInfoRow(
            'Reviewed Date',
            _formatDate(_pickValue(shopper, 'kyc_reviewed_at')),
          ),
          _buildMaybeInfoRow('ID Number', _pickValue(shopper, 'id_number')),
          _buildMaybeInfoRow(
            'Date of Birth',
            _pickValue(shopper, 'date_of_birth'),
          ),
          _buildMaybeInfoRow('Gender', _pickValue(shopper, 'gender')),
          _buildMaybeInfoRow('ID Type', _pickValue(shopper, 'id_type')),
          _buildMaybeInfoRow(
            'ID Expiry Date',
            _pickValue(shopper, 'id_expiry_date'),
          ),
          _buildMaybeInfoRow(
            'Residential Address',
            _pickValue(shopper, 'residential_address'),
          ),
          _buildMaybeInfoRow(
            'District/Region',
            _pickValue(shopper, 'district') ?? _pickValue(shopper, 'region'),
          ),
        ].whereType<Widget>(),
        const SizedBox(height: 10),
        _buildSubHeader('Business'),
        ...[
          _buildMaybeInfoRow(
            'Business/Stall Name',
            _pickValue(shopper, 'business_name'),
          ),
          _buildMaybeInfoRow(
            'Market Location',
            _pickValue(shopper, 'market_location'),
          ),
          _buildMaybeInfoRow(
            'Business Category',
            _pickValue(shopper, 'business_category'),
          ),
          _buildMaybeInfoRow(
            'Years Operating',
            _pickValue(shopper, 'years_operating'),
          ),
          _buildMaybeInfoRow('TIN Number', _pickValue(shopper, 'tin_number')),
        ].whereType<Widget>(),
        const SizedBox(height: 10),
        _buildSubHeader('Payment'),
        ...[
          _buildMaybeInfoRow(
            'Mobile Money Provider',
            _pickValue(shopper, 'mobile_money_provider'),
          ),
          _buildMaybeInfoRow(
            'Mobile Money Number',
            _pickValue(shopper, 'mobile_money_number'),
          ),
          _buildMaybeInfoRow('Bank Name', _pickValue(shopper, 'bank_name')),
          _buildMaybeInfoRow(
            'Bank Account Name',
            _pickValue(shopper, 'bank_account_name'),
          ),
          _buildMaybeInfoRow(
            'Bank Account Number',
            _pickValue(shopper, 'bank_account_number'),
          ),
        ].whereType<Widget>(),
        const SizedBox(height: 10),
        _buildSubHeader('Emergency Contact'),
        ...[
          _buildMaybeInfoRow(
            'Emergency Contact Name',
            _pickValue(shopper, 'emergency_contact_name'),
          ),
          _buildMaybeInfoRow(
            'Emergency Contact Phone',
            _pickValue(shopper, 'emergency_contact_phone'),
          ),
        ].whereType<Widget>(),
        const SizedBox(height: 10),
        _buildSubHeader('Risk & Audit'),
        ...[
          _buildMaybeInfoRow(
            'KYC Resubmissions',
            _pickValue(shopper, 'kyc_resubmission_count'),
          ),
          _buildMaybeInfoRow(
            'Rejection Reason',
            _pickValue(shopper, 'kyc_rejection_reason'),
          ),
          _buildMaybeInfoRow(
            'Flagged Events',
            _pickValue(shopper, 'flagged_events_count'),
          ),
          _buildMaybeInfoRow(
            'Admin Notes',
            _pickValue(shopper, 'kyc_admin_notes'),
          ),
          _buildMaybeInfoRow(
            'Last Reviewed By',
            _pickValue(shopper, 'kyc_reviewed_by_name'),
          ),
        ].whereType<Widget>(),
      ]),
    ];

    return Container(
      color: AppColors.grey50,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primarySoft,
                            child: Text(
                              (shopper['name']?.toString().isNotEmpty == true)
                                  ? shopper['name'].toString()[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shopper['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                shopper['phone'] ?? 'N/A',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getKycStatusColor(kycStatus),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatKycStatus(kycStatus),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accountActive
                                  ? AppColors.cardGreen
                                  : AppColors.errorSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              accountActive
                                  ? 'ACCOUNT ACTIVE'
                                  : 'ACCOUNT INACTIVE',
                              style: TextStyle(
                                color: accountActive
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'suspend',
                                child: Text('Suspend account'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete account'),
                              ),
                              PopupMenuItem(
                                value: 'message',
                                child: Text('Message shopper'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _tabButton('Overview', 0)),
                      const SizedBox(width: 20),
                      Expanded(child: _tabButton('KYC', 1)),
                      const SizedBox(width: 20),
                      Expanded(child: _tabButton('Activity', 2)),
                      const SizedBox(width: 20),
                      Expanded(child: _tabButton('Orders', 3)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_activeTab == 0) ...[
                    _buildSection('Personal Information', [
                      _buildInfoRow('Email', _displayValue(shopper, 'email')),
                      _buildInfoRow('Phone', _displayValue(shopper, 'phone')),
                      _buildInfoRow('Name', _displayValue(shopper, 'name')),
                      _buildInfoRow(
                        'Registered',
                        _formatDate(_pickValue(shopper, 'createdAt')),
                      ),
                      _buildInfoRow(
                        'Online Status',
                        _pickValue(shopper, 'is_online') == true
                            ? 'Online'
                            : 'Offline',
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildSection('Performance', [
                      _buildInfoRow('Rate', _formatRate(shopper)),
                      _buildInfoRow(
                        'Total Ratings',
                        (_pickValue(shopper, 'total_ratings') ?? 0).toString(),
                      ),
                      _buildInfoRow(
                        'Cancellation Rate',
                        _formatDynamicValue(
                          _pickValue(shopper, 'cancellation_rate'),
                        ),
                      ),
                      _buildInfoRow(
                        'Last Login',
                        _formatDate(_pickValue(shopper, 'last_login_at')),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onEdit(shopper),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                  if (_activeTab == 1) ...kycContent,
                  if (_activeTab == 2)
                    _buildSection('Activity', [
                      _buildTimelineItem(
                        'Orders completed: ${_pickValue(shopper, 'total_orders_completed') ?? 0}',
                        Icons.shopping_bag,
                      ),
                      _buildTimelineItem(
                        'Support tickets: ${_pickValue(shopper, 'support_tickets_count') ?? 0}',
                        Icons.support_agent,
                      ),
                      _buildTimelineItem(
                        'Flags: ${_pickValue(shopper, 'flagged_events_count') ?? 0}',
                        Icons.flag,
                      ),
                      _buildTimelineItem(
                        'Referral count: ${_pickValue(shopper, 'referral_count') ?? 0}',
                        Icons.group_add,
                      ),
                    ]),
                  if (_activeTab == 3)
                    _buildSection('Orders', [
                      _buildInfoRow(
                        'Total Orders Fulfilled',
                        (_pickValue(shopper, 'total_orders_completed') ?? 0)
                            .toString(),
                      ),
                      _buildInfoRow(
                        'Total GMV',
                        CurrencyFormatter.format(
                          _pickValue(shopper, 'total_gmv') ?? 0,
                        ),
                      ),
                      _buildInfoRow(
                        'Average Order Value',
                        CurrencyFormatter.format(
                          _pickValue(shopper, 'avg_order_value') ?? 0,
                        ),
                      ),
                      _buildInfoRow(
                        'Total Earnings',
                        CurrencyFormatter.format(
                          _pickValue(shopper, 'total_earnings') ?? 0,
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
          if (_activeTab == 1 && (canApprove || canReject))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.grey200)),
              ),
              child: Row(
                children: [
                  if (canApprove)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onApproveKyc,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve KYC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textWhite,
                        ),
                      ),
                    ),
                  if (canApprove && canReject) const SizedBox(width: 10),
                  if (canReject)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onRejectKyc,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reject KYC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.textWhite,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : AppColors.grey300,
              width: selected ? 2.5 : 1,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _displayValue(Map<String, dynamic> shopper, String key) {
    final value = _pickValue(shopper, key);
    if (value == null) return 'N/A';
    final text = value.toString().trim();
    return text.isEmpty ? 'N/A' : text;
  }

  Widget? _buildMaybeInfoRow(String label, dynamic value) {
    final text = _formatDynamicValue(value);
    if (!_showEmptyFields && text == 'N/A') return null;
    return _buildInfoRow(label, text);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
