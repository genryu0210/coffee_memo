import 'dart:io';
import 'dart:ui';

import 'package:coffee_memo/screen/cb_edit_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:coffee_memo/utils.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

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
  late int bodyLevel;
  late int acidityLevel;

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
      roastLevel =
          '${Utils().roastLevels[(int.parse(controllers["roastLevel"]!.text))]}ロースト';
    } else {
      roastLevel = '';
    }

    bodyLevel = int.parse(controllers['body']!.text);
    acidityLevel = int.parse(controllers['acidity']!.text);
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

  Widget textBox(String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          japaneseTitles[key]!,
          style: TextStyle(fontSize: 16),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.black, width: 1.0))),
                  child: Text(
                    itemDetails![key],
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget Function(File? _storedImage, VoidCallback? onTap) beansImage =
      Utils.beansImage;

  Widget tasteLevel(String taste) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          japaneseTitles[taste]!,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(
          height: 34,
          child: Row(
            children: List.generate(
              5,
              (index) => _buildBodyIcon(taste, index + 1),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildBodyIcon(String taste, int level) {
    int currentIndex = _getCurrentIndex(taste);
    return IconButton(
      icon: Icon(
        Icons.star,
        color: currentIndex >= level ? Colors.amber : Colors.grey,
      ),
      onPressed: () {},
    );
  }

  int _getCurrentIndex(String taste) {
    switch (taste) {
      case 'body':
        return bodyLevel;
      case 'acidity':
        return acidityLevel;
      // 他の味覚の場合も同様に追加
      default:
        return -1;
    }
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
                      textBox('name'),
                      textBox('purchaseDate'),
                    ],
                  ),
                ),
              ],
            ),
            textBox('description'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: textBox('store'),
                ),
                Container(
                  padding: EdgeInsets.only(right: 16.0),
                ),
                Expanded(
                  child: textBox('price'),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: textBox('origin')),
                Container(
                  padding: EdgeInsets.only(right: 16.0),
                ),
                Expanded(child: textBox('farmName'))
              ],
            ),
            Row(
              children: [
                Expanded(child: textBox('variety')),
                SizedBox(
                  width: 16
                ),
                Expanded(child: Container()),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Text(
              '焙煎度',
              style: TextStyle(fontSize: 16),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                roastLevel,
                style: TextStyle(fontSize: 16),
              ),
            ),
            tasteLevel('body'),
            tasteLevel('acidity'),
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
