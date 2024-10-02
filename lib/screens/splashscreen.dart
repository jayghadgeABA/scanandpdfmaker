import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scanandpdfmaker/screens/homescreen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Get.off(() => HomeScreen());
    });
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(
          flex: 40,
        ),
        Center(
          child: Image.asset(
            "assets/png/pdf.png",
            height: Get.height * 0.25,
            color: Colors.red.shade900,
          ),
        ),
        const Spacer(
          flex: 5,
        ),
        const Text(
          "Scan to PDF",
          style: TextStyle(fontSize: 30),
        ),
        const Spacer(
          flex: 50,
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Text("Designed by Jayesh Ghadge"),
        ),
        const Spacer(
          flex: 1,
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            "Made with ❤️ in India",
          ),
        ),
        const SizedBox(
          height: 10,
        )
      ],
    ));
  }
}
