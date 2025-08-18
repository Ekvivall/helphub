import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';

class CustomCheckboxWithText extends FormField<bool> {
  CustomCheckboxWithText({
    super.key,
    bool super.initialValue = false,
    required String text,
    super.onSaved,
    super.validator,
    ValueChanged<bool?>? onChanged,

    Color? activeColor,
    Color? checkColor,
    TextStyle? textStyle,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    bool showErrorsLive = false,
    Color? borderSideColor
  }) : super(
         autovalidateMode: showErrorsLive
             ? AutovalidateMode.onUserInteraction
             : AutovalidateMode.disabled,
         builder: (FormFieldState<bool> state) {
           final defaultActiveColor = activeColor ?? appThemeColors.blueAccent;
           final defaultCheckColor =
               checkColor ?? appThemeColors.backgroundLightGrey;
           final defaultTextStyle =
               textStyle ??
               TextStyleHelper.instance.title13Regular.copyWith(
                 height: 1.2,
                 color: appThemeColors.primaryBlack,
               );

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 crossAxisAlignment: crossAxisAlignment,
                 children: [
                   Checkbox(
                     value: state.value ?? false,
                     onChanged: (bool? newValue) {
                       state.didChange(newValue);
                       if (onChanged != null) {
                         onChanged(newValue);
                       }
                     },
                     activeColor: defaultActiveColor,
                     checkColor: defaultCheckColor,
                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                     side: BorderSide(color: borderSideColor??appThemeColors.primaryBlack),
                   ),
                   Expanded(
                     child: GestureDetector(
                       onTap: () {
                         bool? newValue = !(state.value ?? false);
                         state.didChange(newValue);
                         if (onChanged != null) {
                           onChanged(newValue);
                         }
                       },
                       child: Text(text, style: defaultTextStyle,),
                     ),
                   ),
                 ],
               ),
               if (state.hasError)
                 Padding(
                   padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                   child: Text(
                     state.errorText!,
                     style: TextStyleHelper.instance.title13Regular.copyWith(
                       color: appThemeColors.errorRed,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}
