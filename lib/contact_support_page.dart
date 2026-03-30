import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'services/api_client.dart';
import 'faq_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────
const _kDark       = Color(0xFF091925);
const _kBlue       = Color(0xFF2EABFE);
const _kBlueFaint  = Color(0x1A2EABFE);
const _kBlueBorder = Color(0x382EABFE);
const _kWhite      = Colors.white;
const _kBg         = Color(0xFFF6F7FB);
const _kMuted      = Color(0xFF5B7384);
const _kBorder     = Color(0x14020817);
const _kRed        = Color(0xFFEF4444);
const _kAmber      = Color(0xFFF59E0B);
const _kGreen      = Color(0xFF008000);
const _kPurple     = Color(0xFF9569F7);
const _kTeal       = Color(0xFF00B4B4);

// ─── Category Model ───────────────────────────────────────────────
class _Category {
  final String key, label;
  final IconData icon;
  final Color color;
  const _Category({required this.key, required this.label, required this.icon, required this.color});
}

const _categories = [
  _Category(key: 'technical',   label: 'Technical Issue',   icon: Icons.error_outline_rounded,        color: _kRed),
  _Category(key: 'billing',     label: 'Billing & Payment', icon: Icons.credit_card_rounded,          color: _kAmber),
  _Category(key: 'course',      label: 'Course Question',   icon: Icons.menu_book_outlined,           color: _kBlue),
  _Category(key: 'certificate', label: 'Certificate',       icon: Icons.workspace_premium_outlined,   color: _kGreen),
  _Category(key: 'account',     label: 'Account & Profile', icon: Icons.person_outline_rounded,       color: _kPurple),
  _Category(key: 'other',       label: 'Other',             icon: Icons.help_outline_rounded,         color: _kMuted),
];

const _priorities = [
  {'key': 'low',    'label': 'Low',    'color': _kMuted},
  {'key': 'normal', 'label': 'Normal', 'color': _kBlue},
  {'key': 'high',   'label': 'High',   'color': _kAmber},
  {'key': 'urgent', 'label': 'Urgent', 'color': _kRed},
];

// ═══════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════
class ContactSupportPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  const ContactSupportPage({Key? key, required this.userName, required this.userEmail}) : super(key: key);

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  // ── State ─────────────────────────────────────────────────────────
  String _view = 'list'; // 'list' | 'new' | 'detail'
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic>? _selected;
  bool _loading = true;
  bool _submitting = false;
  bool _replyLoading = false;
  String _error = '';
  String _success = '';
  String? _token;
  final _replyCtrl = TextEditingController();

  // ── Form state ────────────────────────────────────────────────────
  String _formCategory = 'other';
  String _formPriority = 'normal';
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  // ── Auth header ───────────────────────────────────────────────────
  Map<String, String> get _authHeaders => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  @override
  void initState() {
    super.initState();
    _initToken();
  }

  Future<void> _initToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _token = prefs.getString('token'));
    await _loadTickets();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────
  Future<void> _loadTickets() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await ApiClient.get(ApiConfig.supportMine, headers: _authHeaders);
      final raw = (res['data']?['tickets'] as List?) ?? [];
      setState(() => _tickets = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      setState(() => _error = 'Failed to load tickets.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitTicket() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Subject and message are required.');
      return;
    }
    setState(() { _submitting = true; _error = ''; });
    try {
      await ApiClient.post(ApiConfig.support, body: {
        'subject':  _subjectCtrl.text.trim(),
        'category': _formCategory,
        'priority': _formPriority,
        'message':  _messageCtrl.text.trim(),
      }, headers: _authHeaders);
      setState(() {
        _success = 'Your support ticket has been submitted! We\'ll get back to you soon.';
        _subjectCtrl.clear();
        _messageCtrl.clear();
        _formCategory = 'other';
        _formPriority = 'normal';
      });
      await _loadTickets();
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) setState(() { _success = ''; _view = 'list'; });
    } catch (e) {
      setState(() => _error = 'Failed to submit ticket.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openTicket(Map<String, dynamic> ticket) async {
    setState(() { _selected = ticket; _view = 'detail'; });
    try {
      final res = await ApiClient.get('${ApiConfig.support}/${ticket['_id']}', headers: _authHeaders);
      if (mounted) setState(() => _selected = Map<String, dynamic>.from(res['data']?['ticket'] as Map? ?? ticket));
    } catch (_) { /* use cached */ }
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty || _selected == null) return;
    setState(() { _replyLoading = true; });
    try {
      final res = await ApiClient.post(
        '${ApiConfig.support}/${_selected!['_id']}/reply',
        body: {'message': _replyCtrl.text.trim()},
        headers: _authHeaders,
      );
      final updated = Map<String, dynamic>.from(res['data']?['ticket'] as Map? ?? _selected!);
      setState(() {
        _selected = updated;
        _replyCtrl.clear();
        _tickets = _tickets.map((t) => t['_id'] == _selected!['_id'] ? updated : t).toList();
      });
    } catch (_) {
      setState(() => _error = 'Failed to send reply.');
    } finally {
      if (mounted) setState(() => _replyLoading = false);
    }
  }

  int get _openCount => _tickets.where((t) {
    final s = t['status'] as String? ?? '';
    return s == 'open' || s == 'in_progress';
  }).length;

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: RefreshIndicator(
            color: _kBlue,
            onRefresh: _loadTickets,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 4),
                  _buildHeaderDivider(),
                  const SizedBox(height: 16),
                  if (_view == 'new')    _buildNewTicketForm()
                  else if (_view == 'detail' && _selected != null) _buildTicketDetail()
                  else _buildTicketList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      );

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: _kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _kDark, size: 18),
          onPressed: () {
            if (_view != 'list') {
              setState(() { _view = 'list'; _selected = null; _error = ''; });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text('Contact Support',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900,
                color: _kDark, fontSize: 16)),
        actions: [
          if (_view == 'list')
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() { _view = 'new'; _error = ''; _success = ''; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kDark, borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, color: _kWhite, size: 13),
                      SizedBox(width: 5),
                      Text('New', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                          fontSize: 12, color: _kWhite)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _buildPageHeader() => Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _kBlueFaint, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBlueBorder),
            ),
            child: const Icon(Icons.help_outline_rounded, color: _kBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Contact Support',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800,
                        fontSize: 18, color: _kDark, letterSpacing: -0.2)),
                SizedBox(height: 2),
                Text('Get help from the NMLS Relstone support team',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        fontWeight: FontWeight.w600, color: _kMuted)),
              ],
            ),
          ),
          if (_openCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0x1AF59E0B), borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x4DF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF92540A)),
                  const SizedBox(width: 4),
                  Text('$_openCount open',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                          fontWeight: FontWeight.w800, color: Color(0xFF92540A))),
                ],
              ),
            ),
        ],
      );

  Widget _buildHeaderDivider() => Container(
        height: 2,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_kBlue, Colors.transparent]),
          borderRadius: BorderRadius.all(Radius.circular(99)),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════
  // NEW TICKET FORM
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildNewTicketForm() => Container(
        decoration: BoxDecoration(
          color: _kWhite, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                const Expanded(
                  child: Text('Submit a Support Request',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800,
                          fontSize: 15, color: _kDark)),
                ),
                GestureDetector(
                  onTap: () => setState(() { _view = 'list'; _error = ''; }),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0x08020817), borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _kBorder),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: _kMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (_success.isNotEmpty) ...[_SuccessBanner(msg: _success), const SizedBox(height: 12)],
            if (_error.isNotEmpty)   ...[_ErrorBanner(msg: _error),   const SizedBox(height: 12)],

            // Category
            _FieldLabel(label: 'CATEGORY', required: true),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8, mainAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: _categories.map((cat) {
                final active = _formCategory == cat.key;
                return GestureDetector(
                  onTap: () => setState(() => _formCategory = cat.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? cat.color.withOpacity(0.10) : const Color(0x05020817),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: active ? cat.color : const Color(0x1A020817),
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(cat.icon, size: 13, color: active ? cat.color : _kMuted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(cat.label,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 9,
                                  fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                                  color: active ? cat.color : _kMuted),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Priority
            _FieldLabel(label: 'PRIORITY'),
            const SizedBox(height: 8),
            Row(
              children: _priorities.map((p) {
                final active = _formPriority == p['key'];
                final color  = p['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _formPriority = p['key'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? color.withOpacity(0.12) : _kWhite,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: active ? color : const Color(0x1F020817)),
                      ),
                      child: Text(p['label'] as String,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: active ? color : _kMuted)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Subject
            _FieldLabel(label: 'SUBJECT', required: true),
            const SizedBox(height: 8),
            _StyledTextField(
              ctrl: _subjectCtrl,
              placeholder: 'Brief description of your issue…',
              maxLength: 120,
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${_subjectCtrl.text.length}/120',
                  style: const TextStyle(fontSize: 10, color: _kMuted)),
            ),
            const SizedBox(height: 14),

            // Message
            _FieldLabel(label: 'MESSAGE', required: true),
            const SizedBox(height: 8),
            _StyledTextField(
              ctrl: _messageCtrl,
              placeholder: 'Please describe your issue in detail. Include any error messages, course names, or order numbers…',
              maxLines: 6,
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${_messageCtrl.text.length} characters',
                  style: const TextStyle(fontSize: 10, color: _kMuted)),
            ),
            const SizedBox(height: 20),

            // Footer
            const Divider(color: Color(0x0F020817)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => setState(() { _view = 'list'; _error = ''; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kWhite, borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0x1F020817)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                            fontSize: 12, color: _kMuted)),
                  ),
                ),
                const SizedBox(width: 9),
                GestureDetector(
                  onTap: _submitting ? null : _submitTicket,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _submitting ? 0.65 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kDark, borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        children: [
                          if (_submitting)
                            const SizedBox(width: 12, height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _kWhite))
                          else
                            const Icon(Icons.send_rounded, size: 13, color: _kWhite),
                          const SizedBox(width: 6),
                          Text(_submitting ? 'Submitting…' : 'Submit Ticket',
                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                                  fontSize: 12, color: _kWhite)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════
  // TICKET DETAIL
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTicketDetail() {
    final t       = _selected!;
    final status  = t['status'] as String? ?? 'open';
    final replies = (t['replies'] as List?) ?? [];
    final closed  = status == 'closed' || status == 'resolved';

    return Container(
      decoration: BoxDecoration(
        color: _kWhite, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta
          Text(t['subject'] as String? ?? '—',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800,
                  fontSize: 16, color: _kDark, letterSpacing: -0.2)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _StatusPill(status: status),
            _PriorityPill(priority: t['priority'] as String? ?? 'normal'),
            _CategoryPill(category: t['category'] as String? ?? 'other'),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time_rounded, size: 10, color: _kMuted),
              const SizedBox(width: 3),
              Text(_formatDate(t['createdAt'] as String?),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kMuted)),
            ]),
          ]),
          const SizedBox(height: 14),
          const Divider(color: Color(0x0F020817)),
          const SizedBox(height: 12),

          // Original message
          _MsgBlock(
            initials: (widget.userName.isNotEmpty ? widget.userName[0] : 'S').toUpperCase(),
            senderName: widget.userName,
            role: 'Student',
            date: _formatDate(t['createdAt'] as String?),
            message: t['message'] as String? ?? '',
            isSupport: false,
          ),

          // Replies
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...replies.map((r) {
              final m          = Map<String, dynamic>.from(r as Map);
              final isSupport  = m['sender_role'] == 'instructor' || m['sender_role'] == 'admin';
              final senderName = m['sender_name'] as String? ?? 'User';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MsgBlock(
                  initials: isSupport ? 'S' : (senderName.isNotEmpty ? senderName[0] : 'U').toUpperCase(),
                  senderName: senderName,
                  role: isSupport ? 'Support' : 'You',
                  date: _formatDate(m['created_at'] as String?),
                  message: m['message'] as String? ?? '',
                  isSupport: isSupport,
                ),
              );
            }),
          ],

          // Reply box
          if (!closed) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0x0F020817)),
            const SizedBox(height: 12),
            const Text('ADD A REPLY',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800,
                    color: _kMuted, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _StyledTextField(
              ctrl: _replyCtrl,
              placeholder: 'Type your message here…',
              maxLines: 4,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: (_replyLoading || _replyCtrl.text.trim().isEmpty) ? null : _sendReply,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: (_replyLoading || _replyCtrl.text.trim().isEmpty) ? 0.5 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(9)),
                    child: Row(children: [
                      if (_replyLoading)
                        const SizedBox(width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _kWhite))
                      else
                        const Icon(Icons.send_rounded, size: 13, color: _kWhite),
                      const SizedBox(width: 6),
                      Text(_replyLoading ? 'Sending…' : 'Send Reply',
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                              fontSize: 12, color: _kWhite)),
                    ]),
                  ),
                ),
              ),
            ),
          ],

          // Closed note
          if (closed) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.07),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _kGreen.withOpacity(0.20)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_outline_rounded, size: 14, color: _kGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This ticket has been $status.${status == "resolved" ? " We hope your issue was resolved!" : ""} Open a new ticket if you need further help.',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                        fontWeight: FontWeight.w700, color: _kGreen),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TICKET LIST
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTicketList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error.isNotEmpty)   ...[_ErrorBanner(msg: _error),   const SizedBox(height: 12)],
          if (_success.isNotEmpty) ...[_SuccessBanner(msg: _success), const SizedBox(height: 12)],

          // Category quick-access grid
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 9, mainAxisSpacing: 9,
            childAspectRatio: 1.45,
            children: _categories.map((cat) => GestureDetector(
              onTap: () => setState(() {
                _formCategory = cat.key;
                _view = 'new';
                _error = '';
                _success = '';
              }),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kWhite, borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _kBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: cat.color.withOpacity(0.20)),
                      ),
                      child: Icon(cat.icon, size: 16, color: cat.color),
                    ),
                    const SizedBox(height: 7),
                    Text(cat.label, textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                            fontWeight: FontWeight.w700, color: _kDark)),
                  ],
                ),
              ),
            )).toList(),
          ),

          const SizedBox(height: 20),

          // FAQ link
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: _kBlueFaint, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBlueBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: _kBlue),
                  SizedBox(width: 8),
                  Text('Visit Help Center / FAQ',
                      style: TextStyle(fontFamily: 'Poppins', color: _kBlue,
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  Spacer(),
                  Icon(Icons.chevron_right_rounded, color: _kBlue, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text('MY SUPPORT TICKETS',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800,
                  fontSize: 12, color: _kDark, letterSpacing: 0.6)),
          const SizedBox(height: 10),

          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _kBlue),
            ))
          else if (_tickets.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: _tickets.map((t) => _TicketRow(
                ticket: t,
                onTap: () => _openTicket(t),
              )).toList(),
            ),
        ],
      );

  Widget _buildEmptyState() => Container(
        padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0x04020817),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0x20020817), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _kMuted.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kMuted.withOpacity(0.22)),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 22, color: _kMuted),
            ),
            const SizedBox(height: 12),
            const Text('No tickets yet',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800,
                    fontSize: 14, color: Color(0xBF020817))),
            const SizedBox(height: 6),
            const Text('Have a question or issue? Submit a support ticket and our team will get back to you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                    fontWeight: FontWeight.w600, color: _kMuted, height: 1.6)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() { _view = 'new'; _error = ''; _success = ''; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _kDark, borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, size: 12, color: _kWhite),
                  SizedBox(width: 6),
                  Text('Submit Your First Ticket',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                          fontSize: 12, color: _kWhite)),
                ]),
              ),
            ),
          ],
        ),
      );

  // ── Helpers ───────────────────────────────────────────────────────
  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '—';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// TICKET ROW
// ═══════════════════════════════════════════════════════════════════
class _TicketRow extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onTap;
  const _TicketRow({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat      = _categories.firstWhere((c) => c.key == ticket['category'], orElse: () => _categories.last);
    final replies  = (ticket['replies'] as List?) ?? [];
    final hasUnread = replies.any((r) => (r as Map)['sender_role'] != 'student');
    final replyCount = replies.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: hasUnread ? const Color(0x592EABFE) : _kBorder,
            width: hasUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasUnread
                  ? const Color(0x1F2EABFE)
                  : Colors.black.withOpacity(0.04),
              blurRadius: hasUnread ? 10 : 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(ticket['subject'] as String? ?? '—',
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                              fontSize: 13, color: _kDark),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (hasUnread)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kBlueFaint, borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x402EABFE)),
                        ),
                        child: const Text('New reply',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 9,
                                fontWeight: FontWeight.w900, color: _kBlue)),
                      ),
                  ]),
                  const SizedBox(height: 5),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _StatusPill(status: ticket['status'] as String? ?? 'open'),
                    _PriorityPill(priority: ticket['priority'] as String? ?? 'normal'),
                    _CategoryPill(category: ticket['category'] as String? ?? 'other'),
                    if (replyCount > 0)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 9, color: _kMuted),
                        const SizedBox(width: 3),
                        Text('$replyCount ${replyCount == 1 ? "reply" : "replies"}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kMuted)),
                      ]),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 15, color: Color(0x59020817)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MESSAGE BLOCK
// ═══════════════════════════════════════════════════════════════════
class _MsgBlock extends StatelessWidget {
  final String initials, senderName, role, date, message;
  final bool isSupport;
  const _MsgBlock({
    required this.initials, required this.senderName, required this.role,
    required this.date, required this.message, required this.isSupport,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isSupport ? const Color(0x0A2EABFE) : const Color(0x04020817),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSupport ? const Color(0x262EABFE) : const Color(0x0D020817),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSupport ? const Color(0x262EABFE) : const Color(0xFF091925),
              ),
              alignment: Alignment.center,
              child: Text(initials,
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14,
                      color: isSupport ? _kBlue : _kTeal)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(senderName,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                            fontSize: 12, color: _kDark)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSupport ? const Color(0x1A2EABFE) : const Color(0x0F020817),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isSupport ? const Color(0x382EABFE) : const Color(0x1A020817)),
                      ),
                      child: Text(role,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isSupport ? _kBlue : _kMuted)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(date, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kMuted)),
                  const SizedBox(height: 6),
                  Text(message,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                          fontWeight: FontWeight.w500, color: Color(0xCC020817), height: 1.65)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
// PILL ATOMS
// ═══════════════════════════════════════════════════════════════════
class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  static const _map = {
    'open':        {'color': _kBlue,  'bg': Color(0x1A2EABFE), 'label': 'Open'},
    'in_progress': {'color': _kAmber, 'bg': Color(0x1AF59E0B), 'label': 'In Progress'},
    'resolved':    {'color': _kGreen, 'bg': Color(0x1A008000), 'label': 'Resolved'},
    'closed':      {'color': _kMuted, 'bg': Color(0x1A5B7384), 'label': 'Closed'},
  };

  @override
  Widget build(BuildContext context) {
    final s     = _map[status] ?? _map['open']!;
    final color = s['color'] as Color;
    final bg    = s['bg'] as Color;
    final label = s['label'] as String;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 9,
              fontWeight: FontWeight.w900, color: color)),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String priority;
  const _PriorityPill({required this.priority});

  static const _colors = {
    'low': _kMuted, 'normal': _kBlue, 'high': _kAmber, 'urgent': _kRed,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[priority] ?? _kBlue;
    final label = priority.isEmpty ? '' : '${priority[0].toUpperCase()}${priority.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 9,
              fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String category;
  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    final cat = _categories.firstWhere((c) => c.key == category, orElse: () => _categories.last);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cat.color.withOpacity(0.10), borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cat.color.withOpacity(0.25)),
      ),
      child: Text(cat.label,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 9,
              fontWeight: FontWeight.w800, color: cat.color)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED ATOMS
// ═══════════════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800,
                color: Color(0x99020817), letterSpacing: 0.8)),
        if (required)
          const Text(' *', style: TextStyle(fontSize: 10, color: _kRed)),
      ]);
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String placeholder;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  const _StyledTextField({
    required this.ctrl, required this.placeholder,
    this.maxLines = 1, this.maxLength, this.onChanged,
  });
  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
            fontWeight: FontWeight.w500, color: Color(0xD9020817)),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
              fontWeight: FontWeight.w500, color: Color(0x60020817)),
          counterText: '',
          filled: true, fillColor: _kWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0x24020817)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0x24020817)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _kBlue, width: 1.5),
          ),
        ),
      );
}

class _SuccessBanner extends StatelessWidget {
  final String msg;
  const _SuccessBanner({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: _kGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _kGreen.withOpacity(0.22)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_outline_rounded, size: 14, color: _kGreen),
          const SizedBox(width: 8),
          Flexible(child: Text(msg,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  fontWeight: FontWeight.w700, color: _kGreen))),
        ]),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: _kRed.withOpacity(0.07),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _kRed.withOpacity(0.22)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: _kRed),
          const SizedBox(width: 8),
          Flexible(child: Text(msg,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  fontWeight: FontWeight.w700, color: _kRed))),
        ]),
      );
}