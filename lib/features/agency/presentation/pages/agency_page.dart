import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../domain/entities/agency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/agency_providers.dart';

class AgencyPage extends ConsumerStatefulWidget {
  const AgencyPage({super.key});

  @override
  ConsumerState<AgencyPage> createState() => _AgencyPageState();
}

class _AgencyPageState extends ConsumerState<AgencyPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deductionController = TextEditingController(
    text: '0',
  );
  bool _isStarred = false;

  Future<void> _addAgency() async {
    if (_nameController.text.isEmpty) return;
    final newAgency = Agency(
      id: '', // Firestore will auto-generate the ID
      name: _nameController.text,
      comparisonDeduction: double.tryParse(_deductionController.text) ?? 0.0,
      isStarred: _isStarred,
    );

    try {
      await ref.read(agencyControllerProvider).addAgency(newAgency);
      setState(() {
        _nameController.clear();
        _deductionController.text = '0';
        _isStarred = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agency Added Successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _updateAgency(Agency updatedAgency) async {
    try {
      await ref.read(agencyControllerProvider).updateAgency(updatedAgency);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Agency Updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteAgency(String id) async {
    try {
      await ref.read(agencyControllerProvider).deleteAgency(id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Agency Deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return AppLayout(
      activeRoute: '/agency',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildAddAgencyCard(isMobile),
          const SizedBox(height: 16),
          _buildAgencySettingsCard(isMobile),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Agency Master',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Maintain one agency name for imports, starring and comparison deduction. The deduction is applied only to the comparison fare.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAgencyCard(bool isMobile) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add agency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (isMobile) ...[
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Agency Name',
                  hintText: 'e.g. Glansa, Fly Creative',
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _deductionController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Deduction',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _isStarred = !_isStarred),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isStarred ? Colors.amber[700]! : Colors.grey.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _isStarred ? Colors.amber.withValues(alpha: 0.12) : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                            color: _isStarred ? Colors.amber[700] : AppColors.buttonGrey,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Star',
                            style: TextStyle(
                              fontWeight: _isStarred ? FontWeight.bold : FontWeight.w500,
                              color: _isStarred ? Colors.amber[900] : AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _addAgency,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Add Agency',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Agency name e.g. Glansa',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _deductionController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Deduction',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _isStarred = !_isStarred),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _isStarred,
                            onChanged: (val) =>
                                setState(() => _isStarred = val ?? false),
                          ),
                          const Text('Star'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _addAgency,
                    child: const Text('Add Agency'),
                  ),
                ],
              ),
            ],
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
            const Text(
              'Agency settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Example: Wallet ₹200 less, Santo ₹500 less. You can change these anytime.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ref.watch(agenciesStreamProvider).when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (agencies) {
                    if (agencies.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No agencies added yet.',
                            style: TextStyle(color: AppColors.textGrey),
                          ),
                        ),
                      );
                    }

                    if (isMobile) {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: agencies.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final agency = agencies[index];
                          return _AgencyListItem(
                            key: ValueKey(agency.id),
                            agency: agency,
                            isMobile: true,
                            onSave: _updateAgency,
                            onDelete: () => _deleteAgency(agency.id),
                          );
                        },
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: agencies.length + 1,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Agency',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text(
                                      'Starred',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Comparison deduction',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Center(
                                    child: Text(
                                      'Action',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final agency = agencies[index - 1];
                        return _AgencyListItem(
                          key: ValueKey(agency.id),
                          agency: agency,
                          isMobile: false,
                          onSave: _updateAgency,
                          onDelete: () => _deleteAgency(agency.id),
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

class _AgencyListItem extends StatefulWidget {
  final Agency agency;
  final bool isMobile;
  final Function(Agency) onSave;
  final VoidCallback onDelete;

  const _AgencyListItem({
    super.key,
    required this.agency,
    required this.isMobile,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_AgencyListItem> createState() => _AgencyListItemState();
}

class _AgencyListItemState extends State<_AgencyListItem> {
  late TextEditingController _nameController;
  late TextEditingController _deductionController;
  late bool _isStarred;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.agency.name);
    _deductionController = TextEditingController(
      text: widget.agency.comparisonDeduction.toString(),
    );
    _isStarred = widget.agency.isStarred;
  }

  @override
  void didUpdateWidget(_AgencyListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.agency != oldWidget.agency) {
      _nameController.text = widget.agency.name;
      _deductionController.text = widget.agency.comparisonDeduction.toString();
      _isStarred = widget.agency.isStarred;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.agency.copyWith(
      name: _nameController.text.trim(),
      comparisonDeduction:
          double.tryParse(_deductionController.text) ?? 0.0,
      isStarred: _isStarred,
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Agency Name',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _isStarred ? 'Starred Agency' : 'Mark as Starred',
                  icon: Icon(
                    _isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                    color: _isStarred ? Colors.amber[700] : Colors.grey,
                    size: 28,
                  ),
                  onPressed: () => setState(() => _isStarred = !_isStarred),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _deductionController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Comparison Deduction',
                      prefixText: '₹ ',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.errorRed,
                  ),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete Agency',
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Checkbox(
                value: _isStarred,
                onChanged: (val) => setState(() => _isStarred = val ?? false),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _deductionController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(60, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.errorRed),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
