import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:food_app/pages/welcome_page.dart';
import '../api_service.dart';
import 'carousel_img.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String menuTitle = 'Main Menu';
  String logo = '';
  List<Map<String, dynamic>> categories = [];
  List<dynamic> products = [];
  String selectedCategory = ''; // Track selected category
  bool isCategoriesLoading = true;
  bool isProductsLoading = true;
  List<Map<String, dynamic>> orderItems = []; // Track order items

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchCategories();
    await _fetchProducts();
  }

  Future<void> _fetchCategories() async {
    try {
      final categoriesData = await ApiService.fetchCategories();
      setState(() {
        categories = categoriesData.map((category) => {
          'id': category['id'],
          'name': category['name'],
          'image': category['image'],
        }).toList();
        isCategoriesLoading = false;
      });
    } catch (e) {
      setState(() {
        isCategoriesLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching categories: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.jet,
        ),
      );
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final productsData = await ApiService.fetchProducts();
      setState(() {
        products = productsData;
        isProductsLoading = false;
      });
    } catch (e) {
      setState(() {
        isProductsLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching products: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.jet,
        ),
      );
    }
  }

  void _updateLogo(String newLogo) {
    setState(() {
      logo = newLogo;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
      menuTitle = category; // Update menuTitle based on the selected category
    });
  }

  List<dynamic> _getFilteredProducts() {
    if (selectedCategory.isEmpty) {
      return products; // Show all products if no category is selected
    }
    return products.where((product) => product['category'] == selectedCategory).toList();
  }

  void _addToOrder(Map<String, dynamic> product) {
    setState(() {
      orderItems.add(product);
    });
  }

  double _calculateTotalAmount() {
    return orderItems.fold(0, (sum, item) => sum + (item['price'] as num));
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();

    return Scaffold(
      body: Column(
        children: [
          // Carousel Slider Section
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CarouselImg(onLogoLoaded: _updateLogo),
          ),
          // Logo and Sidebar Section
          Expanded(
            child: Row(
              children: [
                // Sidebar with Logo and Categories
                Container(
                  width: 90,
                  color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Logo
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: logo.isNotEmpty
                            ? ClipOval(
                          child: Image.network(
                            logo,
                            fit: BoxFit.contain,
                            width: 70,
                            height: 70,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, color: Colors.red);
                            },
                          ),
                        )
                            : const Text(
                          "Logo",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Categories List
                      Expanded(
                        child: isCategoriesLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return GestureDetector(
                              onTap: () => _onCategorySelected(category['name']),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.white,
                                    child: ClipOval(
                                      child: Image.network(
                                        category['image'],
                                        fit: BoxFit.contain,
                                        width: 70,
                                        height: 70,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.error, color: Colors.red);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    category['name'],
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content Area
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                    child: Column(
                      children: [
                        // Menu Title
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              menuTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Products GridView
                        Expanded(
                          child: isProductsLoading
                              ? const Center(child: CircularProgressIndicator())
                              : GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 150, // Maximum width for each card
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.8, // Adjust the aspect ratio as needed
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return CustomizeOrderPanel(
                                        product: product,
                                        onAddToOrder: _addToOrder,
                                      );
                                    },
                                  );
                                },
                                child: Card(
                                  elevation: 2,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Image.network(
                                          product['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.error, color: Colors.red);
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '₱${product['price'].toString()}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
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
                ),
              ],
            ),
          ),
          // Order Summary Section
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              height: 150,
              width: double.infinity,
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 70,
                    width: double.infinity,
                    child: Row(
                      children: [
                        Text('Total Amount: ₱${_calculateTotalAmount().toStringAsFixed(2)}'),
                        const SizedBox(width: 10),
                        Text('Total Items: ${orderItems.length}'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WelcomePage()),
                          );
                        },
                        child: const Text('Cancel Order'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Handle order confirmation
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.airforceBlue,
                        ),
                        child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Customize Order Panel
class CustomizeOrderPanel extends StatelessWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToOrder;

  const CustomizeOrderPanel({
    required this.product,
    required this.onAddToOrder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Name
          Text(
            product['name'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // Product Image
          Image.network(
            product['image'],
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, color: Colors.red);
            },
          ),
          const SizedBox(height: 10),
          // Customization Options (Example: Add Notes)
          const Text(
            'Add Notes:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Enter your notes...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Update notes in the product
              product['notes'] = value;
            },
          ),
          const SizedBox(height: 20),
          // Add to Order Button
          ElevatedButton(
            onPressed: () {
              // Pass the customized product back to the parent
              onAddToOrder(product);
              Navigator.pop(context); // Close the panel
            },
            child: const Text('Add to Order'),
          ),
        ],
      ),
    );
  }
}