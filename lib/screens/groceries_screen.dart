import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/data/dummy_items.dart';
import 'package:shopping_list_app/model/category.dart';
import 'package:shopping_list_app/model/grocery_item.dart';
import 'package:shopping_list_app/screens/new_grocery_screen.dart';
import 'package:http/http.dart' as http;

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  List<GroceryItem> groceries = [];
  var isLoading = true;

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  void addNewGrocery(GroceryItem item) {
    setState(() {
      groceries.add(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "New Grocery Added",
        ),
      ),
    );
  }

  void _loadData() async {
    final Uri url = Uri.https(
        "shopping-list-flutter-practice-default-rtdb.asia-southeast1.firebasedatabase.app",
        "shopping-list.json");
    final data = await http.get(url);
    if (data.body == "null") {
      setState(() {
        isLoading = false;
      });
    }
    final Map<String, dynamic> listData = json.decode(data.body);
    List<GroceryItem> list = [];

    for (final item in listData.entries) {
      Category transformedCategory = categories.entries.firstWhere((element) {
        return element.key.name.toLowerCase() ==
            item.value["category"].toString().toLowerCase();
      }).value;

      list.add(GroceryItem(
        id: item.key,
        name: item.value["name"],
        category: transformedCategory,
        quantity: item.value["quantity"],
      ));
    }

    setState(() {
      isLoading = false;
      groceries = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => NewGroceryScreen(
                    addNewGrocery: addNewGrocery,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: !isLoading
          ? groceries.isEmpty
              ? const Center(
                  child: Text("No Groceries added yet"),
                )
              : ListView.builder(
                  itemCount: groceries.length,
                  itemBuilder: (ctx, index) => Dismissible(
                    key: ValueKey(
                      groceries[index],
                    ),
                    onDismissed: (direction) async {
                      GroceryItem removedItem = groceries[index];
                      setState(() {
                        groceries.remove(groceries[index]);
                      });

                      Uri url = Uri.https(
                          "shopping-list-flutter-practice-default-rtdb.asia-southeast1.firebasedatabase.app",
                          "shopping-list/${removedItem.id}.json");
                      Response result = await http.delete(url);

                      if (result.statusCode >= 400) {
                        groceries.insert(index, removedItem);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Grocery Item Removed"),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: "Undo",
                                onPressed: () async {
                                  // Inserting the item again because of UNDO.
                                  url = Uri.https(
                                      "shopping-list-flutter-practice-default-rtdb.asia-southeast1.firebasedatabase.app",
                                      "shopping-list.json");

                                  result = await http.post(
                                    url,
                                    headers: {
                                      "Content-Type": "application/json",
                                    },
                                    body: json.encode(
                                      {
                                        'name': removedItem.name,
                                        'quantity': removedItem.quantity,
                                        'category': removedItem.category.title
                                      },
                                    ),
                                  );

                                  setState(
                                    () {
                                      groceries.insert(
                                        index,
                                        GroceryItem(
                                          id: json.decode(result.body)["name"],
                                          name: removedItem.name,
                                          quantity: removedItem.quantity,
                                          category: removedItem.category,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: ListTile(
                      leading: Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          color: groceries[index].category.color,
                        ),
                      ),
                      title: Text(groceries[index].name),
                      trailing: Text(
                        groceries[index].quantity.toString(),
                      ),
                    ),
                  ),
                )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
