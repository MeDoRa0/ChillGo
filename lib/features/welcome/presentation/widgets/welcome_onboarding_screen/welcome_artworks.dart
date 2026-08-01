part of '../../screens/welcome_onboarding_screen.dart';

class _WelcomeBrandArtwork extends StatelessWidget {
  const _WelcomeBrandArtwork();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ChillGo brings friends together for easy meetups',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ChillGoColors.lavender,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(72),
                    topRight: Radius.circular(48),
                    bottomLeft: Radius.circular(58),
                    bottomRight: Radius.circular(76),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChillGoBrandMark(),
                    SizedBox(height: 10),
                    Text(
                      'Good company. Easy meetups.\nBetter days.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ChillGoColors.inkMuted,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const ChillGoMeetupHighlights(),
          ],
        ),
      ),
    );
  }
}

class _CrewPlanArtwork extends StatelessWidget {
  const _CrewPlanArtwork();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Weekend Wanderers crew has a sunset picnic at Al Azhar Park in two hours',
      child: ExcludeSemantics(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: ChillGoColors.skySoft,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ChillGoColors.outline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x146D3A72),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 18,
                left: 16,
                right: 16,
                child: _CrewIdentityPreview(),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 112,
                child: ClipPath(
                  clipper: _CrewFooterClipper(),
                  child: ColoredBox(color: ChillGoColors.surface),
                ),
              ),
              const Positioned(
                left: 12,
                right: 12,
                bottom: 20,
                child: _OutingPreview(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 94,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: ChillGoColors.sunshine,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Starts in 2h',
                      style: TextStyle(
                        color: ChillGoColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrewIdentityPreview extends StatelessWidget {
  const _CrewIdentityPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ChillGoColors.surface.withValues(alpha: 0.88),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.groups, color: ChillGoColors.sky, size: 22),
        ),
        const SizedBox(height: 5),
        const Text(
          'Weekend Wanderers',
          style: TextStyle(
            color: ChillGoColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const _PreviewAvatarRow(),
      ],
    );
  }
}

class _PreviewAvatarRow extends StatelessWidget {
  const _PreviewAvatarRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 30,
      child: Stack(
        children: const [
          _PreviewAvatar(color: ChillGoColors.sunshineSoft),
          Positioned(
            left: 24,
            child: _PreviewAvatar(color: ChillGoColors.coralSoft),
          ),
          Positioned(
            left: 48,
            child: _PreviewAvatar(color: ChillGoColors.leafSoft),
          ),
        ],
      ),
    );
  }
}

class _PreviewAvatar extends StatelessWidget {
  const _PreviewAvatar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ChillGoColors.skySoft, width: 2),
      ),
      child: const Icon(
        Icons.sentiment_satisfied_alt_rounded,
        color: ChillGoColors.ink,
        size: 17,
      ),
    );
  }
}

class _OutingPreview extends StatelessWidget {
  const _OutingPreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Sunset picnic',
          style: TextStyle(
            color: ChillGoColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Today · 5:30 PM',
              style: TextStyle(
                color: ChillGoColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.location_on_rounded, color: ChillGoColors.sky, size: 16),
            SizedBox(width: 2),
            Flexible(
              child: Text(
                'Al Azhar Park',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ChillGoColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CrewFooterClipper extends CustomClipper<Path> {
  const _CrewFooterClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 18)
      ..cubicTo(
        size.width * 0.2,
        -4,
        size.width * 0.34,
        22,
        size.width * 0.52,
        12,
      )
      ..cubicTo(size.width * 0.7, 2, size.width * 0.82, 19, size.width, 10)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_CrewFooterClipper oldClipper) => false;
}

class _LiveMeetupArtwork extends StatelessWidget {
  const _LiveMeetupArtwork();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Live meetup at Al Azhar Park: Mariam arrived, Omar is on the way, and you are getting ready',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 360,
            height: 300,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ChillGoColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ChillGoColors.outline),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x146D3A72),
                    blurRadius: 16,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Meetup',
                    style: TextStyle(
                      color: ChillGoColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  _MeetupPlacePreview(),
                  SizedBox(height: 14),
                  _MeetupStatusPreview(
                    name: 'Mariam',
                    status: 'Arrived',
                    backgroundColor: ChillGoColors.leafSoft,
                  ),
                  SizedBox(height: 8),
                  _MeetupStatusPreview(
                    name: 'Omar',
                    status: 'On my way',
                    backgroundColor: ChillGoColors.skySoft,
                  ),
                  SizedBox(height: 8),
                  _MeetupStatusPreview(
                    name: 'You',
                    status: 'Getting ready',
                    backgroundColor: ChillGoColors.sunshineSoft,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetupPlacePreview extends StatelessWidget {
  const _MeetupPlacePreview();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: ChillGoColors.coralSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: ChillGoColors.coral,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Al Azhar Park',
                style: TextStyle(
                  color: ChillGoColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Meet at the main gate',
                style: TextStyle(color: ChillGoColors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeetupStatusPreview extends StatelessWidget {
  const _MeetupStatusPreview({
    required this.name,
    required this.status,
    required this.backgroundColor,
  });

  final String name;
  final String status;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: ChillGoColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: ChillGoColors.ink,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: ChillGoColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(status, style: const TextStyle(color: ChillGoColors.inkMuted)),
        ],
      ),
    );
  }
}
