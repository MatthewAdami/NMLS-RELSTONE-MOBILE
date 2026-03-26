import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models/course_model.dart';
import 'models/cart_item_model.dart';
import 'repositories/auth_repository.dart';
import 'repositories/course_repository.dart';
import 'cart/cart_local_storage.dart';

class CoursesCatalogController extends ChangeNotifier {
  final AuthRepository authRepository;
  final CourseRepository courseRepository;
  final VoidCallback? onUnauthorized;
  final CartLocalStorage _cartStorage = CartLocalStorage();

  CoursesCatalogController({
    required this.authRepository,
    required this.courseRepository,
    this.onUnauthorized,
  });

  bool loading = false;
  String? errorMessage;
  String? userState;
  String selectedType = 'All';
  String searchQuery = '';
  List<CourseModel> allCourses = <CourseModel>[];
  List<CourseModel> visibleCourses = <CourseModel>[];

  // Cart state is in-memory. We only persist to localStorage on Checkout
  // (details page also writes immediately per requirement).
  List<CartItemModel> cart = <CartItemModel>[];

  Future<void> initialize() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Allow Add-to-Cart to survive page refreshes by rehydrating memory.
      cart = await _cartStorage.readCart();

      final user = await authRepository.fetchMe();
      final state = user.state.trim();

      if (state.isEmpty) {
        errorMessage =
            'Your profile has no state yet. Please update your profile to browse courses.';
        userState = null;
        allCourses = <CourseModel>[];
        visibleCourses = <CourseModel>[];
        loading = false;
        notifyListeners();
        return;
      }

      userState = state;
      await _fetchCoursesBySelectedType();
    } on UnauthorizedException catch (_) {
      errorMessage = 'Your session has expired. Please sign in again.';
      onUnauthorized?.call();
    } on NetworkException catch (e) {
      errorMessage = e.message;
    } on ApiClientException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  bool isInCart(String courseId) {
    return cart.any((c) => c.id == courseId);
  }

  Future<void> persistCartToLocalStorage() async {
    await _cartStorage.writeCart(cart);
  }

  Future<void> checkout() async {
    await persistCartToLocalStorage();
  }

  Future<void> clearCartFromLocalStorage() async {
    cart = <CartItemModel>[];
    notifyListeners();
    await _cartStorage.clearCart();
  }

  void addToCart(CourseModel course, {bool persistImmediately = false}) {
    if (isInCart(course.id)) return;

    cart = [
      ...cart,
      CartItemModel(
        id: course.id,
        title: course.title,
        price: course.price,
        hasTextbook: course.hasTextbook,
        textbookPrice: course.textbookPrice,
        includeTextbook: false,
      ),
    ];
    notifyListeners();

    if (persistImmediately) {
      persistCartToLocalStorage();
    }
  }

  void removeFromCart(String courseId) {
    cart = cart.where((c) => c.id != courseId).toList();
    notifyListeners();
  }

  void toggleTextbook(String courseId, bool include) {
    cart = cart
        .map(
          (c) => c.id == courseId
              ? CartItemModel(
                  id: c.id,
                  title: c.title,
                  price: c.price,
                  hasTextbook: c.hasTextbook,
                  textbookPrice: c.textbookPrice,
                  includeTextbook: include,
                )
              : c,
        )
        .toList();
    notifyListeners();
  }

  Future<void> setType(String type) async {
    if (selectedType == type) return;
    selectedType = type;
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _fetchCoursesBySelectedType();
    } on UnauthorizedException catch (_) {
      errorMessage = 'Your session has expired. Please sign in again.';
      onUnauthorized?.call();
    } on NetworkException catch (e) {
      errorMessage = e.message;
    } on ApiClientException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    _applyLocalFilter();
    notifyListeners();
  }

  Future<void> retry() async {
    await initialize();
  }

  Future<void> _fetchCoursesBySelectedType() async {
    final state = userState?.trim();
    if (state == null || state.isEmpty) {
      errorMessage =
          'Your profile has no state yet. Please update your profile to browse courses.';
      allCourses = <CourseModel>[];
      visibleCourses = <CourseModel>[];
      return;
    }

    final fetched = await courseRepository.fetchCourses(
      state: state,
      type: selectedType,
    );
    allCourses = fetched;
    _applyLocalFilter();
  }

  void _applyLocalFilter() {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      visibleCourses = List<CourseModel>.from(allCourses);
      return;
    }

    visibleCourses = allCourses.where((course) {
      final title = course.title.toLowerCase();
      final description = course.description.toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }
}
