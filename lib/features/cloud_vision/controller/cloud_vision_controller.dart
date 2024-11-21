import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

    for (final image in images) {
      final bytes = image.readAsBytesSync();

      final format = _getImageExtension(image);
      if (format == null) {
        continue;
      }

      if (format == 'png' || format == 'jpg' || format == 'jpeg') {
        base64Images.add(base64Encode(bytes));
      } else if (format == 'webp') {
        final convertedImage = _convertToPng(bytes);
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
