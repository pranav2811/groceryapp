import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool isDeliverySelected = true; // Control toggle between Delivery and Pickup

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleTabs(), // Delivery and Pickup tabs
            const SizedBox(height: 20),
            _buildRecentSearches(),
            _buildSuggestions(), // Display categories like Pizza, Burger, etc.
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pop(context); // Close the search screen
        },
      ),
      title: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.mic),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.grey[200],
          filled: true,
        ),
      ),
    );
  }

  Widget _buildToggleTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isDeliverySelected = true;
            });
          },
          child: Column(
            children: [
              Text(
                'Delivery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDeliverySelected ? Colors.black : Colors.grey,
                ),
              ),
              if (isDeliverySelected)
                Container(
                  height: 2,
                  width: 60,
                  color: Colors.redAccent,
                  margin: const EdgeInsets.only(top: 4),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              isDeliverySelected = false;
            });
          },
          child: Column(
            children: [
              Text(
                'Pickup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: !isDeliverySelected ? Colors.black : Colors.grey,
                ),
              ),
              if (!isDeliverySelected)
                Container(
                  height: 2,
                  width: 60,
                  color: Colors.redAccent,
                  margin: const EdgeInsets.only(top: 4),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR RECENT SEARCHES',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                        'https://example.com/diljit_profile_image.jpg'),
                    radius: 18,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dil-Luminati Tour - India',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('See Diljit Dosanjh Perform Live',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // Handle removing recent search
                },
              ),
            ],
          ),
          const Divider(thickness: 1),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHAT’S ON YOUR MIND?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _buildSuggestionItems(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSuggestionItems() {
    final items = [
      {'name': 'Pizza', 'image': 'https://example.com/pizza_image.jpg'},
      {'name': 'Burger', 'image': 'https://example.com/burger_image.jpg'},
      {'name': 'Biryani', 'image': 'https://example.com/biryani_image.jpg'},
      {'name': 'Paratha', 'image': 'https://example.com/paratha_image.jpg'},
      {'name': 'Chicken', 'image': 'https://example.com/chicken_image.jpg'},
      {'name': 'Rolls', 'image': 'https://example.com/rolls_image.jpg'},
    ];

    return items.map((item) {
      return Column(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(item['image']!),
            radius: 30,
          ),
          const SizedBox(height: 5),
          Text(item['name']!),
        ],
      );
    }).toList();
  }
}
