# KSA Guide

Flutter app for browsing living-in-Saudi guides from two sites, in one category tree:

- [lifeinsaudiarabia.net](https://lifeinsaudiarabia.net) — 2,313 articles
- [saudiexpatriate.com](https://saudiexpatriate.com) — 1,039 articles

## Run

```bash
cd ~/Desktop/KSAGUIDE
flutter pub get
flutter run
```

Rebuild the merged catalog after a new scrape:

```bash
python3 tools/build_catalog.py
```

Saudi Expatriate topics are folded into the same categories (Iqama, Visas, Driving, etc.). Distinct topics such as Nitaqat, Employee Benefits, Expat Community, and Deals become extra subcategories.
