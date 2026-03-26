import '../api_client.dart';
import '../models/course_model.dart';

class CourseRepository {
  final ApiClient apiClient;

  const CourseRepository(this.apiClient);

  Future<List<CourseModel>> fetchCourses({
    required String state,
    String? type,
  }) async {
    final query = <String, String>{'state': state};

    final normalizedType = type?.trim();
    if (normalizedType != null &&
        normalizedType.isNotEmpty &&
        normalizedType.toLowerCase() != 'all') {
      query['type'] = normalizedType;
    }

    final response = await apiClient.getJson('/api/courses', query: query);
    final dynamic rawList = response['courses'] ?? response['data'] ?? response;

    if (rawList is! List) {
      throw const ApiClientException('Invalid /api/courses response shape.');
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(CourseModel.fromJson)
        .toList();
  }

  Future<CourseModel> fetchCourseById(String id) async {
    final response = await apiClient.getJson('/api/courses/$id');
    final dynamic courseJson =
        response['course'] ?? response['data'] ?? response;

    if (courseJson is! Map<String, dynamic>) {
      throw const ApiClientException(
        'Invalid /api/courses/:id response shape.',
      );
    }

    return CourseModel.fromJson(courseJson);
  }
}
