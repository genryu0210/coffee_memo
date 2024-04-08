import 'dart:io';

import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:image_picker/image_picker.dart';
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
  int selectedIndex = -1;

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
    selectedIndex = int.parse(controllers['roastLevel']!.text);
  }

  @override
  void dispose() {
    controllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  Future<void> _selectImage() async {
    // ボトムシートを表示する関数
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text('カメラで撮影'),
                  onTap: () {
                    _getImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('ギャラリーから選択'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile =
        await ImagePicker().pickImage(source: source, maxWidth: 600);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
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
    row['roastLevel'] = selectedIndex;
    await dbHelper.update(table, row);
    Navigator.of(context).pop(); // 更新後に画面を閉じる
  }

  Widget Function(File? _storedImage, VoidCallback? onTap) beansImage =
      Utils.beansImage;

  Widget customTextField(String key, double value) {
    return SizedBox(
      width: value,
      child: TextField(
        controller: controllers[key],
        decoration: InputDecoration(labelText: japaneseTitles[key]),
      ),
    );
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
                  child: itemDetails?['imagePath'] != null &&
                          itemDetails!['imagePath'].isNotEmpty
                      ? beansImage(_selectedImage, _selectImage)
                      : beansImage(null, _selectImage),
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
                        color: selectedIndex == index
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(
                          () {
                            selectedIndex = index; // 選択されたインデックスを更新
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
            customTextField('body', screenWidth / 2 - 32),
            customTextField('acidity', screenWidth / 2 - 32),
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
