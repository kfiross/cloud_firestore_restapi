///
/// Implements Exception class to encapsulate Http errors - both io errors
/// and http response errors as error text
///

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}