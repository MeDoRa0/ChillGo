part of '../interactive_outing_card.dart';

class _OutingTitle extends StatelessWidget {
  const _OutingTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: ChillGoColors.ink,
      fontSize: 20,
      height: 1.12,
      fontWeight: FontWeight.w900,
    ),
  );
}
