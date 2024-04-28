import 'dart:io';

import 'package:coffee_memo/styles.dart';
import 'package:coffee_memo/widgets.dart';
import 'package:flutter/material.dart';
import 'package:coffee_memo/db/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:coffee_memo/utils.dart';

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
  final List<String> processes = Utils().processes;
  DateTime purchaseDate = DateTime.now();
  String? RoastLevel;
  int bodyIndex = -1;
  int acidityIndex = -1;
  String? selectedProcess;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() async {
    final data = await dbHelper.queryItemById(table, widget.itemId);
    setState(await () {
      itemDetails = data;
      _selectedImage = itemDetails!['imagePath'] != ''
          ? File(itemDetails!['imagePath'])
          : null;
    });
    itemDetails?.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.toString());
    });
    purchaseDate = DateTime.parse(itemDetails!['purchaseDate']);
    RoastLevel = int.parse(controllers['roastLevel']!.text) == -1
        ? null
        : roastLevels[int.parse(controllers['roastLevel']!.text)];
    bodyIndex = int.parse(controllers['body']!.text);
    acidityIndex = int.parse(controllers['acidity']!.text);
    selectedProcess = itemDetails!['process'];
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
    row['roastLevel'] =
        RoastLevel != null ? roastLevels.indexOf(RoastLevel!) : -1;
    row['body'] = bodyIndex;
    row['acidity'] = acidityIndex;
    row['purchaseDate'] = DateFormat('yyyy-MM-dd').format(purchaseDate);
    row['updateDate'] = DateTime.now().toString();
    row['process'] = selectedProcess;

    await dbHelper.update(table, row);
    Navigator.of(context).pop(); // 更新後に画面を閉じる
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (itemDetails == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 116, 32, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: ImagePickerWidget(
                      onImagePicked: (image) {
                        setState(() {
                          _selectedImage = image;
                        });
                      },
                      storedImage: _selectedImage),
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
                        selectedDate: purchaseDate,
                        onDateSelected: (date) {
                          setState(() {
                            purchaseDate = date;
                          });
                        },
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
                          onItemSelected: (String value) {
                            setState(() {
                              selectedProcess = value;
                            });
                          }),
                    ),
                    Container(width: 16),
                    Expanded(
                      child: CustomDropdownMenu(
                        selectedItem: RoastLevel,
                        itemList: roastLevels,
                        onItemSelected: (String value) {
                          setState(() {
                            RoastLevel = value;
                          });
                        },
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
                SegmentedLevelSelector(
                  selectedIndex: bodyIndex,
                  segmentedList: Utils().bodyLevels,
                  onPressed: (index) {
                    setState(() {
                      bodyIndex = index;
                    });
                  },
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
                SegmentedLevelSelector(
                  selectedIndex: acidityIndex,
                  segmentedList: Utils().acidityLevels,
                  onPressed: (index) {
                    setState(() {
                      acidityIndex = index;
                    });
                  },
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
        backgroundColor: controllers['name']!.text.isEmpty
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
        onPressed: controllers['name']!.text.isEmpty ? () {} : _updateItem,
      ),
    );
  }
}
