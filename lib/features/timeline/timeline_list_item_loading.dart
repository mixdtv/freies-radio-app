import 'package:flutter/material.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/utils/colors.dart';

class TimelineListItemLoading extends StatelessWidget {
  const TimelineListItemLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 6,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6,left: 16,right: 16,bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 13,
                  ),
                  const SizedBox(height: 9,),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: AppGradient.getPanelGradient(context),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: ShimmerLoading(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9),
                                    color: Colors.white
                                ),
                              ),
                              const SizedBox(width: 16,),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 11,
                                      color: Colors.white,
                                      margin: EdgeInsets.only(bottom: 5),
                                    ),
                                    Container(
                                      width: 100,
                                      height: 14,
                                      color: Colors.white,
                                      margin: EdgeInsets.only(bottom: 5),
                                    ),
                                    Container(
                                      width: 80,
                                      height: 11,
                                      color: Colors.white,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16,),
                          Container(
                            width: double.infinity,
                            height: 14,
                            color: Colors.white,
                            margin: EdgeInsets.only(bottom: 5),
                          ),
                          Container(
                            width: double.infinity,
                            height: 14,
                            color: Colors.white,
                            margin: EdgeInsets.only(bottom: 5),
                          ),
                          Container(
                            width: double.infinity,
                            height: 14,
                            color: Colors.white,
                            margin: EdgeInsets.only(bottom: 5),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
