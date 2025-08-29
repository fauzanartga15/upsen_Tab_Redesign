import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../constant/app_color.dart'; // Import AppColor
import 'home_page.dart'; // Import HomePage

class SuccessConfirmationPage extends StatefulWidget {
  final String employeeName;
  final String employeePosition;
  final String checkInTime;
  final String status;
  final String location;
  final String nextAction;
  final double matchConfidence;
  final String? successAttendace; // Tambahan parameter

  const SuccessConfirmationPage({
    super.key,
    this.employeeName = 'Enka HRD', // Mock data - replace with API
    this.employeePosition = 'SPV - HR Department', // Mock data
    this.checkInTime = '08:15:32', // Mock data
    this.status = 'ON TIME', // Mock data
    this.location = 'MAIN OFFICE', // Mock data
    this.nextAction = 'Check-out at 16:00', // Mock data
    this.matchConfidence = 0.96, // Mock data
    this.successAttendace, // Parameter baru
  });

  @override
  State<SuccessConfirmationPage> createState() =>
      _SuccessConfirmationPageState();
}

class _SuccessConfirmationPageState extends State<SuccessConfirmationPage>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _cardController;
  late AnimationController
  _countdownController; // Tambahan untuk countdown animation
  late Animation<double> _bounceAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _countdownAnimation; // Animation untuk countdown

  // Timer dan countdown
  Timer? _autoRedirectTimer;
  int _countdown = 10;
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Setup countdown animation controller
    _countdownController = AnimationController(
      duration: const Duration(seconds: 10), // 10 detik
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    // Countdown animation dari 1.0 ke 0.0 (mundur)
    _countdownAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.linear),
    );
  }

  void _startAnimations() {
    _bounceController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
      // Start countdown animation setelah card muncul
      _countdownController.forward();
    });

    // Start auto redirect timer (10 detik)
    _autoRedirectTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _navigateToHome();
      }
    });

    // Start countdown timer (update setiap detik)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });

        if (_countdown <= 0) {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _cardController.dispose();
    _countdownController.dispose(); // Dispose countdown controller
    _autoRedirectTimer?.cancel();
    _countdownTimer.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false, // Remove semua route sebelumnya
      );
    }
  }

  String _getEmployeeInitials() {
    List<String> nameParts = widget.employeeName.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0].substring(0, 2).toUpperCase();
    }
    return 'EH';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColor
                .kGradientBg, // Menggunakan gradient bg yang sudah diupdate
            stops: [0.1, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                maxWidth: MediaQuery.of(context).size.width,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: 30.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Confidence Badge
                    _buildConfidenceBadge(),

                    const SizedBox(height: 20),

                    // Success Icon
                    _buildSuccessIcon(),

                    const SizedBox(height: 20),

                    // Employee Card
                    _buildEmployeeCard(),

                    const SizedBox(height: 30),

                    // Continue Button
                    _buildContinueButton(),

                    const SizedBox(height: 15),

                    // Auto redirect info
                    _buildAutoRedirectInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColor.kPrimaryDark.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              'You Are Success, ${widget.successAttendace ?? "Check-in"}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColor.kGradientCyanVibrant,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColor.kCyanPrimary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              '${(widget.matchConfidence * 100).toInt()}% Match',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: SizedBox(
            width: 120, // Lebih besar untuk menampung circular progress
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular Progress Background
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: 1.0, // Background circle
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.transparent,
                    ),
                  ),
                ),
                // Animated Circular Progress (Countdown)
                AnimatedBuilder(
                  animation: _countdownAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: _countdownAnimation.value,
                        strokeWidth: 4,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _countdownAnimation.value > 0.3
                              ? Colors.white
                              : Colors.red.shade300, // Merah saat hampir habis
                        ),
                      ),
                    );
                  },
                ),
                // Success Icon dengan countdown text
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        color: AppColor.kCyanSecondary,
                        size: 32,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_countdown',
                        style: GoogleFonts.poppins(
                          color: _countdown <= 3
                              ? Colors.red.shade400
                              : AppColor.kCyanSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeCard() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _cardAnimation.value)),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
                minWidth: 300,
              ),
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 35,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Employee Photo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColor.kGradientCyanVibrant,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.kCyanPrimary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getEmployeeInitials(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Employee Name
                  Text(
                    widget.employeeName,
                    style: GoogleFonts.poppins(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: AppColor.kTextDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  // Employee Position
                  Text(
                    widget.employeePosition,
                    style: GoogleFonts.poppins(
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                      color: AppColor.kTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 15),

                  // Attendance Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColor.kNeutralLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInfoRow('CHECK-IN TIME:', widget.checkInTime),
                        const SizedBox(height: 8),
                        _buildInfoRow('STATUS:', widget.status),
                        const SizedBox(height: 8),
                        _buildInfoRow('LOCATION:', widget.location),
                        const SizedBox(height: 8),
                        _buildInfoRow('NEXT:', widget.nextAction),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: MediaQuery.of(context).size.width * 0.025,
              color: AppColor.kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: MediaQuery.of(context).size.width * 0.028,
              fontWeight: FontWeight.bold,
              color: AppColor.kCyanSecondary,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColor.kGradientCyanVibrant,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColor.kCyanPrimary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: () {
          // Cancel timer ketika button ditekan
          _autoRedirectTimer?.cancel();
          _countdownTimer.cancel();
          _countdownController.stop(); // Stop countdown animation

          _navigateToHome();
        },
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Text(
          'Continue',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoRedirectInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.home,
            color: Colors.white.withValues(alpha: 0.8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Returning to home...',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
