import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:confetti/confetti.dart';

class SuccessPage extends StatelessWidget {
  final String name;
  final String treeUrl;

  const SuccessPage({
    super.key,
    required this.name,
    required this.treeUrl,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    const greenColor = Color(0xFF006341);
    final screenWidth = MediaQuery.of(context).size.width; // ✅ For responsive UI

    return Scaffold(
      backgroundColor: greenColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/tree_logo.png',
              height: screenWidth * 0.07, // ✅ Responsive logo size
            ),
            SizedBox(width: screenWidth * 0.02),
            const Text(
              "Tree Assigned",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: greenColor,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),

      // ✅ Scrollable for smaller screens
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅
              Image.asset(
                'assets/sankalptaru_logo.png',
                height: screenWidth * 0.5,
                width: screenWidth * 0.5,
              ),
              SizedBox(height: screenWidth * 0.05),

              // ✅ IPL-style animated congratulations (Responsive)
              AnimatedCongrats(name: name),
              SizedBox(height: screenWidth * 0.06),

              // ✅ QR Code with border
              Container(
                padding: EdgeInsets.all(screenWidth * 0.01),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.yellow, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: treeUrl,
                  version: QrVersions.auto,
                  size: screenWidth * 0.75, // ✅ QR size adjusts dynamically
                ),
              ),
              SizedBox(height: screenWidth * 0.06),

              // ✅ URL text
              const Text(
                "Tree URL:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),

              // ✅ Clickable link (Responsive text size)
              GestureDetector(
                onTap: () => _launchUrl(treeUrl),
                child: SizedBox(
                  width: screenWidth * 0.8,
                  child: Text(
                    treeUrl,
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: screenWidth * 0.05,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.09),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ IPL-style Congratulations Animation (Responsive)
class AnimatedCongrats extends StatefulWidget {
  final String name;
  const AnimatedCongrats({super.key, required this.name});

  @override
  State<AnimatedCongrats> createState() => _AnimatedCongratsState();
}

class _AnimatedCongratsState extends State<AnimatedCongrats> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play(); // Start confetti animation
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String message =
        "🎉 Congratulations, ${widget.name}! \nYour tree has been planted! 🌳";
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.9, // ✅ Prevent overflow on small screens
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🎇 Firecracker Confetti Effect
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2,
            emissionFrequency: 0.08,
            numberOfParticles: 30,
            maxBlastForce: 25,
            minBlastForce: 10,
            gravity: 0.2,
            colors: const [
              Colors.yellow,
              Colors.green,
              Colors.red,
              Colors.blue,
              Colors.orange,
            ],
          ),

          // ✨ IPL-style shiny animated text (Auto resizes)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedTextKit(
              repeatForever: true,
              animatedTexts: [
                ColorizeAnimatedText(
                  message,
                  textAlign: TextAlign.center,
                  textStyle: TextStyle(
                    fontSize: screenWidth * 0.07, // ✅ Auto scales
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  colors: [
                    Colors.yellow,
                    Colors.orange,
                    Colors.red,
                    Colors.deepOrange,
                    Colors.yellow,
                  ],
                  speed: const Duration(milliseconds: 300),
                ),
              ],
              isRepeatingAnimation: true,
            ),
          ),
        ],
      ),
    );
  }
}
