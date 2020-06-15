import '../cloud_firestore_restapi.dart';

import 'package:http/http.dart' as http;



class FirestoreDocument {
  final String collectionName;
  final String key;
  Map<String, dynamic> data;

  var _baseUrl = Firestore.instance.config.baseUrl;
  var _webKey = Firestore.instance.config.webKey;
  var _accessToken = Firestore.instance.config.idToken;

  FirestoreDocument(this.collectionName, this.key, {this.data});

  ///
  /// getter for the existence of the document
  ///
  bool get exists => data != null;

  ///
  /// returns the document data
  ///
  Future<FirestoreDocument> get() async {
    final endpoint = '$_baseUrl/$collectionName/$key?key=$_webKey';

    try {
      final response = _accessToken == null
          ? await http.get(endpoint)
          : await http.get(endpoint,
          headers: {"Authorization": "Bearer $_accessToken"});

      if (response.statusCode < 400) {
        Map<String, dynamic> map = Firestore.mapFirestoreToDart(response.body);
        return FirestoreDocument(collectionName, key, data: map);
      } else {
        print(//throw HttpException(
            'Error reading $collectionName. ${response.reasonPhrase}');
      }
    } catch (error) {
      print(//throw HttpException(
          'Error reading $collectionName. ${error.toString()}');
    }

    // if error occurs, no data will be
    return FirestoreDocument(collectionName, key);
  }
}