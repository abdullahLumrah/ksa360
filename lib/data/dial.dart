import 'package:url_launcher/url_launcher.dart';

Future<void> callNumber(String number) async {
  final cleaned = String.fromCharCodes(
    number.codeUnits.where((c) => (c >= 48 && c <= 57) || c == 43),
  );
  final uri = Uri(scheme: 'tel', path: cleaned);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> openMap(double lat, double lng, String name) async {
  final encoded = Uri.encodeComponent(name);
  final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encoded)');
  if (await canLaunchUrl(geo)) {
    await launchUrl(geo);
    return;
  }
  final web = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  await launchUrl(web, mode: LaunchMode.externalApplication);
}
