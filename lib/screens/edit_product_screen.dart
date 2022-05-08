import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/product.dart';

import '../providers/products.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({Key? key}) : super(key: key);
  static const routeName = '/edit-product-screen';

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageUrlController = TextEditingController();
  final _imageUrlFocusNode = FocusNode();
  final _form = GlobalKey<FormState>();
  final _editedProduct = _MutableProduct();
  late final String _title;
  var _isInit = true;
  var _isLoading = false;

  @override
  void initState() {
    _imageUrlFocusNode.addListener(_updateImageUrl);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final settings = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _title = settings['title'] as String;
      String? _id = settings['id']; //null if new item
      if (_id != null) {
        final product = Provider.of<Products>(context, listen: false).findById(_id);
        _editedProduct.id = product.id;
        _editedProduct.title = product.title;
        _editedProduct.price = product.price;
        _editedProduct.description = product.description;
        _editedProduct.imageUrl = product.imageUrl;
        _editedProduct.isFavorite = product.isFavorite;
        _imageUrlController.text = product.imageUrl;
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _updateImageUrl() {
    if (!_imageUrlFocusNode.hasFocus) {
      setState(() {});
    }
  }

  Future<void> _saveForm() async {
    if (_form.currentState!.validate()) {
      _form.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      final product = Product(
        id: _editedProduct.id ?? '0',
        title: _editedProduct.title,
        description: _editedProduct.description,
        price: _editedProduct.price,
        imageUrl: _editedProduct.imageUrl,
        isFavorite: _editedProduct.isFavorite,
      );
      if (_editedProduct.id == null) {
        try {
          await Provider.of<Products>(context, listen: false).addProduct(product);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product ${product.title} was added')));
          Navigator.of(context).pop();
        } catch (error) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('An error occurred'),
              content: Text('Something went wrong'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    //Navigator.of(context).pop();
                  },
                  child: Text('Okay'),
                ),
              ],
            ),
          );
        }
      } else {
        await Provider.of<Products>(context, listen: false).updateProduct(product.id, product);
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product ${product.title} was updated')));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _imageUrlFocusNode.removeListener(_updateImageUrl);
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageUrlController.dispose();
    _imageUrlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //var settings = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    return Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            IconButton(
              onPressed: () {
                _saveForm();
              },
              icon: Icon(Icons.save),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _form,
                  child: ListView(
                    children: [
                      TextFormField(
                        initialValue: _editedProduct.title,
                        decoration: InputDecoration(labelText: 'Title'),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (value) {
                          FocusScope.of(context).requestFocus(_priceFocusNode);
                        },
                        onSaved: (value) {
                          _editedProduct.title = value ?? '';
                        },
                        validator: (s) {
                          if (s!.isEmpty) return 'Please, enter a title';
                          return null;
                        },
                      ),
                      TextFormField(
                        initialValue: _editedProduct.price.toStringAsFixed(2) != '0.00' ? _editedProduct.price.toStringAsFixed(2) : '',
                        decoration: InputDecoration(labelText: 'Price'),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        focusNode: _priceFocusNode,
                        onFieldSubmitted: (value) {
                          FocusScope.of(context).requestFocus(_descriptionFocusNode);
                        },
                        onSaved: (value) {
                          _editedProduct.price = double.tryParse(value ?? '0') ?? 0;
                        },
                        validator: (s) {
                          if (s!.isEmpty) return 'Please, enter a price';
                          if (double.tryParse(s) == null) return 'Please, enter a valid price';
                          if (double.tryParse(s)! <= 0) return 'Please enter a number greater then zero';
                          return null;
                        },
                      ),
                      TextFormField(
                        initialValue: _editedProduct.description,
                        decoration: InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        focusNode: _descriptionFocusNode,
                        onSaved: (value) {
                          _editedProduct.description = value ?? '';
                        },
                        validator: (s) {
                          s = s!.trim();
                          if (s.isEmpty) return 'Please, enter a description';
                          if (s.length < 10) return 'Should be at least 10 characters long';
                          return null;
                        },
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: EdgeInsets.only(top: 8, right: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 1,
                                color: Colors.grey,
                              ),
                            ),
                            child: _imageUrlController.text.isEmpty
                                ? Text('Enter an URL')
                                : Image.network(
                                    _imageUrlController.text,
                                    errorBuilder: (ctx, o, st) => Image.network('https://demofree.sirv.com/nope-not-here.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Expanded(
                            child: TextFormField(
                              onEditingComplete: () => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Image URL',
                              ),
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              controller: _imageUrlController,
                              focusNode: _imageUrlFocusNode,
                              onSaved: (value) {
                                _editedProduct.imageUrl = value ?? '';
                              },
                              validator: (s) {
                                if (s!.isEmpty) return 'Please enter an image URL';
                                if (!s.startsWith('http:') && !s.startsWith('https:')) return 'Please enter a valid URL';
                                return null;
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ));
  }
}

class _MutableProduct {
  String? id;
  String title;
  String description;
  double price;
  String imageUrl;
  bool isFavorite;

  _MutableProduct({
    this.id,
    this.title = '',
    this.description = '',
    this.price = 0,
    this.imageUrl = '',
    this.isFavorite = false,
  });
}
