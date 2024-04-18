import 'dart:io';

import 'package:coffee_memo/screen/jn_edit_screen.dart';
import 'package:coffee_memo/utils.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:intl/intl.dart';

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
  Map<String, dynamic>? _beanDetails;
  final japaneseTitles = Utils().japaneseTitles;
  Map<String, int> tasteIndexMap = {
    'overall': -1,
    'body': -1,
    'acidity': -1,
    'sweetness': -1, // 例として「甘みの指数」を追加
    'bitterness': -1, // 「苦味の指数」を追加
    'aroma': -1, // 「香りの指数」を追加
  };

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
    getBeansDetails();
  }

  void getBeansDetails() async {
    if (itemDetails!['usedBeans'] != null) {
      var beanDetails = await dbHelper.queryItemById(
          'CoffeeBeansTable', itemDetails!['usedBeans']);
      setState(() {
        _beanDetails = beanDetails;
      });
    }
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
          japaneseTitles['${taste}Score']!,
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
    if(itemDetails!['${taste}Score'] == null) {
      print("err");
    }
    int currentIndex = itemDetails!['${taste}Score'];
    return IconButton(
      icon: Icon(
        Icons.local_cafe,
        color: currentIndex >= level ? Colors.amber : Colors.grey,
      ),
      onPressed: () {
      },
    );
  }

  Widget tasteScores(String taste) {
    return Column(
      children: [textBox('${taste}Memo'), tasteLevel(taste)],
    );
  }

  Widget coffeeBeanDetailsCard(Map<String, dynamic>? beanDetails) {
    if (beanDetails == null || beanDetails.isEmpty) return SizedBox();
    return Visibility(
      visible: beanDetails.isNotEmpty,
      child: Card(
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("購入店: ${beanDetails['store']}"),
              Text(
                  "購入日: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(beanDetails['purchaseDate']))}"),
              Row(
                children: [
                  Expanded(child: Text("焙煎度: ${beanDetails['roastLevel']}")),
                  Expanded(child: Text("精製方法: ${beanDetails['process']}")),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text("ボディ: ${beanDetails['body']}")),
                  Expanded(child: Text("酸味: ${beanDetails['acidity']}")),
                ],
              ),
              // 他の必要な情報もここに追加
            ],
          ),
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
                  padding: EdgeInsets.only(left: 8.0, right: 8.0),
                  child: beansImage(
                      itemDetails!['imagePath'].isNotEmpty
                          ? File(itemDetails!['imagePath'])
                          : null,
                      null),
                ),
                Container(
                  padding: EdgeInsets.only(left: 16),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          japaneseTitles['usedBeans']!,
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
                    _beanDetails?['name'] ?? '',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ), 
                      
                      textBox('brewDate')
                    ],
                  ),
                ),
              ],
            ),
            coffeeBeanDetailsCard(_beanDetails),
            tasteScores('overall'),
            tasteScores('acidity'),
            tasteScores('aroma'),
            tasteScores('bitterness'),
            tasteScores('body'),
            tasteScores('sweetness'),
            Row(
              children: [
                Expanded(child: Container()),
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
                      onPressed: () => _showDeleteDialog(context),
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
