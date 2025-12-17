import 'package:flutter/material.dart';

class LinearVisualLine extends StatefulWidget {
  final double top;
  final double width;
  final Color color;
  const LinearVisualLine({super.key,
    required this.color,
    required this.top,
    required this.width,

  });

  @override
  _LinearVisualLineState createState() => _LinearVisualLineState();
}

class _LinearVisualLineState extends State<LinearVisualLine> with TickerProviderStateMixin{
  late AnimationController mainController;
  late AnimationController topController;
  late Animation<double> mainAnimation;
  Animation<double>? topAnimation;

  final int aniationTime = 300;

  @override
  void initState() {
    mainController = AnimationController(
        duration: Duration(milliseconds: aniationTime),
        vsync: this);
    topController = AnimationController(
        duration: Duration(milliseconds: 1500),
        vsync: this);
    mainAnimation = Tween(begin: 0.0,end: widget.top).animate(CurvedAnimation(
      parent: mainController,
      curve: Interval(0, 0.5)
    ));

    super.initState();
    mainController.forward();
  }

  @override
  void dispose() {
    mainController.dispose();
    topController.dispose();
    super.dispose();
  }

  _stopTopAnimationIfItReachTop() {
    if(mainAnimation.value >= topAnimation!.value) {
      topController.reset();
      topAnimation = null;
      mainAnimation.removeListener(_stopTopAnimationIfItReachTop);
    }
  }

  @override
  void didUpdateWidget(covariant LinearVisualLine oldWidget) {

    if(this.widget.top != oldWidget.top) {
      double oldValue = mainAnimation.value;
      mainController.reset();
      mainAnimation.removeListener(_stopTopAnimationIfItReachTop);
      mainAnimation = Tween(begin: oldValue,end: widget.top).animate(mainController);
      if(topAnimation != null) {
        mainAnimation.addListener(_stopTopAnimationIfItReachTop);
      } else if(topAnimation == null && oldValue > widget.top) {
        topAnimation = Tween(begin: oldValue,end: 0.0).animate(topController);
        topController.forward();
      }

      mainController.forward();
    }
    super.didUpdateWidget(oldWidget);

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      //  color: Colors.red,
      child: AnimatedBuilder(
          animation: Listenable.merge([mainAnimation,topAnimation]),
          builder: (context,anim) {
            return CustomPaint(
              foregroundPainter: LinePainter(
                  color:widget.color,
                  top:topAnimation?.value ?? mainAnimation.value,all:mainAnimation.value),
              child: SizedBox(
                width: widget.width,
                height: double.infinity,
              ),
            );
          }
      ),
    );
  }

}

class LinePainter extends CustomPainter {
  final double top;
  final double all;
  final Color color;
  LinePainter({
    required this.color,
    required this.top,
    required this.all
  });
  @override
  void paint(Canvas canvas, Size size) {
    var paintDefault = Paint();
    paintDefault.color = color.withOpacity(0.1);
    paintDefault.strokeWidth = 2;

    var paintActive = Paint();
    paintActive.color = color.withOpacity(0.5);
    paintActive.strokeWidth = 2;

    var paintSelected = Paint();
    paintSelected.color = color;
    paintSelected.strokeWidth = 2;


    double itemHeight = 10;
    int count = (size.height / itemHeight).floor();
    // print("height ${size.height} count $count top ${(size.height * top / itemHeight).round()}");
    for(int i = 0;i<=count;i++) {
      double offset = itemHeight * i + 4;
      Paint paint = paintDefault;

      int allIndex = (size.height * all / itemHeight).round();
      int topIndex = (size.height * top / itemHeight).round();



      if(allIndex > topIndex) {
        topIndex = allIndex;
      }

      if(allIndex >= i) {
        paint = paintActive;
      }

      if(topIndex ==  i ) {
        paint = paintSelected;
      }

      canvas.drawLine(
        Offset(0, size.height - offset),
        Offset(size.width, size.height - offset),
        paint,
      );
    }


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
