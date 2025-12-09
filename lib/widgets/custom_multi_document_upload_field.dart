import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../theme/text_style_helper.dart';
import '../theme/theme_helper.dart';

class CustomMultiDocumentUploadField extends FormField<List<File>> {
  CustomMultiDocumentUploadField({
    super.key,
    required String labelText,
    ValueChanged<List<File>>? onChanged,
    super.onSaved,
    super.validator,
    TextStyle? labelStyle,
    List<File>? initialValue,
    Color? color,
    List<String> allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'png'],
    List<String>? initialDocumentUrls, // Додаємо поле для існуючих документів
  }) : super(
         initialValue: initialValue ?? [],
         builder: (FormFieldState<List<File>> state) {
           Future<void> pickDocuments() async {
             try {
               FilePickerResult? result = await FilePicker.platform.pickFiles(
                 allowMultiple: true,
                 type: FileType.custom,
                 allowedExtensions: allowedExtensions,
               );

               if (result != null) {
                 List<File> newFiles = result.paths
                     .map((path) => File(path!))
                     .toList();

                 // Перевірка розміру кожного файлу
                 List<File> validFiles = [];
                 for (File file in newFiles) {
                   final int fileSizeInBytes = await file.length();
                   final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

                   if (fileSizeInMB <= 10) {
                     validFiles.add(file);
                   } else {
                     ScaffoldMessenger.of(state.context).showSnackBar(
                       SnackBar(
                         content: Text(
                           'Файл ${p.basename(file.path)} більше 10 МБ і був пропущений',
                         ),
                         backgroundColor: appThemeColors.errorRed,
                       ),
                     );
                   }
                 }

                 if (validFiles.isNotEmpty) {
                   final updatedList = [...state.value!, ...validFiles];
                   state.didChange(updatedList);
                   onChanged?.call(updatedList);
                 }
               }
             } catch (e) {
               ScaffoldMessenger.of(state.context).showSnackBar(
                 SnackBar(
                   content: Text('Помилка при виборі файлів: $e'),
                   backgroundColor: appThemeColors.errorRed,
                 ),
               );
             }
           }

           void removeDocument(int index) {
             final updatedList = [...state.value!];
             updatedList.removeAt(index);
             state.didChange(updatedList);
             onChanged?.call(updatedList);
           }

           Future<void> openUrl(String url) async {
             try {
               final uri = Uri.parse(url);
               if (await canLaunchUrl(uri)) {
                 await launchUrl(uri, mode: LaunchMode.externalApplication);
               } else {
                 ScaffoldMessenger.of(state.context).showSnackBar(
                   SnackBar(
                     content: Text('Не вдалося відкрити файл'),
                     backgroundColor: appThemeColors.errorRed,
                   ),
                 );
               }
             } catch (e) {
               ScaffoldMessenger.of(state.context).showSnackBar(
                 SnackBar(
                   content: Text('Помилка при відкритті файлу: $e'),
                   backgroundColor: appThemeColors.errorRed,
                 ),
               );
             }
           }

           String getFileNameFromUrl(String url) {
             try {
               final uri = Uri.parse(url);
               final path = uri.path;
               if (path.contains('/')) {
                 return path.split('/').last;
               }
               return 'Документ';
             } catch (e) {
               return 'Документ';
             }
           }

           IconData getFileIcon(String fileName) {
             final extension = p.extension(fileName).toLowerCase();
             switch (extension) {
               case '.pdf':
                 return Icons.picture_as_pdf;
               case '.doc':
               case '.docx':
                 return Icons.description;
               case '.png':
               case '.jpg':
               case '.jpeg':
                 return Icons.image;
               case '.txt':
                 return Icons.text_snippet;
               default:
                 return Icons.insert_drive_file;
             }
           }

           String getFileSize(File file) {
             try {
               final bytes = file.lengthSync();
               if (bytes < 1024) {
                 return '$bytes Б';
               } else if (bytes < 1024 * 1024) {
                 return '${(bytes / 1024).toStringAsFixed(1)} КБ';
               } else {
                 return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
               }
             } catch (e) {
               return 'Невідомий розмір';
             }
           }

           final hasExistingDocs =
               initialDocumentUrls != null && initialDocumentUrls.isNotEmpty;
           final hasNewDocs = state.value!.isNotEmpty;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 labelText,
                 style:
                     labelStyle ??
                     TextStyleHelper.instance.title16Bold.copyWith(
                       color: appThemeColors.backgroundLightGrey,
                     ),
               ),
               TextButton.icon(
                 onPressed: pickDocuments,
                 icon: Icon(
                   Icons.add,
                   color: appThemeColors.backgroundLightGrey,
                   size: 20,
                 ),
                 label: Text(
                   'Додати файли',
                   style: TextStyleHelper.instance.title14Regular.copyWith(
                     color: appThemeColors.backgroundLightGrey,
                   ),
                 ),
               ),

               // Існуючі документи
               if (hasExistingDocs) ...[
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: appThemeColors.blueMixedColor.withAlpha(51),
                     borderRadius: BorderRadius.circular(10),
                     border: Border.all(
                       color: appThemeColors.backgroundLightGrey.withAlpha(77),
                     ),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Icon(
                             Icons.folder,
                             color: appThemeColors.backgroundLightGrey,
                             size: 16,
                           ),
                           const SizedBox(width: 8),
                           Text(
                             'Існуючі документи',
                             style: TextStyleHelper.instance.title14Regular
                                 .copyWith(
                                   color: appThemeColors.backgroundLightGrey,
                                   fontWeight: FontWeight.w600,
                                 ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 8),
                       ...initialDocumentUrls.map((url) {
                         final fileName = getFileNameFromUrl(url);

                         return Container(
                           margin: const EdgeInsets.only(bottom: 4),
                           padding: const EdgeInsets.symmetric(
                             horizontal: 12,
                             vertical: 8,
                           ),
                           decoration: BoxDecoration(
                             color: appThemeColors.blueAccent.withAlpha(25),
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(
                               color: appThemeColors.blueAccent.withAlpha(77),
                             ),
                           ),
                           child: Row(
                             children: [
                               Icon(
                                 getFileIcon(fileName),
                                 color: appThemeColors.blueAccent,
                                 size: 20,
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       fileName,
                                       style: TextStyleHelper
                                           .instance
                                           .title14Regular
                                           .copyWith(
                                             color: appThemeColors
                                                 .backgroundLightGrey,
                                             fontWeight: FontWeight.w500,
                                           ),
                                       maxLines: 1,
                                       overflow: TextOverflow.ellipsis,
                                     ),
                                     Text(
                                       'Поточний файл',
                                       style: TextStyleHelper
                                           .instance
                                           .title13Regular
                                           .copyWith(
                                             color: appThemeColors.blueAccent,
                                             fontWeight: FontWeight.w500,
                                           ),
                                     ),
                                   ],
                                 ),
                               ),
                               IconButton(
                                 icon: Icon(
                                   Icons.open_in_new,
                                   color: appThemeColors.blueAccent,
                                   size: 20,
                                 ),
                                 onPressed: () => openUrl(url),
                               ),
                             ],
                           ),
                         );
                       }).toList(),
                     ],
                   ),
                 ),
                 const SizedBox(height: 12),
               ],

               // Нові файли для завантаження
               if (hasNewDocs) ...[
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: appThemeColors.cyanAccent.withAlpha(213),
                     borderRadius: BorderRadius.circular(10),
                     border: Border.all(
                       color: appThemeColors.backgroundLightGrey.withAlpha(77),
                     ),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Icon(
                             Icons.upload_file,
                             color: appThemeColors.blueAccent,
                             size: 16,
                           ),
                           const SizedBox(width: 8),
                           Text(
                             'Нові файли',
                             style: TextStyleHelper.instance.title14Regular
                                 .copyWith(
                                   color: appThemeColors.backgroundLightGrey,
                                   fontWeight: FontWeight.w600,
                                 ),
                           ),
                           const Spacer(),
                           TextButton(
                             onPressed: () {
                               state.didChange([]);
                               onChanged?.call([]);
                             },
                             child: Text(
                               'Очистити',
                               style: TextStyleHelper.instance.title13Regular
                                   .copyWith(color: appThemeColors.errorLight),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 8),
                       ...List.generate(state.value!.length, (index) {
                         final file = state.value![index];
                         final fileName = p.basename(file.path);
                         final fileSize = getFileSize(file);

                         return Container(
                           key: ValueKey(file),
                           margin: const EdgeInsets.only(bottom: 4),
                           padding: const EdgeInsets.symmetric(
                             horizontal: 12,
                             vertical: 8,
                           ),
                           decoration: BoxDecoration(
                             color: appThemeColors.blueAccent.withAlpha(25),
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(
                               color: appThemeColors.blueAccent.withAlpha(77),
                             ),
                           ),
                           child: Row(
                             children: [
                               Icon(
                                 getFileIcon(fileName),
                                 color: appThemeColors.blueAccent,
                                 size: 20,
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       fileName,
                                       style: TextStyleHelper
                                           .instance
                                           .title14Regular
                                           .copyWith(
                                             color: appThemeColors
                                                 .backgroundLightGrey,
                                             fontWeight: FontWeight.w500,
                                           ),
                                       maxLines: 1,
                                       overflow: TextOverflow.ellipsis,
                                     ),
                                     Text(
                                       fileSize,
                                       style: TextStyleHelper
                                           .instance
                                           .title13Regular
                                           .copyWith(
                                             color: appThemeColors
                                                 .backgroundLightGrey
                                                 .withAlpha(178),
                                           ),
                                     ),
                                   ],
                                 ),
                               ),
                               IconButton(
                                 onPressed: () => removeDocument(index),
                                 icon: Icon(
                                   Icons.delete,
                                   color: appThemeColors.errorLight,
                                   size: 20,
                                 ),
                               ),
                             ],
                           ),
                         );
                       }),
                     ],
                   ),
                 ),
               ] else if (!hasExistingDocs) ...[
                 // Плейсхолдер коли немає файлів
                 GestureDetector(
                   onTap: pickDocuments,
                   child: Container(
                     height: 80,
                     width: double.infinity,
                     decoration: BoxDecoration(
                       color:
                           color ?? appThemeColors.blueMixedColor.withAlpha(77),
                       borderRadius: BorderRadius.circular(10),
                       border: Border.all(
                         color: state.hasError
                             ? appThemeColors.errorRed
                             : appThemeColors.backgroundLightGrey,
                         width: 2,
                       ),
                     ),
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(
                           Icons.attach_file,
                           color: appThemeColors.backgroundLightGrey,
                           size: 24,
                         ),
                         const SizedBox(width: 8),
                         Text(
                           'Додати документи',
                           style: TextStyleHelper.instance.title14Regular
                               .copyWith(
                                 color: appThemeColors.backgroundLightGrey,
                               ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           'PDF, DOC, DOCX до 10 МБ',
                           style: TextStyleHelper.instance.title13Regular
                               .copyWith(
                                 color: appThemeColors.backgroundLightGrey
                                     .withAlpha(128),
                               ),
                         ),
                       ],
                     ),
                   ),
                 ),
               ],

               if (state.hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(
                     state.errorText!,
                     style: TextStyle(
                       color: appThemeColors.errorRed,
                       fontSize: 12,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}
