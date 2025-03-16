import 'package:flutter/material.dart';
import 'package:food_app/pages/welcome_page.dart';

import '../api_service.dart';
import '../color.dart';
import '../product_card.dart';
import 'carousel_img.dart';
import 'customize_order.dart';
import 'order_summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final FixedExtentScrollController _scrollController = FixedExtentScrollController();
  int selectedCategoryIndex = 0;
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
    Future.delayed(Duration.zero, () {
      _scrollController.jumpToItem(100000 ~/ 2);
    });
  }

  Future<void> _loadData() async {
    await _fetchCategories();
    await _fetchProducts();
  }

  Future<void> _fetchCategories() async {
    try {
      final categoriesData = await ApiService.fetchCategories();
      if (!mounted) return; // Check if the widget is still mounted before updating state
      setState(() {
        categories = categoriesData.map((category) => {
          'Id': category['Id'],
          'CategoryName': category['CategoryName'],
        }).toList();
        isCategoriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Prevent using context if not mounted
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
      final productsData = await ApiService.fetchProducts('1');
      if (!mounted) return;

      setState(() {
        products = productsData;
        isProductsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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

  void _onCategorySelected(String categoryId, int index) {
    // Check if the selected categoryId exists in the categories list
    final isValidCategory = categories.any((cat) => cat['Id'].toString() == categoryId);

    if (isValidCategory) {
      setState(() {
        selectedCategory = categoryId; // Set selectedCategory to the category ID
        menuTitle = categories.firstWhere((cat) => cat['Id'].toString() == categoryId)['CategoryName']; // Update menuTitle
        selectedCategoryIndex = index % categories.length;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid category selected', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.jet,
        ),
      );
    }
  }

  List<dynamic> _getFilteredProducts() {
    if (selectedCategory.isEmpty) {
      return products; // Show all products if no category is selected
    }

    // Get all valid category IDs
    final validCategoryIds = categories.map((cat) => cat['Id'].toString()).toList();

    // Filter products based on selectedCategory and ensure CategoryId is valid
    return products.where((product) {
      final productCategoryId = product['CategoryId'].toString();
      return productCategoryId == selectedCategory && validCategoryIds.contains(productCategoryId);
    }).toList();
  }

  void _addToOrder(Map<String, dynamic> product) {
    // Ensure the base price is always included
    final basePrice = (product['Price'] as num?)?.toDouble() ?? 0.0;

    // Check if the product has variants (from fetchItemDetails)
    final selectedVariantId = product['selectedVariant'];
    final variants = product['itemVariants'] as List<dynamic>? ?? [];
    final selectedVariant = variants.isNotEmpty
        ? variants.firstWhere(
          (variant) => variant['SKUId'] == selectedVariantId,
      orElse: () => null,
    )
        : null;

    // Use the selected variant's price if available, otherwise use the base price
    final variantPrice = selectedVariant != null
        ? (selectedVariant['Price'] as num?)?.toDouble() ?? basePrice
        : basePrice;

    // Calculate the total price of modifiers (if any)
    final modifiers = product['modifiers'] as List<Map<String, dynamic>>? ?? [];
    final totalModifierPrice = modifiers.fold<double>(0.0, (sum, modifier) {
      return sum + ((modifier['Price'] as num?)?.toDouble() ?? 0.0);
    });

    // Calculate the final price (base price + variant price + modifiers)
    final finalPrice = variantPrice + totalModifierPrice;

    setState(() {
      // Check if the product already exists in the cart
      int existingIndex = orderItems.indexWhere((item) =>
      item['Id'] == product['Id'] && // Match by product ID
          item['selectedVariant'] == selectedVariantId && // Match by selected variant
          item['modifiers'] == modifiers); // Match by modifiers

      if (existingIndex != -1) {
        // If the product already exists, increment the quantity
        orderItems[existingIndex]['quantity'] += 1;
      } else {
        // If the product is new, add it to the cart
        final newItem = {
          ...product,
          'Price': finalPrice, // Use the final calculated price
          'quantity': 1,
          'notes': product['notes'],
        };
        orderItems.add(newItem);
      }
    });
  }

  double _calculateTotalAmount() {
    return orderItems.fold(0.0, (double sum, item) {
      final price = (item['Price'] as num? ?? 0).toDouble(); // Use double
      final quantity = item['quantity'] as int? ?? 0; // Quantity is always an int
      return sum + (price * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();
    final screenWidth = MediaQuery.of(context).size.width;

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
                  width: 120, // 20% of screen width
                  color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Logo
                      CircleAvatar(
                        radius: 30, // 7.5% of screen width
                        backgroundColor: Colors.white,
                        child: logo.isNotEmpty
                            ? ClipOval(
                          child: Image.network(
                            logo,
                            fit: BoxFit.contain,
                            width: screenWidth * 0.10, // 15% of screen width
                            height: screenWidth * 0.10, // 15% of screen width
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
                            : ListWheelScrollView.useDelegate(
                          controller: _scrollController,
                          itemExtent: 100, // 15% of screen height
                          physics: FixedExtentScrollPhysics(),
                          diameterRatio: 2.5,
                          perspective: 0.0001,
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 100000, // Simulate infinite looping
                            builder: (context, index) {
                              final actualIndex = index % categories.length;
                              final category = categories[actualIndex];
                              return GestureDetector(
                                onTap: () {
                                  _onCategorySelected(category['Id'].toString(), actualIndex); // Pass the category ID as a string
                                  _scrollController.animateToItem(
                                    index,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: SizedBox(
                                  height: 100, // 15% of screen height
                                  child: Column(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          category['CategoryName'],
                                          style: const TextStyle(fontSize: 12, color: Colors.black),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 150,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return ProductCard(
                                  product: product,
                                  onTap: (itemId) async {
                                    try {
                                      // Fetch item details
                                      final itemDetails = await ApiService.fetchItemDetails('1', itemId);

                                      if (!mounted) return;

                                      // Debugging: Print itemDetails to verify the structure
                                      print('Item Details: $itemDetails');
                                      print('Products: $product');

                                      // Show the customization panel
                                      final result = await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (context) => CustomizeOrderPanel(itemDetails: itemDetails, product: product),
                                      );

                                      if (result != null) {
                                        // Log the customization result

                                        // Add the product to the cart with customization data
                                        _addToOrder({
                                          ...itemDetails, // Include all item details
                                          'Price': product['Price'] ?? itemDetails['Price'], // Use the passed price or fallback to basePrice
                                          'selectedVariant': result['variantId'], // Add selected variant
                                          'modifiers': result['modifiers'], // Add selected modifiers
                                          'notes': result['notes'], // Include notes
                                        });
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error loading item details: $e')),
                                      );
                                    }
                                  },
                                );
                              },
                            )
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
            child: OrderSummaryPanel(
              totalAmount: _calculateTotalAmount(),
              totalItems: orderItems.length,
              orderItems: orderItems, // Pass the orderItems list
              onCancel: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomePage()),
                );
              },
              onDone: () {
              },
            ),
          ),
        ],
      ),
    );
  }
}



