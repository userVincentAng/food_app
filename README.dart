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

  void _onCategorySelected(String category, int index) {
    setState(() {
      selectedCategory = category;
      menuTitle = category; // Update menuTitle based on the selected category
      selectedCategoryIndex = index % categories.length;
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
                  width: 120,
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
                            : ListWheelScrollView.useDelegate(
                          controller: _scrollController,
                          itemExtent: 100,
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
                                  _onCategorySelected(category['name'], actualIndex);
                                  _scrollController.animateToItem(
                                    index,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: SizedBox(
                                  height: 100,
                                  child: Column(
                                    children: [
                                      Container(
                                        color: Colors.white,
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
                                      Flexible(
                                        child: Text(
                                          category['name'],
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
                                    isScrollControlled: true, // Allows the sheet to take up more space
                                    builder: (context) {
                                      return SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.75, // 75% of screen height
                                        child: CustomizeOrderPanel(
                                          product: product,
                                          onAddToOrder: _addToOrder,
                                        ),
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
                          Navigator.pushReplacement(
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
