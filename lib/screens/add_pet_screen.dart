import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../providers/auth_provider.dart';
import '../providers/pets_provider.dart';
import '../models/pet_model.dart';
import '../widgets/paw_snackbar.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();

  PetType _selectedType = PetType.dog;
  PetGender _selectedGender = PetGender.male;
  bool _isLoading = false;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    super.dispose();
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

  Future<void> _handleSavePet() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petsProvider = Provider.of<PetsProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      PawSnackBar.error(context, 'User not authenticated');
      setState(() => _isLoading = false);
      return;
    }

    final success = await petsProvider.addPet(
      ownerId: userId,
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

    if (success && mounted) {
      PawSnackBar.success(context, 'Pet added successfully!');
      Navigator.pop(context);
    } else if (mounted) {
      PawSnackBar.error(
        context,
        petsProvider.errorMessage ?? 'Failed to add pet',
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
                colors: [PawTrustApp.trustGreen, Color(0xFF059669)],
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
                    'Add Pet',
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
                    'Tell us about your furry friend',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Form ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Photo Picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 106,
                              height: 106,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    PawTrustApp.trustGreen.withAlpha(77),
                                    PawTrustApp.primaryBlue.withAlpha(51),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: PawTrustApp.borderColor,
                                  backgroundImage: _imageBytes != null
                                      ? MemoryImage(_imageBytes!)
                                      : null,
                                  child: _imageBytes == null
                                      ? const Icon(
                                          Icons.pets_rounded,
                                          size: 40,
                                          color: PawTrustApp.textSecondary,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: PawTrustApp.trustGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: PawTrustApp.trustGreen.withAlpha(
                                        77,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Tap to add photo',
                        style: GoogleFonts.poppins(
                          color: PawTrustApp.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card with fields
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
                          _buildTextField(
                            label: 'Pet Name',
                            controller: _nameController,
                            icon: Icons.pets_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter pet name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildDropdown<PetType>(
                            label: 'Pet Type',
                            value: _selectedType,
                            icon: Icons.category_rounded,
                            items: PetType.values,
                            displayName: (t) =>
                                t.name[0].toUpperCase() + t.name.substring(1),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedType = v);
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            label: 'Breed (Optional)',
                            controller: _breedController,
                            icon: Icons.info_outline_rounded,
                          ),
                          const SizedBox(height: 18),
                          _buildTextField(
                            label: 'Age (years)',
                            controller: _ageController,
                            icon: Icons.cake_rounded,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter age';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildDropdown<PetGender>(
                            label: 'Gender',
                            value: _selectedGender,
                            icon: Icons.wc_rounded,
                            items: PetGender.values,
                            displayName: (g) =>
                                g.name[0].toUpperCase() + g.name.substring(1),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedGender = v);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSavePet,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Pet',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: PawTrustApp.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: PawTrustApp.surfaceLight,
      ),
    );
  }

  Widget _buildDropdown<T extends Enum>({
    required String label,
    required T value,
    required IconData icon,
    required List<T> items,
    required String Function(T) displayName,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: PawTrustApp.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: PawTrustApp.surfaceLight,
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: PawTrustApp.textPrimary),
      items: items
          .map(
            (item) =>
                DropdownMenuItem(value: item, child: Text(displayName(item))),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
