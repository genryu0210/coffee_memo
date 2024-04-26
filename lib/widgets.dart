import 'package:coffee_memo/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'styles.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String itemKey;
  final TextInputType keyboardType;
  final int? maxLines;
  final String hintText;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.itemKey,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Utils().japaneseTitles[itemKey]!, style: AppStyles.normalText),
        SizedBox(
          width: screenWidth,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0)),
                hintText: hintText),
          ),
        )
      ],
    );
  }
}

class ImagePickerWidget extends StatefulWidget {
  final void Function(File pickedImage) onImagePicked;
  final File? storedImage;

  const ImagePickerWidget({
    Key? key,
    required this.onImagePicked,
    this.storedImage,
  }) : super(key: key);

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _storedImage;

  @override
  void initState() {
    super.initState();
    _storedImage = widget.storedImage;
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.storedImage != oldWidget.storedImage) {
      // 更新された storedImage を使用して、_storedImage を更新
      setState(() {
        _storedImage = widget.storedImage;
      });
    }
  }

  Image beansImage() {
    Image imageFile = _storedImage != null
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
    return imageFile;
  }

  void _showImagePicker() {
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
      widget.onImagePicked(_storedImage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showImagePicker,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(width: 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: _storedImage != null
              ? Image.file(_storedImage!,
                  width: 150, height: 150, fit: BoxFit.cover)
              : Image.asset('assets/placeholder.jpg',
                  width: 150, height: 150, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// 日時選択ウィジェット
class DateTimePicker extends StatelessWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final int firstDate;
  final int lastDate;

  const DateTimePicker({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.firstDate,
    required this.lastDate,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // 最初に表示する日付
      firstDate: DateTime(firstDate), // 選択できる日付の最小値
      lastDate: DateTime(lastDate), // 選択できる日付の最大値
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(width: 1.0),
            ),
            width: double
                .infinity, // Add this line to stretch the box to the screen edge
            child: Text(
              DateFormat('yyyy-MM-dd').format(selectedDate),
              style: AppStyles.normalText,
            ),
          ),
        )
      ],
    );
  }
}

class CustomDropdownMenu extends StatefulWidget {
  final String? selectedItem;
  final List<String> itemList;
  final void Function(String) onItemSelected;

  const CustomDropdownMenu({
    Key? key,
    this.selectedItem,
    required this.itemList,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  State<CustomDropdownMenu> createState() => _CustomDropdownMenuState();
}

class _CustomDropdownMenuState extends State<CustomDropdownMenu> {
  String? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
          border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
      )),
      value: _selectedItem,
      icon: const Icon(Icons.arrow_downward),
      iconSize: 24,
      style: AppStyles.normalText,
      borderRadius: BorderRadius.circular(15),
      onChanged: (String? newValue) {
        setState(() {
          _selectedItem = newValue;
        });
        widget.onItemSelected(newValue!);
      },
      items: widget.itemList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}

class TasteLevelWidget extends StatelessWidget {
  final String taste;
  final int currentLevel;
  final Function(int) onLevelChanged;

  const TasteLevelWidget({
    Key? key,
    required this.taste,
    required this.currentLevel,
    required this.onLevelChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Utils().japaneseTitles[taste]!, // または他の方法でタイトルを取得
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(
          height: 34,
          child: Row(
            children: List.generate(
              5,
              (index) {
                int level = index + 1;
                return IconButton(
                  icon: Icon(
                    Icons.local_cafe,
                    color: currentLevel >= level ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => onLevelChanged(level),
                );
              },
            ),
          ),
        )
      ],
    );
  }
}
