import 'dart:io';

import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:coffee_memo/screen/jn_insert_screen.dart';
import 'jn_detail_screen.dart';

class JournalHomeScreen extends StatefulWidget {
  @override
  State<JournalHomeScreen> createState() => _JournalHomeScreenState();
}

class _JournalHomeScreenState extends State<JournalHomeScreen> {
  final dbHelper = DatabaseHelper.instance;
  final table = 'JournalTable';
 late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() async {
    final data = await dbHelper.queryAllRows(table);
    setState(() {
      _items = data.reversed.toList();

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbHelper.queryAllRows(table),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1, // 1行に表示するアイテム数
                childAspectRatio: 4 / 1, // アイテムの縦横比
                mainAxisSpacing: 0, 

              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    AspectRatio(
                      aspectRatio: 4.0,
                      child: Card(
                        margin: EdgeInsets.zero,
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
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _items[index]['deviceUsed'],
                        style: TextStyle(
                          fontSize: 16,
                        ),
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
