part of '../../screens/outing_form_screen.dart';

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.selectedMapLocation,
    required this.onPressed,
  });

  final String? selectedMapLocation;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: selectedMapLocation ?? 'Choose location on map',
        child: Material(
          color: ChillGoColors.canvas,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 132,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(painter: _MapPreviewPainter()),
                  const Align(
                    alignment: Alignment(0, -0.2),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: ChillGoColors.coral,
                      size: 44,
                    ),
                  ),
                  if (selectedMapLocation != null)
                    _SelectedMapLabel(selectedMapLocation!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
