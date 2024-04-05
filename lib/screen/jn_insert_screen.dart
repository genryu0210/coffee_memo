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
  final table = 'JournalTable';
  List<Map<String, dynamic>> _coffeeBeans = [];
  Map<String, TextEditingController> controllers = {};
  File? _storedImage;
  String _selectedBean = '';
  final Map japaneseTitles = Utils().japaneseTitles;


  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    // DatabaseHelperからjournalColumnsリストを取得
    final columns = dbHelper.journalColumns.where((column) => column != 'id' && column != 'imagePath').toList();

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
    if (controllers['deviceUsed']?.text.isEmpty ?? true) {
    final snackBar = SnackBar(
      content: Text('名前を入力してください'),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    return;
  }
      Map<String, dynamic> row = {
    for (var entry in controllers.entries)
      entry.key: entry.value.text,
    'imagePath': imagePath, // 特別な扱いが必要なフィールドを追加
  };
    await dbHelper.insert(table, row);

    Navigator.of(context).pop(); // データ挿入後に画面を閉じる
  }

  DropdownButton<String> _buildCoffeeBeansDropdown() {
    return DropdownButton<String>(
      value: _selectedBean,
      onChanged: (String? newValue) {
        setState(() {
          _selectedBean = newValue!;
        });
      },
      items: _coffeeBeans
          .map<DropdownMenuItem<String>>((Map<String, dynamic> bean) {
        return DropdownMenuItem<String>(
          value: bean['id'].toString(), // IDなどの一意の識別子
          child: Text(bean['name']), // 表示する名前
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('新しいコーヒー豆を追加'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Column(
              children: controllers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: japaneseTitles[entry.key], // ラベルの取得
                  ),
                  // keyboardType: _getKeyboardType(entry.key), // キーボードタイプの指定
                ),
              );
            }).toList(),), 
                _storedImage != null
                    ? Image.file(
                        _storedImage!,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/placeholder.jpg', // プレースホルダー画像へのパス
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                Text('画像が選択されていません'),
                ElevatedButton(
                  onPressed: _selectImage,
                  child: Text('画像を選択'),
                ),
            
                ElevatedButton(
                  onPressed: _addCoffeeBeanWithImage,
                  child: Text('追加'),
                ),
          ],
        ),
      ),
    );
  }
}
