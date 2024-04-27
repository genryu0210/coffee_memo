import 'dart:io';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:coffee_memo/screen/cb_insert_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:coffee_memo/screen/cb_detail_screen.dart';

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
      extendBodyBehindAppBar: true,

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbHelper.queryAllRows(table),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 1行に表示するアイテム数
                childAspectRatio: 4 / 6, // アイテムの縦横比
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 0.8,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0), // 角の丸み
                          side: BorderSide(width: 0.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailScreen(itemId: _items[index]['id']),
                              ),
                            );
                            _refreshItems();
                          },
                          child: _items[index]['imagePath'] != null &&
                                  _items[index]['imagePath'].isNotEmpty
                              ? Image.file(
                                  File(_items[index]['imagePath']),
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/placeholder.jpg',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    Text(
                      _items[index]['name'],
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text("エラーが発生しました");
          }
          return Center(child: CircularProgressIndicator());
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
