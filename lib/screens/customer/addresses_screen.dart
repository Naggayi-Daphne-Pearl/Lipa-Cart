import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../models/address.dart';
import '../../models/user.dart' as user_models;

class AddressesScreen extends StatefulWidget {
  final String? returnRoute;

  const AddressesScreen({super.key, this.returnRoute});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final authProvider = context.read<AuthProvider>();
    final addressService = context.read<AddressService>();

    final customerId = authProvider.user?.customerId;
    if (authProvider.user != null &&
        authProvider.token != null &&
        customerId != null) {
      final success = await addressService.fetchAddresses(
        authProvider.token!,
        customerId,
      );
      if (success) {
        await authProvider.setAddresses(addressService.userAddresses);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        backgroundColor: Colors.green,
      ),
      body: Consumer2<AuthProvider, AddressService>(
        builder: (context, auth, addressService, _) {
          if (addressService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              // Existing addresses
              if (addressService.addresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No addresses yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your first delivery address to get started',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: addressService.addresses.length,
                    itemBuilder: (context, index) {
                      final address = addressService.addresses[index];
                      return AddressCard(
                        address: address,
                        isDefault:
                            addressService.defaultAddress?.id == address.id,
                        onEdit: () => _showAddressForm(
                          context,
                          auth,
                          addressService,
                          address,
                        ),
                        onDelete: () => _deleteAddress(
                          context,
                          auth,
                          addressService,
                          address.id,
                        ),
                        onSetDefault: () => _setDefault(
                          context,
                          auth,
                          addressService,
                          address.id,
                        ),
                      );
                    },
                  ),
                ),

              // Add new address button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showAddressForm(context, auth, addressService, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Address'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddressForm(
    BuildContext context,
    AuthProvider auth,
    AddressService addressService,
    Address? address,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddressForm(
        address: address,
        userId: auth.user?.customerId ?? '',
        token: auth.token ?? '',
        onSave:
            (
              label,
              addressLine,
              city,
              landmark,
              instructions,
              isDefault,
            ) async {
              if (address == null) {
                await addressService.createAddress(
                  token: auth.token!,
                  customerId: auth.user!.customerId ?? '',
                  label: label,
                  addressLine: addressLine,
                  city: city,
                  landmark: landmark,
                  deliveryInstructions: instructions,
                  isDefault: isDefault,
                );
              } else {
                await addressService.updateAddress(
                  token: auth.token!,
                  addressId: address.id,
                  label: label,
                  addressLine: addressLine,
                  city: city,
                  landmark: landmark,
                  deliveryInstructions: instructions,
                  isDefault: isDefault,
                );
              }
              await auth.setAddresses(addressService.userAddresses);
              if (context.mounted) {
                Navigator.pop(context);
                if (address == null && widget.returnRoute != null) {
                  context.go(widget.returnRoute!);
                }
              }
            },
      ),
    );
  }

  Future<void> _deleteAddress(
    BuildContext context,
    AuthProvider auth,
    AddressService addressService,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text('This action cannot be undone'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await addressService.deleteAddress(auth.token!, id);
      await auth.setAddresses(addressService.userAddresses);
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    AuthProvider auth,
    AddressService addressService,
    int id,
  ) async {
    await addressService.setDefaultAddress(auth.token!, id);
    await auth.setAddresses(addressService.userAddresses);
  }
}

class AddressCard extends StatelessWidget {
  final Address address;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const AddressCard({
    super.key,
    required this.address,
    required this.isDefault,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  address.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.fullAddress,
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (address.deliveryInstructions != null) ...[
              const SizedBox(height: 8),
              Text(
                '📝 ${address.deliveryInstructions}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                if (!isDefault)
                  TextButton(
                    onPressed: onSetDefault,
                    child: const Text(
                      'Set as Default',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddressForm extends StatefulWidget {
  final Address? address;
  final String userId;
  final String token;
  final Function(
    String label,
    String addressLine,
    String city,
    String? landmark,
    String? instructions,
    bool isDefault,
  )
  onSave;

  const AddressForm({
    super.key,
    this.address,
    required this.userId,
    required this.token,
    required this.onSave,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late TextEditingController labelController;
  late TextEditingController addressLineController;
  late TextEditingController cityController;
  late TextEditingController landmarkController;
  late TextEditingController instructionsController;
  bool isDefault = false;

  @override
  void initState() {
    super.initState();
    labelController = TextEditingController(text: widget.address?.label ?? '');
    addressLineController = TextEditingController(
      text: widget.address?.addressLine ?? '',
    );
    cityController = TextEditingController(text: widget.address?.city ?? '');
    landmarkController = TextEditingController(
      text: widget.address?.landmark ?? '',
    );
    instructionsController = TextEditingController(
      text: widget.address?.deliveryInstructions ?? '',
    );
    isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    labelController.dispose();
    addressLineController.dispose();
    cityController.dispose();
    landmarkController.dispose();
    instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.address == null ? 'Add Address' : 'Edit Address',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: 'Label',
                hintText: 'e.g., Home, Office',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressLineController,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cityController,
              decoration: InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: landmarkController,
              decoration: InputDecoration(
                labelText: 'Landmark (optional)',
                hintText: 'e.g., Near market, Next to park',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: instructionsController,
              decoration: InputDecoration(
                labelText: 'Delivery Instructions (optional)',
                hintText: 'e.g., Ring the bell twice',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: isDefault,
              onChanged: (v) => setState(() => isDefault = v ?? false),
              title: const Text('Set as default address'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(
                    labelController.text,
                    addressLineController.text,
                    cityController.text,
                    landmarkController.text.isEmpty
                        ? null
                        : landmarkController.text,
                    instructionsController.text.isEmpty
                        ? null
                        : instructionsController.text,
                    isDefault,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  widget.address == null ? 'Add Address' : 'Update Address',
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
