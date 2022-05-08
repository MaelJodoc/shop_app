import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shop_app/providers/cart.dart';
import 'package:http/http.dart' as http;

class Orders with ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => [..._orders];

  Future<void> fetchAndSetOrders() async {
    final uri = Uri.https('shop-flutter-c082a-default-rtdb.firebaseio.com', '/orders.json');
    final response = await http.get(uri);
    //print(jsonDecode(response.body.toString()));
    final List<Order> loaderOrders = [];
    final data = json.decode(response.body) as Map<String, dynamic>?;
    if (data == null) return;
    data.forEach((key, value) {
      Order order = Order(
        id: key,
        amount: value['amount'],
        dateTime: DateTime.parse(value['dateTime']),
        products: (value['products'] as List)
            .map((e) => CartItem(
                  id: e['id'],
                  title: e['title'],
                  quantity: e['quantity'],
                  price: e['price'],
                ))
            .toList(),
      );
      loaderOrders.add(order);
    });
    _orders.clear();
    _orders.addAll(loaderOrders.reversed);
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final uri = Uri.https('shop-flutter-c082a-default-rtdb.firebaseio.com', '/orders.json');
    final dateTimeNow = DateTime.now();

    final response = await http.post(
      uri,
      body: jsonEncode(
        {
          'amount': total,
          'dateTime': dateTimeNow.toIso8601String(),
          'products': cartProducts
              .map(
                (e) => {
                  'id': e.id,
                  'title': e.title,
                  'quantity': e.quantity,
                  'price': e.price,
                },
              )
              .toList(),
        },
      ),
    );
    _orders.insert(
      0,
      Order(
        id: jsonDecode(response.body)['name'],
        amount: total,
        products: cartProducts,
        dateTime: dateTimeNow,
      ),
    );
    notifyListeners();
  }
}

class Order {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  Order({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });
}
