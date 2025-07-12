class ServerException implements Exception {
  final String? message;
  const ServerException({this.message});
}

class CacheException implements Exception {
  final String? message;
  const CacheException({this.message});
}

class NetworkException implements Exception {
  final String? message;
  const NetworkException({this.message});
}

class BadRequestException implements Exception {
  final String? message;
  const BadRequestException({this.message});
}

class UnauthorizedException implements Exception {
  final String? message;
  const UnauthorizedException({this.message});
}

class NotFoundException implements Exception {
  final String? message;
  const NotFoundException({this.message});
}

class FetchDataException implements Exception {
  final String? message;
  const FetchDataException({this.message});
}

class NoInternetConnectionException implements Exception {
  final String? message;
  const NoInternetConnectionException({this.message});
}

class RequestCancelledException implements Exception {
  final String? message;
  const RequestCancelledException({this.message});
}