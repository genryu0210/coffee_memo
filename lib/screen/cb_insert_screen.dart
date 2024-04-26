import 'package:coffee_memo/styles.dart';
import 'package:coffee_memo/utils.dart';
import 'package:coffee_memo/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
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
  final Map japaneseTitles = Utils().japaneseTitles;
  final List<String> roastLevels = Utils().roastLevels;
  final List<String> processes = Utils().processes;
  String? RoastLevel;
  int bodyIndex = -1;
  int acidityIndex = -1;
  DateTime selectedDate = DateTime.now();
  File? _selectedImage;
  String? selectedProcess;
  bool? nameHasText;

  @override
  void initState() {
    super.initState();
    _initControllers();
    controllers['name']!.addListener(() { 
      setState(() {
        // nameHasText =true;
      });});
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

  void _handleImage(File pickedImage) {
    setState(() {
      _selectedImage = pickedImage;
    });
  }

  void _handleDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  void _handleRoastlevel(String value) {
    setState(() {
      RoastLevel = value;
    });
  }

  void _handleProcess(String value) {
    setState(() {
      selectedProcess = value;
    });
  }

  Future<void> _addCoffeeBeanWithImage() async {
    String imagePath = _selectedImage?.path ?? '';
    if (controllers['name']?.text.isEmpty ?? true) {
      const snackBar = SnackBar(
        content: Text('コーヒー豆の名前を入力してください'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    Map<String, dynamic> row = {
      for (var entry in controllers.entries) entry.key: entry.value.text,
      'imagePath': imagePath, // 特別な扱いが必要なフィールドを追加
      'roastLevel': RoastLevel == null ? -1 : roastLevels.indexOf(RoastLevel!),
      'process': selectedProcess,
      'body': bodyIndex,
      'acidity': acidityIndex,
      'purchaseDate': DateFormat('yyyy-MM-dd').format(selectedDate),
      'updateDate': DateTime.now().toString()
    };
    await dbHelper.insert(table, row);

    Navigator.of(context).pop(); // データ挿入後に画面を閉じる
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
            children: <Widget>[
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: ImagePickerWidget(onImagePicked: _handleImage),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: controllers['name']!,
                          itemKey: 'name',
                          hintText: 'エチオピア イルガチェフェ',
                          maxLines: 1,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '購入日',
                          style: AppStyles.normalText,
                        ),
                        DateTimePicker(
                          selectedDate: selectedDate,
                          onDateSelected: _handleDate,
                          firstDate: 2020,
                          lastDate: 2040,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CustomTextField(
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  controller: controllers['description']!,
                  itemKey: 'description',
                  hintText: '香り、高度、COE順位...'),
              Container(height: 8),
              CustomTextField(
                  controller: controllers['store']!,
                  itemKey: 'store',
                  hintText: 'ex:コーヒーキャロット'),
              Container(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: controllers['price']!,
                      itemKey: 'price',
                      hintText: '1500',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Container(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: controllers['purchasedGrams']!,
                      itemKey: 'purchasedGrams',
                      hintText: '200',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Container(height: 8),
              CustomTextField(
                controller: controllers['origin']!,
                itemKey: 'origin',
                hintText: 'エチオピア',
              ),
              Container(height: 8),
              CustomTextField(
                controller: controllers['farmName']!,
                itemKey: 'farmName',
                hintText: 'エスメラルダ農園',
              ),
              Container(height: 8),
              CustomTextField(
                controller: controllers['variety']!,
                itemKey: 'variety',
                hintText: 'ティピカ種',
              ),
              Container(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('精製方法')),
                      Container(width: 16),
                      Expanded(child: Text('焙煎度')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomDropdownMenu(
                          selectedItem: selectedProcess,
                          itemList: processes,
                          onItemSelected: _handleProcess,
                        ),
                      ),
                      Container(width: 16),
                      Expanded(
                        child: CustomDropdownMenu(
                          selectedItem: RoastLevel,
                          itemList: roastLevels,
                          onItemSelected: _handleRoastlevel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Utils().japaneseTitles['body']!, // または他の方法でタイトルを取得
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: List.generate(
                        3,
                        (index) {
                          int level = index + 1;
                          return Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: bodyIndex == level
                                      ? Theme.of(context).primaryColor
                                      : Colors.black,
                                  width: bodyIndex == level ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextButton(
                                child: Text(
                                  Utils().bodyLevels[index],
                                  style: AppStyles.normalText,
                                ),
                                onPressed: () {
                                  setState(() {
                                    bodyIndex = level;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Utils().japaneseTitles['acidity']!, // または他の方法でタイトルを取得
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: List.generate(
                        3,
                        (index) {
                          int level = index + 1;
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: acidityIndex == level
                                      ? Theme.of(context).primaryColor
                                      : Colors.black,
                                  width: acidityIndex == level ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextButton(
                                child: Text(
                                  Utils().acidityLevels[index],
                                  style: AppStyles.normalText,
                                ),
                                onPressed: () {
                                  setState(() {
                                    acidityIndex = level;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                ],
              ),
              Container(height: 8),
              CustomTextField(
                controller: controllers['story']!,
                itemKey: 'story',
                hintText: 'エルインヘルト農園は、グアテマラ北西部ウエウエテナンゴ県の谷沿いに...',
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: controllers['name']!.text.isEmpty? Colors.grey : Theme.of(context).primaryColor,
          label: Container(
            width: screenWidth * 0.8,
            child: Center(
              child: Text(
                '保存',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          onPressed: controllers['name']!.text.isEmpty? (){} : _addCoffeeBeanWithImage,
        ));
  }
}
