import 'package:coffee_memo/utils.dart';
import 'package:coffee_memo/widgets.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'dart:io';

class InsertScreen extends StatefulWidget {
  @override
  _InsertScreenState createState() => _InsertScreenState();
}

class _InsertScreenState extends State<InsertScreen> {
  final dbHelper = DatabaseHelper.instance;
  final table = 'JournalTable';
  Map<String, TextEditingController> controllers = {};
  Map<String, dynamic> _beanDetails = {};
  final Map japaneseTitles = Utils().japaneseTitles;
  List<DropdownMenuItem<String>> _coffeeBeansDropdown = [];
  File? _selectedImage;
  String? _selectedBean;
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
    _loadCoffeeBeans();
  }

  void _initControllers() {
    final columns =
        dbHelper.journalColumns.where((column) => column != 'id').toList();
    columns.forEach((column) {
      controllers[column] = TextEditingController();
    });
  }

  Future<void> _loadCoffeeBeans() async {
    final data = await dbHelper.queryAllRows('CoffeeBeansTable');
    setState(() {
      _coffeeBeansDropdown = data.map((bean) {
        return DropdownMenuItem<String>(
          value: bean['id'].toString(),
          child: Text(bean['name']),
        );
      }).toList();

      if (_coffeeBeansDropdown.isNotEmpty) {
        _onCoffeeBeanSelected(_coffeeBeansDropdown[0].value);
      }
    });
  }

  Future<void> _addJournalWithImage() async {
    String imagePath = _selectedImage?.path ?? '';
    Map<String, dynamic> row = {
      for (var entry in controllers.entries) entry.key: entry.value.text,
      'usedBeans': _selectedBean,
      'imagePath': imagePath,
      'overallScore': tasteIndexMap['overall'],
      'acidityScore': tasteIndexMap['acidity'],
      'aromaScore': tasteIndexMap['aroma'],
      'bitternessScore': tasteIndexMap['bitterness'],
      'bodyScore': tasteIndexMap['body'],
      'sweetnessScore': tasteIndexMap['sweetness'],
      'brewDate': selectedDate.toString(),
      'updateDate': DateTime.now().toString()
    };
    try {
      await dbHelper.insert(table, row);
    } catch (e) {
      print('Error inserting data: $e');
    }
    // await dbHelper.insert(table, row);

    Navigator.of(context).pop(); // データ挿入後に画面を閉じる
  }

  Widget _coffeeBeanSelector() {
    return DropdownButton<String>(
      borderRadius: BorderRadius.all(Radius.circular(15)),
      value: _selectedBean,
      onChanged: (newValue) {
        _onCoffeeBeanSelected(newValue);
      },
      items: _coffeeBeansDropdown,
    );
  }

  void _onCoffeeBeanSelected(String? newValue) async {
    if (newValue == null) return;

    setState(() {
      _selectedBean = newValue;
    });

    // データベースから選択された豆の詳細を取得
    var beanDetails = await dbHelper.queryItemById(
        'CoffeeBeansTable', int.parse(_selectedBean!));

    // 豆の詳細を表示するためのステート更新
    setState(() {
      _beanDetails = beanDetails;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // 最初に表示する日付
      firstDate: DateTime(2020), // 選択できる日付の最小値
      lastDate: DateTime.now(), // 選択できる日付の最大値
    );

    if (picked != null) {
      setState(() {
        // 選択された日付を変数に代入
        selectedDate = picked;
      });
    }
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
      children: [
        CustomTextField(
          controller: controllers['${taste}Memo']!,
          hintText: 'ここに${japaneseTitles[taste]}の感想を記入してください',
          itemKey: '${taste}Memo',
        ),
        SizedBox(height: 8.0),
        TasteLevelWidget(
          taste: taste,
          currentLevel: tasteIndexMap[taste]!,
          onLevelChanged: (level) {
            setState(() {
              tasteIndexMap[taste] = level;
            });
          },
        ),
      ],
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
                  padding: EdgeInsets.only(left: 8.0, right: 8.0),
                  child: ImagePickerWidget(
                    onImagePicked: (image) {
                      setState(() {
                        _selectedImage = image;
                      });
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 8),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '使用した豆',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      _coffeeBeanSelector(),
                      Container(
                        width: double.infinity,
                        height: 1.0,
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(width: 1.0, color: Colors.black)),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          '抽出日',
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
            CoffeeBeanDetailsCard(beanDetails: _beanDetails),
            SizedBox(height: 8),
            Text(japaneseTitles['brewMethods'], style: TextStyle(fontSize: 16)),
            TextFormField(
              controller: controllers['brewMethods'],
              decoration: InputDecoration(
                  hintText: "ここに抽出方法を記入してください",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)))),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              autofocus: false,
            ),
            SizedBox(height: 8),
            tasteScores('overall'),
            SizedBox(height: 8),
            tasteScores('acidity'),
            SizedBox(height: 8),
            tasteScores('aroma'),
            SizedBox(height: 8),
            tasteScores('bitterness'),
            SizedBox(height: 8),
            tasteScores('body'),
            SizedBox(height: 8),
            tasteScores('sweetness'),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: tasteIndexMap['overall'] == -1
            ? Colors.grey
            : Theme.of(context).primaryColor,
        label: Container(
          width: screenWidth * 0.8,
          child: Center(
            child: Text(
              '保存',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        onPressed:
            tasteIndexMap['overall'] == -1 ? () {} : _addJournalWithImage,
      ),
    );
  }
}
