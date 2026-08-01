part of '../interactive_outing_card.dart';

class _CardActionOverlay extends StatelessWidget {
  const _CardActionOverlay({
    required this.outingId,
    required this.onChat,
    required this.onLiveMeetup,
  });

  final String outingId;
  final VoidCallback? onChat;
  final VoidCallback? onLiveMeetup;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (onChat != null)
        Positioned(
          right: onLiveMeetup == null ? 14 : 70,
          bottom: 12,
          child: _CardChatButton(outingId: outingId, onPressed: onChat!),
        ),
      if (onLiveMeetup != null)
        Positioned(
          right: 14,
          bottom: 12,
          child: _LiveMeetupButton(onPressed: onLiveMeetup!),
        ),
    ],
  );
}
