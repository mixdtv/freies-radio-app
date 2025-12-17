import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlayButton extends StatelessWidget {
  final Function() onClick;
  final bool isPlay;
  final bool isLoading;
  final bool isPodcast;

  const PlayButton({super.key, required this.onClick, required this.isPlay, this.isLoading = false, this.isPodcast = false});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final darkModeOn = (brightness == Brightness.dark);

    final buttonColor = darkModeOn ? Colors.white : Colors.black;
    return InkWell(
        onTap: onClick,
        child: //SvgPicture.asset(darkModeOn ? "assets/icons/ic_play_dark.svg" : "assets/icons/ic_play_light.png",width: 98,));
        Stack(
          children: [
            Image.asset(
              darkModeOn ? "assets/icons/ic_play_button_dark3.png" : "assets/icons/ic_play_button_light3.png",
              width: 122,
              height: 122,
              alignment: Alignment.center,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) {
                  return child;
                }
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 100),
                  child: frame == null
                    ? Container(
                        width: 122,
                        height: 122,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: buttonColor.withOpacity(0.1),
                        ),
                      )
                    : child,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 122,
                  height: 122,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: buttonColor.withOpacity(0.1),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: Center(
                child: _buildIcon(buttonColor, isLoading, isPlay),
              ),
            )
          ],
        ));
  }

  Widget _buildIcon(Color buttonColor, bool isLoading, bool isPlay) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
        ),
      );
    } else if (isPlay) {
      if (isPodcast) {
        // Pause icon (two vertical bars) for podcasts
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 4, height: 14, color: buttonColor),
            const SizedBox(width: 4),
            Container(width: 4, height: 14, color: buttonColor),
          ],
        );
      } else {
        // Stop icon (square) for live streams
        return Container(
          width: 12,
          height: 12,
          color: buttonColor,
        );
      }
    } else {
      return CustomPaint(
        painter: TrianglePainter(color: buttonColor),
        child: Container(
          width: 14,
          height: 14,
        ),
      );
    }
  }

}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    canvas.drawPath(getTrianglePath(size.width, size.height), paint);
  }

  Path getTrianglePath(double x, double y) {
    return Path()
      ..moveTo(x * 0.2, 0)
      ..lineTo(x , y/2)
      ..lineTo(x * 0.2, y)
      ..close();
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
