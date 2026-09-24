/// Returns a Firestore-safe, lowercase tag name, or an empty string if invalid.
String normalizeTag(String raw) {
  var tag = raw.trim();
  while (tag.startsWith('#') || tag.startsWith('＃')) {
    tag = tag.substring(1);
  }
  tag = tag.replaceAll(RegExp(r'\s+'), '').replaceAll('/', '');
  if (tag.length > 20) tag = tag.substring(0, 20);
  tag = tag.toLowerCase();
  if (tag == '.' || tag == '..') return '';
  if (tag.startsWith('__') && tag.endsWith('__')) return '';
  return tag;
}
