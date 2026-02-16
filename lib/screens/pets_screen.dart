import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pets_provider.dart';
import '../models/pet_model.dart';
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
    final theme = Theme.of(context);
    final trust = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: Column(
        children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [trust, trust.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Row(
              children: [
                const SizedBox(width: 48), // Balance the row
                const Expanded(
                  child: Center(
                    child: Text(
                      'My Pets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddPetScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Consumer<PetsProvider>(
                builder: (context, petsProvider, _) {
                  if (petsProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (petsProvider.pets.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount:
                        petsProvider.pets.length + 1, // +1 for add button
                    itemBuilder: (context, index) {
                      if (index == petsProvider.pets.length) {
                        return _buildAddPetButton(context);
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
    final trust = Theme.of(context).colorScheme.secondary;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: trust.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pets, size: 40, color: trust),
              ),
              const SizedBox(height: 16),
              const Text(
                'No pets added yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your pet to start tracking walks and care activity.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildAddPetButton(context),
      ],
    );
  }

  Widget _buildPetCard(BuildContext context, PetModel pet) {
    final trust = Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditPetScreen(pet: pet),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: trust.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_getPetIcon(pet.type), color: trust, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.type.name[0].toUpperCase()}${pet.type.name.substring(1)} • ${pet.age} years • ${pet.gender.name[0].toUpperCase()}${pet.gender.name.substring(1)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (pet.breed != null && pet.breed!.isNotEmpty)
                    Text(
                      pet.breed!,
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPetButton(BuildContext context) {
    final trust = Theme.of(context).colorScheme.secondary;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPetScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: trust,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add a Pet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  IconData _getPetIcon(PetType type) {
    switch (type) {
      case PetType.dog:
        return Icons.pets;
      case PetType.cat:
        return Icons.emoji_nature;
      default:
        return Icons.cruelty_free;
    }
  }
}
