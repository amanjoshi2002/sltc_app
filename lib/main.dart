import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: SalesOrderForm(),
  ));
}

class SalesOrderForm extends StatefulWidget {
  @override
  _SalesOrderFormState createState() => _SalesOrderFormState();
}

class _SalesOrderFormState extends State<SalesOrderForm> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? selectedRetailStore;
  List<Product> products = [];
  List<ProductEntry> productEntries = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final response =
        await http.get(Uri.parse('http://sltc.co.in/get-products/'));
    if (response.statusCode == 200) {
      setState(() {
        final List<dynamic> data = json.decode(response.body);
        products = data.map((item) => Product.fromJson(item)).toList();
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

  List<Product> _searchProducts(String query) {
    if (query.isEmpty) {
      return products;
    } else {
      return products
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Order Form'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final selectedRetailStore = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RetailStoreSelectionPage()),
                      );
                      setState(() {
                        this.selectedRetailStore = selectedRetailStore;
                      });
                    },
                    child: Text('Select Retail Store'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Products',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text, // Set keyboard type to text
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text('Search'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: _searchProducts(_searchController.text).length,
                  itemBuilder: (context, index) {
                    final product =
                        _searchProducts(_searchController.text)[index];
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        title: Text(product.name),
                        leading: Checkbox(
                          value: product.selected,
                          onChanged: (value) {
                            setState(() {
                              product.selected = value!;
                            });
                          },
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              product.quantity = int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitOrder,
                child: Text('Submit Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitOrder() async {
    final retail = selectedRetailStore;
    String orderDetails = 'Retail Store: $retail\nOrder Items:\n';
    for (var product in products) {
      if (product.selected) {
        orderDetails += '${product.name}: ${product.quantity}\n';
        productEntries.add(ProductEntry(
            product: product.name, quantity: product.quantity));
      }
    }
    await Clipboard.setData(ClipboardData(text: orderDetails));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order submitted successfully!'),
      ),
    );

    // Reset selected products and their quantities
    for (var product in products) {
      product.selected = false;
      product.quantity = 0;
    }
    _searchController.clear();
    setState(() {});
  }
}

class RetailStoreSelectionPage extends StatefulWidget {
  @override
  _RetailStoreSelectionPageState createState() =>
      _RetailStoreSelectionPageState();
}

class _RetailStoreSelectionPageState extends State<RetailStoreSelectionPage> {
  List<String> retailStores = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRetailStores();
  }

  Future<void> _fetchRetailStores() async {
    final response =
        await http.get(Uri.parse('http://sltc.co.in/get-retail-stores/'));
    if (response.statusCode == 200) {
      setState(() {
        final List<dynamic> data = json.decode(response.body);
        retailStores = data.map((item) => item['name'].toString()).toList();
      });
    } else {
      throw Exception('Failed to load retail stores');
    }
  }

  List<String> _searchRetailStores(String query) {
    if (query.isEmpty) {
      return retailStores;
    } else {
      return retailStores
          .where((store) => store.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Retail Store'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Retail Stores',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text('Search'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchRetailStores(_searchController.text).length,
                itemBuilder: (context, index) {
                  final store = _searchRetailStores(_searchController.text)[index];
                  return ListTile(
                    title: Text(store),
                    onTap: () {
                      Navigator.pop(context, store);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Product {
  final String name;
  bool selected;
  int quantity;

  Product({required this.name, this.selected = false, this.quantity = 0});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
    );
  }
}

class ProductEntry {
  final String product;
  final int quantity;

  ProductEntry({required this.product, required this.quantity});
}
