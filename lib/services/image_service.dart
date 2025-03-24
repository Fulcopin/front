import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final cloudinary = CloudinaryPublic(
    'dpczd4ufe',  // Cloud name
    'ml_default', // Upload preset
  );
  static final String _cloudName = 'dpczd4ufe';
 // Update CloudinaryService
static Future<String?> uploadImage(File image) async {
  try {
    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        image.path,
        folder: 'products',
        
      ),
    );
    
    print('Image uploaded: ${response.secureUrl}');
    return response.secureUrl;
  } catch (e) {
    print('Cloudinary upload error: $e');
    return null;
  }
}

  static Future<String?> uploadProductImage(File image, String productId) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: 'products',
          resourceType: CloudinaryResourceType.Image,
          publicId: 'product_$productId',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Product image upload error: $e');
      return null;
    }
  }

   static String getImageUrl(String publicId) {
    return 'https://res.cloudinary.com/$_cloudName/image/upload/$publicId';
  }
}