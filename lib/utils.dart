import 'dart:io';

import 'package:flutter/material.dart';

class Utils {
  final Map<String, String> japaneseTitles = {
    'id': 'ID',
    'name': '名前',
    'store': '購入店',
    'imagePath': '画像パス',
    'description': '説明', 
    'purchaseDate': '購入日',
    'updateDate': '更新日',
    'price': '価格',
    'purchasedGrams': '購入グラム数',
    'origin': '産地',
    'farmName': '農園名',
    'variety': '品種',
    'process': '精製方法', 
    'roastLevel': '焙煎度',
    'body': 'ボディ',
    'acidity': '酸味',
    'story': 'ストーリー',
    'usedBeans': '使用した豆',
    'deviceUsed': '使用器具',
    'brewDate': '抽出日',
    'overallScore': '総合点数',
    'overallMemo': '総合メモ',
    'acidityScore': '酸味',
    'acidityMemo': '酸味に関するメモ',
    'aromaScore': '香り',
    'aromaMemo': '香りに関するメモ',
    'bitternessScore': '苦味',
    'bitternessMemo': '苦味に関するメモ',
    'bodyScore': 'ボディ',
    'bodyMemo': 'ボディに関するメモ',
    'sweetnessScore': '甘味',
    'sweetnessMemo': '甘味に関するメモ',
  };
    final List<String> roastLevels = [
    'ライト',
    'シナモン',
    'ミディアム',
    'ハイ',
    'シティ',
    'フルシティ',
    'フレンチ',
    'イタリアン'
  ];

  static Widget beansImage(File? _storedImage, VoidCallback? onTap) {
    Image imageFile = _storedImage != null
      ? Image.file(
          _storedImage,
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
      onTap: onTap != null ? onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(width: 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: imageFile,
        ),
      ),
    );
  }

  Widget customTextField(String key, double value, Map<String, TextEditingController> controllers) {
    return SizedBox(
      width: value,
      child: TextField(
        controller: controllers[key],
        decoration: InputDecoration(labelText: japaneseTitles[key]),
      ),
    );
  }
}
