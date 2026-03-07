import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  //get the firebase storage to store the image 
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ================================================================================
  // ====== method to upload the image and return the download URL====================
  // ================================================================================
  Future<String> uploadImage({
    required String uid,
    required File imageFile,
    required String category,
  }) async {
    try {
      // Create a unique name for the file based on the timestamp and original extension
      String fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Create the storage path in the form users/uid/category/filename
      // e.g., users/test1-assistant/nic/1715000000.jpg
      String storagePath = 'users/$uid/$category/$fileName';
      
      // get the path along with the reference of the storage
      Reference ref = _storage.ref().child(storagePath);
      
      // task for uploading the image
      UploadTask uploadTask = ref.putFile(imageFile);
      
      // actually call the above task to complete and get the snapshot
      TaskSnapshot snapshot = await uploadTask;
      
      // return the  URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Error uploading image: $e';
    }
  }
}