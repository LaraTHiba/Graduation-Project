import 'package:flutter/material.dart';

class ProCompanyRequestDialog extends StatelessWidget {
  const ProCompanyRequestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      elevation: 16,
      backgroundColor: Colors.white,
      child: Container(
        width: screenWidth * 0.95,
        constraints: BoxConstraints(
          minHeight: screenHeight * 0.2,
          maxHeight: screenHeight * 0.3,
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF93),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.business_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            const Text(
              "Pro-Company Request",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006C5F),
                letterSpacing: 0.5,
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.grey),
              splashRadius: 22,
            ),
          ],
        ),
      ),
    );
  }
}
