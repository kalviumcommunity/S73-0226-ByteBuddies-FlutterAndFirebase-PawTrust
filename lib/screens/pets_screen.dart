import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/pets_provider.dart';
import '../models/pet_model.dart';
import '../widgets/shimmer_loading.dart';
import 'add_pet_screen.dart';
import 'edit_pet_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePets();
    });
  }

  void _initializePets() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petsProvider = Provider.of<PetsProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId != null) {
      petsProvider.initializePets(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawTrustApp.surfaceLight,
      body: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [PawTrustApp.trustGreen, Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Center(
                        child: Text(
                          'My Pets',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddPetScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          Expanded(
            child: Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: const BoxDecoration(
                color: PawTrustApp.surfaceLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Consumer<PetsProvider>(
                builder: (context, petsProvider, _) {
                  if (petsProvider.isLoading) {
                    return const ShimmerList(itemCount: 4);
                  }

                  if (petsProvider.pets.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: petsProvider.pets.length + 1,
                    itemBuilder: (context, index) {
                      if (index == petsProvider.pets.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: _buildAddPetButton(context),
                        );
                      }
                      return _buildPetCard(context, petsProvider.pets[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: PawTrustApp.borderColor.withAlpha(100)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: PawTrustApp.trustGreen.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  size: 40,
                  color: PawTrustApp.trustGreen,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No pets added yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: PawTrustApp.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your pet to start tracking walks and care activity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: PawTrustApp.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildAddPetButton(context),
      ],
    );
  }

  Widget _buildPetCard(BuildContext context, PetModel pet) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditPetScreen(pet: pet)),
        );
      },
      child: Hero(
        tag: 'pet-${pet.id}',
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PawTrustApp.borderColor.withAlpha(100)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PawTrustApp.trustGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getPetIcon(pet.type),
                    color: PawTrustApp.trustGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: PawTrustApp.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${pet.type.name[0].toUpperCase()}${pet.type.name.substring(1)} • ${pet.age} years • ${pet.gender.name[0].toUpperCase()}${pet.gender.name.substring(1)}',
                        style: GoogleFonts.poppins(
                          color: PawTrustApp.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (pet.breed != null && pet.breed!.isNotEmpty)
                        Text(
                          pet.breed!,
                          style: GoogleFonts.poppins(
                            color: PawTrustApp.textSecondary.withAlpha(180),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: PawTrustApp.textSecondary.withAlpha(120),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPetScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: PawTrustApp.trustGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add a Pet',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  IconData _getPetIcon(PetType type) {
    switch (type) {
      case PetType.dog:
        return Icons.pets_rounded;
      case PetType.cat:
        return Icons.emoji_nature_rounded;
      default:
        return Icons.cruelty_free_rounded;
    }
  }
}
