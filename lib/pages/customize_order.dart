import 'package:flutter/material.dart';

class CustomizeOrderPanel extends StatefulWidget {
  final Map<String, dynamic> itemDetails;
  final Map<String, dynamic> product;

  const CustomizeOrderPanel(
      {super.key, required this.itemDetails, required this.product});

  @override
  CustomizeOrderPanelState createState() => CustomizeOrderPanelState();
}

class CustomizeOrderPanelState extends State<CustomizeOrderPanel> {
  int? selectedVariant;
  Map<int, Map<String, dynamic>> selectedModifiers = {};
  final TextEditingController _notesController = TextEditingController();
  double finalPrice = 0.0;
  int _quantity = 1; // Quantity state variable

  @override
  void initState() {
    super.initState();
    finalPrice = widget.product['Price'] ?? widget.itemDetails['Price'];
  }

  void _updateFinalPrice() {
    double totalPrice = widget.product['Price'] ?? widget.itemDetails['Price'];

    if (selectedVariant != null) {
      var selectedVariantDetails =
          widget.itemDetails['itemVariants'].firstWhere(
        (variant) => variant['SKUId'] == selectedVariant,
        orElse: () => {},
      );
      if (selectedVariantDetails.isNotEmpty) {
        totalPrice = selectedVariantDetails['Price'];
      }
    }

    for (var modifier in selectedModifiers.values) {
      totalPrice += modifier['Price'];
    }

    setState(() {
      finalPrice = totalPrice * _quantity; // Multiply price by quantity
    });
  }

  @override
  Widget build(BuildContext context) {
    var variants = widget.itemDetails['itemVariants'] ?? [];
    var modifiers = widget.itemDetails['itemModifiers'] ?? [];
    var productName =
        widget.product['ProductName'] ?? widget.itemDetails['ProductName'];
    var basePrice = widget.product['Price'] ?? widget.itemDetails['Price'];
    var imageUrl = widget.product['ImgUrl'];

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
                            'https://sellercenter.shoppazing.com/api/$imageUrl',
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
                    const Text("Select Size",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...variants.map<Widget>((variant) {
                      return RadioListTile<int>(
                        title: Text(
                            "${variant['CombiName']} - ₱${variant['Price']}"),
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
                    const Text("Add Extras",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...modifiers.map<Widget>((modifier) {
                      bool isRequired = modifier['IsRequired'] ?? false;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(modifier['ModifierName'] ?? "Extras",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (isRequired)
                            ...modifier['ModifierOptions']
                                .map<Widget>((option) {
                              return RadioListTile<int>(
                                title: Text(
                                    "${option['Name']} - ₱${option['Price']}"),
                                value: option['Id'],
                                groupValue:
                                    selectedModifiers.containsKey(option['Id'])
                                        ? option['Id']
                                        : null,
                                onChanged: (value) {
                                  setState(() {
                                    selectedModifiers.removeWhere((key, val) =>
                                        val['ModifierId'] ==
                                        modifier['ModifierId']);
                                    selectedModifiers[option['Id']] = option;
                                    _updateFinalPrice();
                                  });
                                },
                              );
                            }).toList(),
                          if (!isRequired)
                            ...modifier['ModifierOptions']
                                .map<Widget>((option) {
                              return CheckboxListTile(
                                title: Text(
                                    "${option['Name']} - ₱${option['Price']}"),
                                value:
                                    selectedModifiers.containsKey(option['Id']),
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
                  const Text("Add Notes",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: "Add instructions or notes...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                  _updateFinalPrice();
                                });
                              }
                            : null,
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _quantity++;
                            _updateFinalPrice();
                          });
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                      ),
                    ],
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
                  color: Colors.black.withAlpha(26),
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
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
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
                          ? variants.firstWhere(
                              (variant) => variant['SKUId'] == selectedVariant)
                          : {},
                      'modifiers': selectedModifiers.values.toList(),
                      'notes': _notesController.text.trim(),
                      'quantity': _quantity, // Include quantity in the response
                      'price': finalPrice,
                      'imageUrl': imageUrl,
                      'ProductName': widget.product['ProductName'] ??
                          widget.itemDetails['ProductName'],
                      'Id': widget.product['Id'] ?? widget.itemDetails['Id'],
                    });
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
