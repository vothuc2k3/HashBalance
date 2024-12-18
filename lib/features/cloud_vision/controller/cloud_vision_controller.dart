import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:image/image.dart' as img;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/cloud_vision/repository/cloud_vision_repository.dart';

final cloudVisionControllerProvider = Provider((ref) {
  return CloudVisionController(
    cloudVisionRepository: ref.read(cloudVisionRepositoryProvider),
  );
});

class CloudVisionController {
  final CloudVisionRepository _cloudVisionRepository;

  CloudVisionController({
    required CloudVisionRepository cloudVisionRepository,
  }) : _cloudVisionRepository = cloudVisionRepository;

  Future<List<String>> _encodeImagesToBase64(List<File> images) async {
    List<String> base64Images = [];
    const maxSize = 500 * 1024;
    const maxQuality = 50;
    const stepSize = 10;

    for (final image in images) {
      final originalSize = image.lengthSync();

      if (originalSize < maxSize) {
        base64Images.add(base64Encode(image.readAsBytesSync()));
        continue;
      }

      int quality = maxQuality;
      List<int>? compressedBytes;
      while (quality > 0) {
        compressedBytes = await FlutterImageCompress.compressWithFile(
          image.absolute.path,
          quality: quality,
        );

        if (compressedBytes != null && compressedBytes.length < maxSize) {
          break;
        }

        quality -= stepSize;
      }

      final format = _getImageExtension(image);
      if (format == null) {
        continue;
      }

      if (format == 'png' || format == 'jpg' || format == 'jpeg') {
        base64Images.add(base64Encode(compressedBytes!));
      } else if (format == 'webp') {
        final convertedImage = _convertToPng(compressedBytes!);
        base64Images.add(base64Encode(convertedImage));
      }
    }

    return base64Images;
  }

  String? _getImageExtension(File image) {
    final path = image.path.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'jpg';
    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.webp')) return 'webp';
    return null;
  }

  List<int> _convertToPng(List<int> bytes) {
    final originalImage = img.decodeImage(Uint8List.fromList(bytes));

    if (originalImage == null) {
      return bytes;
    }

    return img.encodePng(originalImage);
  }

  Future<Either<Failures, bool>> areImagesSafe(List<File> images) async {
    final base64Images = await _encodeImagesToBase64(images);
    return await _cloudVisionRepository.areImagesSafe(base64Images);
  }
}
