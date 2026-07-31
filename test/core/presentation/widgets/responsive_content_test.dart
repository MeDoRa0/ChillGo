import 'package:chillgo/core/presentation/theme/chillgo_theme.dart';
import 'package:chillgo/core/presentation/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('crew grid uses one column on a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_responsiveGridApp());

    final firstTile = tester.getTopLeft(find.byKey(const Key('tile-1')));
    final secondTile = tester.getTopLeft(find.byKey(const Key('tile-2')));

    expect(secondTile.dx, firstTile.dx);
    expect(secondTile.dy, greaterThan(firstTile.dy));
  });

  testWidgets('crew grid uses three columns on tablet width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_responsiveGridApp());

    final firstTile = tester.getTopLeft(find.byKey(const Key('tile-1')));
    final secondTile = tester.getTopLeft(find.byKey(const Key('tile-2')));
    final thirdTile = tester.getTopLeft(find.byKey(const Key('tile-3')));

    expect(secondTile.dy, firstTile.dy);
    expect(thirdTile.dy, firstTile.dy);
    expect(secondTile.dx, greaterThan(firstTile.dx));
    expect(thirdTile.dx, greaterThan(secondTile.dx));
  });
}

Widget _responsiveGridApp() {
  return MaterialApp(
    theme: ChillGoTheme.sunshine,
    home: Scaffold(
      body: ResponsiveContent(
        maxWidth: 1080,
        child: SingleChildScrollView(
          child: ResponsiveGrid(
            children: [
              for (var index = 1; index <= 3; index++)
                ColoredBox(
                  key: Key('tile-$index'),
                  color: ThemeData().colorScheme.primaryContainer,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
