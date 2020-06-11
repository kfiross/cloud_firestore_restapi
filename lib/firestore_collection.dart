import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'cloud_firestore_restapi.dart';
import 'package:http/http.dart' as http;

var _baseUrl = Firestore.instance.config.baseUrl;
var _webKey = Firestore.instance.config.webKey;
var _accessToken = Firestore.instance.config.idToken;

class FirestoreDocument {
  String collectionName;
  String key;
  Map<String, dynamic> data;

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

class FirestoreCollection {
  final String name;

  FirestoreCollection(this.name);

  FirestoreDocument document(String documentName) {
    return FirestoreDocument(name, documentName);
  }

  ///
  /// Returns all documents in a collection as List<Map<String, dynamic>> .
  /// #### Parameters
  /// **collection** name of the collection root. example: 'users', 'users/seniors'
  /// #### Optional Parameters
  /// **sort** Specifies more than one sort fields List: [ {'field: 'date', 'direction': 'ASCENDING' },]. If it's just one field you may use **sortField**, **sortOrder** parameters.Direction can be either 'ASCENDING' or 'DESCENDING'.
  ///
  /// **query** Specifies multiple filters linked by *AND*.
  /// **query** is a List of Query objects.
  ///
  /// **keyField**, **keyOp**, **keyValue** can be used fopr single condition.
  ///
  ///
  Future<List<FirestoreDocument>> snapshots({
//    String collection,
    String sortField,
    String sortOrder = 'ASCENDING',
    String keyField,
    String keyOp = 'EQUAL',
    String keyValue,
    List<Map<String, dynamic>> sort,
    List<Query> query,
  }) async {
    List<FirestoreDocument> items = [];
    try {
      Map<String, Map<String, dynamic>> sQuery = {
        "structuredQuery": {
          "from": [
            {"collectionId": name},
          ],
        }
      };
      if (sortField != null) {
        sQuery['structuredQuery']['orderBy'] = [
          {
            "field": {"fieldPath": sortField},
            "direction": sortOrder
          },
        ];
      } else if (sort != null) {
        List<Map<String, dynamic>> fields = [];
        sort.forEach((item) {
          fields.add({
            "field": {"fieldPath": item['field']},
            "direction": item['direction'],
          });
        });
        sQuery['structuredQuery']['orderBy'] = fields;
      }
      if (keyField != null) {
        sQuery['structuredQuery']['where'] = {
          "fieldFilter": {
            "field": {"fieldPath": keyField},
            "op": keyOp,
            "value": Firestore.encode(keyValue),
          }
        };
      } else if (query != null) {
        List<Map<String, dynamic>> rows = [];

        // ensure input order
        for (int i = 0; i < query.length; i++) {
          rows.add({
            'fieldfilter': {
              "field": {"fieldPath": query[i].field},
              "op": describeEnum(query[i].op),
              "value": Firestore.encode(query[i].value),
            },
          });
        }
        // TODO: allow queries of aribitrary complexities

        sQuery['structuredQuery']['where'] = {
          "compositeFilter": {
            "filters": rows,
            "op": 'AND',
          }
        };
      }

      final response = await http.post(
        '$_baseUrl:runQuery?key=$_webKey',
        body: json.encode(sQuery),
      );

      if (response.statusCode < 400) {
        final docs = json.decode(response.body);

        docs.forEach((doc) async {
          Map<String, dynamic> item = {};
          final fields = doc['document']['fields'];

          fields.forEach((k, v) => {item[k] = Firestore.parse(v)});
          String key /*item['\$id']*/ = doc['document']['name'].split('/').last;

          items.add(FirestoreDocument(name, key, data: item));
        });
        return items;
      } else {
        //throw HttpException('Error reading $name. ${response.reasonPhrase}');
        print('Error reading $name. ${response.reasonPhrase}');
      }
    } catch (error) {
      //throw HttpException('Error reading $name. ${error.toString()}');
      print('Error reading $name. ${error.toString()}');
    }

    return items;
  }
}
