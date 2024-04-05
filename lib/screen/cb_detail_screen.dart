import 'dart:io';

import 'package:coffee_memo/screen/cb_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:coffee_memo/utils.dart';

class DetailScreen extends StatefulWidget {
  final int itemId;
  const DetailScreen({super.key, required this.itemId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final dbHelper = DatabaseHelper.instance;
  final table = 'CoffeeBeansTable';
  Map<String, dynamic>? itemDetails;
  Map<String, TextEditingController> controllers = {};
  final japaneseTitles = Utils().japaneseTitles;

  @override
  void initState() {
    super.initState();
    _refreshItem();
  }

  void _refreshItem() async {
    final data = await dbHelper.queryItemById(table, widget.itemId);
    setState(() {
      itemDetails = data;
      _initControllers();
    });
  }

  void _initControllers() {
    itemDetails?.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.toString());
    });
  }

  void _showDeleteDialog(BuildContext context, String name) {
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

  Widget beansImage() {
    Image WidgetImage;
    if (itemDetails!['imagePath'] != null) {
      File imageFile = File(itemDetails!['imagePath']);
      WidgetImage = Image.file(
        imageFile,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else {
      WidgetImage = Image.asset(
        'assets/placeholder.jpg', // プレースホルダー画像へのパス
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(width: 1.0),
      ),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(30), child: WidgetImage),
    );
  }

  Widget customTextField(String key, double value) {
    return SizedBox(
      width: value,
      child: TextField(
        readOnly: true,
        controller: controllers[key],
        decoration: InputDecoration(
          labelText: japaneseTitles[key],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (itemDetails == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()), // ロード中のインジケータを表示
      );
    }
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 32, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: beansImage(),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customTextField('name', screenWidth * 0.5),
                      customTextField('store', screenWidth * 0.5),
                    ],
                  ),
                ),
              ],
            ),
            customTextField('description', screenWidth * 0.9),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: customTextField('purchaseDate', screenWidth * 0.4),
                ),
                Container(
                  padding: EdgeInsets.only(right: 16.0),
                ),
                Expanded(
                  child: customTextField('price', screenWidth * 0.4),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: customTextField('origin', screenWidth * 0.5)),
                Container(
                  padding: EdgeInsets.only(right: 16.0),
                ),
                Expanded(child: customTextField('farmName', screenWidth * 0.5))
              ],
            ),
            customTextField('variety', screenWidth / 2 - 32),
            customTextField('roastLevel', screenWidth / 2 - 32),
            customTextField('body', screenWidth / 2 - 32),
            customTextField('acidity', screenWidth / 2 - 32),
            Row(
              children: [
                customTextField('story', screenWidth / 2 - 32),
                Expanded(
                  child: Container(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  EditScreen(itemId: itemDetails!["id"])),
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
          ],
        ),
      ),
    );
  }
}
