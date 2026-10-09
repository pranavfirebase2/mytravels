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
  Widget build(BuildContext context) {
    return AppLayout(
      activeRoute: '/agency',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildAddAgencyCard(),
          const SizedBox(height: 16),
          _buildAgencySettingsCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppColors.cardBackground,
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
              style: TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAgencyCard() {
    return Card(
      color: AppColors.cardBackground,
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
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Agency name e.g. Glansa',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _deductionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _isStarred,
                      onChanged: (val) =>
                          setState(() => _isStarred = val ?? false),
                    ),
                    const Text('Star'),
                  ],
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: _addAgency,
                  child: const Text('Add Agency'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencySettingsCard() {
    return Card(
      color: AppColors.cardBackground,
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
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),
            ref
                .watch(agenciesStreamProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (agencies) {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: agencies.length + 1,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
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
                                Expanded(
                                  flex: 2,
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
  final Function(Agency) onSave;
  final VoidCallback onDelete;

  const _AgencyListItem({
    super.key,
    required this.agency,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Checkbox(
              value: _isStarred,
              onChanged: (val) => setState(() => _isStarred = val ?? false),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _deductionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(60, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    final updated = widget.agency.copyWith(
                      name: _nameController.text,
                      comparisonDeduction:
                          double.tryParse(_deductionController.text) ?? 0,
                      isStarred: _isStarred,
                    );
                    widget.onSave(updated);
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.errorRed),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
