import 'package:flutter/material.dart';

class CustomizeOrderPanel extends StatefulWidget {
  final Map<String, dynamic> itemDetails;
  final Map<String, dynamic> product;

  const CustomizeOrderPanel({super.key, required this.itemDetails, required this.product});

  @override
  CustomizeOrderPanelState createState() => CustomizeOrderPanelState();
}

class CustomizeOrderPanelState extends State<CustomizeOrderPanel> {
  int? selectedVariant; // Store SKUId
  Map<int, Map<String, dynamic>> selectedModifiers = {}; // Track selected modifiers with their details
  final TextEditingController _notesController = TextEditingController(); // Controller for notes
  double finalPrice = 0.0; // Track the final price

  @override
  void initState() {
    super.initState();
    // Initialize finalPrice with the base price
    finalPrice = widget.product['Price'] ?? widget.itemDetails['Price'];
  }

  @override
  void dispose() {
    _notesController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _updateFinalPrice() {
    double totalPrice = widget.product['Price'] ?? widget.itemDetails['Price'];

    // If a variant is selected, use its price
    if (selectedVariant != null) {
      var selectedVariantDetails = widget.itemDetails['itemVariants'].firstWhere(
            (variant) => variant['SKUId'] == selectedVariant,
        orElse: () => {},
      );
      if (selectedVariantDetails.isNotEmpty) {
        totalPrice = selectedVariantDetails['Price'];
      }
    }

    // Add the price of selected modifiers
    selectedModifiers.values.forEach((modifier) {
      totalPrice += modifier['Price'];
    });

    // Update finalPrice and trigger a UI rebuild
    setState(() {
      finalPrice = totalPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    var variants = widget.itemDetails['itemVariants'] ?? [];
    var modifiers = widget.itemDetails['itemModifiers'] ?? [];
    var productName = widget.product['ProductName'] ?? widget.itemDetails['ProductName'];
    var basePrice = widget.product['Price'] ?? widget.itemDetails['Price'];
    var imageUrl = 'https://sellercenter.shoppazing.com/api/${widget.product['ImgUrl']}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Product Image, Name, and Base Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₱$basePrice",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Variants Selection
                  if (variants.isNotEmpty) ...[
                    const Text("Select Size", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...variants.map<Widget>((variant) {
                      return RadioListTile<int>(
                        title: Text("${variant['CombiName']} - ₱${variant['Price']}"),
                        value: variant['SKUId'],
                        groupValue: selectedVariant,
                        onChanged: (value) {
                          setState(() {
                            selectedVariant = value;
                            _updateFinalPrice();
                          });
                        },
                      );
                    }).toList(),
                  ],

                  // Modifiers Selection
                  if (modifiers.isNotEmpty) ...[
                    const Text("Add Extras", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...modifiers.map<Widget>((modifier) {
                      bool isRequired = modifier['IsRequired'] ?? false;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(modifier['ModifierName'] ?? "Extras",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (isRequired)
                            ...modifier['ModifierOptions'].map<Widget>((option) {
                              return RadioListTile<int>(
                                title: Text("${option['Name']} - ₱${option['Price']}"),
                                value: option['Id'],
                                groupValue: selectedModifiers.containsKey(option['Id'])
                                    ? option['Id']
                                    : null,
                                onChanged: (value) {
                                  setState(() {
                                    selectedModifiers.removeWhere((key, val) =>
                                    val['ModifierId'] == modifier['ModifierId']);
                                    selectedModifiers[option['Id']] = option;
                                    _updateFinalPrice();
                                  });
                                },
                              );
                            }).toList(),
                          if (!isRequired)
                            ...modifier['ModifierOptions'].map<Widget>((option) {
                              return CheckboxListTile(
                                title: Text("${option['Name']} - ₱${option['Price']}"),
                                value: selectedModifiers.containsKey(option['Id']),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedModifiers[option['Id']] = option;
                                    } else {
                                      selectedModifiers.remove(option['Id']);
                                    }
                                    _updateFinalPrice();
                                  });
                                },
                              );
                            }).toList(),
                        ],
                      );
                    }).toList(),
                  ],

                  // Add Notes Section
                  const SizedBox(height: 16),
                  const Text("Add Notes", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: "Add instructions or notes...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Sticky Button at the Bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (variants.isNotEmpty && selectedVariant == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a size!')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'variantId': selectedVariant,
                      'variantDetails': selectedVariant != null
                          ? variants.firstWhere((variant) => variant['SKUId'] == selectedVariant)
                          : {},
                      'modifiers': selectedModifiers.values.toList(),
                      'notes': _notesController.text.trim(),
                      'price': finalPrice,
                      'ProductName': widget.product['ProductName'] ?? widget.itemDetails['ProductName'],
                      'Id': widget.product['Id'] ?? widget.itemDetails['Id'],
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text(
                    "Add to Cart ₱${finalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}