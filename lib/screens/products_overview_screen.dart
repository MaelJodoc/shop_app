import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/cart.dart';
import 'package:shop_app/providers/products.dart';
import 'package:shop_app/screens/cart_screen.dart';
import 'package:shop_app/widgets/app_drawer.dart';
import 'package:shop_app/widgets/badge.dart';
import '../widgets/products_grid.dart';

enum FilterOptions { favorites, all }

class ProductsOverviewScreen extends StatefulWidget {
  static const routeName = '/products-overview-screen';

  const ProductsOverviewScreen({Key? key}) : super(key: key);

  @override
  State<ProductsOverviewScreen> createState() => _ProductsOverviewScreenState();
}

class _ProductsOverviewScreenState extends State<ProductsOverviewScreen> {
  bool _showFavoritesOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    final products = Provider.of<Products>(context, listen: false);
    products.fetchAndSetProducts(onlyUsersProducts: false).then((_) => setState(() => _isLoading = false));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //final products = Provider.of<Products>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shop'),
        actions: [
          Consumer<Cart>(
            builder: (ctx, cart, ch) {
              return Badge(
                child: ch!,
                color: Theme.of(context).colorScheme.secondary,
                value: cart.itemsCount.toString(),
              );
            },
            child: IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.of(context).pushNamed(CartScreen.routeName);
              },
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            onSelected: (FilterOptions f) {
              setState(() {
                switch (f) {
                  case FilterOptions.all:
                    _showFavoritesOnly = false;
                    break;
                  case FilterOptions.favorites:
                    _showFavoritesOnly = true;
                    break;
                }
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                child: Text('Favorites Only'),
                value: FilterOptions.favorites,
              ),
              const PopupMenuItem(
                child: Text('All'),
                value: FilterOptions.all,
              ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ProductsGrid(_showFavoritesOnly),
    );
  }
}
