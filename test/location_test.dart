import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickkart/models/delivery_location.dart';
import 'package:quickkart/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const noida = DeliveryLocation(
    state: 'Uttar Pradesh',
    district: 'Gautam Buddha Nagar',
    pincode: '201301',
  );

  group('DeliveryLocation', () {
    test('shortLine header ke liye chhoti rehti hai (state ke bina)', () {
      expect(noida.shortLine, 'Gautam Buddha Nagar, 201301');
    });

    test('fullLine mein state bhi aata hai', () {
      expect(noida.fullLine, 'Gautam Buddha Nagar, Uttar Pradesh - 201301');
    });

    test('isValid teeno fields maangta hai aur 6-digit pincode', () {
      expect(noida.isValid, isTrue);
      expect(
        const DeliveryLocation(state: 'UP', district: 'X', pincode: '2013')
            .isValid,
        isFalse,
        reason: '5 digit pincode invalid hona chahiye',
      );
      expect(
        const DeliveryLocation(state: '', district: 'X', pincode: '201301')
            .isValid,
        isFalse,
      );
      expect(
        const DeliveryLocation(
                state: 'UP', district: 'X', pincode: '20130a')
            .isValid,
        isFalse,
      );
    });

    test('JSON round-trip', () {
      final copy = DeliveryLocation.fromJson(noida.toJson());
      expect(copy.sameAs(noida), isTrue);
      expect(copy.fullLine, noida.fullLine);
    });

    test('purane format (city/label) se saved entry nahi tootti', () {
      // Pehle location label + address + city + pincode se banti thi.
      final legacy = DeliveryLocation.fromJson({
        'label': 'Home',
        'address': 'Flat 402, Sector 12',
        'city': 'Noida',
        'pincode': '201301',
      });
      expect(legacy.district, 'Noida', reason: 'city ko district maana jaaye');
      expect(legacy.pincode, '201301');
      expect(legacy.state, '');
    });

    test('sameAs case-insensitive hai', () {
      const other = DeliveryLocation(
        state: 'uttar pradesh',
        district: 'gautam buddha nagar',
        pincode: '201301',
      );
      expect(noida.sameAs(other), isTrue);
    });
  });

  group('LocationService', () {
    test('shuru mein koi location select nahi hoti', () async {
      final service = await LocationService.load();
      expect(service.current, isNull);
      expect(service.hasLocation, isFalse);
      expect(service.saved, isEmpty);
    });

    test('select karne par current set hoti hai aur saved mein aati hai',
        () async {
      final service = await LocationService.load();
      await service.select(noida);

      expect(service.hasLocation, isTrue);
      expect(service.current!.fullLine, noida.fullLine);
      expect(service.saved.length, 1);
    });

    test('wahi location dobara select karne par duplicate nahi banti', () async {
      final service = await LocationService.load();
      await service.select(noida);
      await service.select(noida);
      expect(service.saved.length, 1);
    });

    test('same district ke alag pincode alag entries hain', () async {
      final service = await LocationService.load();
      await service.select(noida);
      await service.select(const DeliveryLocation(
        state: 'Uttar Pradesh',
        district: 'Gautam Buddha Nagar',
        pincode: '201303',
      ));
      expect(service.saved.length, 2);
    });

    test('reload karne par selection wapas aati hai', () async {
      final service = await LocationService.load();
      await service.select(noida);

      final reloaded = await LocationService.load();
      expect(reloaded.current, isNotNull);
      expect(reloaded.current!.fullLine, noida.fullLine);
      expect(reloaded.saved.length, 1);
    });

    test('remove karne par saved se hatti hai aur current clear ho jaati hai',
        () async {
      final service = await LocationService.load();
      await service.select(noida);
      await service.remove(noida);

      expect(service.saved, isEmpty);
      expect(service.current, isNull);
    });

    test('searchSaved district aur pincode dono se match karta hai', () async {
      final service = await LocationService.load();
      await service.select(noida);

      expect(service.searchSaved('gautam').length, 1);
      expect(service.searchSaved('201301').length, 1);
      expect(service.searchSaved('uttar').length, 1);
      expect(service.searchSaved('   '), isEmpty);
      expect(service.searchSaved('kerala'), isEmpty);
    });

    test('saved list 8 se zyada nahi badhti', () async {
      final service = await LocationService.load();
      for (var i = 0; i < 12; i++) {
        await service.select(DeliveryLocation(
          state: 'State $i',
          district: 'District $i',
          pincode: '10000$i'.substring(0, 6),
        ));
      }
      expect(service.saved.length, 8);
      expect(service.saved.first.district, 'District 11');
    });
  });
}
