import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../api_service.dart';

class CarouselImg extends StatefulWidget {
  final Function(String) onLogoLoaded;

  const CarouselImg({required this.onLogoLoaded, super.key});

  @override
  CarouselImageState createState() => CarouselImageState();
}

class CarouselImageState extends State<CarouselImg> {
  List<dynamic> imageUrls = [];
  bool isLoading = true;
  String logo = '';

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final data = await ApiService.fetchLogoAndImages();
      final recipes = data['users'];

      // Filter images for carousel
      final filteredRecipes = recipes.where((recipe) => [3, 5, 6].contains(recipe['id'])).toList();

      // Get logo image
      final logoImage = recipes.firstWhere((recipe) => recipe['id'] == 1, orElse: () => null);

      setState(() {
        // Explicitly cast the image URLs to String
        imageUrls = filteredRecipes.map((recipe) => recipe['image'] as String).toList();
        logo = logoImage != null ? logoImage['image'] as String : '';
        widget.onLogoLoaded(logo);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : CarouselSlider(
      items: imageUrls.map((imageUrl) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
              onError: (error, stackTrace) => const Icon(Icons.error, color: Colors.red),
            ),
          ),
        );
      }).toList(),
      options: CarouselOptions(
        height: 150,
        autoPlay: true,
        viewportFraction: 1.0,
        enableInfiniteScroll: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
      ),
    );
  }
}


