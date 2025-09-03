import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ImageLabelService {
  /// Download Cloudinary image and extract ML Kit labels
  static Future<List<String>> getLabelsFromUrl(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/temp.jpg');
    await file.writeAsBytes(response.bodyBytes);

    final inputImage = InputImage.fromFile(file);

    // ✅ Fix: add options
    final options = ImageLabelerOptions(confidenceThreshold: 0.7);
    final labeler = ImageLabeler(options: options);

    final labels = await labeler.processImage(inputImage);
    await labeler.close();

    return labels.map((e) => e.label).toList();
  }
}
