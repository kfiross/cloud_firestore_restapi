import 'dart:convert';

import '../cloud_firestore_restapi.dart';

import 'package:http/http.dart' as http;

import 'exceptions.dart';

class FirestoreDocument {
  final String collectionName;
  final String documentID;
  final Map<String, dynamic> data;

  var _baseUrl = Firestore.instance.config.baseUrl;
  var _webKey = Firestore.instance.config.webKey;
  var _accessToken = Firestore.instance.config.idToken;

  FirestoreDocument(this.collectionName, this.documentID, {this.data});

  ///
  /// getter for the existence of the document
  ///
  bool get exists => data != null;

  get key => documentID;

  ///
  /// returns the document's data
  ///
  Future<FirestoreDocument> get() async {
    final endpoint = '$_baseUrl/$collectionName/$documentID?key=$_webKey';

    try {
      final response = _accessToken == null
          ? await http.get(endpoint)
          : await http.get(endpoint,
          headers: {"Authorization": "Bearer $_accessToken"});

      if (response.statusCode < 400) {
        Map<String, dynamic> map = Firestore.mapFirestoreToDart(response.body);
        return FirestoreDocument(collectionName, documentID, data: map);
      } else {
        print(//throw HttpException(
            'Error reading $collectionName. ${response.reasonPhrase}');
      }
    } catch (error) {
      print(//throw HttpException(
          'Error reading $collectionName. ${error.toString()}');
    }

    // if error occurs, no data will be
    return FirestoreDocument(collectionName, documentID);
  }

  /// Updates firestore document specified by **id**
  /// [data] contains a map with records contents
  /// only fields in the body are updated.
  /// Adds a new document to the collection if there is no document corresponding to the [id]
  /// and [addNew] is true - set false
  ///
  /// Throws [HttpException] on error
  ///

  Future<void> updateData(Map<String, dynamic> data) async {
    try {
      String updateMask = '';
      data.keys.forEach((k) {
        updateMask += '&updateMask.fieldPaths=$k';
      });
      final response = await http.patch(
        '$_baseUrl/$collectionName/$documentID?key=$_webKey$updateMask',
        body: json.encode(Firestore.serialize(
          item: data,
        )),
      );

      if (response.statusCode >= 400) {
          throw HttpException('Error updating $collectionName/$documentID. ${response.reasonPhrase}');
      }
    } catch (error) {
      throw HttpException('Error updating $collectionName/$documentID. ${error.toString()}');
    }
  }

  ///
  /// Deletes the document from the collection
  ///
  /// Throws exception if document does not exist
  /// Throws exception on I/O error

  Future<void> delete() async {
    try {
      await http.put(
          '$_baseUrl/$collectionName/$documentID?key=$_webKey');
    } catch (error) {
      throw HttpException('Error deleting $collectionName/$documentID. ${error.toString()}');
    }
  }
}