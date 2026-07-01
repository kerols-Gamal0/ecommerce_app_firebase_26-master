import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app_api_26/features/home/presentation/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CollectionReference<Map<String, dynamic>> productsReference;

  @override
  void initState() {
    super.initState();
    getProducts();
    getFavorites();
  }

  void getProducts() {
    productsReference = FirebaseFirestore.instance.collection('products');
  }

  late List<dynamic> favorites;
  bool loading = true;
  void getFavorites() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    favorites = await FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .get()
        .then((snapshot) {
          return snapshot.get('favorites') as List<dynamic>;
        });
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _nameController = TextEditingController(),
        _descriptionController = TextEditingController(),
        _priceController = TextEditingController(),
        _imageUrlController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Price"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(labelText: "Image Url"),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isEmpty ||
                          _priceController.text.isEmpty) {
                        return;
                      }

                      final name = _nameController.text;
                      final description = _descriptionController.text;
                      final price =
                          double.tryParse(_priceController.text) ?? 0.0;
                      final imageUrl = _imageUrlController.text;

                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      await productsReference.add({
                        "name": name,
                        "description": description,
                        "price": price,
                        "image": imageUrl,
                      });
                      _nameController.clear();
                      _descriptionController.clear();
                      _priceController.clear();
                      _imageUrlController.clear();
                    },
                    child: const Text("Add Product"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const Text(
                  'Our Shop',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.blue),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.blue),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Shoes', 'Shirts', 'Tech', 'Home'].map((cat) {
                  bool isAll = cat == 'All';
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isAll ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (!isAll)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                          ),
                      ],
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isAll ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: productsReference.snapshots(),
                builder: (context, asyncSnapshot) {
                  if (asyncSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (asyncSnapshot.hasError) {
                    return Center(child: Text("Error: ${asyncSnapshot.error}"));
                  }

                  if (!asyncSnapshot.hasData ||
                      asyncSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No products found"));
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: asyncSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final product = asyncSnapshot.data!.docs[index].data();
                      return ProductCard(
                        id: asyncSnapshot.data!.docs[index].id,
                        title: product['name'] ?? 'No Name',
                        price: (product['price'] is num)
                            ? (product['price'] as num).toDouble()
                            : 0.0,
                        description: product['description'] ?? '',
                        image:
                            product['image'] ??
                            'https://via.placeholder.com/150',
                        isFavorite: favorites.contains(
                          asyncSnapshot.data!.docs[index].id,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
