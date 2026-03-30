import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nmls_mobile/config/api_config.dart';

// ─── Theme tokens (match web) ─────────────────────────────────────
const _kNavy   = Color(0xFF091925);
const _kBlue   = Color(0xFF2EABFE);
const _kTeal   = Color(0xFF00B4B4);
const _kGreen  = Color(0xFF22C55E);
const _kBg     = Color(0xFFF6F7FB);
const _kBorder = Color(0x14020817);
const _kMuted  = Color(0x80091925);
const _kWhite  = Colors.white;

const _kSubmissionSteps = [
  'Relstone NMLS reports your completion to NMLS within 7 business days of finishing your course.',
  'Log in to your NMLS account and verify your CE appears under \'Education\' in your record.',
  'If your state requires direct submission, download your certificate PDF and upload it through your state regulator\'s portal.',
  'Keep your certificate PDF for personal records — regulators may request proof during audits.',
  'Contact Relstone support if your CE does not appear in NMLS within 10 business days.',
];

// ═══════════════════════════════════════════════════════════════════
// MY CERTIFICATES SCREEN
// ═══════════════════════════════════════════════════════════════════
class MyCertificatesScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const MyCertificatesScreen({Key? key, this.user}) : super(key: key);

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  List<Map<String, dynamic>> _certs = [];
  bool   _loading = true;
  String? _error;
  String? _token;
  bool   _bannerOpen = false;
  Map<String, dynamic>? _preview;
  bool   _copied = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    await _fetchCerts();
  }

  Future<void> _fetchCerts() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Replace with your ApiConfig.baseUrl
      final res = await http.get(
Uri.parse(ApiConfig.certificates),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final raw  = (data['certificates'] as List?) ?? [];
        setState(() {
          _certs = raw.map((c) => Map<String, dynamic>.from(c as Map)).toList();
        });
      } else {
        setState(() => _error = 'Failed to load certificates.');
      }
    } catch (_) {
      setState(() => _error = 'Failed to load certificates.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _userName {
    final n = (widget.user?['name'] ?? '').toString().trim();
    return n.isEmpty ? 'Student Name' : n;
  }

  Future<void> _openLinkedIn(Map<String, dynamic> cert) async {
    final title     = Uri.encodeComponent(cert['course_title'] ?? 'NMLS Course');
    final org       = Uri.encodeComponent('Relstone NMLS');
    final completed = cert['completed_at'] as String?;
    final dt        = completed != null ? DateTime.tryParse(completed) : null;
    final month     = dt?.month ?? DateTime.now().month;
    final year      = dt?.year  ?? DateTime.now().year;
    final url = Uri.parse(
      'https://www.linkedin.com/profile/add?startTask=CERTIFICATION_NAME'
      '&name=$title&organizationName=$org&issueMonth=$month&issueYear=$year',
    );
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  String _certId(Map<String, dynamic> cert) {
    final id = (cert['_id'] ?? '').toString();
    return id.length >= 10 ? id.substring(id.length - 10).toUpperCase() : id.toUpperCase();
  }

  String _fmtDate(String? iso, {bool long = false}) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      const short = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const full  = ['January','February','March','April','May','June','July','August','September','October','November','December'];
      if (long) return '${full[d.month - 1]} ${d.day}, ${d.year}';
      return '${short[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2.5))
                  : _error != null
                      ? _buildError()
                      : _certs.isEmpty
                          ? _buildEmpty()
                          : _buildContent(),
            ),
          ],
        ),
      ),
      // Preview modal overlay
      floatingActionButton: null,
    );
  }

  // ── Header (matches web page header + navy top bar) ───────────────
  Widget _buildHeader() => Container(
    color: _kNavy,
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
    child: Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white70),
            ),
            const Expanded(
              child: Text(
                'My Certificates',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: _kWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 18),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _loading ? '' : '${_certs.length} certificate${_certs.length == 1 ? '' : 's'} earned',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF7D92A3),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  // ── Main scrollable content ───────────────────────────────────────
  Widget _buildContent() => Stack(
    children: [
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page kicker + badge row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBlue.withOpacity(0.20)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 13, color: _kBlue),
                      SizedBox(width: 5),
                      Text('Achievements', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: _kBlue, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kBlue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBlue.withOpacity(0.20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, size: 15, color: _kBlue),
                      const SizedBox(width: 6),
                      Text(
                        '${_certs.length} Certificate${_certs.length == 1 ? '' : 's'} Earned',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: _kNavy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Submission banner
            _buildSubmissionBanner(),
            const SizedBox(height: 14),

            // Certificate cards
            ..._certs.map((cert) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CertCard(
                cert: cert,
                userName: _userName,
                fmtDate: _fmtDate,
                onPreview: () => setState(() => _preview = cert),
                onLinkedIn: () => _openLinkedIn(cert),
              ),
            )),
          ],
        ),
      ),

      // Modal overlay
      if (_preview != null) ...[
        GestureDetector(
          onTap: () => setState(() => _preview = null),
          child: Container(color: Colors.black.withOpacity(0.65)),
        ),
        _buildPreviewModal(_preview!),
      ],
    ],
  );

  // ── Submission banner ─────────────────────────────────────────────
  Widget _buildSubmissionBanner() => Container(
    decoration: BoxDecoration(
      color: _kBlue.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBlue.withOpacity(0.18)),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _kBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBlue.withOpacity(0.20)),
                ),
                child: const Icon(Icons.info_outline_rounded, size: 16, color: _kBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to submit your CE to your state commission',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 13, color: _kNavy),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Relstone NMLS reports completions directly to NMLS within 7 business days.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _bannerOpen = !_bannerOpen),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBlue.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _bannerOpen ? 'Hide' : 'Show steps',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: _kBlue),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _bannerOpen ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right_rounded, size: 14, color: _kBlue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_bannerOpen) ...[
          Container(height: 1, color: _kBlue.withOpacity(0.10)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                ..._kSubmissionSteps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(99)),
                        alignment: Alignment.center,
                        child: Text('${e.key + 1}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: _kWhite)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _kNavy, height: 1.5)),
                      ),
                    ],
                  ),
                )),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://mortgage.nationwidelicensingsystem.org'), mode: LaunchMode.externalApplication),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 13, color: _kBlue),
                      SizedBox(width: 5),
                      Text('Visit NMLS Resource Center', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: _kBlue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  // ── Preview Modal (bottom sheet style on mobile) ──────────────────
  Widget _buildPreviewModal(Map<String, dynamic> cert) {
    final certId    = _certId(cert);
    final completed = cert['completed_at'] as String?;
    final courseType = (cert['course_type'] ?? '').toString().toUpperCase();

    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: GestureDetector(
        onTap: () {}, // prevent close on tap inside
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          decoration: const BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, -10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0x22091925), borderRadius: BorderRadius.circular(99)),
              ),

              // Modal header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 18, color: _kBlue),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Certificate Preview', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 15, color: _kNavy)),
                    ),
                    GestureDetector(
                      onTap: () => _openLinkedIn(cert),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x0F0A66C2),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0x400A66C2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.link_rounded, size: 14, color: Color(0xFF0A66C2)),
                            SizedBox(width: 5),
                            Text('LinkedIn', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A66C2))),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _preview = null),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x08020817),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kBorder),
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: _kMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x12020817)),

              // Scrollable body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── Certificate card preview ──────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: _kWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8))],
                          border: Border.all(color: _kBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Top gradient bar
                            Container(
                              height: 5,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [_kBlue, _kTeal]),
                              ),
                            ),

                            // Cert header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      color: _kBlue.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _kBlue.withOpacity(0.22), width: 2),
                                    ),
                                    child: const Icon(Icons.workspace_premium_rounded, size: 26, color: _kBlue),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text('Relstone NMLS', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: _kBlue, letterSpacing: 1.2)),
                                  const SizedBox(height: 4),
                                  const Text('Certificate of Completion', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w900, color: _kNavy, letterSpacing: -0.3)),
                                  const SizedBox(height: 3),
                                  Text(
                                    courseType == 'PE' ? 'Pre-Licensing Education (PE)' : 'Continuing Education (CE)',
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, color: _kMuted, letterSpacing: 0.6),
                                  ),
                                ],
                              ),
                            ),

                            // Divider with icon
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Expanded(child: Container(height: 1, color: _kBlue.withOpacity(0.18))),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: Icon(Icons.workspace_premium_rounded, size: 14, color: _kBlue),
                                  ),
                                  Expanded(child: Container(height: 1, color: _kBlue.withOpacity(0.18))),
                                ],
                              ),
                            ),

                            // Cert body
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                              child: Column(
                                children: [
                                  const Text('This is to certify that', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
                                  const SizedBox(height: 6),
                                  Text(
                                    _userName,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w900, color: _kNavy, letterSpacing: -0.4),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 2, bottom: 10),
                                    height: 2,
                                    width: 140,
                                    decoration: BoxDecoration(
                                      color: _kBlue.withOpacity(0.22),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  const Text('has successfully completed', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
                                  const SizedBox(height: 8),
                                  Text(
                                    cert['course_title'] ?? '—',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w900, color: _kNavy, height: 1.4),
                                  ),
                                  const SizedBox(height: 14),

                                  // Details grid
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _kBlue.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _kBlue.withOpacity(0.14)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: _CertDetailItem(label: 'Credit Hours', value: cert['credit_hours'] != null ? '${cert['credit_hours']} Hours' : '—')),
                                            Expanded(child: _CertDetailItem(label: 'Completion Date', value: _fmtDate(completed, long: true))),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(child: _CertDetailItem(label: 'State', value: cert['state'] ?? widget.user?['state'] ?? '—')),
                                            Expanded(child: _CertDetailItem(label: 'State Approval #', value: cert['state_approval'] ?? '—')),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(child: _CertDetailItem(label: 'NMLS ID', value: widget.user?['nmls_id'] ?? '—')),
                                            Expanded(child: _CertDetailItem(label: 'Certificate ID', value: certId)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Signature row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _SigBlock(label: 'Authorized Signature', name: 'Relstone NMLS'),
                                      Container(
                                        width: 50, height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _kBlue.withOpacity(0.40), width: 1.5, style: BorderStyle.solid),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.workspace_premium_rounded, size: 20, color: _kBlue),
                                            const SizedBox(height: 2),
                                            const Text('OFFICIAL', style: TextStyle(fontFamily: 'Poppins', fontSize: 6, fontWeight: FontWeight.w900, color: _kBlue, letterSpacing: 0.8)),
                                          ],
                                        ),
                                      ),
                                      _SigBlock(
                                        label: 'Date Issued',
                                        name: completed != null
                                            ? () {
                                                try {
                                                  final d = DateTime.parse(completed).toLocal();
                                                  const m = ['January','February','March','April','May','June','July','August','September','October','November','December'];
                                                  return '${m[d.month - 1]} ${d.year}';
                                                } catch (_) { return completed; }
                                              }()
                                            : '—',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Attestation
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0x05020817),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _kBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('ATTESTATION', style: TextStyle(fontFamily: 'Poppins', fontSize: 8, fontWeight: FontWeight.w900, color: _kMuted, letterSpacing: 0.8)),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'By accepting this certificate, I hereby acknowledge receipt of my course completion and authorize the education provider to report my education hours to NMLS. I am the named person on this certificate and have completed this course.',
                                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: _kNavy, height: 1.55),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Bottom bar
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [_kNavy, Color(0xFF0D2A4A)]),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Certificate ID: $certId', style: const TextStyle(fontFamily: 'Poppins', fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.4)),
                                  const Text(' · ', style: TextStyle(color: Colors.white30, fontSize: 8)),
                                  const Text('Relstone NMLS', style: TextStyle(fontFamily: 'Poppins', fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Side panel actions (stacked on mobile) ────
                      // Certificate ID + copy
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CERTIFICATE ID', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: _kMuted, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(certId, style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w900, fontSize: 14, color: _kNavy)),
                                ),
                                GestureDetector(
                                  onTap: () => _copyId(certId),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0x08020817),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _kBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                          size: 13,
                                          color: _copied ? _kGreen : _kMuted,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _copied ? 'Copied!' : 'Copy',
                                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: _copied ? _kGreen : _kMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // LinkedIn button
                      GestureDetector(
                        onTap: () => _openLinkedIn(cert),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0x050A66C2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x400A66C2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 18, color: Color(0xFF0A66C2)),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Add to LinkedIn Profile', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0A66C2))),
                                    Text('Showcase your certification', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0x990A66C2))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0x660A66C2)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Submission steps
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 13, color: _kMuted),
                                SizedBox(width: 6),
                                Text('Submitting to State', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: _kMuted, letterSpacing: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ..._kSubmissionSteps.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 18, height: 18,
                                    decoration: BoxDecoration(color: _kBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
                                    alignment: Alignment.center,
                                    child: Text('${e.key + 1}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w900, color: _kBlue)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(e.value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: _kNavy, height: 1.55)),
                                  ),
                                ],
                              ),
                            )),
                            GestureDetector(
                              onTap: () => launchUrl(Uri.parse('https://mortgage.nationwidelicensingsystem.org'), mode: LaunchMode.externalApplication),
                              child: const Row(
                                children: [
                                  Icon(Icons.open_in_new_rounded, size: 12, color: _kBlue),
                                  SizedBox(width: 5),
                                  Text('Visit NMLS Resource Center', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: _kBlue)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0x08020817),
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(Icons.workspace_premium_outlined, size: 34, color: _kMuted),
          ),
          const SizedBox(height: 18),
          const Text('No certificates yet', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 18, color: _kNavy)),
          const SizedBox(height: 8),
          const Text(
            'Complete a course to earn your first NMLS certificate.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _kMuted, height: 1.6),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: _kNavy, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 15, color: _kWhite),
                  SizedBox(width: 8),
                  Text('Browse Courses', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 14, color: _kWhite)),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, size: 16, color: _kWhite),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFB91C1C)))),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// CERTIFICATE CARD (matches web CertificateCard)
// ═══════════════════════════════════════════════════════════════════
class _CertCard extends StatelessWidget {
  final Map<String, dynamic> cert;
  final String userName;
  final String Function(String?, {bool long}) fmtDate;
  final VoidCallback onPreview;
  final VoidCallback onLinkedIn;

  const _CertCard({
    required this.cert,
    required this.userName,
    required this.fmtDate,
    required this.onPreview,
    required this.onLinkedIn,
  });

  @override
  Widget build(BuildContext context) {
    final courseType = (cert['course_type'] ?? '').toString().toUpperCase();
    final isPE       = courseType == 'PE';
    final accentColor = isPE ? _kBlue : _kTeal;
    final completed  = cert['completed_at'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Accent bar
          Container(height: 4, color: accentColor),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + type badge
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accentColor.withOpacity(0.18)),
                      ),
                      child: Icon(Icons.workspace_premium_rounded, size: 22, color: accentColor),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: accentColor.withOpacity(0.22)),
                      ),
                      child: Text(
                        courseType.isEmpty ? 'CE' : courseType,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w900, color: accentColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Course title
                Text(
                  cert['course_title'] ?? '—',
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 15, color: _kNavy, height: 1.3),
                ),
                const SizedBox(height: 12),

                // Meta grid (2-col like web)
                Row(
                  children: [
                    Expanded(child: _MetaItem(icon: Icons.schedule_rounded,   label: 'Credit Hours', value: cert['credit_hours'] != null ? '${cert['credit_hours']} hrs' : '—')),
                    Expanded(child: _MetaItem(icon: Icons.calendar_today_rounded, label: 'Completed',    value: fmtDate(completed))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _MetaItem(icon: Icons.location_on_rounded, label: 'State',        value: cert['state'] ?? '—')),
                    Expanded(child: _MetaItem(icon: Icons.description_rounded, label: 'Approval No.', value: cert['state_approval'] ?? '—')),
                  ],
                ),
                const SizedBox(height: 12),

                // Completed badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _kGreen.withOpacity(0.22)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF15803D)),
                      SizedBox(width: 6),
                      Text('Completed & Verified', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons (matches web cardActions)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onPreview,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(color: _kNavy, borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description_rounded, size: 14, color: _kWhite),
                              SizedBox(width: 6),
                              Text('Quick Preview', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 13, color: _kWhite)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x050A66C2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x3F0A66C2)),
                      ),
                      child: GestureDetector(
                        onTap: onLinkedIn,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.link_rounded, size: 18, color: Color(0xFF0A66C2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared atoms ──────────────────────────────────────────────────
class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 13, color: _kMuted)),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: _kMuted, letterSpacing: 0.4)),
            const SizedBox(height: 1),
            Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: _kNavy)),
          ],
        ),
      ),
    ],
  );
}

class _CertDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _CertDetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 8, fontWeight: FontWeight.w900, color: _kMuted, letterSpacing: 0.6)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: _kNavy)),
    ],
  );
}

class _SigBlock extends StatelessWidget {
  final String label;
  final String name;
  const _SigBlock({required this.label, required this.name});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(width: 80, height: 1, color: const Color(0x33091925)),
      const SizedBox(height: 5),
      Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 8, fontWeight: FontWeight.w800, color: _kMuted, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: _kNavy)),
    ],
  );
}