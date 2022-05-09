import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
  });

  Future<void> toggleFavoriteStatus(String? token, String? userId) async {
    final uri = Uri.https(
      'shop-flutter-c082a-default-rtdb.firebaseio.com',
      '/userFavorites/$userId/$id.json',
      {'auth': token},
    );
    final oldIsFavorite = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();
    try {
      final response = await http.put(uri, body: json.encode(isFavorite));
      if (response.statusCode >= 400) {
        isFavorite = oldIsFavorite;
        notifyListeners();
        log('Try to change favorite status. Error code ${response.statusCode}');
      }
    } catch (e) {
      isFavorite = oldIsFavorite;
      notifyListeners();
      log(e.toString());
    }
  }
}
