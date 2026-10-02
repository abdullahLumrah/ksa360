/// Maps SDK + Places. Restrict this key in Google Cloud to Android/iOS
/// apps (`com.ksaguide.ksa360`), Maps SDK, and Places API (New).
const kGoogleMapsApiKey = 'AIzaSyAUjMG0glAvJsfUZJ-D0KPU_JC_foYbJqM';

const kGoogleMapsDarkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0E1412"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#A8B5AD"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0E1412"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2A3530"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#D4B483"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#12201A"},{"visibility":"on"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1C2823"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0B0F0E"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8F9A93"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#32463C"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#D4B483"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#071018"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4A6A88"}]}
]
''';
