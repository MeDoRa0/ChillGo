import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';

class PickedAvatar {
  final List<int> bytes;
  final String fileExtension;

  const PickedAvatar({required this.bytes, required this.fileExtension});
}

class ImageHelper {
  static const int maxAvatarBytes = 500 * 1024;
  static const int maxAvatarDimension = 512;

  final ImagePicker _picker;

  ImageHelper({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<PickedAvatar?> pickAndCompressAvatar(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: maxAvatarDimension.toDouble(),
      maxHeight: maxAvatarDimension.toDouble(),
      imageQuality: 85,
    );

    if (pickedFile == null) return null;

    final originalBytes = await pickedFile.readAsBytes();
    final decoded = image.decodeImage(originalBytes);
    if (decoded == null) {
      throw const FormatException('Selected file is not a supported image');
    }

    final resized = _resizeForAvatar(decoded);
    final compressed = _encodeJpegUnderLimit(resized);

    return PickedAvatar(bytes: compressed, fileExtension: 'jpg');
  }

  image.Image _resizeForAvatar(image.Image source) {
    final longestSide = source.width > source.height
        ? source.width
        : source.height;
    if (longestSide <= maxAvatarDimension) return source;

    return image.copyResize(
      source,
      width: source.width >= source.height ? maxAvatarDimension : null,
      height: source.height > source.width ? maxAvatarDimension : null,
      interpolation: image.Interpolation.average,
    );
  }

  List<int> _encodeJpegUnderLimit(image.Image src) {
    // First pass: reduce quality on the original (possibly pre-resized) image.
    for (var quality = 85; quality >= 45; quality -= 10) {
      final encoded = image.encodeJpg(src, quality: quality);
      if (encoded.length <= maxAvatarBytes) {
        return Uint8List.fromList(encoded);
      }
    }

    // Quality reductions were not enough – halve the dimensions and retry.
    final downscaled = image.copyResize(
      src,
      width: (src.width / 2).round(),
      height: (src.height / 2).round(),
      interpolation: image.Interpolation.average,
    );

    for (var quality = 85; quality >= 45; quality -= 10) {
      final encoded = image.encodeJpg(downscaled, quality: quality);
      if (encoded.length <= maxAvatarBytes) {
        return Uint8List.fromList(encoded);
      }
    }

    throw StateError(
      'Image cannot be compressed to fit within '
      '${maxAvatarBytes ~/ 1024} KB even after downscaling. '
      'Please choose a smaller or simpler image.',
    );
  }
}
