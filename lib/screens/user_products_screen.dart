import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/products.dart';
import 'package:shop_app/screens/edit_product_screen.dart';
import 'package:shop_app/widgets/app_drawer.dart';
import 'package:shop_app/widgets/user_product_item.dart';

import '../providers/product.dart';

class UserProductsScreen extends StatelessWidget {
  static const routeName = '/user-products-screen';

  const UserProductsScreen({Key? key}) : super(key: key);

  Future<void> _refreshProducts(BuildContext ctx) async {
    await Provider.of<Products>(ctx, listen: false).fetchAndSetProducts();
  }

  @override
  Widget build(BuildContext context) {
    //final Products products = Provider.of<Products>(context)..fetchAndSetProducts();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Products'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(
              EditProductScreen.routeName,
              arguments: {'title': 'Add Product'},
            ),
            icon: const Icon(Icons.add),
          )
        ],
      ),
      drawer: AppDrawer(),
      body: FutureBuilder(
        future: Provider.of<Products>(context, listen: false).fetchAndSetProducts(),
        builder: (BuildContext ctx, AsyncSnapshot<dynamic> snapshot) {
          return Consumer<Products>(
            builder: (context, value, child) {
              if (snapshot.connectionState==ConnectionState.done) {
                return RefreshIndicator(
                  onRefresh: () => _refreshProducts(context),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: ListView.builder(
                      itemBuilder: (ctx, i) {
                        Product p = value.items[i];
                        return Column(
                          children: [
                            UserProductItem(
                              id: p.id,
                              title: p.title,
                              imageUrl: p.imageUrl,
                            ),
                            Divider(
                              thickness: 1.5,
                            ),
                          ],
                        );
                      },
                      itemCount: value.items.length,
                    ),
                  ),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          );
        },
      ),
    );
  }
}
