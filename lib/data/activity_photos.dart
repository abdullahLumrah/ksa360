import '../models/activity.dart';

String _shot(String id) =>
    'https://images.unsplash.com/$id?auto=format&fit=crop&w=1000&q=72';

const _kindShots = <String, List<String>>{
  'cinema': [
    'photo-1489599849927-2ee91cede3ba',
    'photo-1440404653325-ab127d49abc1',
    'photo-1489599849927-2ee91cede3ba',
    'photo-1517604931442-73e72f0e5f36',
    'photo-1478720568477-1520c2d40b3d',
    'photo-1536440136628-849c177e76a1',
    'photo-1524985069026-dd778a71c7b4',
    'photo-1595769816263-9b910be24d5f',
    'photo-1461151304267-38535e780c79',
    'photo-1574267432553-4b46210174a2',
    'photo-1518676590629-3dcbd9c4a1c4',
    'photo-1542204165-65bf26472b9b',
  ],
  'bowl': [
    'photo-1612872087720-bb876e2e67d1',
    'photo-1566577739112-5180d4bf9390',
    'photo-1534158914592-062992fbe900',
    'photo-1578662996442-48f60103fc96',
    'photo-1464983953574-0892a716854b',
    'photo-1511882150382-421056c89033',
    'photo-1574629810360-7efbbe195018',
    'photo-1546519638-68e109498ffc',
  ],
  'speed': [
    'photo-1541443131876-44b03de101c5',
    'photo-1503376780353-7e6692767b70',
    'photo-1552519507-da3b142c6e3d',
    'photo-1492144534655-ae79c964c9d7',
    'photo-1511919342434-ae3b35b22e9d',
    'photo-1568605117036-5fe5e7bab0b7',
    'photo-1549317661-bd32c8ce0db2',
    'photo-1514316454349-750a7fd3da3a',
  ],
  'desert': [
    'photo-1469854523086-cc02fe5d8800',
    'photo-1509316785289-025f5b846b35',
    'photo-1473580044384-7ba9967e16bc',
    'photo-1426604966848-d7adac402bff',
    'photo-1500534314209-a25ddb2bd429',
    'photo-1682686580391-112d7c7237b5',
    'photo-1472214103451-9374bd1c798e',
    'photo-1516026672322-bc52d70d0cfa',
    'photo-1533106497176-45ae19e68ba2',
    'photo-1501785888041-af3ef285b470',
  ],
  'atv': [
    'photo-1558618666-fcd25c85f82e',
    'photo-1558981403-ab5ea4d3c146',
    'photo-1529416414570-7c1c0f0c3f3b',
    'photo-1621600411688-4be93c2c1208',
    'photo-1533106497176-45ae19e68ba2',
    'photo-1544191696-1566c6b5b9d4',
    'photo-1519751138087-5bf79dfbc860',
    'photo-1469854523086-cc02fe5d8800',
  ],
  'mall': [
    'photo-1519567241046-7f034f4ea197',
    'photo-1441986300917-64674bd600d8',
    'photo-1481437156560-3205f6a55735',
    'photo-1555529669-e69e7aa0ba9a',
    'photo-1528698827591-07aa003192e8',
    'photo-1445205170230-053b83016050',
    'photo-1567449303078-57ad995bd329',
    'photo-1472851294608-062f824d29cc',
  ],
  'snow': [
    'photo-1551698618-1dfe5d97d256',
    'photo-1483921020237-59cfff1d9b70',
    'photo-1418985991508-e47386d96a71',
    'photo-1454496522488-7a8e488e8606',
    'photo-1551698618-1dfe5d97d256',
    'photo-1605540436563-5bca919ae766',
    'photo-1551632811-561732d1e306',
  ],
  'theme': [
    'photo-1515442261605-65987783cb6a',
    'photo-1509023464722-18d996393ca8',
    'photo-1464047736614-af63643285bf',
    'photo-1533236897111-3eaec90d85e2',
    'photo-1563994295396-0c7300c3d6c3',
    'photo-1544027993-37dbfe435803',
  ],
  'water': [
    'photo-1500375592092-40eb2168fd21',
    'photo-1507525428034-b723cf961d3e',
    'photo-1439066615861-d1af74d74000',
    'photo-1505118380757-91f5f5632de0',
    'photo-1471922694854-ff1b63b20054',
    'photo-1505142468610-359e7d316be0',
    'photo-1439405326854-014607f694d7',
  ],
  'kids': [
    'photo-1503454537195-1dcabb73ffb9',
    'photo-1472162072942-cd5147eb3902',
    'photo-1502086223501-137b72987b77',
    'photo-1516627145497-ae6968895b74',
    'photo-1500995617113-cf789362bca1',
    'photo-1587654780291-39c9404d746b',
  ],
  'arcade': [
    'photo-1511512578047-dfb367046420',
    'photo-1550745165-9bc0b252726f',
    'photo-1538481199705-c710c4e965fc',
    'photo-1593305841991-05c297ea4733',
    'photo-1552820728-8b83bb6b773f',
    'photo-1493711662062-fa541adb3fc8',
  ],
  'trampoline': [
    'photo-1518611012118-696072aa579a',
    'photo-1571902943202-507ec2618e8f',
    'photo-1517836357463-d25dfeac3438',
    'photo-1571019613454-1cb2f99b2d8b',
    'photo-1518611645805-56ea94ba4fd1',
  ],
  'ice': [
    'photo-1515705576967-46bdebc99e28',
    'photo-1483664852095-4fcf87500bbd',
    'photo-1418985991508-e47386d96a71',
    'photo-1605540436563-5bca919ae766',
    'photo-1457269449834-928af64c684d',
  ],
  'vr': [
    'photo-1593508512255-86ab42a8e620',
    'photo-1617802690992-15d93263d3a9',
    'photo-1622979135225-d2ba2692f255',
    'photo-1478416272538-5f1590d59d77',
    'photo-1535223289827-42f1e9919769',
  ],
  'escape': [
    'photo-1478760329108-5c3ed9d495a0',
    'photo-1519074069444-1ba4fff87d61',
    'photo-1557683316-973635b0cd14',
    'photo-1481277542470-605612bd2d61',
    'photo-1507003211169-0a1dd7228f2d',
  ],
  'combat': [
    'photo-1547347298-4074fc3086f0',
    'photo-1517466787929-bc90951d0974',
    'photo-1571019613454-1cb2f99b2d8b',
    'photo-1526506118085-60ce8714f8c5',
    'photo-1517838277536-f5f99be501cd',
  ],
  'sport': [
    'photo-1554068865-24cecd4e34b8',
    'photo-1622279457486-62dcc4a431f4',
    'photo-1546519638-68e109498ffc',
    'photo-1517649763962-0c623066013b',
    'photo-1461896836934-ffe607ba6851',
  ],
  'outdoor': [
    'photo-1464822759023-fed622ff2c3b',
    'photo-1469474968028-56623f02e42e',
    'photo-1506905925346-21bda4d32df4',
    'photo-1470071459604-3b5ec3a7fe05',
    'photo-1441974231531-c6227db76b6e',
    'photo-1501785888041-af3ef285b470',
  ],
  'night': [
    'photo-1492684223066-81342ee5ff30',
    'photo-1516450360452-9312f5e86fc7',
    'photo-1566737236500-c8ac43014a67',
    'photo-1514525253161-7a46d19cd819',
    'photo-1470229722913-7c0e2dbbafd3',
    'photo-1493225457124-a3eb161ffa5f',
  ],
};

List<String> photosForKind(String kind) {
  final ids = _kindShots[kind] ?? _kindShots['cinema']!;
  return [for (final id in ids) _shot(id)];
}

String kindPhotoFor(String kind) => photosForKind(kind).first;

String activityPhotoFor(KsaActivity place) {
  final name = place.name.toLowerCase();
  var key = place.kind;
  if (place.kind == 'desert' &&
      (name.contains('atv') ||
          name.contains('quad') ||
          name.contains('sandboard'))) {
    key = 'atv';
  }
  final shots = photosForKind(key);
  return shots[place.id.hashCode.abs() % shots.length];
}
