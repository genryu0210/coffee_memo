import 'package:coffee_memo/utils.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;

class InsertScreen extends StatefulWidget {
  @override
  _InsertScreenState createState() => _InsertScreenState();
}

class _InsertScreenState extends State<InsertScreen> {
  final dbHelper = DatabaseHelper.instance;
  final table = 'CoffeeBeansTable';
  Map<String, TextEditingController> controllers = {};
  File? _storedImage;
  final Map japaneseTitles = Utils().japaneseTitles;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    // DatabaseHelperからcoffeebeansColumnsリストを取得
    final columns = dbHelper.coffeebeansColumns
        .where((column) => column != 'id' && column != 'imagePath')
        .toList();

    // 各カラムに対してTextEditingControllerを初期化
    columns.forEach((column) {
      controllers[column] = TextEditingController();
    });
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
                    Navigator.of(context).pop();
                    _getImage(ImageSource.camera);
                  }),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('ギャラリーから選択'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getImage(ImageSource.gallery);
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
        _storedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _addCoffeeBeanWithImage() async {
    String imagePath = _storedImage?.path ?? '';
    if (controllers['name']?.text.isEmpty ?? true) {
      const snackBar = SnackBar(
        content: Text('名前を入力してください'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    Map<String, dynamic> row = {
      for (var entry in controllers.entries) entry.key: entry.value.text,
      'imagePath': imagePath, // 特別な扱いが必要なフィールドを追加
    };
    await dbHelper.insert(table, row);

    Navigator.of(context).pop(); // データ挿入後に画面を閉じる
  }

  Widget beansImage(_storedImage) {
    Image imageFile;

    imageFile = _storedImage != null
        ? Image.file(
            _storedImage!,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          )
        : Image.asset(
            'assets/placeholder.jpg', // プレースホルダー画像へのパス
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          );
    return InkWell(
      onTap: _selectImage,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(width: 1.0),
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(30), child: imageFile),
      ),
    );
  }

  Widget customTextField(String key, double value) {
    return SizedBox(
      width: value,
      child: TextField(
        controller: controllers[key],
        decoration: InputDecoration(
          labelText: japaneseTitles[key], // ラベルの取得
        ),
        // keyboardType: _getKeyboardType(entry.key), // キーボードタイプの指定
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
                  child: beansImage(_storedImage),
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
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: _addCoffeeBeanWithImage,
                    style: ButtonStyle(
                      iconColor: MaterialStateProperty.resolveWith(
                        (Set states) {
                          return Theme.of(context).primaryColor;
                        },
                      ),
                    ),
                    child: Text('追加'),
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
