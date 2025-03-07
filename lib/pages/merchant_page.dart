import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:food_app/pages/login_page.dart';
import 'package:food_app/pages/welcome_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MerchantPage extends StatefulWidget {
  const MerchantPage({super.key});

  @override
  State<MerchantPage> createState() => _MerchantPageState();
}

class _MerchantPageState extends State<MerchantPage> {
  List<dynamic> merchants = [];
  List<dynamic> posList = [];
  String? selectedMerchant;
  String? selectedPos;
  bool isMerchantSelected = false;
  bool isPosSelected = false;

  @override
  void initState() {
    super.initState();
    fetchMerchants();
  }

  Future<void> fetchMerchants() async {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/JayMatawaran/APIs/refs/heads/main/merchants%26pos.json'));
    if (response.statusCode == 200) {
      setState(() {
        merchants = json.decode(response.body)['merchants'];
      });
    } else {
      throw Exception('Failed to load merchants');
    }
  }

  void onMerchantSelected(String merchant) {
    setState(() {
      selectedMerchant = merchant;
      isMerchantSelected = true;
      selectedPos = null;
      isPosSelected = false;
      posList = merchants.firstWhere((m) => m['merchant_name'] == merchant)['pos_systems'];
    });
  }

  void onPosSelected(String pos) {
    setState(() {
      selectedPos = pos;
      isPosSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.8;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: Image.asset('assets/images/logo.png'),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return MerchantSelectionPanel(
                          merchants: merchants,
                          onMerchantSelected: onMerchantSelected,
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: AppColors.jet,
                  ),
                  child: Text(
                    'Select Merchant',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: isMerchantSelected
                      ? () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return PosSelectionPanel(
                          posList: posList,
                          onPosSelected: onPosSelected,
                        );
                      },
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: isMerchantSelected ? AppColors.jet : Colors.grey,
                  ),
                  child: Text(
                    'Select POS',
                    style: TextStyle(
                      fontSize: 18,
                      color: isMerchantSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: isPosSelected ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomePage()),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: isPosSelected ? AppColors.airforceBlue : Colors.grey,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      color: isMerchantSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MerchantSelectionPanel extends StatefulWidget {
  final List<dynamic> merchants;
  final Function(String) onMerchantSelected;

  const MerchantSelectionPanel({
    super.key,
    required this.merchants,
    required this.onMerchantSelected,
  });

  @override
  State<MerchantSelectionPanel> createState() => _MerchantSelectionPanelState();
}

class _MerchantSelectionPanelState extends State<MerchantSelectionPanel> {
  List<dynamic> filteredMerchants = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredMerchants = widget.merchants;
    searchController.addListener(_filterMerchants);
  }

  void _filterMerchants() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredMerchants = widget.merchants.where((merchant) {
        final merchantName = merchant['merchant_name'].toLowerCase();
        return merchantName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search merchants...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredMerchants.length,
            itemBuilder: (context, index) {
              final merchant = filteredMerchants[index]['merchant_name'];
              return ListTile(
                title: Text(merchant),
                onTap: () {
                  widget.onMerchantSelected(merchant);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class PosSelectionPanel extends StatefulWidget {
  final List<dynamic> posList;
  final Function(String) onPosSelected;

  const PosSelectionPanel({
    super.key,
    required this.posList,
    required this.onPosSelected,
  });

  @override
  State<PosSelectionPanel> createState() => _PosSelectionPanelState();
}

class _PosSelectionPanelState extends State<PosSelectionPanel> {
  List<dynamic> filteredPosList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredPosList = widget.posList;
    searchController.addListener(_filterPosList);
  }

  void _filterPosList() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPosList = widget.posList.where((pos) {
        final posName = pos['pos_name'].toLowerCase();
        return posName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search POS...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredPosList.length,
            itemBuilder: (context, index) {
              final pos = filteredPosList[index]['pos_name'];
              return ListTile(
                title: Text(pos),
                onTap: () {
                  widget.onPosSelected(pos);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}