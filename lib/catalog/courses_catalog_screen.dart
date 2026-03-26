import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'catalog_theme.dart';
import 'courses_catalog_controller.dart';
import 'course_details_screen.dart';
import 'models/course_model.dart';

class CoursesCatalogScreen extends StatefulWidget {
  const CoursesCatalogScreen({super.key});

  @override
  State<CoursesCatalogScreen> createState() => _CoursesCatalogScreenState();
}

class _CoursesCatalogScreenState extends State<CoursesCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _openCartDrawer(BuildContext ctx) {
    final scaffold = Scaffold.maybeOf(ctx);
    scaffold?.openEndDrawer();
  }

  void _closeCartDrawer(BuildContext ctx) {
    Navigator.of(ctx).pop();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoursesCatalogController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoursesCatalogController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: kCatalogBg,
          appBar: AppBar(
            backgroundColor: kCatalogDark,
            foregroundColor: kCatalogWhite,
            title: const Text('Course Catalog'),
            actions: [
              Builder(
                builder: (appBarCtx) => IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  tooltip: 'Cart',
                  onPressed: () => _openCartDrawer(appBarCtx),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    '${controller.cart.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          endDrawer: _CartDrawerContent(
            controller: controller,
            onClose: () => _closeCartDrawer(context),
          ),
          body: Column(
            children: [
              _FiltersSection(
                userState: controller.userState,
                selectedType: controller.selectedType,
                searchController: _searchController,
                onTypeChanged: controller.setType,
                onSearchChanged: controller.setSearchQuery,
              ),
              Expanded(child: _buildBody(controller)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(CoursesCatalogController controller) {
    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return _ErrorView(
        message: controller.errorMessage!,
        onRetry: controller.retry,
      );
    }

    if (controller.visibleCourses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No courses found for your current filters.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.visibleCourses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final course = controller.visibleCourses[index];
        return _CourseCard(
          course: course,
          inCart: controller.isInCart(course.id),
          onAddPressed: () {
            controller.addToCart(course);
            _openCartDrawer(context);
          },
        );
      },
    );
  }
}

class _FiltersSection extends StatelessWidget {
  final String? userState;
  final String selectedType;
  final TextEditingController searchController;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSearchChanged;

  const _FiltersSection({
    required this.userState,
    required this.selectedType,
    required this.searchController,
    required this.onTypeChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: Text('State: ${userState ?? 'N/A'}'),
            avatar: const Icon(Icons.location_on_outlined, size: 18),
            backgroundColor: kCatalogBlue.withValues(alpha: 0.12),
            side: const BorderSide(color: kCatalogBlue),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedType,
            decoration: kCatalogInputDecoration(
              hintText: 'Course type',
              labelText: 'Course type',
            ),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'PE', child: Text('PE')),
              DropdownMenuItem(value: 'CE', child: Text('CE')),
            ],
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: kCatalogInputDecoration(
              hintText: 'Search by title or description',
              prefixIcon: Icons.search,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final bool inCart;
  final VoidCallback onAddPressed;

  const _CourseCard({
    required this.course,
    required this.inCart,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCatalogWhite,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: kCatalogDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Type: ${course.type}',
              style: const TextStyle(
                color: kCatalogMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              'Credit hours: ${course.creditHours}',
              style: const TextStyle(
                color: kCatalogMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              'Price: \$${course.price}',
              style: const TextStyle(
                color: kCatalogMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              'Modules: ${course.modulesCount}',
              style: const TextStyle(
                color: kCatalogMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (course.modules.isNotEmpty)
              ExpansionTile(
                title: Text('View modules (${course.modulesCount})'),
                iconColor: kCatalogBlue,
                collapsedIconColor: kCatalogBlue,
                collapsedTextColor: kCatalogMuted,
                textColor: kCatalogDark,
                collapsedBackgroundColor: kCatalogWhite,
                backgroundColor: kCatalogWhite,
                children: course.modules
                    .map(
                      (m) => ListTile(
                        dense: true,
                        title: Text(
                          m.title,
                          style: const TextStyle(
                            color: kCatalogDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CourseDetailsScreen(courseId: course.id),
                        ),
                      );
                    },
                    style: kCatalogPrimaryButtonStyle(),
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: inCart ? null : onAddPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inCart ? Colors.grey : kCatalogBlue,
                      foregroundColor: kCatalogWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Text(inCart ? 'Added' : 'Add to Cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartDrawerContent extends StatelessWidget {
  final CoursesCatalogController controller;
  final VoidCallback onClose;

  const _CartDrawerContent({required this.controller, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cart = controller.cart;
    final num total = cart.fold<num>(
      0,
      (sum, item) =>
          sum +
          item.price +
          (item.includeTextbook == true ? item.textbookPrice : 0),
    );

    return Drawer(
      width: 360,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Cart',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: kCatalogDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: cart.isEmpty
                  ? const Center(
                      child: Text(
                        'Cart is empty.',
                        style: TextStyle(color: kCatalogMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cart.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return Card(
                          color: kCatalogWhite,
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: kCatalogDark,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Remove',
                                      onPressed: () {
                                        controller.removeFromCart(item.id);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Course price: \$${item.price}',
                                  style: const TextStyle(
                                    color: kCatalogMuted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                if (item.hasTextbook) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: item.includeTextbook == true,
                                        onChanged: (value) {
                                          controller.toggleTextbook(
                                            item.id,
                                            value ?? false,
                                          );
                                        },
                                      ),
                                      Text(
                                        'Include textbook (+\${item.textbookPrice})',
                                        style: const TextStyle(
                                          color: kCatalogMuted,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Total: \$$total',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: kCatalogDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: cart.isEmpty
                        ? null
                        : () async {
                            await controller.checkout();
                            onClose();
                            if (!context.mounted) return;
                            Navigator.of(context).pushNamed('/checkout');
                          },
                    style: kCatalogPrimaryButtonStyle(),
                    child: const Text('Checkout'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: kCatalogWhite,
                      foregroundColor: kCatalogDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: kCatalogBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continue browsing',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kCatalogMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: kCatalogPrimaryButtonStyle(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
