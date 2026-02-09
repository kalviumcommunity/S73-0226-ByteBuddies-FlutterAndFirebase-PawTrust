import 'package:flutter/material.dart';

class CaregiverListScreen extends StatelessWidget {
  const CaregiverListScreen({super.key});

  static const Color trustGreen = Color(0xFF2F7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      body: Column(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  trustGreen,
                  Color(0xFF4CAF50),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Find Caregiver',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _caregiverCard(
                    name: 'Aarav Sharma',
                    rating: '4.8',
                    distance: '1.2 km away',
                  ),
                  _caregiverCard(
                    name: 'Neha Verma',
                    rating: '4.6',
                    distance: '2.5 km away',
                  ),
                  _caregiverCard(
                    name: 'Rahul Mehta',
                    rating: '4.9',
                    distance: '0.9 km away',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _caregiverCard({
    required String name,
    required String rating,
    required String distance,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: trustGreen,
            ),
            child: const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(
                Icons.person,
                color: trustGreen,
                size: 32,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distance,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified,
                      color: trustGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Verified',
                      style: TextStyle(
                        color: trustGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: trustGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
