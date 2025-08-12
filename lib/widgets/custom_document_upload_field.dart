import 'package:flutter/material.dart';

import '../theme/text_style_helper.dart';
import '../theme/theme_helper.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CustomImageUploadField extends FormField<File> {
  CustomImageUploadField({
    super.key,
    required String labelText,
    ValueChanged<File?>? onChanged,
    super.onSaved,
    super.validator,
    super.initialValue,
  }) : super(
         builder: (FormFieldState<File> state) {
           Future<void> pickImage() async {
             final ImagePicker picker = ImagePicker();
             final XFile? image = await picker.pickImage(
               source: ImageSource.gallery,
             );
             if (image != null) {
               final file = File(image.path);
               state.didChange(file);
               onChanged?.call(file);
             }
           }

           void clearImage() {
             state.didChange(null);
             onChanged?.call(null);
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 labelText,
                 style: TextStyleHelper.instance.title16Bold.copyWith(
                   color: appThemeColors.backgroundLightGrey,
                 ),
               ),
               const SizedBox(height: 8),
               if (state.value != null)
                 // --- Вигляд з обраним зображенням ---
                 Container(
                   height: 200,
                   width: double.infinity,
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(10),
                     image: DecorationImage(
                       image: FileImage(state.value!),
                       fit: BoxFit.cover,
                     ),
                   ),
                   child: Stack(
                     children: [
                       Positioned(
                         top: 8,
                         right: 8,
                         child: GestureDetector(
                           onTap: clearImage,
                           child: Container(
                             padding: const EdgeInsets.all(4),
                             decoration: BoxDecoration(
                               color: appThemeColors.errorRed.withAlpha(177),
                               borderRadius: BorderRadius.circular(15),
                             ),
                             child: Icon(
                               Icons.close,
                               color: appThemeColors.primaryWhite,
                               size: 20,
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                 )
               else
                 // --- Вигляд-заповнювач для вибору зображення ---
                 GestureDetector(
                   onTap: pickImage,
                   child: Container(
                     height: 120,
                     width: double.infinity,
                     decoration: BoxDecoration(
                       color: appThemeColors.blueMixedColor.withAlpha(77),
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
                           Icons.add_a_photo,
                           color: appThemeColors.backgroundLightGrey,
                           size: 40,
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Додати фото',
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

