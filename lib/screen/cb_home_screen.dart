import 'dart:io';

import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:coffee_memo/screen/cb_insert_screen.dart';
import 'cb_detail_screen.dart';

class CoffeeBeansHomeScreen extends StatefulWidget {
  @override
  State<CoffeeBeansHomeScreen> createState() => _CoffeeBeansHomeScreenState();
}

class _CoffeeBeansHomeScreenState extends State<CoffeeBeansHomeScreen> {
  final dbHelper = DatabaseHelper.instance;
  final table = 'CoffeeBeansTable';
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() async {
    final data = await dbHelper.queryAllRows(table);
    setState(() {
      _items = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbHelper.queryAllRows(table),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ListTile(
                    title: Text(_items[index]['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Text(_items[index]['origin']), // 産地
                        Text(_items[index]['store']), // 購入したお店
                        // 他のデータもここに追加
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            DetailScreen(itemId: _items[index]['id']),
                      ));
                      _refreshItems(); // リストを更新
                    },
                    leading: _items[index]['imagePath'] != null && _items[index]['imagePath'].isNotEmpty
                        ? Image.file(
                            File(_items[index]['imagePath']),
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                          )
                        : Image.asset(
                            'assets/placeholder.jpg',
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                          ),
                    trailing: Icon(Icons.arrow_forward));
              },
            );
          } else if (snapshot.hasError) {
            return Text("エラーが発生しました");
          }
          return CircularProgressIndicator();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => InsertScreen()),
          );
          _refreshItems();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
