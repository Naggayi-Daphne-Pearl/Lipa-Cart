import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/address_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthService>();
    final addressService = context.read<AddressService>();

    // Load user's addresses
    if (auth.user != null && auth.token != null) {
      await addressService.fetchAddresses(auth.token!, auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lipa Cart'),
        elevation: 0,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<AuthService>(
                    builder: (context, auth, _) => Text(
                      'Welcome, ${auth.user?.name ?? 'Customer'}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Fresh groceries delivered to your door'),
                ],
              ),
            ),

            // Delivery address card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<AddressService>(
                builder: (context, addressService, _) {
                  final defaultAddress = addressService.defaultAddress;
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      title: const Text('Deliver to'),
                      subtitle: defaultAddress != null && defaultAddress.id != 0
                          ? Text(defaultAddress.fullAddress)
                          : const Text('Add delivery address'),
                      onTap: () => context.go('/customer/addresses'),
                    ),
                  );
                },
              ),
            ),

            // Categories section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shop by Category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/customer/categories'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            // Category grid (TODO: implement with ProductProvider)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final categories = ['Fruits', 'Vegetables', 'Dairy', 'Meat'];
                  return GestureDetector(
                    onTap: () => context.go('/customer/categories'),
                    child: Card(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              size: 40,
                              color: Colors.green,
                            ),
                            SizedBox(height: 8),
                            Text(
                              categories[index],
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Recent orders section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/customer/orders'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            // Recent orders list (TODO: implement with OrderProvider)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: ListTile(
                  title: const Text('No orders yet'),
                  subtitle: const Text(
                    'Start shopping to place your first order',
                  ),
                  onTap: () => context.go('/customer/categories'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
