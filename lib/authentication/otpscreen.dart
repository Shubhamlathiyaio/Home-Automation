import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/authentication/profilePage.dart';
import 'package:smart_home/main.dart';
import 'package:smart_home/screens/add_location.dart';
import 'package:smart_home/screens/HomePage.dart';

class OTPScreen extends StatefulWidget {
  final String number;
  final String verificationCode;

  const OTPScreen(
      {super.key, required this.number, required this.verificationCode});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen>
    with SingleTickerProviderStateMixin {
  String otpFill = '';
  bool isLoading = false;
  var temp;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D3436),
      body: Stack(
        children: [
          // Background design
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verification Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We sent a code to +91-${widget.number}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // OTP Input
                      PinCodeTextField(
                        keyboardType: TextInputType.number,
                        appContext: context,
                        length: 6,
                        obscureText: false,
                        animationType: AnimationType.scale,
                        cursorColor: const Color(0xFF2D3436),
                        textStyle: const TextStyle(
                          color: Color(0xFF2D3436),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 50,
                          fieldWidth: 45,
                          activeFillColor: Colors.white,
                          activeColor: Colors.white,
                          selectedColor: Colors.white,
                          selectedFillColor: Colors.white,
                          inactiveFillColor: Colors.white.withOpacity(0.8),
                          inactiveColor: Colors.white.withOpacity(0.8),
                        ),
                        animationDuration: const Duration(milliseconds: 300),
                        backgroundColor: Colors.transparent,
                        enableActiveFill: true,
                        onCompleted: (value) {
                          otpFill = value;
                          codeSend(value);
                        },
                        onChanged: (value) {
                          otpFill = value;
                        },
                      ),

                      const SizedBox(height: 40),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (otpFill.isEmpty) {
                              _showError('Please enter OTP');
                            } else if (otpFill.length < 6) {
                              _showError('Please enter valid OTP');
                            } else {
                              codeSend(otpFill);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2D3436),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // const SizedBox(height: 24),

                      // // Resend option
                      // Center(
                      //   child: TextButton(
                      //     onPressed: () {
                      //       // Add resend logic
                      //     },
                      //     child: Text(
                      //       'Resend Code',
                      //       style: TextStyle(
                      //         color: Colors.white.withOpacity(0.8),
                      //         fontSize: 16,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  codeSend(String otp) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      await FirebaseAuth.instance
          .signInWithCredential(PhoneAuthProvider.credential(
        verificationId: widget.verificationCode,
        smsCode: otp,
      ))
          .then((value) async {
        final FirebaseAuth auth = FirebaseAuth.instance;
        getData();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      wrongOtp();
    }
  }

  wrongOtp() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return GiffyDialog(
            giffy: Lottie.asset('assets/Lottie/wrong_otp.json'),
            title: const Text('OTP Invalid',
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            content: const Text('Please enter correct OTP',
                style: TextStyle(fontSize: 17, color: Colors.black)),
            actions: [
              Center(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                      height: 40,
                      width: 90,
                      decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Center(
                        child: Text(
                          'OK',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      )),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  getData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('users');
    ref.onValue.listen((DatabaseEvent event) async {
      if (mounted) {
        setState(() {
          temp = event.snapshot.child(widget.number).value;
        });
      }

      var sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString('Login_Number', widget.number);
      String abcd = sharedPreferences.getString('Login_Number') ?? '';
      phoneNumber = abcd;

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (temp == null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (context) {
              return ProfilePage(number: widget.number);
            },
          ), (route) => false);
        }
      } else {
        // Check if location exists
        final locationSnapshot = await FirebaseDatabase.instance
            .ref('users/${widget.number}/Location')
            .get();

        if (mounted) {
          if (!locationSnapshot.exists || locationSnapshot.value == null) {
            // No location, go to add location page
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => AddLocation(number: widget.number),
                ),
                (route) => false);
          } else {
            await sharedPreferences.setString('Login_Number', widget.number);
            String abc = sharedPreferences.getString('Login_Number') ?? '';
            phoneNumber = abc;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
              builder: (context) {
                return Homepage(number: widget.number);
              },
            ), (route) => false);
          }
        }
      }
    });
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw circles
    for (var i = 0; i < 5; i++) {
      final radius = (size.width / 2) * (i + 1) / 5;
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        paint,
      );
    }

    // Draw dots pattern
    for (var i = 0; i < 100; i++) {
      final x = (i * size.width / 20) % size.width;
      final y = (i * size.height / 20) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
