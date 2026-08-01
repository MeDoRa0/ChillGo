part of '../../screens/outing_form_screen.dart';

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: ShimmerBox(
      height: 4,
      borderRadius: 2,
      semanticLabel: 'Loading outing',
    ),
  );
}
