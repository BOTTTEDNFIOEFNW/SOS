import '../constants/api_constants.dart';

String resolveFileUrl(String? path) {
  if (path == null || path.trim().isEmpty) return '';

  if (path.startsWith('http')) return path;

  return '${ApiConstants.fileBaseUrl}$path';
}
