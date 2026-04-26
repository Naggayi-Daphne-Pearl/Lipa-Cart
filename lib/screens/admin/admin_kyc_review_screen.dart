import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/rider_service.dart';
import '../../services/shopper_service.dart';

enum KycRole { shopper, rider }

class AdminKycReviewScreen extends StatefulWidget {
  final KycRole role;
  final Map<String, dynamic> applicant;

  const AdminKycReviewScreen({
    super.key,
    required this.role,
    required this.applicant,
  });

  @override
  State<AdminKycReviewScreen> createState() => _AdminKycReviewScreenState();
}

enum _Decision { approve, reject, requestMoreInfo }

class _AdminKycReviewScreenState extends State<AdminKycReviewScreen> {
  _Decision _decision = _Decision.approve;
  final _reasonController = TextEditingController();
  final _adminNotesController = TextEditingController();
  final Set<String> _fieldsToResubmit = {};
  bool _submitting = false;
  String? _error;

  static const _shopperFields = [
    {'key': 'id_photo', 'label': 'ID document'},
    {'key': 'face_photo', 'label': 'Face photo'},
  ];

  static const _riderFields = [
    {'key': 'id_photo', 'label': 'ID document'},
    {'key': 'face_photo', 'label': 'Face photo'},
    {'key': 'license_photo', 'label': 'Driver licence'},
  ];

  static const _rejectReasonOptions = [
    'Document is blurry or unreadable',
    'Document does not match applicant',
    'Expired or invalid document',
    'Suspected fraudulent submission',
    'Incomplete information',
    'Other (use notes)',
  ];

  List<Map<String, String>> get _fieldOptions =>
      widget.role == KycRole.shopper ? _shopperFields : _riderFields;

  Map<String, dynamic> get _profile {
    final raw = widget.applicant[widget.role == KycRole.shopper ? 'shopper' : 'rider'];
    if (raw is Map<String, dynamic>) return raw;
    return widget.applicant;
  }

  String? get _documentId =>
      _profile['documentId']?.toString() ??
      widget.applicant['documentId']?.toString();

  @override
  void dispose() {
    _reasonController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final docId = _documentId;
    if (docId == null) {
      setState(() => _error = 'Missing applicant documentId.');
      return;
    }

    if (_decision == _Decision.requestMoreInfo && _fieldsToResubmit.isEmpty) {
      setState(
        () => _error = 'Pick at least one field for the applicant to resubmit.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _submitting = false;
        _error = 'Not signed in.';
      });
      return;
    }

    final decisionStr = switch (_decision) {
      _Decision.approve => 'approve',
      _Decision.reject => 'reject',
      _Decision.requestMoreInfo => 'request_more_info',
    };

    try {
      if (widget.role == KycRole.shopper) {
        await ShopperService.submitKycDecision(
          docId,
          token: token,
          decision: decisionStr,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
          adminNotes: _adminNotesController.text.trim().isEmpty
              ? null
              : _adminNotesController.text.trim(),
          fieldsToResubmit: _decision == _Decision.requestMoreInfo
              ? _fieldsToResubmit.toList()
              : null,
        );
      } else {
        await RiderService.submitKycDecision(
          docId,
          token: token,
          decision: decisionStr,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
          adminNotes: _adminNotesController.text.trim().isEmpty
              ? null
              : _adminNotesController.text.trim(),
          fieldsToResubmit: _decision == _Decision.requestMoreInfo
              ? _fieldsToResubmit.toList()
              : null,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.applicant['name'] ?? 'Applicant').toString();
    final phone = (widget.applicant['phone'] ?? '').toString();
    final kycStatus = (_profile['kyc_status'] ?? 'pending_review').toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.role == KycRole.shopper
              ? 'Shopper KYC review'
              : 'Rider KYC review',
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          final left = _ApplicantPanel(
            role: widget.role,
            applicant: widget.applicant,
            profile: _profile,
            name: name,
            phone: phone,
            kycStatus: kycStatus,
          );
          final right = _DecisionConsole(
            decision: _decision,
            onDecisionChanged: (d) => setState(() => _decision = d),
            reasonController: _reasonController,
            rejectReasonOptions: _rejectReasonOptions,
            adminNotesController: _adminNotesController,
            fieldOptions: _fieldOptions,
            fieldsToResubmit: _fieldsToResubmit,
            onFieldToggle: (k, v) {
              setState(() {
                if (v) {
                  _fieldsToResubmit.add(k);
                } else {
                  _fieldsToResubmit.remove(k);
                }
              });
            },
            submitting: _submitting,
            error: _error,
            onSubmit: _submit,
          );

          if (isWide) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: left),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: right),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [left, const SizedBox(height: 16), right],
            ),
          );
        },
      ),
    );
  }
}

class _ApplicantPanel extends StatelessWidget {
  final KycRole role;
  final Map<String, dynamic> applicant;
  final Map<String, dynamic> profile;
  final String name;
  final String phone;
  final String kycStatus;

  const _ApplicantPanel({
    required this.role,
    required this.applicant,
    required this.profile,
    required this.name,
    required this.phone,
    required this.kycStatus,
  });

  String? _photoUrl(List<String> keys) {
    for (final k in keys) {
      final v = profile[k];
      if (v is String && v.isNotEmpty) return v;
      if (v is Map<String, dynamic>) {
        final url = v['url'];
        if (url is String && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final facePhoto = _photoUrl(['face_photo_url', 'face_photo']);
    final idPhoto = _photoUrl(['id_photo_url', 'id_photo']);
    final licensePhoto = _photoUrl(['license_photo_url', 'license_photo']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.grey200,
                backgroundImage:
                    facePhoto != null ? NetworkImage(facePhoto) : null,
                child: facePhoto == null
                    ? const Icon(Icons.person, color: AppColors.grey500)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(status: kycStatus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle('Documents'),
          _DocumentTile(label: 'ID document', url: idPhoto),
          if (role == KycRole.rider)
            _DocumentTile(label: 'Driver licence', url: licensePhoto),
          _DocumentTile(label: 'Face photo', url: facePhoto),
          const SizedBox(height: 24),
          _SectionTitle('Personal details'),
          ..._buildDetails(),
          if ((profile['kyc_admin_notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle('Previous admin notes'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(profile['kyc_admin_notes'].toString()),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDetails() {
    String? get(String key) {
      final v = profile[key];
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    final rows = <Widget>[];
    if (role == KycRole.shopper) {
      _add(rows, 'Market location', get('market_location'));
      _add(rows, 'ID number', get('id_number'));
      _add(rows, 'Mobile money', get('mobile_money_provider'));
      _add(rows, 'Mobile money number', get('mobile_money_number'));
    } else {
      _add(rows, 'Vehicle type', get('vehicle_type'));
      _add(rows, 'Vehicle make', get('vehicle_make'));
      _add(rows, 'Vehicle plate', get('vehicle_plate'));
      _add(rows, 'Licence number', get('license_number'));
      _add(rows, 'ID number', get('id_number'));
    }
    return rows;
  }

  void _add(List<Widget> rows, String label, String? value) {
    if (value == null) return;
    rows.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(
                label,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      'approved' => (AppColors.success, AppColors.cardGreen),
      'rejected' => (AppColors.error, AppColors.errorSoft),
      'more_info_requested' => (AppColors.warning, AppColors.accentSoft),
      _ => (AppColors.info, AppColors.cardBlue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: colors.$1,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String label;
  final String? url;
  const _DocumentTile({required this.label, required this.url});

  void _openFullscreen(BuildContext context) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(24),
        child: InteractiveViewer(
          child: Image.network(url!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _openFullscreen(context),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                image: url != null
                    ? DecorationImage(
                        image: NetworkImage(url!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: url == null
                  ? Center(
                      child: Text(
                        'Not provided',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tap to zoom',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionConsole extends StatelessWidget {
  final _Decision decision;
  final ValueChanged<_Decision> onDecisionChanged;
  final TextEditingController reasonController;
  final List<String> rejectReasonOptions;
  final TextEditingController adminNotesController;
  final List<Map<String, String>> fieldOptions;
  final Set<String> fieldsToResubmit;
  final void Function(String, bool) onFieldToggle;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;

  const _DecisionConsole({
    required this.decision,
    required this.onDecisionChanged,
    required this.reasonController,
    required this.rejectReasonOptions,
    required this.adminNotesController,
    required this.fieldOptions,
    required this.fieldsToResubmit,
    required this.onFieldToggle,
    required this.submitting,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Decision Console',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _DecisionRadio(
            value: _Decision.approve,
            current: decision,
            onChanged: onDecisionChanged,
            label: 'Approve',
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
          _DecisionRadio(
            value: _Decision.reject,
            current: decision,
            onChanged: onDecisionChanged,
            label: 'Reject',
            color: AppColors.error,
            icon: Icons.block,
          ),
          _DecisionRadio(
            value: _Decision.requestMoreInfo,
            current: decision,
            onChanged: onDecisionChanged,
            label: 'Request more info',
            color: AppColors.warning,
            icon: Icons.help_outline,
          ),
          const SizedBox(height: 16),
          if (decision == _Decision.reject) ...[
            _SectionTitle('Reason'),
            DropdownButtonFormField<String>(
              value: rejectReasonOptions.contains(reasonController.text)
                  ? reasonController.text
                  : null,
              hint: const Text('Pick a reason'),
              items: rejectReasonOptions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) {
                if (v != null) reasonController.text = v;
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Or write a custom reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (decision == _Decision.requestMoreInfo) ...[
            _SectionTitle('Which fields to resubmit?'),
            ...fieldOptions.map(
              (f) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: fieldsToResubmit.contains(f['key']),
                onChanged: (v) => onFieldToggle(f['key']!, v ?? false),
                title: Text(f['label']!),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Message to applicant (sent in app)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionTitle('Admin notes (internal only)'),
          TextField(
            controller: adminNotesController,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(submitting ? 'Submitting...' : 'Submit decision'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.grey900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionRadio extends StatelessWidget {
  final _Decision value;
  final _Decision current;
  final ValueChanged<_Decision> onChanged;
  final String label;
  final Color color;
  final IconData icon;

  const _DecisionRadio({
    required this.value,
    required this.current,
    required this.onChanged,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.grey200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Radio<_Decision>(
              value: value,
              groupValue: current,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
