import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profile = authProvider.userProfile;
      if (profile != null) {
        _nameController.text = profile.fullName;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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

  Future<String?> _uploadProfileImage(String uid) async {
    if (_imageBytes == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/$uid.jpg',
      );
      await ref.putData(
        _imageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Upload image if selected
    String? photoUrl;
    if (_imageBytes != null) {
      final uid = authProvider.currentUser?.uid;
      if (uid != null) {
        photoUrl = await _uploadProfileImage(uid);
      }
    }

    final success = await authProvider.updateProfile(
      fullName: _nameController.text.trim(),
      photoUrl: photoUrl,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF2F7D32),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Failed to update profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
      authProvider.clearError();
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
          // Header
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [trust, trust.withAlpha(217)],
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
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Update your personal information',
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
                    // Profile Photo Picker
                    Center(
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final existingUrl =
                              authProvider.userProfile?.photoUrl;
                          return GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _imageBytes != null
                                      ? MemoryImage(_imageBytes!)
                                      : (existingUrl != null
                                            ? NetworkImage(existingUrl)
                                            : null),
                                  child:
                                      (_imageBytes == null &&
                                          existingUrl == null)
                                      ? Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.grey.shade400,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: trust,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Tap to change photo',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Full Name Field
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Display (Read-only)
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 20,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            authProvider.currentUser?.email ??
                                                'N/A',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: Colors.black54,
                                                ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.lock_outline,
                                          size: 16,
                                          color: Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email cannot be changed',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.black38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Role Display (Read-only)
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Role',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          authProvider.userProfile?.role
                                                      .toString() ==
                                                  'UserRole.caregiver'
                                              ? Icons.directions_walk
                                              : Icons.pets,
                                          size: 20,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            authProvider.userProfile?.role
                                                        .toString() ==
                                                    'UserRole.caregiver'
                                                ? 'Caregiver'
                                                : 'Pet Owner',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: Colors.black54,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trust,
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
                                'Save Changes',
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
}
