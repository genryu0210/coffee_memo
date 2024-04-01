import 'dart:io';

import 'package:coffee_memo/screen/jn_edit_screen.dart';
import 'package:coffee_memo/utils.dart';
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
  final table = 'JournalTable';
  Map<String, dynamic>? itemDetails;
  Map<String, String> japaneseTitles = Utils().japaneseTitles;
  List columns = [];

  @override
  void initState() {
    super.initState();
    _refreshItem();
    _initColumns();
  }

  void _initColumns() {
    columns = dbHelper.journalColumns
        .where((column) => column != 'id' && column != 'imagePath')
        .toList();
  }

  void _refreshItem() async {
    final data = await dbHelper.queryItemById(table, widget.itemId);
    setState(() {
      itemDetails = data;
    });
  }

  void _showDeleteDialog(BuildContext context) {
    // データベース削除の確認ダイアログを表示
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('削除しますか？'),
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
        // title: Text(itemDetails!['name']),
        backgroundColor: Theme.of(context).primaryColor, // 項目の名前をタイトルとして表示
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columns.map<Widget>((element) {
                return Text(
                    '${japaneseTitles[element]}: ${itemDetails![element]}',
                    style: TextStyle(fontSize: 18));
              }).toList(),
            ),
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
                          builder: (context) => EditScreen(item: itemDetails!)),
                    );
                    _refreshItem();
                  },
                  child: const Text("編集"),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _showDeleteDialog(context),
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
