import 'dart:convert';

import 'exceptions.dart';
import 'firestore_document.dart';
import 'query.dart';
import 'package:flutter/foundation.dart';

import '../cloud_firestore_restapi.dart';
import 'package:http/http.dart' as http;

var _baseUrl = Firestore.instance.config.baseUrl;
var _webKey = Firestore.instance.config.webKey;

class FirestoreCollection {
  final String id;

  FirestoreCollection(this.id);

  /// Returns a `FirestoreDocument` with the provided path.
  ///
  /// If no [path] is provided, an auto-generated ID is used.
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  FirestoreDocument document([String path]) {
    return FirestoreDocument(id, path);
  }

  ///
  /// Returns all documents in a collection as List<FirestoreDocument> .

  /// [sort] Specifies more than one sort fields List: [ {'field: 'date', 'direction': 'ASCENDING' },]. If it's just one field you may use **sortField**, **sortOrder** parameters.Direction can be either 'ASCENDING' or 'DESCENDING'.
  /// [query] Specifies multiple filters linked by *AND*.is a List of Query objects.
  /// [keyField], [keyOp], [keyValue] can be used fpr single condition.
  ///
  Future<List<FirestoreDocument>> getDocuments({
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
            {"collectionId": id},
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

          items.add(FirestoreDocument(id, key, data: item));
        });
        return items;
      } else {
        //throw HttpException('Error reading ${this.id}. ${response.reasonPhrase}');
        print('Error reading ${this.id}. ${response.reasonPhrase}');
      }
    } catch (error) {
      //throw HttpException('Error reading ${this.id}. ${error.toString()}');
      print('Error reading ${this.id}. ${error.toString()}');
    }

    return items;
  }

  /// Returns a `FirestoreDocument` with an auto-generated ID, after
  /// populating it with provided [data].
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  Future<FirestoreDocument> add({
    Map<String, dynamic> body,
    dynamic id,
  }) async {
    try {
      final docId = id != null
          ? '/${id.runtimeType.toString() == 'String' ? id : id.toString()}'
          : '';
      final response = await http.post(
        '$_baseUrl/${this.id}$docId/?key=$_webKey',
        body: json.encode(Firestore.serialize(
          item: body,
        )),
      );
      // there is an error
      if (response.statusCode >= 400) {
        throw HttpException(
            'Error adding ${this.id}. ${response.reasonPhrase}');
      }
      var map = Firestore.mapFirestoreToDart(response.body);
      return FirestoreDocument(this.id, docId, data: map);
    } catch (error) {
      throw HttpException('Error adding ${this.id}. ${error.toString()}');
    }
  }

}
