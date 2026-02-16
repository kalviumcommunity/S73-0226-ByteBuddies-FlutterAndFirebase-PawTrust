import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pets_provider.dart';
import '../models/pet_model.dart';

class EditPetScreen extends StatefulWidget {
  final PetModel pet;

  const EditPetScreen({super.key, required this.pet});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  static const Color trustGreen = Color(0xFF2F7D32);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();

  late PetType _selectedType;
  late PetGender _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize form with existing pet data
    _nameController.text = widget.pet.name;
    _breedController.text = widget.pet.breed ?? '';
    _ageController.text = widget.pet.age.toString();
    _selectedType = widget.pet.type;
    _selectedGender = widget.pet.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final petsProvider = Provider.of<PetsProvider>(context, listen: false);

    final success = await petsProvider.updatePet(
      petId: widget.pet.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      breed: _breedController.text.trim().isEmpty
          ? null
          : _breedController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      gender: _selectedGender,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet updated successfully!'),
          backgroundColor: trustGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(petsProvider.errorMessage ?? 'Failed to update pet'),
          backgroundColor: Colors.red,
        ),
      );
      petsProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [trustGreen, Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Pet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Update your pet\'s information',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Form Content
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
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Pet Information Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pet Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Pet Name
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Pet Name *',
                              hintText: 'Enter pet name',
                              prefixIcon: const Icon(Icons.pets),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter pet name';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Pet Type
                          DropdownButtonFormField<PetType>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              labelText: 'Pet Type *',
                              prefixIcon: const Icon(Icons.category),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                            ),
                            items: PetType.values
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(_getPetTypeName(type)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Breed
                          TextFormField(
                            controller: _breedController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Breed (Optional)',
                              hintText: 'Enter breed',
                              prefixIcon: const Icon(Icons.info_outline),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Age
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age (years) *',
                              hintText: 'Enter age',
                              prefixIcon: const Icon(Icons.cake),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter age';
                              }
                              final age = int.tryParse(value.trim());
                              if (age == null) {
                                return 'Please enter a valid number';
                              }
                              if (age < 0 || age > 50) {
                                return 'Age must be between 0 and 50';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Gender
                          DropdownButtonFormField<PetGender>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Gender *',
                              prefixIcon: const Icon(Icons.wc),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                            ),
                            items: PetGender.values
                                .map((gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(_getGenderName(gender)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedGender = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Update Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleUpdatePet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trustGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Update Pet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Delete Button
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _showDeleteDialog,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text(
                          'Delete Pet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPetTypeName(PetType type) {
    switch (type) {
      case PetType.dog:
        return 'Dog';
      case PetType.cat:
        return 'Cat';
      case PetType.other:
        return 'Other';
    }
  }

  String _getGenderName(PetGender gender) {
    switch (gender) {
      case PetGender.male:
        return 'Male';
      case PetGender.female:
        return 'Female';
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text(
          'Are you sure you want to delete ${widget.pet.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDeletePet();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeletePet() async {
    setState(() => _isLoading = true);

    final petsProvider = Provider.of<PetsProvider>(context, listen: false);
    final success = await petsProvider.deletePet(widget.pet.id);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pet deleted successfully'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(petsProvider.errorMessage ?? 'Failed to delete pet'),
          backgroundColor: Colors.red,
        ),
      );
      petsProvider.clearError();
    }
  }
}
