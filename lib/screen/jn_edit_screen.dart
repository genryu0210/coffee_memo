import 'dart:io';

import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import '../utils.dart';

class EditScreen extends StatefulWidget {
  late Map<String, dynamic> item;

  EditScreen({required this.item});

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final table = 'JournalTable';
  final dbHelper = DatabaseHelper.instance;
  File? _selectedImage;
  late Map<String, Map> _controllers;
  final japaneseTitles = Utils().japaneseTitles;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = { for (var item in dbHelper.journalColumns.where((column) => column != 'id' && column != 'imagePath')
        .toList()
    ) item : {
        'controller': TextEditingController(
            text:
                widget.item[item] != null ? widget.item[item].toString() : ''),
        'JapaneseTitle':  japaneseTitles[item] ?? item,
      } };
  }

  @override
  void dispose() {
    _controllers.forEach((key, value) {
      value['controller'].dispose();
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
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _updateItem() async {
    final imagePath =
        _selectedImage != null ? _selectedImage!.path : widget.item['imagePath'];

    Map<String, dynamic> row = {
      'id': widget.item['id'],
      'imagePath': imagePath,
    };
    _controllers.forEach((key, value) {
      row[key] = value['controller'].text; // 各フィールドの値をマップに追加
    });
    await dbHelper.update(table, row);
    Navigator.of(context).pop(); // 更新後に画面を閉じる
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('編集'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: _buildFields(),
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    List<Widget> fields = [];

    _controllers.forEach((key, value) {
      if(key != "id"){
      fields.add(TextField(
        controller: value['controller'],
        decoration: InputDecoration(labelText: value['JapaneseTitle']),
      ));
      // fields.add(SizedBox(height: 8));
  }});

    // 画像表示の条件分岐
    if (_selectedImage != null) {
      fields.add(Image.file(
        _selectedImage!,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
      ));
    } else if (widget.item['imagePath'] != null &&
        widget.item['imagePath'].isNotEmpty) {
      fields.add(Image.file(
        File(widget.item['imagePath']),
        width: 250,
        height: 250,
        fit: BoxFit.cover,
      ));
    } else {
      fields.add(Image.asset('assets/placeholder.jpg'));
    }

    fields.add(ElevatedButton(
      onPressed: _selectImage,
      child: Text('画像を選択'),
    ));

    fields.add(ElevatedButton(
      onPressed: _updateItem,
      child: Text('保存'),
    ));

    return fields;
  }
}
