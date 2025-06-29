import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:helphub/theme/theme_helper.dart';

import '../core/utils/image_constant.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http') || startsWith('https')) {
      if (endsWith('.svg')) {
        return ImageType.networkSvg;
      }
      return ImageType.network;
    } else if (endsWith('.svg')) {
      return ImageType.svg;
    } else if (startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, networkSvg, file, unknown }

class CustomImageView extends StatelessWidget {
  final String? imagePath;
  final double? height;
  final double? width;
  final Color? color;
  final BoxFit? fit;
  final String? placeHolder; // Для CachedNetworkImage (помилка/плейсхолдер)
  final Alignment? alignment;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? radius;
  final BoxBorder? border;

  final String _resolvedImagePath;

  CustomImageView({
    super.key,
    this.imagePath,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder,
  }) : _resolvedImagePath = (imagePath == null || imagePath.isEmpty)
           ? ImageConstant.imgImageNotFound
           : imagePath;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildCoreImageView();
    if (radius != null) {
      imageWidget = ClipRRect(borderRadius: radius!, child: imageWidget);
    }
    if (border != null) {
      imageWidget = Container(
        decoration: BoxDecoration(border: border, borderRadius: radius),
        child: imageWidget,
      );
    }
    imageWidget = InkWell(onTap: onTap, child: imageWidget);

    imageWidget = Padding(
      padding: margin ?? EdgeInsets.zero,
      child: imageWidget,
    );

    return alignment != null
        ? Align(alignment: alignment!, child: imageWidget)
        : imageWidget;
  }

  Widget _buildCoreImageView() {
    switch (_resolvedImagePath.imageType) {
      case ImageType.svg:
        return SvgPicture.asset(
          _resolvedImagePath,
          height: height,
          width: width,
          fit: fit ?? BoxFit.contain,
          colorFilter: color != null
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : null,
        );
      case ImageType.file:
        return Image.file(
          File(_resolvedImagePath),
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
        );
      case ImageType.networkSvg:
        return SvgPicture.network(
          _resolvedImagePath,
          height: height,
          width: width,
          fit: fit ?? BoxFit.contain,
          colorFilter: color != null
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : null,
        );
      case ImageType.network:
        return CachedNetworkImage(
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          imageUrl: _resolvedImagePath,
          color: color,
          placeholder: (context, url) => Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(appThemeColors.grey400),
              backgroundColor: appThemeColors.grey100,
            ),
          ),
          errorWidget: (context, url, error) => Image.asset(
            placeHolder ?? ImageConstant.imgImageNotFound,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
          ),
        );
      case ImageType.png:
      default:
        return Image.asset(
          _resolvedImagePath,
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
        );
    }
  }
}
