import 'dart:io';

import 'package:coffee_memo/widgets.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../utils.dart';

class EditScreen extends StatefulWidget {
  final int itemId;

  EditScreen({required this.itemId});

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final table = 'CoffeeBeansTable';
  final dbHelper = DatabaseHelper.instance;
  File? _selectedImage;
  Map<String, dynamic>? itemDetails;
  Map<String, TextEditingController> controllers = {};
  final japaneseTitles = Utils().japaneseTitles;
  final List<String> roastLevels = Utils().roastLevels;
  DateTime purchaseDate = DateTime.now();
  int roastIndex = -1;
  int bodyIndex = -1;
  int acidityIndex = -1;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() async {
    final data = await dbHelper.queryItemById(table, widget.itemId);
    setState(await () {
      itemDetails = data;
      _selectedImage = itemDetails!['imagePath'] != null
          ? File(itemDetails!['imagePath'])
          : null;
    });
    itemDetails?.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.toString());
    });
    purchaseDate = DateTime.parse(itemDetails!['purchaseDate']);
    roastIndex = int.parse(controllers['roastLevel']!.text);
    bodyIndex = int.parse(controllers['body']!.text);
    acidityIndex = int.parse(controllers['acidity']!.text);
  }

  @override
  void dispose() {
    controllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  void _updateItem() async {
    final imagePath = _selectedImage != null
        ? _selectedImage!.path
        : itemDetails!['imagePath'];

    Map<String, dynamic> row = {
      'id': itemDetails!['id'],
      // 'imagePath': imagePath,
    };
    controllers.forEach((key, value) {
      row[key] = value.text; // 各フィールドの値をマップに追加
    });
    row['imagePath'] = imagePath;
    row['roastLevel'] = roastIndex;
    row['body'] = bodyIndex;
    row['acidity'] = acidityIndex;
    row['purchaseDate'] = DateFormat('yyyy-MM-dd').format(purchaseDate);
    row['updateDate'] = DateTime.now().toString();

    await dbHelper.update(table, row);
    Navigator.of(context).pop(); // 更新後に画面を閉じる
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate, // 最初に表示する日付
      firstDate: DateTime(2020), // 選択できる日付の最小値
      lastDate: DateTime(2040), // 選択できる日付の最大値
    );

    if (picked != null) {
      setState(() {
        // 選択された日付を変数に代入
        purchaseDate = picked;
      });
    }
  }

  Widget customTextField(String key, double value) {
    return SizedBox(
      width: value,
      child: TextField(
        controller: controllers[key],
        decoration: InputDecoration(labelText: japaneseTitles[key]),
      ),
    );
  }

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
      onPressed: () {
        setState(() {
          _setTasteIndex(taste, level);
        });
      },
    );
  }

  int _getCurrentIndex(String taste) {
    switch (taste) {
      case 'body':
        return bodyIndex;
      case 'acidity':
        return acidityIndex;
      // 他の味覚の場合も同様に追加
      default:
        return -1;
    }
  }

  void _setTasteIndex(String taste, int level) {
    switch (taste) {
      case 'body':
        bodyIndex = level;
        break;
      case 'acidity':
        acidityIndex = level;
        break;
      // 他の味覚の場合も同様に追加
    }
  }
  

  void _handleImage(File pickedImage) {
    setState(() {
      _selectedImage = pickedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
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
                  child: ImagePickerWidget(
                    onImagePicked: _handleImage,storedImage: _selectedImage,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customTextField('name', screenWidth * 0.5),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '購入日',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '${purchaseDate.year}/${purchaseDate.month}/${purchaseDate.day}',
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                              onPressed: () => _selectDate(context),
                              icon: Icon(Icons.calendar_today))
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        height: 1.0,
                        decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(width: 1.0, color: Colors.black)),
                        ),
                      )
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
                  child: customTextField('store', screenWidth * 0.4),
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
            SizedBox(
              height: 32,
            ),
            Text(
              '焙煎度',
              style: TextStyle(fontSize: 16),
            ),
            Container(
              height: 34,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: roastLevels.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1.0,
                        color: roastIndex == index
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(
                          () {
                            roastIndex = index; // 選択されたインデックスを更新
                          },
                        );
                      },
                      child: Text(
                        roastLevels[index],
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
            tasteLevel('body'),
            tasteLevel('acidity'),
            Row(
              children: [
                customTextField('story', screenWidth / 2 - 32),
                Expanded(
                  child: Container(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: _updateItem,
                    style: ButtonStyle(
                      iconColor: MaterialStateProperty.resolveWith(
                        (Set states) {
                          return Theme.of(context).primaryColor;
                        },
                      ),
                    ),
                    child: Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
