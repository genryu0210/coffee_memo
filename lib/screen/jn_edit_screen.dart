import 'package:coffee_memo/utils.dart';
import 'package:coffee_memo/widgets.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class EditScreen extends StatefulWidget {
  final int itemId;
  EditScreen({required this.itemId});

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final dbHelper = DatabaseHelper.instance;
  final table = 'JournalTable';
  Map<String, TextEditingController> controllers = {};
  File? _storedImage;
  List<DropdownMenuItem<String>> _coffeeBeansDropdown = [];
  String? _selectedBean;
  Map<String, dynamic>? _beanDetails;

  final Map japaneseTitles = Utils().japaneseTitles;
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  Map<String, int> tasteIndexMap = {
    'overall': -1,
    'body': -1,
    'acidity': -1,
    'sweetness': -1, // 例として「甘みの指数」を追加
    'bitterness': -1, // 「苦味の指数」を追加
    'aroma': -1, // 「香りの指数」を追加
  };

  Map<String, dynamic>? itemDetails;

  @override
  void initState() {
    super.initState();
    _loadItem();
    _loadCoffeeBeans();
  }

  void _loadItem() async {
    var data = await dbHelper.queryItemById(table, widget.itemId);
    if (data != null) {
      _initControllers(data);
      setState(() {
        itemDetails = data;
        // _selectedBean = itemDetails!['usedBeans'];
        tasteIndexMap = {
          'overall': itemDetails!['overallScore'],
          'body': itemDetails!['bodyScore'],
          'acidity': itemDetails!['acidityScore'],
          'sweetness': itemDetails!['sweetnessScore'], // 例として「甘みの指数」を追加
          'bitterness': itemDetails!['bitternessScore'], // 「苦味の指数」を追加
          'aroma': itemDetails!['aromaScore'], // 「香りの指数」を追加
        };

        isLoading = false;
      });
      getBeansDetails();
    }
  }

  void _initControllers(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (key != 'id' && key != 'imagePath' && value is String) {
        controllers[key] = TextEditingController(text: value.toString());
      }
    });
  }

  void getBeansDetails() async {
    if (itemDetails!['usedBeans'] != null) {
      try {
        var beanDetails = await dbHelper.queryItemById(
            'CoffeeBeansTable', itemDetails!['usedBeans']);
        setState(() {
          _beanDetails = beanDetails;
        });
      } catch (e) {
        setState(() {
          _beanDetails = null;
        });
      }
    }
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
        if (_beanDetails != null) {
          _onCoffeeBeanSelected(
              _coffeeBeansDropdown[itemDetails!['usedBeans'] - 1].value);
        } else {
          _onCoffeeBeanSelected(_coffeeBeansDropdown[0].value);
        }
      }
    });
  }

  Future<void> _addCoffeeBeanWithImage() async {
    String imagePath = _storedImage?.path ?? '';
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
      'brewDate': DateFormat('yyyy-MM-dd').format(selectedDate),
      'updateDate': DateTime.now().toString()
    };
    await dbHelper.insert(table, row);

    Navigator.of(context).pop(); // データ挿入後に画面を閉じる
  }

  Widget _coffeeBeanSelector() {
    return DropdownButton<String>(
      value: _selectedBean,
      onChanged: (newValue) {
        setState(() {
          _onCoffeeBeanSelected(newValue);
        });
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
      lastDate: DateTime.now(), // 選択できる日付の最大値
    );

    if (picked != null) {
      setState(() {
        // 選択された日付を変数に代入
        selectedDate = picked;
      });
    }
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
        customTextField('${taste}Memo', 400),
        SizedBox(height: 8.0),
        tasteLevel(taste),
      ],
    );
  }

  Widget coffeeBeanDetailsCard(Map<String, dynamic>? beanDetails) {
    if (beanDetails == null || beanDetails.isEmpty) return SizedBox();
    return Visibility(
      visible: beanDetails.isNotEmpty,
      child: Card(
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("購入店: ${beanDetails['store']}"),
              Text(
                  "購入日: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(beanDetails['purchaseDate']))}"),
              Row(
                children: [
                  Expanded(child: Text("焙煎度: ${beanDetails['roastLevel']}")),
                  Expanded(child: Text("精製方法: ${beanDetails['process']}")),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text("ボディ: ${beanDetails['body']}")),
                  Expanded(child: Text("酸味: ${beanDetails['acidity']}")),
                ],
              ),
              // 他の必要な情報もここに追加
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
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
                        child: BeansImage(
                            storedImage: _storedImage, onTap: _selectImage),
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 16),
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
                                    top: BorderSide(
                                        width: 1.0, color: Colors.black)),
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
                                    top: BorderSide(
                                        width: 1.0, color: Colors.black)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  coffeeBeanDetailsCard(_beanDetails),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 8),
                      Text(japaneseTitles['brewMethods'],
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: controllers['brewMethods'],
                        decoration: InputDecoration(
                          hintText: "ここに抽出方法を記入してください",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        autofocus: false,
                      ),
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
                      Expanded(child: Container()),
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
