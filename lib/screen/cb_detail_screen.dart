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
  late String roastLevel;

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
    if (controllers["roastLevel"]!.text != '-1') {
    roastLevel = '${Utils().roastLevels[(int.parse(controllers["roastLevel"]!.text))]}ロースト';  
    } else {
      roastLevel = '';
    }
    
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

  Widget Function(String key, double value,
          Map<String, TextEditingController> controllers) customTextField =
      Utils().customTextField;

  Widget makeCustomTextField(String key, double value) {
    return customTextField(key, value, controllers);
  }

  Widget Function(File? _storedImage, VoidCallback? onTap) beansImage =
      Utils.beansImage;

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
                  child: beansImage(
                      itemDetails!['imagePath'].isNotEmpty
                          ? File(itemDetails!['imagePath'])
                          : null,
                      null),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      makeCustomTextField('name', screenWidth * 0.5),
                      makeCustomTextField('store', screenWidth * 0.5),
                    ],
                  ),
                ),
              ],
            ),
            makeCustomTextField('description', screenWidth * 0.9),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: makeCustomTextField('purchaseDate', screenWidth * 0.4),
                ),
                Container(
                  padding: EdgeInsets.only(right: 16.0),
                ),
                Expanded(
                  child: makeCustomTextField('price', screenWidth * 0.4),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: makeCustomTextField('origin', screenWidth * 0.5)),
                Container(
                  padding: EdgeInsets.only(right: 16.0),
                ),
                Expanded(child: makeCustomTextField('farmName', screenWidth * 0.5))
              ],
            ),
            makeCustomTextField('variety', screenWidth / 2 - 32),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '焙煎度',
                style: TextStyle(fontSize: 16),
              ),
            ),
            Container(
              height: 34,
              child: Text(roastLevel),
            ),
            makeCustomTextField('body', screenWidth / 2 - 32),
            makeCustomTextField('acidity', screenWidth / 2 - 32),
            Row(
              children: [
                makeCustomTextField('story', screenWidth / 2 - 32),
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
