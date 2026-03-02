import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../providers/pets_provider.dart';
import '../models/pet_model.dart';
import '../widgets/paw_snackbar.dart';

class EditPetScreen extends StatefulWidget {
  final PetModel pet;

  const EditPetScreen({super.key, required this.pet});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();

  late PetType _selectedType;
  late PetGender _selectedGender;
  bool _isLoading = false;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.pet.name;
    _breedController.text = widget.pet.breed ?? '';
    _ageController.text = widget.pet.age.toString();
    _selectedType = widget.pet.type;
    _selectedGender = widget.pet.gender;
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
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
    HapticFeedback.lightImpact();

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
      imageBytes: _imageBytes,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      PawSnackBar.success(context, 'Pet updated successfully!');
      Navigator.pop(context);
    } else {
      PawSnackBar.error(
        context,
        petsProvider.errorMessage ?? 'Failed to update pet',
      );
      petsProvider.clearError();
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
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 8,
              24,
              28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [PawTrustApp.primaryBlue, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Edit Pet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Update your pet\'s information',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Form Content ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Pet Information Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: PawTrustApp.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pet Photo
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 98,
                                    height: 98,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          PawTrustApp.primaryBlue.withAlpha(77),
                                          PawTrustApp.tertiary.withAlpha(51),
                                        ],
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: CircleAvatar(
                                        radius: 45,
                                        backgroundColor:
                                            PawTrustApp.borderColor,
                                        backgroundImage: _imageBytes != null
                                            ? MemoryImage(_imageBytes!)
                                            : (widget.pet.photoUrl != null
                                                  ? NetworkImage(
                                                      widget.pet.photoUrl!,
                                                    )
                                                  : null),
                                        child:
                                            (_imageBytes == null &&
                                                widget.pet.photoUrl == null)
                                            ? const Icon(
                                                Icons.pets_rounded,
                                                size: 36,
                                                color:
                                                    PawTrustApp.textSecondary,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: PawTrustApp.primaryBlue,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: PawTrustApp.primaryBlue
                                                .withAlpha(77),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Pet Details',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: PawTrustApp.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Pet Name
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Pet Name *',
                              hintText: 'Enter pet name',
                              prefixIcon: const Icon(Icons.pets_rounded),
                              filled: true,
                              fillColor: PawTrustApp.surfaceLight,
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
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: PawTrustApp.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Pet Type *',
                              prefixIcon: const Icon(Icons.category_rounded),
                              filled: true,
                              fillColor: PawTrustApp.surfaceLight,
                            ),
                            items: PetType.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(_getPetTypeName(type)),
                                  ),
                                )
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
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Breed (Optional)',
                              hintText: 'Enter breed',
                              prefixIcon: const Icon(
                                Icons.info_outline_rounded,
                              ),
                              filled: true,
                              fillColor: PawTrustApp.surfaceLight,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Age
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Age (years) *',
                              hintText: 'Enter age',
                              prefixIcon: const Icon(Icons.cake_rounded),
                              filled: true,
                              fillColor: PawTrustApp.surfaceLight,
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
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: PawTrustApp.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Gender *',
                              prefixIcon: const Icon(Icons.wc_rounded),
                              filled: true,
                              fillColor: PawTrustApp.surfaceLight,
                            ),
                            items: PetGender.values
                                .map(
                                  (gender) => DropdownMenuItem(
                                    value: gender,
                                    child: Text(_getGenderName(gender)),
                                  ),
                                )
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
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleUpdatePet,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Update Pet',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Delete Button
                    SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _showDeleteDialog,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          foregroundColor: const Color(0xFFEF4444),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          'Delete Pet',
                          style: GoogleFonts.poppins(
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

  void _showDeleteDialog() async {
    HapticFeedback.mediumImpact();
    final confirmed = await PawDialog.confirm(
      context,
      title: 'Delete Pet',
      message:
          'Are you sure you want to delete ${widget.pet.name}? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDangerous: true,
    );
    if (confirmed == true) _handleDeletePet();
  }

  Future<void> _handleDeletePet() async {
    setState(() => _isLoading = true);

    final petsProvider = Provider.of<PetsProvider>(context, listen: false);
    final success = await petsProvider.deletePet(widget.pet.id);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      PawSnackBar.warning(context, 'Pet deleted successfully');
      Navigator.pop(context);
    } else {
      PawSnackBar.error(
        context,
        petsProvider.errorMessage ?? 'Failed to delete pet',
      );
      petsProvider.clearError();
    }
  }
}
