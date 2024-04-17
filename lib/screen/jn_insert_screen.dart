import 'package:coffee_memo/utils.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class InsertScreen extends StatefulWidget {
  @override
  _InsertScreenState createState() => _InsertScreenState();
}

class _InsertScreenState extends State<InsertScreen> {
  final dbHelper = DatabaseHelper.instance;
  final table = 'JournalTable';
  Map<String, TextEditingController> controllers = {};
  File? _storedImage;
  final Map japaneseTitles = Utils().japaneseTitles;
  DateTime selectedDate = DateTime.now();
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
    _initControllers();
  }

  void _initControllers() {
    final columns = dbHelper.journalColumns
        .where((column) => column != 'id' && column != 'imagePath')
        .toList();

    // 各カラムに対してTextEditingControllerを初期化
    columns.forEach((column) {
      controllers[column] = TextEditingController();
    });
  }

  Future<void> _addCoffeeBeanWithImage() async {
    String imagePath = _storedImage?.path ?? '';
    if (controllers['usedBeans']?.text.isEmpty ?? true) {
      const snackBar = SnackBar(
        content: Text('使用した豆を入力してください'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    Map<String, dynamic> row = {
      for (var entry in controllers.entries) entry.key: entry.value.text,
      'imagePath': imagePath, // 特別な扱いが必要なフィールドを追加
      'overallScore': tasteIndexMap['overall'],
      'acidityScore': tasteIndexMap['acidity'],
      'aromaScore': tasteIndexMap['aroma'],
      'bitternessScore': tasteIndexMap['bitter'],
      'bodyScore': tasteIndexMap['body'],
      'sweetnessScore': tasteIndexMap['sweetness'],
      'brewDate': DateFormat('yyyy-MM-dd').format(selectedDate),
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
          japaneseTitles['${taste}Score'],
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
    int currentIndex = tasteIndexMap[taste]!;
    return IconButton(
      icon: Icon(
        Icons.local_cafe,
        color: currentIndex >= level ? Colors.amber : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          tasteIndexMap[taste] = level;
        });
      },
    );
  }

  Widget tasteScores(String taste) {
    return Column(
      children: [customTextField('${taste}Memo', 400), tasteLevel(taste)],
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
                  child: beansImage(_storedImage, _selectImage),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customTextField('usedBeans', screenWidth * 0.5),
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
                  child: customTextField('variety', screenWidth * 0.4),
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
            tasteScores('overall'),
            tasteScores('acidity'),
            tasteScores('aroma'),
            tasteScores('bitterness'),
            tasteScores('body'),
            tasteScores('sweetness'),
            Row(
              children: [
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

List<Map<String, dynamic>> _coffeeBeans = [];
Map<String, TextEditingController> controllers = {};
File? _storedImage;
String _selectedBean = '';
final Map japaneseTitles = Utils().japaneseTitles;
