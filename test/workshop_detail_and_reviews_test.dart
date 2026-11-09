import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mecloc/models/workshop.dart';
import 'package:mecloc/providers/auth_provider.dart';
import 'package:mecloc/providers/vehicle_provider.dart';
import 'package:mecloc/providers/workshop_provider.dart';
import 'package:mecloc/widgets/workshop_detail_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Workshop Model & Distance Formatting Tests', () {
    test('formattedDistance converts sub-kilometer distances to meters', () {
      const workshopNear = Workshop(
        id: 'w_near',
        name: 'Auto Elétrica Rápida',
        address: 'Rua Central, 100',
        distanceKm: 0.35,
      );

      expect(workshopNear.formattedDistance, equals('350 m'));
    });

    test('formattedDistance limits kilometers to 1 decimal place', () {
      const workshopFar = Workshop(
        id: 'w_far',
        name: 'Oficina do João',
        address: 'Av. Brasil, 2500',
        distanceKm: 3.1415926535,
      );

      expect(workshopFar.formattedDistance, equals('3.1 km'));
    });

    test('formattedDistance returns empty string when distanceKm is null', () {
      const workshopNoDistance = Workshop(
        id: 'w_nodist',
        name: 'Oficina Central',
        address: 'Rua das Flores, 50',
      );

      expect(workshopNoDistance.formattedDistance, equals(''));
    });

    test('allImageUrls aggregates and deduplicates imageUrl and imageUrls', () {
      const emptyWorkshop = Workshop(
        id: 'w_empty',
        name: 'Oficina Sem Fotos',
        address: 'Rua A, 1',
      );
      expect(emptyWorkshop.allImageUrls, isEmpty);

      const singlePhotoWorkshop = Workshop(
        id: 'w_single',
        name: 'Oficina Foto Única',
        address: 'Rua B, 2',
        imageUrl: 'https://example.com/banner.jpg',
      );
      expect(singlePhotoWorkshop.allImageUrls, equals(['https://example.com/banner.jpg']));

      const multiPhotoWorkshop = Workshop(
        id: 'w_multi',
        name: 'Oficina Carrossel',
        address: 'Rua C, 3',
        imageUrl: 'https://example.com/banner.jpg',
        imageUrls: ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg'],
      );
      expect(multiPhotoWorkshop.allImageUrls.length, equals(3));
      expect(multiPhotoWorkshop.allImageUrls.first, equals('https://example.com/banner.jpg'));
    });
  });

  group('WorkshopProvider Review Tests', () {
    test('addReview adds a review and recalculates average rating and count', () async {
      final provider = WorkshopProvider();

      const workshopId = 'partner:autobahn:001';
      const review1 = WorkshopReview(
        authorName: 'Carlos Silveira',
        rating: 5.0,
        comment: 'Serviço impecável no meu Polo TSI!',
        date: '09/11/2026',
        carModel: 'VW Polo TSI',
      );

      await provider.addReview(workshopId: workshopId, review: review1);

      final reviews = provider.getReviewsForWorkshop(workshopId);
      expect(reviews.length, equals(1));
      expect(reviews.first.authorName, equals('Carlos Silveira'));
      expect(reviews.first.rating, equals(5.0));

      const review2 = WorkshopReview(
        authorName: 'Mariana Lima',
        rating: 4.0,
        comment: 'Muito bom, recomendo.',
        date: '09/11/2026',
      );

      await provider.addReview(workshopId: workshopId, review: review2);
      final updatedReviews = provider.getReviewsForWorkshop(workshopId);
      expect(updatedReviews.length, equals(2));
      // Average: (5.0 + 4.0) / 2 = 4.5
      final total = updatedReviews.fold<double>(0, (acc, r) => acc + r.rating);
      final avg = total / updatedReviews.length;
      expect(avg, equals(4.5));
    });
  });

  group('WorkshopDetailSheet Widget Tests', () {
    Widget buildTestApp(Workshop workshop) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WorkshopProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WorkshopDetailSheet(workshop: workshop),
          ),
        ),
      );
    }

    testWidgets('renders empty placeholder with icon when workshop has no photos', (tester) async {
      const workshop = Workshop(
        id: 'test:w1',
        name: 'Mecânica Modelo',
        address: 'Rua Goiás, 120 - Centro',
        distanceKm: 1.5,
      );

      await tester.pumpWidget(buildTestApp(workshop));
      await tester.pumpAndSettle();

      expect(find.text('Mecânica Modelo'), findsOneWidget);
      expect(find.text('Rua Goiás, 120 - Centro'), findsOneWidget);
      expect(find.byIcon(Icons.no_photography_outlined), findsOneWidget);
      expect(find.text('Nenhuma foto adicionada ainda'), findsOneWidget);
      expect(find.text('1.5 km'), findsOneWidget);
      expect(find.text('Traçar Rota'), findsOneWidget);
      expect(find.text('Avaliações da Oficina'), findsOneWidget);
    });

    testWidgets('renders review form modal and quick action buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const workshop = Workshop(
        id: 'test:w2',
        name: 'Lava Jato Express',
        address: 'Av. Afonso Pena, 900',
        distanceKm: 0.8,
      );

      await tester.pumpWidget(buildTestApp(workshop));
      await tester.pumpAndSettle();

      expect(find.text('800 m'), findsOneWidget);

      final avaliarBtn = find.text('Avaliar');
      expect(avaliarBtn, findsOneWidget);

      await tester.tap(avaliarBtn);
      await tester.pumpAndSettle();

      expect(find.text('Avaliar Lava Jato Express'), findsOneWidget);
      expect(find.text('Publicar Avaliação'), findsOneWidget);
    });
  });
}
