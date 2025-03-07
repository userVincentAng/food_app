import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:food_app/pages/login_page.dart';
import 'package:food_app/pages/welcome_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fuzzy/fuzzy.dart'; // For fuzzy matching
import 'package:rxdart/rxdart.dart'; // For debouncing

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
                      color: Colors.white,
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
                      color: Colors.white,
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
    required this.merchants,
    required this.onMerchantSelected,
  });

  @override
  State<MerchantSelectionPanel> createState() => _MerchantSelectionPanelState();
}

class _MerchantSelectionPanelState extends State<MerchantSelectionPanel> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredMerchants = [];
  final _searchSubject = PublishSubject<String>();

  @override
  void initState() {
    super.initState();
    filteredMerchants = widget.merchants;

    _searchSubject
        .debounceTime(Duration(milliseconds: 300)) // Debounce for 300ms
        .listen((query) {
      filterMerchants(query);
    });

    searchController.addListener(() {
      _searchSubject.add(searchController.text);
    });
  }

  void filterMerchants(String query) {
    final fuzzy = Fuzzy(
      widget.merchants,
      options: FuzzyOptions(
        keys: [WeightedKey<dynamic>(getter: (m) => m['merchant_name'], weight: 1.0)],
      ),
    );
    setState(() {
      filteredMerchants = fuzzy.search(query).map((result) => result.item).toList();
    });
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
              hintText: 'Search Merchant',
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
                title: HighlightedText(
                  text: merchant,
                  query: searchController.text,
                ),
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

  @override
  void dispose() {
    _searchSubject.close();
    searchController.dispose();
    super.dispose();
  }
}

class PosSelectionPanel extends StatefulWidget {
  final List<dynamic> posList;
  final Function(String) onPosSelected;

  const PosSelectionPanel({
    required this.posList,
    required this.onPosSelected,
  });

  @override
  State<PosSelectionPanel> createState() => _PosSelectionPanelState();
}

class _PosSelectionPanelState extends State<PosSelectionPanel> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredPosList = [];
  final _searchSubject = PublishSubject<String>();

  @override
  void initState() {
    super.initState();
    filteredPosList = widget.posList;

    _searchSubject
        .debounceTime(Duration(milliseconds: 300)) // Debounce for 300ms
        .listen((query) {
      filterPosList(query);
    });

    searchController.addListener(() {
      _searchSubject.add(searchController.text);
    });
  }

  void filterPosList(String query) {
    final fuzzy = Fuzzy(
      widget.posList,
      options: FuzzyOptions(
        keys: [WeightedKey<dynamic>(getter: (p) => p['pos_name'], weight: 1.0)],
      ),
    );
    setState(() {
      filteredPosList = fuzzy.search(query).map((result) => result.item).toList();
    });
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
              hintText: 'Search POS',
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
                title: HighlightedText(
                  text: pos,
                  query: searchController.text,
                ),
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

  @override
  void dispose() {
    _searchSubject.close();
    searchController.dispose();
    super.dispose();
  }
}

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final matches = <TextSpan>[];
    int start = 0;

    while (start < textLower.length) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        matches.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        matches.add(TextSpan(text: text.substring(start, index)));
      }
      matches.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      );
      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: matches,
      ),
    );
  }
}
