const postImageFallback = 'frontend/assets/images/anhPhongDemo.jpg';
const uploadedPostImagePrefix = '/uploads/posts/';
const postImageApiOrigin = 'http://10.0.2.2:5093';

bool isPostImageAsset(String path) =>
    path.startsWith('frontend/assets/images/') ||
    path.startsWith('assets/images/');

bool isSharedPostImage(String path) {
  if (isPostImageAsset(path) || path.startsWith(uploadedPostImagePrefix)) {
    return true;
  }
  final uri = Uri.tryParse(path);
  return uri != null &&
      uri.hasAuthority &&
      (uri.scheme == 'http' || uri.scheme == 'https');
}

String postImageDisplayPath(String path) {
  if (path.startsWith('assets/images/')) return 'frontend/$path';
  if (path.startsWith(uploadedPostImagePrefix)) {
    return '$postImageApiOrigin$path';
  }
  return path;
}
