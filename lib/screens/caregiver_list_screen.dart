import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../providers/pets_provider.dart';
import '../services/caregiver_service.dart';
import '../widgets/paw_snackbar.dart';
import '../widgets/shimmer_loading.dart';

class CaregiverListScreen extends StatefulWidget {
  const CaregiverListScreen({super.key});

  @override
  State<CaregiverListScreen> createState() => _CaregiverListScreenState();
}

class _CaregiverListScreenState extends State<CaregiverListScreen> {
  late Future<List<UserModel>> _caregiversFuture;
  final CaregiverService _caregiverService = CaregiverService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _caregiversFuture = _caregiverService.getAllCaregivers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterCaregivers(List<UserModel> caregivers) {
    if (_searchQuery.isEmpty) return caregivers;
    final query = _searchQuery.toLowerCase();
    return caregivers.where((c) {
      return c.fullName.toLowerCase().contains(query) ||
          (c.email.toLowerCase().contains(query));
    }).toList();
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
                colors: [PawTrustApp.tertiary, Color(0xFF9333EA)],
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
                    'Find Your Perfect',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Caregiver',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search caregivers...',
                      hintStyle: GoogleFonts.poppins(
                        color: PawTrustApp.textSecondary,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: PawTrustApp.cardWhite,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Caregiver List
                  Expanded(
                    child: FutureBuilder<List<UserModel>>(
                      future: _caregiversFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: ShimmerList(itemCount: 4),
                          );
                        }

                        if (snapshot.hasError) {
                          debugPrint(
                            'Error loading caregivers: ${snapshot.error}',
                          );
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.error_outline_rounded,
                                    size: 40,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Unable to load caregivers',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: PawTrustApp.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please check your connection and try again',
                                  style: GoogleFonts.poppins(
                                    color: PawTrustApp.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final allCaregivers = snapshot.data ?? [];
                        final caregivers = _filterCaregivers(allCaregivers);

                        if (allCaregivers.isEmpty) {
                          return const _EmptyCaregiverState();
                        }

                        if (caregivers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: PawTrustApp.borderColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: PawTrustApp.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No caregivers match your search',
                                  style: GoogleFonts.poppins(
                                    color: PawTrustApp.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: PawTrustApp.tertiary,
                          onRefresh: () async {
                            setState(() {
                              _caregiversFuture = _caregiverService
                                  .getAllCaregivers();
                            });
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: caregivers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _BuildCaregiverCard(
                                caregiver: caregivers[index],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildCaregiverCard extends StatefulWidget {
  final UserModel caregiver;

  const _BuildCaregiverCard({required this.caregiver});

  @override
  State<_BuildCaregiverCard> createState() => _BuildCaregiverCardState();
}

class _BuildCaregiverCardState extends State<_BuildCaregiverCard> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isCreatingRequest = false;
  int _selectedPetIndex = 0;

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleRequestCaregiver() async {
    if (_selectedDate == null || _selectedTime == null) {
      PawSnackBar.warning(context, 'Please select date and time');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final requestProvider = context.read<RequestProvider>();
    final petsProvider = context.read<PetsProvider>();

    if (authProvider.user == null) {
      PawSnackBar.error(context, 'Please login first');
      return;
    }

    if (petsProvider.isLoading) {
      PawSnackBar.info(context, 'Loading your pets, please wait...');
      return;
    }

    if (petsProvider.pets.isEmpty) {
      PawSnackBar.warning(context, 'Please add a pet first');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isCreatingRequest = true);

    final currentUser = authProvider.user!;
    final pet = petsProvider.pets[_selectedPetIndex];

    final requestDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final success = await requestProvider.createRequest(
      petOwnerId: currentUser.uid,
      caregiverId: widget.caregiver.uid,
      ownerName: currentUser.fullName,
      caregiverName: widget.caregiver.fullName,
      petName: pet.name,
      petType: pet.typeDisplayName,
      requestedDate: requestDateTime,
      requestedTime:
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
    );

    setState(() => _isCreatingRequest = false);

    if (!mounted) return;

    if (success) {
      PawSnackBar.success(
        context,
        'Request sent to ${widget.caregiver.fullName}',
      );
      Navigator.pop(context);
    } else {
      PawSnackBar.error(
        context,
        requestProvider.errorMessage ?? 'Failed to send request',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PawTrustApp.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Name Row
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      PawTrustApp.tertiary.withAlpha(51),
                      PawTrustApp.tertiary.withAlpha(20),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: PawTrustApp.tertiary,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PawTrustApp.tertiary,
                          boxShadow: [
                            BoxShadow(
                              color: PawTrustApp.tertiary.withAlpha(77),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.caregiver.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: PawTrustApp.textPrimary,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Available Caregiver',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: PawTrustApp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pet Selection
          Consumer<PetsProvider>(
            builder: (context, petsProvider, _) {
              if (petsProvider.pets.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: PawTrustApp.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PawTrustApp.tertiary.withAlpha(51)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedPetIndex < petsProvider.pets.length
                        ? _selectedPetIndex
                        : 0,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.pets_rounded,
                      color: PawTrustApp.tertiary,
                      size: 20,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: PawTrustApp.textPrimary,
                    ),
                    items: List.generate(petsProvider.pets.length, (i) {
                      final p = petsProvider.pets[i];
                      return DropdownMenuItem<int>(
                        value: i,
                        child: Text('${p.name} (${p.typeDisplayName})'),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPetIndex = val);
                    },
                  ),
                ),
              );
            },
          ),

          // Date & Time Selection
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PawTrustApp.surfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: PawTrustApp.cardWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedDate != null
                              ? PawTrustApp.tertiary
                              : PawTrustApp.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: PawTrustApp.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: PawTrustApp.cardWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedTime != null
                              ? PawTrustApp.tertiary
                              : PawTrustApp.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: PawTrustApp.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime == null
                                ? 'Select Time'
                                : _selectedTime!.format(context),
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Request Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isCreatingRequest ? null : _handleRequestCaregiver,
              style: ElevatedButton.styleFrom(
                backgroundColor: PawTrustApp.tertiary,
              ),
              icon: _isCreatingRequest
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                _isCreatingRequest ? 'Sending...' : 'Send Request',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCaregiverState extends StatelessWidget {
  const _EmptyCaregiverState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: PawTrustApp.tertiary.withAlpha(26),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  size: 44,
                  color: PawTrustApp.tertiary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Caregivers Available',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: PawTrustApp.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later or try refreshing the page.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: PawTrustApp.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
