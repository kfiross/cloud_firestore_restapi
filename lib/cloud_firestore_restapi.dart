library cloud_firestore_restapi;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'src/app_config.dart';
import 'src/exceptions.dart';
import 'src/firestore_collection.dart';

const _authUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';
var _webKey = Firestore.instance.config.webKey;


///
/// Specifies action to be taken with the passed email, password
///
enum AuthAction {
  signUp,
  signInWithPassword,
}


/// ********************************************************
///  A Flutter Package to use the **Cloud Firestore REST API
/// ********************************************************


AppConfig _config;

class Firestore {

  AppConfig get config => _config;

  static Firestore instance = Firestore._();
  Firestore._();

  static initializeApp({@required projectId,@required webKey}){
    _config = AppConfig(
        projectId,
        webKey,
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents'
    );
  }

  FirestoreCollection collection(String collectionName){
    return FirestoreCollection(collectionName);
  }


  static Map<String, dynamic> mapFirestoreToDart(String jsonString) {
    final doc = json.decode(jsonString);
    Map<String, dynamic> item = {};
    final fields = doc['fields'];
    fields.forEach((k, v) => {item[k] = parse(v)});
    return item;
  }




  ///
  /// Authentication API
  ///

  ///
  /// Returns idToken, expiryDate, userId in a Map
  /// if successful or null
  /// Specify either AuthAction.signUp for a new login
  /// registration or AuthAction.signInWithEmailPassword
  /// Throws Exception on failure or error
  ///

  Future<Map<String, dynamic>> signInOrSignUp({
    String email,
    String password,
    AuthAction action,
  }) async {
    try {
      final response = await http.post('$_authUrl:${describeEnum(action)}?key=$_webKey',
          body: json.encode(
            {
              'email': email,
              'password': password,
              'returnSecureToken': true,
            },
          ));



      final body = json.decode(response.body);

      // set token for authorized requests calls
      _config.setToken(body['idToken']);

      if (response.statusCode >= 400) {
        throw HttpException(body['error']['message']);
      }
      return body;
    } catch (error) {
      throw HttpException(error.toString());
    }
  }

  ///
  ///  Supporting methods & classes
  ///

// Deserialize/Serialize methods

  ///
  /// returns integer value of argument passed.
  /// returns double if value is double
  /// Can be coerced to a double by passing double as type
  ///
  static dynamic intTryParse(dynamic value, [String type]) {
    if (value == null) return 0;
    if (type != null && type == 'double') return doubleTryParse(value);
    return value.runtimeType.toString() == 'String'
        ? int.tryParse(value)
        : value;
  }

  ///
  /// returns double value of argument passed.
  /// returns integer if value is integer
  /// Can be coerced to a integer by passing int as type
  ///
  static dynamic doubleTryParse(dynamic value, [String type]) {
    if (value == null) return 0.0;
    if (type != null && type == 'int') return intTryParse(value);
    var val = value.runtimeType.toString() == 'String' && !value.contains('.')
        ? value + '.0'
        : value * 1.0;
    return val.runtimeType.toString() == 'String' ? double.tryParse(val) : val;
  }

  ///
  /// returns the Google Firestore type of the value passed
  ///

  static Map<String, dynamic> encode(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is int) return {'integerValue': value};
    if (value is double) return {'doubleValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is DateTime) return {'timestampValue': value.toIso8601String()};
    if (value is Map) return {'mapValue': serialize( item: value )};
    if (value is List) {
      final list = [];
      value.forEach((v) {
        list.add(encode(v));
      });
      return {'arrayValue': {"values": list}};
    }

    return {'stringValue': value is String ? value : value.toString()};
  }

  ///
  /// Returns dart value from firestore value passed
  /// Can coerce the return type by passing either 'int' or 'double' as type
  ///
  static dynamic parse(dynamic valueMap, [String type]) {
    dynamic fieldValue;
    if (valueMap == null) {
      return null;
    }

    valueMap.forEach((key, value) {
      try {
        switch (key) {
          case 'booleanValue':
            fieldValue = value as bool;
            break;
          case 'stringValue':
            fieldValue = value as String;
            break;
          case 'integerValue':
            fieldValue = intTryParse(value, type);
            break;
          case 'doubleValue':
            fieldValue = doubleTryParse(value, type);
            break;
          case 'timestampValue':
            fieldValue = value.runtimeType.toString() == 'String'
                ? DateTime.parse(value)
                : value;
            break;
          case 'mapValue':
            final fields = value['fields'] as Map<String, dynamic>;
            var arrayMap = {};
            fields.forEach((fkey, fvalue) {
              arrayMap[fkey] = parse(fvalue as Map<String, dynamic>);
            });
            fieldValue = arrayMap;
            break;
          case 'arrayValue':
            List<dynamic> list = [];
            final valList = value['values'] as List<dynamic>;
            if (valList != null)
              valList.forEach((item) {
                final fields =
                item['mapValue']['fields'] as Map<String, dynamic>;
                var arrayMap = {};
                fields.forEach((fkey, fvalue) {
                  arrayMap[fkey] = parse(fvalue as Map<String, dynamic>);
                });
                list.add(arrayMap);
              });

            fieldValue = list;
            break;
          default:
            break;
        }
      } catch (error) {
        // print(error.toString());
        fieldValue = null;
      }
    });
    return fieldValue;
  }

  ///
  /// Returns a Map with firestore value objects
  /// required by the API for updating firestore
  ///

  static Map<String, dynamic> serialize({
    Map<String, dynamic> item,
  }) {
    Map<String, dynamic> n = {};
    item.forEach((k, v) {
      n[k] = encode(v);
    });
    return {'fields': n};
  }

  ///
  /// Returns a Map with dart values for keys
  /// given  a Map obtained from reading Firestore
  /// can be coerced to int/double by passing
  /// schema of the model
  ///
  static Map<String, dynamic> deserialize(Map<String, dynamic> fields,
      [Map<String, String> schema]) {
    Map<String, dynamic> items = {};

    fields.forEach((field, value) {
      var val = parse(value, schema[field]);
      items[field] = val;
    });
    return items;
  }

  ///
  /// converts doubles, ints, date  string values
  /// to correct dart types

  static dynamic stringToValue(String type, String val) {
    switch (type) {
      case 'double':
        return doubleTryParse(val);
      case 'int':
        return intTryParse(val);
      case 'date':
        return DateTime.parse(val);
    }
    return val;
  }

  ///
  /// Converts a value to a given type
  /// required to correctly convert ints, doubles
  /// dates

  static String valueToString(String type, dynamic val) {
    if (val == null) return '';
    switch (type) {
      case 'double':
        return val.toStringAsFixed(2);
      case 'int':
        return val.toString();
      case 'date':
        return val.toLocal().toString();
      default:
        return val.toString();
    }
  }
} // end class definition

