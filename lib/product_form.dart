import 'package:flutter/material.dart';
import 'database_helper.dart';

import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({super.key});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  int? _productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CRUD Products'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _productPriceController,
                decoration: InputDecoration(labelText: 'Product Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveOrUpdateProduct();
                  }
                },
                child: Text(
                    _productId == null ? 'Save Product' : 'Update Product'),
              ),
              SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: DatabaseHelper().queryAllProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final products = snapshot.data!;
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(products[index]['name']),
                          subtitle: Text(products[index]['price'].toString()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _loadProductForEditing(products[index]);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _deleteProduct(products[index]['id']);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.print),
                                onPressed: () {
                                  _printProduct(products[index]);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveOrUpdateProduct() async {
    if (_productId == null) {
      // Save new product
      Map<String, dynamic> row = {
        'name': _productNameController.text,
        'price': double.tryParse(_productPriceController.text),
      };
      await DatabaseHelper().insertProduct(row);
    } else {
      // Update existing product
      Map<String, dynamic> row = {
        'id': _productId,
        'name': _productNameController.text,
        'price': double.tryParse(_productPriceController.text),
      };
      await DatabaseHelper().updateProduct(row);
    }
    _clearForm();
    setState(() {});
  }

  void _clearForm() {
    _productNameController.clear();
    _productPriceController.clear();
    _productId = null;
  }

  void _loadProductForEditing(Map<String, dynamic> product) {
    _productNameController.text = product['name'];
    _productPriceController.text = product['price'].toString();
    _productId = product['id'];
  }

  void _deleteProduct(int id) async {
    await DatabaseHelper().deleteProduct(id);
    setState(() {});
  }

  void _printProduct(Map<String, dynamic> product) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Product Details', style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 20),
                pw.Text('Name: ${product['name']}',
                    style: pw.TextStyle(fontSize: 18)),
                pw.Text('Price: ${product['price']}',
                    style: pw.TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );

    Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
