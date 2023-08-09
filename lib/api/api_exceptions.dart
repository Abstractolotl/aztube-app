// ignore_for_file: public_member_api_docs, sort_constructors_first
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException $statusCode: $message';
}
