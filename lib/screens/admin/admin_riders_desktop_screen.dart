import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/rider_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class AdminRidersDesktopScreen extends StatefulWidget {
  const AdminRidersDesktopScreen({super.key});

  @override
  State<AdminRidersDesktopScreen> createState() =>
      _AdminRidersDesktopScreenState();
}

class _AdminRidersDesktopScreenState extends State<AdminRidersDesktopScreen> {
  late List<Map<String, dynamic>> _riders = [];
  Map<String, dynamic>? _selectedRider;
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
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
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
        return (rider['name']?.toString().toLowerCase().contains(searchLower) ?? false) ||
            (rider['phone']?.toString().toLowerCase().contains(searchLower) ?? false);
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
            backgroundColor: Colors.green,
          ),
        );
        _loadRiders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
            backgroundColor: Colors.orange,
          ),
        );
        _loadRiders();
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
    final filteredRiders = _getFilteredRiders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riders Management'),
        elevation: 0,
      ),
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
                              horizontal: 12, vertical: 8),
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
                                setState(() =>
                                    _verificationFilter = selected ? true : null);
                              },
                            ),
                          ),
                          Expanded(
                            child: FilterChip(
                              label: const Text('Unverified'),
                              selected: _verificationFilter == false,
                              onSelected: (selected) {
                                setState(() =>
                                    _verificationFilter = selected ? false : null);
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
                                    () => _onlineFilter = selected ? true : null);
                              },
                            ),
                          ),
                          Expanded(
                            child: FilterChip(
                              label: const Text('Offline'),
                              selected: _onlineFilter == false,
                              onSelected: (selected) {
                                setState(() =>
                                    _onlineFilter = selected ? false : null);
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
                    ],
                  ),
                ),
                // Riders list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
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
                                    final isSelected = _selectedRider?['id'] == rider['id'];

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      elevation: isSelected ? 4 : 1,
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.1)
                                          : null,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: rider['is_online']
                                              ? Colors.green
                                              : Colors.grey,
                                          child: Text(
                                            (rider['name'] as String?)
                                                    ?.isNotEmpty ??
                                                false
                                                ? rider['name'][0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          setState(() => _selectedRider = rider);
                                        },
                                        title: Text(
                                          rider['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          rider['phone'] ?? 'N/A',
                                        ),
                                        trailing: Chip(
                                          label: Text(
                                            rider['is_verified'] ?? false
                                                ? 'Verified'
                                                : 'Unverified',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                          backgroundColor:
                                              (rider['is_verified'] ?? false)
                                                  ? Colors.green
                                                  : Colors.orange,
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
                : _RiderDetailsView(
                    rider: _selectedRider!,
                    onVerify: _verifyRider,
                    onUnverify: _unverifyRider,
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

class _RiderDetailsView extends StatelessWidget {
  final Map<String, dynamic> rider;
  final Function(String) onVerify;
  final Function(String) onUnverify;

  const _RiderDetailsView({
    required this.rider,
    required this.onVerify,
    required this.onUnverify,
  });

  @override
  Widget build(BuildContext context) {
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
                      rider['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      rider['phone'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        (rider['is_verified'] ?? false) ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (rider['is_verified'] ?? false) ? 'Verified' : 'Unverified',
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
                _buildInfoRow('Name', rider['name'] ?? 'N/A'),
                _buildInfoRow('Phone', rider['phone'] ?? 'N/A'),
                _buildInfoRow('Email', rider['email'] ?? 'N/A'),
                _buildInfoRow(
                  'Status',
                  (rider['is_online'] ?? false) ? 'Online' : 'Offline',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vehicle Details
            _buildSection(
              'Vehicle Information',
              [
                _buildInfoRow('Type', rider['vehicle_type'] ?? 'N/A'),
                _buildInfoRow('Plate', rider['vehicle_plate'] ?? 'N/A'),
                _buildInfoRow('License', rider['license_number'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 24),

            // Performance Stats
            _buildSection(
              'Performance',
              [
                _buildInfoRow(
                  'Rating',
                  '${rider['rating']?.toStringAsFixed(1) ?? "0"} ⭐',
                ),
                _buildInfoRow(
                  'Total Ratings',
                  '${rider['total_ratings'] ?? 0}',
                ),
                _buildInfoRow(
                  'Deliveries Completed',
                  '${rider['total_deliveries_completed'] ?? 0}',
                ),
                _buildInfoRow(
                  'Total Earnings',
                  CurrencyFormatter.format(rider['total_earnings'] ?? 0),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => (rider['is_verified'] ?? false)
                        ? onUnverify(rider['id'] ?? '')
                        : onVerify(rider['id'] ?? ''),
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
                          ? Colors.orange
                          : Colors.green,
                    ),
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
