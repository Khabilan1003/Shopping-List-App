import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/model/category.dart';
import 'package:shopping_list_app/model/grocery_item.dart';
import 'package:http/http.dart' as http;

class NewGroceryScreen extends StatefulWidget {
  const NewGroceryScreen({super.key, required this.addNewGrocery});
  final void Function(GroceryItem) addNewGrocery;
  @override
  State<NewGroceryScreen> createState() => _NewGroceryScreenState();
}

class _NewGroceryScreenState extends State<NewGroceryScreen> {
  final _formKey = GlobalKey<FormState>();

  String enteredName = "";
  int quantity = 1;
  Category selectedCategory = categories[Categories.vegetables]!;
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Grocery"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  maxLength: 50,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(label: Text("Title")),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().isEmpty) {
                      return "Title should be between 1 to 50 characters";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    enteredName = value!;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        initialValue: "1",
                        decoration: const InputDecoration(
                          label: Text("Quantity"),
                        ),
                        validator: (value) {
                          if (value == null ||
                              int.tryParse(value) == null ||
                              int.tryParse(value)! < 1) {
                            return "Quantity Should be a positive number";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          quantity = int.parse(value!);
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: DropdownButtonFormField(
                        value: selectedCategory,
                        items: [
                          for (final category in categories.entries)
                            DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Container(
                                    height: 24,
                                    width: 24,
                                    color: category.value.color,
                                  ),
                                  const SizedBox(
                                    width: 16,
                                  ),
                                  Text(category.key.name)
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                        validator: (value) {
                          return null;
                        },
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              _formKey.currentState!.reset();
                            },
                      child: const Text("Reset"),
                    ),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                setState(() {
                                  isSaving = true;
                                });
                                final Uri url = Uri.https(
                                    "shopping-list-flutter-practice-default-rtdb.asia-southeast1.firebasedatabase.app",
                                    "shopping-list.json");

                                final result = await http.post(
                                  url,
                                  headers: {
                                    "Content-Type": "application/json",
                                  },
                                  body: json.encode(
                                    {
                                      'name': enteredName,
                                      'quantity': quantity,
                                      'category': selectedCategory.title
                                    },
                                  ),
                                );

                                if (result.statusCode == 200 &&
                                    context.mounted) {
                                  widget.addNewGrocery(GroceryItem(
                                      id: json.decode(result.body)["name"],
                                      name: enteredName,
                                      quantity: quantity,
                                      category: selectedCategory));
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                      child: isSaving
                          ? const CircularProgressIndicator()
                          : const Text("Add Grocery"),
                    ),
                  ],
                )
              ],
            )),
      ),
    );
  }
}
