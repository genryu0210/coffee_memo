import 'dart:io';

import 'package:coffee_memo/screen/cb_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';

class DetailScreen extends StatefulWidget {
  final int itemId;
  DetailScreen({required this.itemId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final dbHelper = DatabaseHelper.instance;
  final table = 'CoffeeBeansTable';
  Map<String, dynamic>? itemDetails;

  @override
  void initState() {
    super.initState();
    _refreshItem();
  }

  void _refreshItem() async {
    final data = await dbHelper.queryItemById(table, widget.itemId);
    setState(() {
      itemDetails = data;
    });
  }

  void _showDeleteDialog(BuildContext context, String name) {
    // データベース削除の確認ダイアログを表示
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${name}を削除しますか？'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('この操作は元に戻せません。'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('削除'),
              onPressed: () async {
                // データベース削除処理
                await dbHelper.delete(table, itemDetails!['id']);
                // Navigator.of(context).pop(true);
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (itemDetails == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()), // ロード中のインジケータを表示
      );
    }
    return Scaffold(
      appBar: AppBar(
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('名前: ${itemDetails!['name']}', style: TextStyle(fontSize: 20)),
            Text('産地: ${itemDetails!['origin']}',
                style: TextStyle(fontSize: 18)),
            Text('購入店: ${itemDetails!['store']}',
                style: TextStyle(fontSize: 18)),
            Text('購入日: ${itemDetails!['purchaseDate']}',
                style: TextStyle(fontSize: 18)),
            Text('更新日: ${itemDetails!['updateDate']}',
                style: TextStyle(fontSize: 18)),
            Text('価格: ${itemDetails!['price']}',
                style: TextStyle(fontSize: 18)),
            Text('購入したグラム数: ${itemDetails!['purchasedGrams']}',
                style: TextStyle(fontSize: 18)),
            Text('農園名: ${itemDetails!['farmName']}',
                style: TextStyle(fontSize: 18)),
            Text('品種: ${itemDetails!['variety']}',
                style: TextStyle(fontSize: 18)),
            Text('焙煎度: ${itemDetails!['roastLevel']}',
                style: TextStyle(fontSize: 18)),
            Text('ボディ: ${itemDetails!['body']}',
                style: TextStyle(fontSize: 18)),
            Text('酸味: ${itemDetails!['acidity']}',
                style: TextStyle(fontSize: 18)),
            Text('ストーリー: ${itemDetails!['story']}',
                style: TextStyle(fontSize: 18)),
            // 画像を表示
// 画像を表示する部分
            itemDetails!['imagePath'] != null &&
                    itemDetails!['imagePath'].isNotEmpty
                ? Image.file(
                    File(itemDetails!['imagePath']),
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/placeholder.jpg',
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  ),

            // 他の詳細情報もここに追加
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => EditScreen(itemId: itemDetails!["id"])),
                    );
                    _refreshItem();
                  },
                  child: const Text("編集"),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _showDeleteDialog(context, itemDetails!['name']),
                  child: const Text("削除"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
