import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/shopper_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class AdminShoppersDesktopScreen extends StatefulWidget {
  const AdminShoppersDesktopScreen({super.key});

  @override
  State<AdminShoppersDesktopScreen> createState() =>
      _AdminShoppersDesktopScreenState();
}

class _AdminShoppersDesktopScreenState extends State<AdminShoppersDesktopScreen> {
  late List<Map<String, dynamic>> _shoppers = [];
  Map<String, dynamic>? _selectedShopper;
  bool _isLoading = true;
  String? _error;
  String? _selectedKycStatus;
  bool? _selectedActiveStatus;
  final _searchController = TextEditingController();

  final List<String> _kycStatuses = [
    'All',
    'not_submitted',
    'pending_review',
    'approved',
    'rejected',
  ];

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
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
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
                          shopper['id'],
                          token: token,
                          reason: reasonController.text,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('KYC rejected successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadShoppers();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
            backgroundColor: Colors.green,
          ),
        );
        _loadShoppers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoppers Management'),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left: Shoppers List
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
                          hintText: 'Search by name or phone...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
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
                              horizontal: 12, vertical: 8),
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
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(
                                    () => _selectedActiveStatus = true);
                                _loadShoppers();
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Active'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedActiveStatus == true
                                    ? AppColors.primary
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(
                                    () => _selectedActiveStatus = false);
                                _loadShoppers();
                              },
                              icon: const Icon(Icons.cancel),
                              label: const Text('Inactive'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedActiveStatus == false
                                    ? Colors.red
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(
                                    () => _selectedActiveStatus = null);
                                _loadShoppers();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedActiveStatus == null
                                    ? AppColors.primary
                                    : Colors.grey[300],
                              ),
                              child: const Text('All'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Shoppers list
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
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
                              ? const Center(
                                  child: Text('No shoppers found'))
                              : ListView.builder(
                                  itemCount: _shoppers.length,
                                  itemBuilder: (context, index) {
                                    final shopper = _shoppers[index];
                                    final isSelected =
                                        _selectedShopper?['id'] == shopper['id'];
                                    final kycStatus = shopper['kyc_status'] ??
                                        'not_submitted';

                                    Color kycColor = Colors.orange;
                                    if (kycStatus == 'approved') {
                                      kycColor = Colors.green;
                                    } else if (kycStatus == 'rejected') {
                                      kycColor = Colors.red;
                                    } else if (kycStatus ==
                                        'pending_review') {
                                      kycColor = Colors.blue;
                                    }

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      elevation: isSelected ? 4 : 1,
                                      color: isSelected
                                          ? AppColors.primary
                                              .withValues(alpha: 0.1)
                                          : null,
                                      child: ListTile(
                                        onTap: () {
                                          setState(() =>
                                              _selectedShopper =
                                                  shopper);
                                        },
                                        leading: CircleAvatar(
                                          child: Text(
                                            (shopper['name'] as String?)
                                                    ?.isNotEmpty ==
                                                true
                                                ? shopper['name'][0]
                                                    .toUpperCase()
                                                : '?',
                                          ),
                                        ),
                                        title: Text(shopper['name'] ?? 'Unknown'),
                                        subtitle: Text(
                                          shopper['phone'] ?? 'N/A',
                                        ),
                                        trailing: Column(
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
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              backgroundColor: kycColor,
                                            ),
                                            if (shopper['is_active'] ==
                                                false)
                                              const Text(
                                                'INACTIVE',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
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
            flex: 1,
            child: _selectedShopper == null
                ? const Center(
                    child: Text('Select a shopper to view details'))
                : _ShopperDetailsView(
                    shopper: _selectedShopper!,
                    onApproveKyc: () =>
                        _approveKyc(_selectedShopper!['id']),
                    onRejectKyc: () =>
                        _showRejectKycDialog(_selectedShopper!),
                    onRefresh: _loadShoppers,
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

class _ShopperDetailsView extends StatelessWidget {
  final Map<String, dynamic> shopper;
  final VoidCallback onApproveKyc;
  final VoidCallback onRejectKyc;
  final VoidCallback onRefresh;

  const _ShopperDetailsView({
    required this.shopper,
    required this.onApproveKyc,
    required this.onRejectKyc,
    required this.onRefresh,
  });

  Color _getKycStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending_review':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _formatKycStatus(String status) {
    return status
        .replaceAllMapped(RegExp(r'_'), (match) => ' ')
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final kycStatus = shopper['kyc_status'] ?? 'not_submitted';
    final canApprove = kycStatus == 'pending_review';
    final canReject = kycStatus == 'pending_review' || kycStatus == 'not_submitted';

    return Container(
      color: Colors.grey[50],
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
                      shopper['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      shopper['phone'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getKycStatusColor(kycStatus),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatKycStatus(kycStatus),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Personal Info
            _buildSection(
              'Personal Information',
              [
                _buildInfoRow('Email', shopper['email'] ?? 'N/A'),
                _buildInfoRow('Phone', shopper['phone'] ?? 'N/A'),
                _buildInfoRow('Name', shopper['name'] ?? 'N/A'),
                _buildInfoRow(
                  'Status',
                  shopper['is_active'] == true
                      ? '✅ Active'
                      : '❌ Inactive',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KYC Status
            _buildSection(
              'KYC Information',
              [
                _buildInfoRow(
                  'Status',
                  _formatKycStatus(kycStatus),
                ),
                if (shopper['kyc_rejection_reason'] != null)
                  _buildInfoRow(
                    'Rejection Reason',
                    shopper['kyc_rejection_reason'],
                  ),
                if (shopper['kyc_submitted_at'] != null)
                  _buildInfoRow(
                    'Submitted Date',
                    shopper['kyc_submitted_at']
                        .toString()
                        .split(' ')[0],
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Performance Stats
            _buildSection(
              'Performance',
              [
                _buildInfoRow(
                  'Rating',
                  '⭐ ${(shopper['rating'] ?? 0).toStringAsFixed(1)}/5.0',
                ),
                _buildInfoRow(
                  'Total Ratings',
                  (shopper['total_ratings'] ?? 0).toString(),
                ),
                _buildInfoRow(
                  'Orders Completed',
                  (shopper['total_orders_completed'] ?? 0).toString(),
                ),
                _buildInfoRow(
                  'Total Earnings',
                  CurrencyFormatter.format(shopper['total_earnings'] ?? 0),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KYC Actions
            if (canApprove || canReject)
              _buildSection(
                'KYC Actions',
                [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      spacing: 8,
                      children: [
                        if (canApprove)
                          ElevatedButton.icon(
                            onPressed: onApproveKyc,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Approve KYC'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (canReject)
                          ElevatedButton.icon(
                            onPressed: onRejectKyc,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Reject KYC'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
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
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
