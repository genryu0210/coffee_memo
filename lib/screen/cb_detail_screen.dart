import 'dart:io';
import 'dart:ui';

import 'package:coffee_memo/screen/cb_edit_screen.dart';
import 'package:coffee_memo/styles.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:coffee_memo/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

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
    });
  }

  void _showDeleteDialog(BuildContext context, String name) {
    // データベース削除の確認ダイアログを表示
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (itemDetails == null) {
      return Scaffold(
        appBar: AppBar(),
        body:
            const Center(child: CircularProgressIndicator()), // ロード中のインジケータを表示
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        EditScreen(itemId: itemDetails!["id"])),
              );
              _refreshItem();
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, itemDetails!['name']),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 116, 16, 8),
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      textBox('name'),
                      textBox('store'),
                    ],
                  ),
                ),
              ],
            ),
            Card(
              margin: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text("購入店: ${itemDetails!['store']}"),
                    Text(
                        "購入日: ${DateFormat('yyyy/MM/dd').format(DateTime.parse(itemDetails!['purchaseDate']))}"),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              "焙煎度: ${itemDetails!['roastLevel'] != -1 ? Utils().roastLevels[itemDetails!['roastLevel']] : ''}"),
                        ),
                        Expanded(
                            child:
                                Text("精製方法: ${itemDetails!['process'] ?? ''}")),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Text(
                                "ボディ: ${itemDetails!['body'] != -1 ? Utils().bodyLevels[itemDetails!['body']] : ''}")),
                        Expanded(
                            child: Text(
                                "酸味: ${itemDetails!['acidity'] != -1 ? Utils().acidityLevels[itemDetails!['acidity']] : ''}")),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text("価格: ${itemDetails!['price']}円"),
                        ),
                        Expanded(
                            child: Text(
                                "購入グラム数: ${itemDetails!['purchasedGrams']}g")),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text("産地: ${itemDetails!['origin'] ?? ''}"),
                        ),
                        Expanded(
                            child:
                                Text("農園名: ${itemDetails!['farmName'] ?? ''}")),
                      ],
                    ),

                    Text("説明: ${itemDetails!['description'] ?? ''}"),
                    Text("ストーリー: ${itemDetails!['story'] ?? ''}"),
                  ],
                ),
              ),
            ),
            Text('最近のアクティビティ', style: AppStyles.headingStyle,), 
            FutureBuilder<List<Map<String, dynamic>>>(
              future: dbHelper.queryRecentActivities(itemDetails!['id'],),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox.shrink();
                } else {
                  final activities = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ListTile(
                        title: Text(activity['overallMemo']),
                        subtitle: Text(activity['overallScore'].toString()),
                      );
                    },
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
