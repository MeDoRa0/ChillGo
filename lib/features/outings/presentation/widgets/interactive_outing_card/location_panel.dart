part of '../interactive_outing_card.dart';

class _LocationPanel extends StatelessWidget {
  const _LocationPanel({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('outing-location-panel'),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: ChillGoColors.surface.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ChillGoColors.outline),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 23,
          color: ChillGoColors.coral,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ChillGoColors.ink,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
