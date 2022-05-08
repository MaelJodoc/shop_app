import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;

  CartItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.price,
  });
}

class Cart with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => Map<String, CartItem>.of(_items);

  int get itemsCount {
    return _items.keys.length;
  }

  double get totalAmount {
    return _items.values.fold(0, (previousValue, element) => previousValue + element.quantity * element.price);
  }

  void removeItemById(String id) {
    var entry = _items.entries.firstWhere((e) => e.value.id == id);
    _items.remove(entry.key);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    CartItem? item = _items[productId];
    if (item == null) return;
    if (item.quantity == 1) {
      _items.remove(productId);
    } else {
      _items.update(
        productId,
        (item) => CartItem(
          id: item.id,
          title: item.title,
          quantity: item.quantity - 1,
          price: item.price,
        ),
      );
    }
    notifyListeners();
  }

  void addItem(String productId, String title, double price) {
    _items.update(
      productId,
      (item) => CartItem(
        id: item.id,
        title: item.title,
        quantity: item.quantity + 1,
        price: item.price,
      ),
      ifAbsent: () => CartItem(
        id: DateTime.now().toString(),
        title: title,
        quantity: 1,
        price: price,
      ),
    );
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
