import 'dart:ui';

class CategoryChipModel {
  String? title;
  String? imagePath;
  Color? backgroundColor;
  Color? textColor;

  CategoryChipModel({
    this.title,
    this.imagePath,
    this.backgroundColor,
    this.textColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'imagePath': imagePath,
      'backgroundColor': backgroundColor?.value,
      'textColor': textColor?.value,
    };
  }

  factory CategoryChipModel.fromMap(Map<String, dynamic> map) {
    return CategoryChipModel(
      title: map['title'] as String?,
      imagePath: map['imagePath'] as String?,
      backgroundColor: map['backgroundColor'] != null
          ? Color(map['backgroundColor'] as int)
          : null,
      textColor: map['textColor'] != null
          ? Color(map['textColor'] as int)
          : null,
    );
  }

  CategoryChipModel copyWith({
    String? title,
    String? imagePath,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return CategoryChipModel(
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }
}
