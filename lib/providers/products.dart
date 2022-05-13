import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shop_app/exceptions/http_exception.dart';
import './product.dart';
import 'package:http/http.dart' as http;

import 'auth.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
/*    Product(
      id: 'p1',
      title: 'Red Shirt',
      description: 'A red shirt - it is pretty red!',
      price: 29.99,
      imageUrl: 'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    ),
    Product(
      id: 'p2',
      title: 'Trousers',
      description: 'A nice pair of trousers.',
      price: 59.99,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    ),
    Product(
      id: 'p3',
      title: 'Yellow Scarf',
      description: 'Warm and cozy - exactly what you need for the winter.',
      price: 19.99,
      imageUrl: 'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    ),
    Product(
      id: 'p4',
      title: 'A Pan',
      description: 'Prepare any meal you want.',
      price: 49.99,
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    ),*/
  ];
  String? _token;
  String? _userId;

  String? get token => _token;

  updateAuth(Auth auth) {
    _token = auth.token;
    _userId = auth.userId;
  }

  List<Product> get items {
    return List.of(_items);
  }

  List<Product> get favoriteItems {
    return _items.where((element) => element.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((item) => item.id == id);
  }

  Future<void> fetchAndSetProducts({bool onlyUsersProducts = true}) async {
    final queryParams = onlyUsersProducts
        ? {
            'auth': _token,
            'orderBy': '"creatorId"',
            'equalTo': '"$_userId"',
          }
        : {
            'auth': _token,
          };
    var uri = Uri.https(
      'shop-flutter-c082a-default-rtdb.firebaseio.com',
      '/products.json',
      queryParams,
    );
    log(uri.toString());
    try {
      final Response response = await http.get(uri);
      log(response.body);
      final responseMap = json.decode(response.body) as Map<String, dynamic>?;
      if (responseMap == null) return;
      uri = Uri.https(
        'shop-flutter-c082a-default-rtdb.firebaseio.com',
        '/userFavorites/$_userId/.json',
        {'auth': _token},
      );
      final responseFavs = await http.get(uri);
      final favsMap = json.decode(responseFavs.body) as Map<String, dynamic>?;

      //print(response.body);
      final List<Product> loadedProducts = [];
      responseMap.forEach((key, value) {
        final double price;
        if (value['price'] is double) {
          price = value['price'];
        } else if (value['price'] is int) {
          price = value['price'] * 1.0;
        } else {
          price = double.parse(value['price']);
        }
        loadedProducts.add(
          Product(
            id: key,
            title: value['title'],
            description: value['description'],
            price: price,
            imageUrl: value['imageUrl'],
            isFavorite: favsMap == null ? false : favsMap[key] ?? false,
          ),
        );
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> addProduct(Product product) async {
    final uri = Uri.https(
      'shop-flutter-c082a-default-rtdb.firebaseio.com',
      '/products.json',
      {
        'auth': {_token}
      },
    );
    try {
      Response response = await http.post(
        uri,
        body: json.encode(
          {
            'title': product.title,
            'description': product.description,
            'price': product.price.toStringAsFixed(2),
            'imageUrl': product.imageUrl,
            //'isFavorite': product.isFavorite,
            'creatorId': _userId,
          },
        ),
      );
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      log(error.toString());
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    int index = _items.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      final uri = Uri.https(
        'shop-flutter-c082a-default-rtdb.firebaseio.com',
        '/products/$id.json',
        {
          'auth': {_token}
        },
      );
      await http.patch(
        uri,
        body: json.encode(
          {
            'title': product.title,
            'description': product.description,
            'price': product.price,
            //'isFavorite': product.isFavorite,
            'imageUrl': product.imageUrl,
          },
        ),
      );
      _items[index] = product;
      notifyListeners();
    } else {
      log('No item with current id');
    }
  }

  Future<void> deleteProduct(String id) async {
    final uri = Uri.https(
      'shop-flutter-c082a-default-rtdb.firebaseio.com',
      '/products/$id.json',
      {
        'auth': {_token}
      },
    );
    final index = _items.indexWhere((e) => e.id == id);
    final item = _items.elementAt(index);
    _items.removeAt(index);
    notifyListeners();
    final response = await http.delete(uri);
    if (response.statusCode >= 400) {
      _items.insert(index, item);
      notifyListeners();
      throw HttpException('Could not delete a product. Code ${response.statusCode}');
    }
    //item=null;
  }
}
