import 'package:flutter/material.dart';

class SlideAnimationRoute extends PageRouteBuilder{
  final Widget page;
  SlideAnimationRoute({required this.page}):super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 100),
    reverseTransitionDuration: const Duration(milliseconds: 100),
    transitionsBuilder: (context, animation, secondaryAnimation, page) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: page,
    ),
  );
}