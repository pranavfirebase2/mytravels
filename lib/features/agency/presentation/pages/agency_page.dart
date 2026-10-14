import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../domain/entities/agency.dart';
import '../providers/agency_providers.dart';

class AgencyPage extends ConsumerStatefulWidget {
  const AgencyPage({super.key});

  @override
  ConsumerState<AgencyPage> createState() => _AgencyPageState();
}

class _AgencyPageState extends ConsumerState<AgencyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAgencyDialog() {
    final nameController = TextEditingController();
    final whatsappController = TextEditingController();
    final deductionController = TextEditingController();
    bool isStarred = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_business_rounded, color: AppColors.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Add New Agency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textGrey),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Agency Name',
                          hintText: 'e.g. Glansa, Signix',
                          prefixIcon: const Icon(Icons.business_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'WhatsApp Number',
                          hintText: 'e.g. +91 9876543210',
                          prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: deductionController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Comparison Deduction',
                          prefixText: '₹ ',
                          hintText: '0',
                          hintStyle: const TextStyle(color: AppColors.textGrey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => setDialogState(() => isStarred = !isStarred),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isStarred ? Colors.amber[700]! : Colors.grey.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: isStarred ? Colors.amber.withValues(alpha: 0.08) : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                                color: isStarred ? Colors.amber[700] : AppColors.buttonGrey,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mark as Starred Agency',
                                style: TextStyle(
                                  fontWeight: isStarred ? FontWeight.bold : FontWeight.w500,
                                  color: isStarred ? Colors.amber[900] : AppColors.textBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.buttonGrey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an agency name')),
                      );
                      return;
                    }

                    final newAgency = Agency(
                      id: '',
                      name: name,
                      whatsappNumber: whatsappController.text.trim(),
                      comparisonDeduction: double.tryParse(deductionController.text.trim()) ?? 0.0,
                      isStarred: isStarred,
                    );

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(dialogContext).pop();

                    try {
                      await ref.read(agencyControllerProvider).addAgency(newAgency);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Agency "$name" added successfully'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error adding agency: $e'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Agency', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateAgency(Agency updatedAgency) async {
    try {
      await ref.read(agencyControllerProvider).updateAgency(updatedAgency);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated "${updatedAgency.name}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating agency: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteAgency(Agency agency) async {
    try {
      await ref.read(agencyControllerProvider).deleteAgency(agency.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Agency "${agency.name}" deleted'),
            backgroundColor: AppColors.buttonGrey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting agency: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _showEditAgencyDialog(Agency agency) {
    final editNameController = TextEditingController(text: agency.name);
    final editWhatsappController = TextEditingController(text: agency.whatsappNumber);
    final editDeductionController = TextEditingController(
      text: agency.comparisonDeduction > 0
          ? (agency.comparisonDeduction.truncateToDouble() == agency.comparisonDeduction
              ? agency.comparisonDeduction.toInt().toString()
              : agency.comparisonDeduction.toString())
          : '',
    );
    bool editIsStarred = agency.isStarred;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppColors.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Edit Agency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: editNameController,
                        decoration: InputDecoration(
                          labelText: 'Agency Name',
                          hintText: 'e.g. Glansa, Signix',
                          prefixIcon: const Icon(Icons.business_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: editWhatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'WhatsApp Number',
                          hintText: 'e.g. +91 9876543210',
                          prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: editDeductionController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Comparison Deduction',
                          prefixText: '₹ ',
                          hintText: '0',
                          hintStyle: const TextStyle(color: AppColors.textGrey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => setDialogState(() => editIsStarred = !editIsStarred),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: editIsStarred ? Colors.amber[700]! : Colors.grey.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: editIsStarred ? Colors.amber.withValues(alpha: 0.08) : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                editIsStarred ? Icons.star_rounded : Icons.star_border_rounded,
                                color: editIsStarred ? Colors.amber[700] : AppColors.buttonGrey,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mark as Starred Agency',
                                style: TextStyle(
                                  fontWeight: editIsStarred ? FontWeight.bold : FontWeight.w500,
                                  color: editIsStarred ? Colors.amber[900] : AppColors.textBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.buttonGrey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    final newName = editNameController.text.trim();
                    if (newName.isEmpty) return;
                    Navigator.of(dialogContext).pop();
                    _updateAgency(
                      agency.copyWith(
                        name: newName,
                        whatsappNumber: editWhatsappController.text.trim(),
                        comparisonDeduction: double.tryParse(editDeductionController.text.trim()) ?? 0.0,
                        isStarred: editIsStarred,
                      ),
                    );
                  },
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(Agency agency) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 24),
              SizedBox(width: 8),
              Text('Delete Agency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text('Are you sure you want to delete "${agency.name}"? This action cannot be undone.'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.buttonGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteAgency(agency);
              },
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return AppLayout(
      activeRoute: '/agency',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(isMobile),
          const SizedBox(height: 16),
          _buildAgencySettingsCard(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isMobile) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Agency Master',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _showAddAgencyDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Agency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Maintain agency details, WhatsApp contact, starring and comparison deduction.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Agency Master',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Maintain agency details, WhatsApp contact, starring and comparison deduction. The deduction is applied only to the comparison fare.',
                          style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    onPressed: _showAddAgencyDialog,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'Add Agency',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAgencySettingsCard(bool isMobile) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Agency Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Comparison deduction and WhatsApp details for all agencies.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search agency by name or WhatsApp number...',
                hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.buttonGrey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.scaffoldBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ref.watch(agenciesStreamProvider).when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Error loading agencies: $err', style: const TextStyle(color: AppColors.errorRed)),
                    ),
                  ),
                  data: (agencies) {
                    if (agencies.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(36.0),
                          child: Column(
                            children: const [
                              Icon(Icons.business_center_outlined, size: 48, color: AppColors.textGrey),
                              SizedBox(height: 10),
                              Text('No agencies added yet.', style: TextStyle(color: AppColors.textGrey, fontSize: 15)),
                              SizedBox(height: 4),
                              Text('Click "Add Agency" above to add your first agency.', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }

                    final filteredAgencies = agencies.where((a) {
                      if (_searchQuery.isEmpty) return true;
                      return a.name.toLowerCase().contains(_searchQuery) ||
                          a.whatsappNumber.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredAgencies.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No agencies matching "$_searchQuery"',
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: isMobile ? 500 : 340,
                            mainAxisExtent: 172,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: filteredAgencies.length,
                          itemBuilder: (context, index) {
                            final agency = filteredAgencies[index];
                            return _AgencyTile(
                              key: ValueKey(agency.id),
                              agency: agency,
                              onStarToggle: () {
                                _updateAgency(agency.copyWith(isStarred: !agency.isStarred));
                              },
                              onEdit: () => _showEditAgencyDialog(agency),
                              onDelete: () => _showDeleteConfirmDialog(agency),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _AgencyTile extends StatelessWidget {
  final Agency agency;
  final VoidCallback onStarToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AgencyTile({
    super.key,
    required this.agency,
    required this.onStarToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deductionFormatted = agency.comparisonDeduction.truncateToDouble() == agency.comparisonDeduction
        ? agency.comparisonDeduction.toInt().toString()
        : agency.comparisonDeduction.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: agency.isStarred
              ? Colors.amber.withValues(alpha: 0.6)
              : Colors.grey.withValues(alpha: 0.22),
          width: agency.isStarred ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: agency.isStarred
                ? Colors.amber.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Avatar + Name + Star Button
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: agency.isStarred
                        ? Colors.amber.withValues(alpha: 0.16)
                        : AppColors.primaryBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      agency.name.isNotEmpty ? agency.name[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: agency.isStarred ? Colors.amber[900] : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agency.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (agency.isStarred)
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 13, color: Colors.amber[800]),
                            const SizedBox(width: 2),
                            Text(
                              'Starred Agency',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: agency.isStarred ? 'Remove star' : 'Star this agency',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    agency.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                    color: agency.isStarred ? Colors.amber[700] : Colors.grey[400],
                    size: 26,
                  ),
                  onPressed: onStarToggle,
                ),
              ],
            ),

            // Middle Section: WhatsApp Row & Deduction Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WhatsApp Row
                InkWell(
                  onTap: agency.whatsappNumber.isNotEmpty
                      ? () {
                          Clipboard.setData(ClipboardData(text: agency.whatsappNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied "${agency.whatsappNumber}" to clipboard'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : onEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: agency.whatsappNumber.isNotEmpty
                                ? const Color(0xFF25D366).withValues(alpha: 0.15)
                                : AppColors.errorRed.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            agency.whatsappNumber.isNotEmpty
                                ? Icons.chat_bubble_rounded
                                : Icons.warning_amber_rounded,
                            size: 13,
                            color: agency.whatsappNumber.isNotEmpty
                                ? const Color(0xFF1EBE5D)
                                : AppColors.errorRed,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            agency.whatsappNumber.isNotEmpty
                                ? agency.whatsappNumber
                                : 'Agency number not added',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: agency.whatsappNumber.isNotEmpty
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: agency.whatsappNumber.isNotEmpty
                                  ? const Color(0xFF1B8A44)
                                  : AppColors.errorRed,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (agency.whatsappNumber.isNotEmpty)
                          const Icon(Icons.copy_rounded, size: 12, color: AppColors.textGrey)
                        else
                          const Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.errorRed),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Deduction Badge (Tap to Edit)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Deduction: ₹ $deductionFormatted',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonGrey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_outlined, size: 11, color: AppColors.textGrey),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom Actions: Edit & Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 13),
                  label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Delete Agency',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.errorRed,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
