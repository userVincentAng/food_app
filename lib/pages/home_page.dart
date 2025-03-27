import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:food_app/pages/welcome_page.dart';
import '../api_service.dart';
import '../product_card.dart';
import 'carousel_img.dart';
import 'customize_order.dart';
import 'order_summary.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> connectionDetails;

  const HomePage({super.key, required this.connectionDetails});

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
  String selectedCategory = '';
  bool isCategoriesLoading = true;
  bool isProductsLoading = true;
  List<Map<String, dynamic>> orderItems = [];
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadData();
    Future.delayed(Duration.zero, () {
      if (_scrollController.hasClients) {
        _scrollController.jumpToItem(100000 ~/ 2);
      }
    });
  }

  Future<void> _initConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });

    Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });

      if (_isOnline && (categories.isEmpty || products.isEmpty)) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection - using cached data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      await _fetchCategories();
      await _fetchProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isCategoriesLoading = true;
    });

    // Check cache first
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedCategories');

    if (cachedData != null) {
      final cachedCategories = json.decode(cachedData);
      if (mounted) {
        setState(() {
          categories = List<Map<String, dynamic>>.from(cachedCategories);
          isCategoriesLoading = false;

          // Select first category by default if none selected
          if (selectedCategory.isEmpty && categories.isNotEmpty) {
            selectedCategory = categories[0]['Id'].toString();
            menuTitle = categories[0]['CategoryName'];
          }
        });
      }
    }

    // Then fetch fresh data
    try {
      final categoriesData = await ApiService.fetchCategories();
      if (!mounted) return;

      // Update cache
      await prefs.setString('cachedCategories', json.encode(categoriesData));

      // Update UI
      setState(() {
        categories = categoriesData.map((category) => {
          'Id': category['Id'],
          'CategoryName': category['CategoryName'],
        }).toList();
        isCategoriesLoading = false;

        if (selectedCategory.isEmpty && categories.isNotEmpty) {
          selectedCategory = categories[0]['Id'].toString();
          menuTitle = categories[0]['CategoryName'];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isCategoriesLoading = false;
      });
      // Only rethrow if we have no cached data
      if (cachedData == null) rethrow;
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isProductsLoading = true;
    });

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
      rethrow;
    }
  }

  void _updateLogo(String newLogo) {
    if (!mounted) return;
    setState(() {
      logo = newLogo;
    });
  }

  void _onCategorySelected(String categoryId, int index) {
    final isValidCategory = categories.any((cat) => cat['Id'].toString() == categoryId);

    if (isValidCategory) {
      setState(() {
        selectedCategory = categoryId;
        menuTitle = categories.firstWhere(
              (cat) => cat['Id'].toString() == categoryId,
          orElse: () => {'CategoryName': 'Menu'},
        )['CategoryName'];
        selectedCategoryIndex = index % categories.length;
      });

      // Scroll to selected category
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateToItem(
            100000 + (selectedCategoryIndex),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  List<dynamic> _getFilteredProducts() {
    if (selectedCategory.isEmpty) {
      return products;
    }

    final validCategoryIds = categories.map((cat) => cat['Id'].toString()).toList();
    return products.where((product) {
      final productCategoryId = product['CategoryId'].toString();
      return productCategoryId == selectedCategory && validCategoryIds.contains(productCategoryId);
    }).toList();
  }

  Future<void> _onProductTap(String itemId, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Loading product details...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Find the base product first
      final baseProduct = products.firstWhere(
            (p) => p['Id'].toString() == itemId,
        orElse: () => throw Exception('Product not found'),
      );

      // Then fetch item details
      final itemDetails = await ApiService.fetchItemDetails('1', itemId);
      if (!mounted) return;

      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (context) => CustomizeOrderPanel(
          itemDetails: itemDetails,
          product: baseProduct, // Pass the base product from the main list
        ),
      );

      if (!mounted || result == null) return;

      _addToOrder({
        ...itemDetails,
        'Id': itemId,
        'ProductName': baseProduct['ProductName'] ?? 'Unnamed Item', // Use name from products list
        'Price': baseProduct['Price'] ?? 0.0, // Use base price from products list
        'selectedVariant': result['variantId'],
        'variantDetails': result['variantDetails'],
        'modifiers': result['modifiers'],
        'notes': result['notes'],
        'quantity': result['quantity'],
        'ImgUrl': baseProduct['ImgUrl'], // Include image URL if needed
      });

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Added ${result['quantity']} ${baseProduct['ProductName']} to order'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _addToOrder(Map<String, dynamic> product) {
    try {
      // Get base price from the product (already comes from products list)
      final basePrice = (product['Price'] as num?)?.toDouble() ?? 0.0;
      final selectedVariantId = product['selectedVariant'];
      final variants = product['itemVariants'] as List<dynamic>? ?? [];

      // Calculate variant price if selected
      final selectedVariant = variants.firstWhereOrNull((v) => v['SKUId'] == selectedVariantId);
      final variantPrice = (selectedVariant?['Price'] as num?)?.toDouble() ?? basePrice;

      // Calculate modifiers total
      final modifiers = product['modifiers'] as List<Map<String, dynamic>>? ?? [];
      final totalModifierPrice = modifiers.fold(0.0, (sum, mod) => sum + ((mod['Price'] as num?)?.toDouble() ?? 0.0));

      // Final price calculation
      final finalPrice = variantPrice + totalModifierPrice;
      final quantity = product['quantity'] as int? ?? 1;

      setState(() {
        final existingItemIndex = orderItems.indexWhere((item) {
          return item['Id'] == product['Id'] &&
              item['selectedVariant'] == selectedVariantId &&
              const DeepCollectionEquality().equals(item['modifiers'], modifiers) &&
              item['notes'] == product['notes'];
        });

        if (existingItemIndex != -1) {
          orderItems[existingItemIndex]['quantity'] += quantity;
        } else {
          orderItems.add({
            ...product,
            'Id': product['Id'],
            'ProductName': product['ProductName'] ?? 'Unnamed Item', // Already from products list
            'Price': finalPrice,
            'quantity': quantity,
            'notes': product['notes'],
            'selectedVariant': selectedVariantId,
            'variantDetails': selectedVariant,
            'modifiers': modifiers,
            'ImgUrl': product['ImgUrl'], // Preserve image URL
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated (${orderItems.length} items)'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateTotalAmount() {
    return orderItems.fold(0.0, (double sum, item) {
      final price = (item['Price'] as num? ?? 0).toDouble();
      final quantity = item['quantity'] as int? ?? 0;
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isOnline ? 0 : 30,
            color: Colors.red,
            child: const Center(
              child: Text(
                'No internet connection',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CarouselImg(onLogoLoaded: _updateLogo),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 120,
                  color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: logo.isNotEmpty
                            ? ClipOval(
                          child: Image.network(
                            logo,
                            fit: BoxFit.contain,
                            width: screenWidth * 0.10,
                            height: screenWidth * 0.10,
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
                      Expanded(
                        child: isCategoriesLoading
                            ? const Center(child: CircularProgressIndicator())
                            : RefreshIndicator(
                          onRefresh: _fetchCategories,
                          child: ListWheelScrollView.useDelegate(
                            controller: _scrollController,
                            itemExtent: 100,
                            physics: const FixedExtentScrollPhysics(),
                            diameterRatio: 2.5,
                            perspective: 0.0001,
                            onSelectedItemChanged: (index) {
                              if (index > 200000 || index < 50000) {
                                _scrollController.jumpToItem(100000 + (index % categories.length));
                              }
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                final actualIndex = index % categories.length;
                                final category = categories[actualIndex];
                                return GestureDetector(
                                  onTap: () {
                                    _onCategorySelected(category['Id'].toString(), actualIndex);
                                    _scrollController.animateToItem(
                                      index,
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: SizedBox(
                                    height: 100,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          category['CategoryName'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: selectedCategoryIndex == actualIndex
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: categories.isNotEmpty ? null : 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                    child: Column(
                      children: [
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
                        Expanded(
                          child: isProductsLoading
                              ? const Center(child: CircularProgressIndicator())
                              : filteredProducts.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'No products available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (!isCategoriesLoading && categories.isNotEmpty)
                                  TextButton(
                                    onPressed: _loadData,
                                    child: const Text('Refresh'),
                                  ),
                              ],
                            ),
                          )
                              : RefreshIndicator(
                            onRefresh: _fetchProducts,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(10),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
                                  onTap: (itemId) => _onProductTap(itemId, context),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          OrderSummaryPanel(
            totalAmount: _calculateTotalAmount(),
            totalItems: orderItems.length,
            orderItems: orderItems,
            onCancel: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WelcomePage(connectionDetails: widget.connectionDetails),
                ),
              );
            },
            onDone: () {
              // Handle checkout logic
            },
            onOrderUpdated: (updatedItems) {
              setState(() {
                orderItems = updatedItems;
              });
            },
            connectionDetails: widget.connectionDetails,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}