import 'package:coffee_memo/utils.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  final List<String> roastLevels = Utils().roastLevels;
  int roastIndex = -1;
  int bodyIndex = -1;
  int acidityIndex = -1;
  DateTime selectedDate = DateTime.now();

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
      'roastLevel': roastIndex,
      'body': bodyIndex,
      'acidity': acidityIndex,
      'purchaseDate': DateFormat('yyyy-MM-dd').format(selectedDate), 
      'updateDate': DateTime.now().toString() 
    };
    await dbHelper.insert(table, row);

    Navigator.of(context).pop(); // データ挿入後に画面を閉じる
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // 最初に表示する日付
      firstDate: DateTime(2020), // 選択できる日付の最小値
      lastDate: DateTime(2040), // 選択できる日付の最大値
    );

    if (picked != null) {
      setState(() {
        // 選択された日付を変数に代入
        selectedDate = picked;
      });
    }
  }

  Widget Function(File? _storedImage, VoidCallback? onTap) beansImage =
      Utils.beansImage;

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

  Widget tasteLevel(String taste) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          japaneseTitles[taste],
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
        Icons.local_cafe,
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
                  child: beansImage(_storedImage, _selectImage),
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
                            '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
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
                  child: customTextField('store', screenWidth * 0.5),
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
            tasteLevel(
              'body',
            ),
            tasteLevel(
              'acidity',
            ),
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
