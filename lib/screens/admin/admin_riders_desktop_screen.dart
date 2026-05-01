import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_user_service.dart';
import '../../services/rider_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/app_loading_indicator.dart';
import 'admin_kyc_review_screen.dart';

class AdminRidersDesktopScreen extends StatefulWidget {
  const AdminRidersDesktopScreen({super.key});

  @override
  State<AdminRidersDesktopScreen> createState() =>
      _AdminRidersDesktopScreenState();
}

class _AdminRidersDesktopScreenState extends State<AdminRidersDesktopScreen> {
  late List<Map<String, dynamic>> _riders = [];
  Map<String, dynamic>? _selectedRider;
  Map<String, dynamic>? _selectedRiderDetails;
  bool _selectedRiderLoading = false;
  String? _selectedRiderError;
  bool _isLoading = true;
  String? _error;
  bool? _verificationFilter;
  bool? _onlineFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  Future<void> _openKycReview(Map<String, dynamic> rider) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminKycReviewScreen(role: KycRole.rider, applicant: rider),
      ),
    );
    if (result == true) {
      _loadRiders();
    }
  }

  String? _extractRiderProfileId(Map<String, dynamic> rider) {
    final nested = rider['rider'];
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
    final direct = rider['rider_document_id']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    return null;
  }

  Future<void> _selectRider(Map<String, dynamic> rider) async {
    setState(() {
      _selectedRider = rider;
      _selectedRiderLoading = true;
      _selectedRiderError = null;
      _selectedRiderDetails = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('No auth token');
      final profileId = _extractRiderProfileId(rider);
      Map<String, dynamic>? details;

      if (profileId != null) {
        try {
          details = await RiderService.getRiderProfileById(
            profileId,
            token: token,
          );
        } catch (_) {
          details = null;
        }
      }

      details ??= await RiderService.getRiderProfileByUser(
        token: token,
        userDocumentId: rider['documentId']?.toString(),
        userId: rider['id'],
      );

      if (details == null || details.isEmpty) {
        throw Exception('Rider profile not found');
      }

      if (!mounted) return;
      setState(() {
        _selectedRiderDetails = {...rider, ...details!, 'rider': details};
        _selectedRiderLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedRiderLoading = false;
        _selectedRiderError = e.toString();
        _selectedRiderDetails = rider;
      });
    }
  }

  String _selectedRiderKycId() {
    final details = _selectedRiderDetails;
    final nested = details?['rider'];
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
    final selectedDocId = _selectedRider?['documentId']?.toString();
    if (selectedDocId != null && selectedDocId.isNotEmpty) return selectedDocId;
    return '';
  }

  Future<void> _loadRiders() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No auth token');
      }

      // Fetch riders from RiderService
      final riders = await RiderService.getRiders(
        token: token,
        isVerified: _verificationFilter,
        isActive: _onlineFilter,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
      );

      if (mounted) {
        setState(() {
          _riders = riders;
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

  List<Map<String, dynamic>> _getFilteredRiders() {
    var filtered = _riders;

    // Filter by verification
    if (_verificationFilter != null) {
      filtered = filtered
          .where((rider) => rider['is_verified'] == _verificationFilter)
          .toList();
    }

    // Filter by online status
    if (_onlineFilter != null) {
      filtered = filtered
          .where((rider) => rider['is_online'] == _onlineFilter)
          .toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((rider) {
        final searchLower = _searchController.text.toLowerCase();
        return (rider['name']?.toString().toLowerCase().contains(searchLower) ??
                false) ||
            (rider['phone']?.toString().toLowerCase().contains(searchLower) ??
                false);
      }).toList();
    }

    return filtered;
  }

  Future<void> _verifyRider(String riderId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) throw Exception('No auth token');

      await RiderService.verifyRider(riderId, token: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider verified successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadRiders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _unverifyRider(String riderId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) throw Exception('No auth token');

      await RiderService.unverifyRider(riderId, token: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider unverified'),
            backgroundColor: AppColors.accent,
          ),
        );
        _loadRiders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> rider) {
    final nameController = TextEditingController(text: rider['name'] ?? '');
    final phoneController = TextEditingController(text: rider['phone'] ?? '');
    final emailController = TextEditingController(text: rider['email'] ?? '');
    final vehicleTypeController = TextEditingController(
      text: rider['vehicle_type'] ?? '',
    );
    final vehiclePlateController = TextEditingController(
      text: rider['vehicle_plate'] ?? '',
    );
    final licenseNumberController = TextEditingController(
      text: rider['license_number'] ?? '',
    );
    final authProvider = context.read<AuthProvider>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Rider Profile'),
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
                  controller: vehicleTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type (e.g., Motorcycle, Car)',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: vehiclePlateController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Plate Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: licenseNumberController,
                  decoration: const InputDecoration(
                    labelText: 'License Number',
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

                        final riderId = rider['id'] ?? rider['documentId'];
                        if (riderId == null)
                          throw Exception('Rider ID not found');

                        final updateData = {
                          'name': nameController.text,
                          'phone': phoneController.text,
                          'email': emailController.text,
                          'vehicle_type': vehicleTypeController.text,
                          'vehicle_plate': vehiclePlateController.text,
                          'license_number': licenseNumberController.text,
                        };

                        await RiderService.updateRider(
                          riderId,
                          updateData,
                          token: token,
                        );

                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Rider profile updated successfully',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadRiders();
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

  void _showCreateRiderDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Rider Account'),
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
                          userType: 'rider',
                          token: token,
                        );

                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Rider account created successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadRiders();
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
                  : const Text('Create Rider'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRiders = _getFilteredRiders();

    return Scaffold(
      appBar: AppBar(title: const Text('Riders Management'), elevation: 0),
      body: Row(
        children: [
          // Left: Riders List
          Expanded(
            flex: 1,
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
                          hintText: 'Search rider name or phone...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: FilterChip(
                              label: const Text('Verified'),
                              selected: _verificationFilter == true,
                              onSelected: (selected) {
                                setState(
                                  () => _verificationFilter = selected
                                      ? true
                                      : null,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: FilterChip(
                              label: const Text('Unverified'),
                              selected: _verificationFilter == false,
                              onSelected: (selected) {
                                setState(
                                  () => _verificationFilter = selected
                                      ? false
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: FilterChip(
                              label: const Text('Online'),
                              selected: _onlineFilter == true,
                              onSelected: (selected) {
                                setState(
                                  () => _onlineFilter = selected ? true : null,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: FilterChip(
                              label: const Text('Offline'),
                              selected: _onlineFilter == false,
                              onSelected: (selected) {
                                setState(
                                  () => _onlineFilter = selected ? false : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _loadRiders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showCreateRiderDialog,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Create Rider'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Riders list
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
                                onPressed: _loadRiders,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredRiders.isEmpty
                      ? const Center(child: Text('No riders found'))
                      : ListView.builder(
                          itemCount: filteredRiders.length,
                          itemBuilder: (context, index) {
                            final rider = filteredRiders[index];
                            final isSelected =
                                _selectedRider?['id'] == rider['id'];

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
                                leading: CircleAvatar(
                                  backgroundColor: (rider['is_online'] ?? false)
                                      ? AppColors.success
                                      : AppColors.grey400,
                                  child: Text(
                                    (rider['name'] as String?)?.isNotEmpty ??
                                            false
                                        ? rider['name'][0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                ),
                                onTap: () => _selectRider(rider),
                                title: Text(
                                  rider['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(rider['phone'] ?? 'N/A'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(
                                        rider['is_verified'] ?? false
                                            ? 'Verified'
                                            : 'Unverified',
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontSize: 11,
                                        ),
                                      ),
                                      backgroundColor:
                                          (rider['is_verified'] ?? false)
                                          ? AppColors.success
                                          : AppColors.accent,
                                    ),
                                    IconButton(
                                      tooltip: 'Review KYC',
                                      icon: const Icon(
                                        Icons.fact_check_outlined,
                                      ),
                                      onPressed: () => _openKycReview(rider),
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
          // Right: Rider Details
          Expanded(
            flex: 1,
            child: _selectedRider == null
                ? const Center(child: Text('Select a rider to view details'))
                : _selectedRiderLoading
                ? const Center(child: AppLoadingIndicator.small())
                : _selectedRiderError != null && _selectedRiderDetails == null
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
                          onPressed: () => _selectRider(_selectedRider!),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _RiderDetailsView(
                    rider: _selectedRiderDetails ?? _selectedRider!,
                    onVerify: (_) => _verifyRider(_selectedRiderKycId()),
                    onUnverify: (_) => _unverifyRider(_selectedRiderKycId()),
                    onEdit: _showEditDialog,
                    onOpenKycReview: () => _openKycReview(
                      _selectedRiderDetails ?? _selectedRider!,
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

class _RiderDetailsView extends StatefulWidget {
  final Map<String, dynamic> rider;
  final Function(String) onVerify;
  final Function(String) onUnverify;
  final Function(Map<String, dynamic>) onEdit;
  final VoidCallback onOpenKycReview;

  const _RiderDetailsView({
    required this.rider,
    required this.onVerify,
    required this.onUnverify,
    required this.onEdit,
    required this.onOpenKycReview,
  });

  @override
  State<_RiderDetailsView> createState() => _RiderDetailsViewState();
}

class _RiderDetailsViewState extends State<_RiderDetailsView> {
  int _activeTab = 0;

  Map<String, dynamic> _riderProfile(Map<String, dynamic> rider) {
    final nested = rider['rider'];
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

  dynamic _pickValue(Map<String, dynamic> rider, String key) {
    final direct = rider[key];
    if (direct != null && direct.toString().isNotEmpty) {
      return direct;
    }
    final profile = _riderProfile(rider);
    final nested = profile[key];
    if (nested != null && nested.toString().isNotEmpty) {
      return nested;
    }
    return null;
  }

  String _formatTrainingStatus(Map<String, dynamic> rider) {
    final completedAt = _pickValue(rider, 'training_completed_at');
    if (completedAt == null || completedAt.toString().isEmpty) {
      return 'Not completed';
    }
    return 'Completed';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    final text = value.toString();
    if (text.isEmpty) return 'N/A';
    if (text.contains('T')) return text.split('T').first;
    return text.split(' ').first;
  }

  String _formatRate(Map<String, dynamic> rider) {
    final raw = _pickValue(rider, 'rating');
    final rate = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '0') ?? 0;
    return '⭐ ${rate.toStringAsFixed(1)}/5.0';
  }

  @override
  Widget build(BuildContext context) {
    final rider = widget.rider;
    return Container(
      color: AppColors.grey50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      rider['phone'] ?? 'N/A',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (rider['is_verified'] ?? false)
                        ? AppColors.success
                        : AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (rider['is_verified'] ?? false) ? 'Verified' : 'Unverified',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _tabButton('Overview', 0)),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('KYC', 1)),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('Activity', 2)),
              ],
            ),
            const SizedBox(height: 16),

            if (_activeTab == 0) ...[
              _buildSection('Personal Information', [
                _buildInfoRow('Name', rider['name'] ?? 'N/A'),
                _buildInfoRow('Phone', rider['phone'] ?? 'N/A'),
                _buildInfoRow('Email', rider['email'] ?? 'N/A'),
                _buildInfoRow('Registered', _formatDate(rider['createdAt'])),
                _buildInfoRow(
                  'Status',
                  (rider['is_online'] ?? false) ? 'Online' : 'Offline',
                ),
              ]),
              const SizedBox(height: 16),
              _buildSection('Vehicle Information', [
                _buildInfoRow('Type', rider['vehicle_type'] ?? 'N/A'),
                _buildInfoRow('Plate', rider['vehicle_plate'] ?? 'N/A'),
                _buildInfoRow('License', rider['license_number'] ?? 'N/A'),
              ]),
              const SizedBox(height: 16),
              _buildSection('Performance', [
                _buildInfoRow('Rate', _formatRate(rider)),
                _buildInfoRow(
                  'Total Ratings',
                  '${_pickValue(rider, 'total_ratings') ?? 0}',
                ),
                _buildInfoRow(
                  'Orders Made',
                  '${_pickValue(rider, 'total_deliveries_completed') ?? 0}',
                ),
                _buildInfoRow(
                  'Total Earnings',
                  CurrencyFormatter.format(
                    _pickValue(rider, 'total_earnings') ?? 0,
                  ),
                ),
                _buildInfoRow('Training Result', _formatTrainingStatus(rider)),
                _buildInfoRow(
                  'Training Completed On',
                  _formatDate(_pickValue(rider, 'training_completed_at')),
                ),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onEdit(rider),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => (rider['is_verified'] ?? false)
                            ? widget.onUnverify(rider['documentId'] ?? '')
                            : widget.onVerify(rider['documentId'] ?? ''),
                        icon: Icon(
                          (rider['is_verified'] ?? false)
                              ? Icons.block
                              : Icons.verified,
                        ),
                        label: Text(
                          (rider['is_verified'] ?? false)
                              ? 'Unverify'
                              : 'Verify',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (rider['is_verified'] ?? false)
                              ? AppColors.accent
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_activeTab == 1)
              _buildSection('KYC Information', [
                _buildInfoRow(
                  'Status',
                  (rider['is_verified'] ?? false) ? 'Verified' : 'Unverified',
                ),
                _buildInfoRow(
                  'KYC Submitted',
                  _formatDate(_pickValue(rider, 'kyc_submitted_at')),
                ),
                _buildInfoRow(
                  'KYC Reviewed',
                  _formatDate(_pickValue(rider, 'kyc_reviewed_at')),
                ),
                _buildInfoRow('Training Result', _formatTrainingStatus(rider)),
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

            if (_activeTab == 2)
              _buildSection('Activity Timeline', [
                _buildTimelineItem(
                  'Deliveries completed: ${_pickValue(rider, 'total_deliveries_completed') ?? 0}',
                  Icons.local_shipping,
                ),
                _buildTimelineItem(
                  'Rating events: ${_pickValue(rider, 'total_ratings') ?? 0}',
                  Icons.star,
                ),
                _buildTimelineItem(
                  'Training status: ${_formatTrainingStatus(rider)}',
                  Icons.school,
                ),
                _buildTimelineItem(
                  'Last login: ${_formatDate(_pickValue(rider, 'last_login_at'))}',
                  Icons.login,
                ),
                _buildTimelineItem(
                  'Support tickets: ${_pickValue(rider, 'support_tickets_count') ?? 0}',
                  Icons.support_agent,
                ),
                _buildTimelineItem(
                  'Flags: ${_pickValue(rider, 'flagged_events_count') ?? 0}',
                  Icons.flag,
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _activeTab == index;
    return OutlinedButton(
      onPressed: () => setState(() => _activeTab = index),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.primarySoft : AppColors.surface,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.grey300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
