import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';

const kResDark = Color(0xFF091925);
const kResBlue = Color(0xFF2EABFE);
const kResBg = Color(0xFFF6F7FB);
const kResWhite = Colors.white;
const kResMuted = Color(0x990B1220);
const kResBorder = Color(0x1A020817);

class BlogResourcesScreen extends StatefulWidget {
  const BlogResourcesScreen({super.key});

  @override
  State<BlogResourcesScreen> createState() => _BlogResourcesScreenState();
}

class _BlogResourcesScreenState extends State<BlogResourcesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  bool _loading = true;
  String _error = '';
  String _categoryFilter = 'All';
  String _dateFilter = 'All Time';

  List<BlogArticle> _articles = <BlogArticle>[];

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  String _dateFilterParam() {
    if (_dateFilter == 'Last 7 Days') return 'last7';
    if (_dateFilter == 'Last 30 Days') return 'last30';
    if (_dateFilter == 'This Year') return 'thisYear';
    return '';
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final uri = Uri.parse(ApiConfig.resources).replace(
        queryParameters: {
          if (_searchCtrl.text.trim().isNotEmpty)
            'search': _searchCtrl.text.trim(),
          if (_categoryFilter != 'All') 'category': _categoryFilter,
          if (_dateFilterParam().isNotEmpty) 'dateFilter': _dateFilterParam(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        setState(() {
          _error = 'Failed to load resources (${response.statusCode})';
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['articles'] as List?) ?? const [];
      final parsed =
          list
              .whereType<Map>()
              .map(
                (entry) =>
                    BlogArticle.fromApi(Map<String, dynamic>.from(entry)),
              )
              .where((entry) => entry != null)
              .cast<BlogArticle>()
              .toList()
            ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      if (!mounted) return;
      setState(() => _articles = parsed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to reach resources service.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openArticle(BlogArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BlogArticleDetailScreen(articleId: article.id, seed: article),
      ),
    );
  }

  Future<void> _subscribe() async {
    final email = _emailCtrl.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.newsletterSubscribe),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription failed (${response.statusCode}).'),
          ),
        );
        return;
      }

      _emailCtrl.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subscribed successfully.')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to subscribe right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _articles;
    final featured = filtered.isNotEmpty ? filtered.first : null;

    return Scaffold(
      backgroundColor: kResBg,
      appBar: AppBar(
        backgroundColor: kResWhite,
        foregroundColor: kResDark,
        elevation: 0,
        title: const Text(
          'Blog & Resources',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      color: kResDark,
                      size: 34,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kResDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchArticles,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchArticles,
              color: kResBlue,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _buildHero(featured),
                  const SizedBox(height: 12),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 12),
                  _buildNewsletterCard(),
                  const SizedBox(height: 12),
                  const Text(
                    'Latest Articles',
                    style: TextStyle(
                      color: kResDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kResWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kResBorder),
                      ),
                      child: const Text(
                        'No articles found for the selected search and filters.',
                        style: TextStyle(
                          color: kResMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    ...filtered.map(
                      (article) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ArticleCard(
                          article: article,
                          onTap: () => _openArticle(article),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHero(BlogArticle? featured) {
    if (featured == null) {
      return Container(
        decoration: BoxDecoration(
          color: kResWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kResBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No featured article for current filters.',
          style: TextStyle(color: kResMuted, fontWeight: FontWeight.w700),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openArticle(featured),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2634), Color(0xFF2EABFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kResDark.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: const Text(
                'Featured Article',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              featured.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              featured.excerpt,
              style: const TextStyle(
                color: Color(0xE6FFFFFF),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MetaPill(label: featured.category),
                const SizedBox(width: 8),
                _MetaPill(label: _fmtDate(featured.publishedAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final categories = [
      'All',
      'Study Tips',
      'State Guides',
      'Career Advice',
      'Industry News',
    ];

    final dateOptions = [
      'All Time',
      'Last 7 Days',
      'Last 30 Days',
      'This Year',
    ];

    return Container(
      decoration: BoxDecoration(
        color: kResWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kResBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _fetchArticles(),
            decoration: InputDecoration(
              hintText: 'Search articles, topics, or author',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF0F3F8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Category',
            style: TextStyle(
              color: kResDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final selected = _categoryFilter == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _categoryFilter = category);
                      _fetchArticles();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Date',
            style: TextStyle(
              color: kResDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _dateFilter,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF0F3F8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: dateOptions
                .map(
                  (option) =>
                      DropdownMenuItem(value: option, child: Text(option)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _dateFilter = value);
              _fetchArticles();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsletterCard() {
    return Container(
      decoration: BoxDecoration(
        color: kResWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kResBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: kResBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'Email Newsletter',
                style: TextStyle(
                  color: kResDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Get weekly study tips, state updates, and industry highlights.',
            style: TextStyle(
              color: kResMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kResBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Subscribe',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class BlogArticleDetailScreen extends StatefulWidget {
  final String articleId;
  final BlogArticle? seed;

  const BlogArticleDetailScreen({
    super.key,
    required this.articleId,
    this.seed,
  });

  @override
  State<BlogArticleDetailScreen> createState() =>
      _BlogArticleDetailScreenState();
}

class _BlogArticleDetailScreenState extends State<BlogArticleDetailScreen> {
  bool _loading = true;
  String _error = '';
  BlogArticle? _article;
  List<BlogArticle> _related = <BlogArticle>[];

  @override
  void initState() {
    super.initState();
    _article = widget.seed;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.resourceDetail(widget.articleId)))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        setState(() {
          _error = 'Failed to load article (${response.statusCode})';
          _loading = false;
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final articleData = data['article'] as Map?;
      final relatedData = (data['related'] as List?) ?? const [];

      final article = articleData == null
          ? null
          : BlogArticle.fromApi(Map<String, dynamic>.from(articleData));

      final related = relatedData
          .whereType<Map>()
          .map((entry) => BlogArticle.fromApi(Map<String, dynamic>.from(entry)))
          .where((entry) => entry != null)
          .cast<BlogArticle>()
          .toList();

      if (!mounted) return;
      setState(() {
        _article = article ?? _article;
        _related = related;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load article details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showShare(String platform) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Share to $platform coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    final article = _article;

    if (_loading && article == null) {
      return const Scaffold(
        backgroundColor: kResBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (article == null) {
      return Scaffold(
        backgroundColor: kResBg,
        appBar: AppBar(
          backgroundColor: kResWhite,
          foregroundColor: kResDark,
          elevation: 0,
          title: const Text(
            'Article',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error.isNotEmpty ? _error : 'Article not found.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kResDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kResBg,
      appBar: AppBar(
        backgroundColor: kResWhite,
        foregroundColor: kResDark,
        elevation: 0,
        title: const Text(
          'Article',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            decoration: BoxDecoration(
              color: kResWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kResBorder),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.category,
                  style: const TextStyle(
                    color: kResBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  style: const TextStyle(
                    color: kResDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 21,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By ${article.author}   ${article.dateLabel}   ${article.readMinutes} min read',
                  style: const TextStyle(
                    color: kResMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                ...article.content.map(
                  (paragraph) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      paragraph,
                      style: const TextStyle(
                        color: kResDark,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Share this article',
                  style: TextStyle(
                    color: kResDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ShareButton(
                      icon: Icons.linked_camera_outlined,
                      label: 'Instagram',
                      onTap: () => _showShare('Instagram'),
                    ),
                    const SizedBox(width: 8),
                    _ShareButton(
                      icon: Icons.business,
                      label: 'LinkedIn',
                      onTap: () => _showShare('LinkedIn'),
                    ),
                    const SizedBox(width: 8),
                    _ShareButton(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      onTap: () => _showShare('Email'),
                    ),
                    const SizedBox(width: 8),
                    _ShareButton(
                      icon: Icons.ios_share_outlined,
                      label: 'Share',
                      onTap: () => _showShare('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_related.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: kResWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kResBorder),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Related Articles',
                    style: TextStyle(
                      color: kResDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._related.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => BlogArticleDetailScreen(
                                articleId: item.id,
                                seed: item,
                              ),
                            ),
                          );
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F3F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: kResDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.category}  ${item.dateLabel}',
                                      style: const TextStyle(
                                        color: kResMuted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: kResMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final BlogArticle article;
  final VoidCallback onTap;

  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: kResWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kResBorder),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MetaPill(label: article.category),
                const SizedBox(width: 8),
                Text(
                  article.dateLabel,
                  style: const TextStyle(
                    color: kResMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              article.title,
              style: const TextStyle(
                color: kResDark,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.excerpt,
              style: const TextStyle(
                color: kResMuted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'By ${article.author}  ${article.readMinutes} min read',
              style: const TextStyle(
                color: kResMuted,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  const _MetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1A2EABFE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x382EABFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kResBlue,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: kResDark),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: kResDark,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlogArticle {
  final String id;
  final String title;
  final String excerpt;
  final List<String> content;
  final String category;
  final String author;
  final DateTime publishedAt;
  final int readMinutes;

  const BlogArticle({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.category,
    required this.author,
    required this.publishedAt,
    required this.readMinutes,
  });

  String get dateLabel =>
      '${publishedAt.month}/${publishedAt.day}/${publishedAt.year}';

  static BlogArticle? fromApi(Map<String, dynamic> data) {
    final id = (data['id'] ?? data['_id'] ?? '').toString().trim();
    final title = (data['title'] ?? '').toString().trim();
    final excerpt = (data['excerpt'] ?? '').toString().trim();
    final category = (data['category'] ?? '').toString().trim();
    final author = (data['author'] ?? 'Relstone Editorial').toString().trim();
    final rawDate = (data['publishedAt'] ?? data['createdAt'] ?? '')
        .toString()
        .trim();
    final publishedAt = DateTime.tryParse(rawDate);

    final content =
        (data['content'] as List?)
            ?.map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList() ??
        <String>[];

    if (id.isEmpty ||
        title.isEmpty ||
        excerpt.isEmpty ||
        category.isEmpty ||
        publishedAt == null) {
      return null;
    }

    return BlogArticle(
      id: id,
      title: title,
      excerpt: excerpt,
      content: content,
      category: category,
      author: author,
      publishedAt: publishedAt,
      readMinutes: (data['readMinutes'] as num?)?.toInt() ?? 5,
    );
  }
}
