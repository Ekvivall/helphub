import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  }) : super(
         initialValue: initialValue ?? [],
         builder: (FormFieldState<List<File>> state) {
           Future<void> pickDocuments() async {
             FilePickerResult? result = await FilePicker.platform.pickFiles(
               allowMultiple: true,
               type: FileType.custom,
               allowedExtensions: allowedExtensions,
             );

             if (result != null) {
               List<File> newFiles = result.paths
                   .map((path) => File(path!))
                   .toList();
               final updatedList = [...state.value!, ...newFiles];
               state.didChange(updatedList);
               onChanged?.call(updatedList);
             }
           }

           void removeDocument(int index) {
             final updatedList = [...state.value!];
             updatedList.removeAt(index);
             state.didChange(updatedList);
             onChanged?.call(updatedList);
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 labelText,
                 style: labelStyle?? TextStyleHelper.instance.title16Bold.copyWith(
                   color: appThemeColors.backgroundLightGrey,
                 ),
               ),
               const SizedBox(height: 8),
               // --- Список обраних документів ---
               if (state.value!.isNotEmpty)
                 Column(
                   children: List.generate(state.value!.length, (index) {
                     final file = state.value![index];
                     return Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       padding: const EdgeInsets.symmetric(
                         horizontal: 12,
                         vertical: 4,
                       ),
                       decoration: BoxDecoration(
                         color:appThemeColors.blueMixedColor,
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Row(
                         children: [
                           Icon(
                             Icons.description,
                             color: appThemeColors.primaryBlack,
                           ),
                           const SizedBox(width: 8),
                           Expanded(
                             child: Text(
                               file.path.split(Platform.pathSeparator).last,
                               style: TextStyleHelper.instance.title14Regular
                                   .copyWith(
                                     color: appThemeColors.primaryBlack,
                                   ),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                           IconButton(
                             onPressed: () => removeDocument(index),
                             icon: Icon(
                               Icons.delete,
                               color: appThemeColors.errorRed,
                             ),
                           ),
                         ],
                       ),
                     );
                   }),
                 ),
               // --- Кнопка для додавання документів ---
               GestureDetector(
                 onTap: pickDocuments,
                 child: Container(
                   height: 60,
                   width: double.infinity,
                   decoration: BoxDecoration(
                     color: color?? appThemeColors.blueMixedColor.withAlpha(77),
                     borderRadius: BorderRadius.circular(10),
                     border: Border.all(
                       color: state.hasError
                           ? appThemeColors.errorRed
                           : appThemeColors.backgroundLightGrey,
                       width: 2,
                     ),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(
                         Icons.attach_file,
                         color: appThemeColors.backgroundLightGrey,
                       ),
                       const SizedBox(width: 8),
                       Text(
                         'Додати документи',
                         style: TextStyleHelper.instance.title14Regular
                             .copyWith(
                               color: appThemeColors.backgroundLightGrey,
                             ),
                       ),
                     ],
                   ),
                 ),
               ),
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
