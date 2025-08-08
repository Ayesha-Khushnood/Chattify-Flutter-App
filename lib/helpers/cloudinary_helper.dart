import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryHelper {
  static const String cloudName = 'dsd0dmx5c'; // change this
  static const String uploadPreset = 'Chattify'; // change this

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      return data['secure_url'];
    } else {
      print('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }
}
