import 'repositories/me_repository.dart';

/// Fetches the current user's profile and returns the home route for their
/// role. Falls back to '/worker' if /api/me fails.
Future<String> homeRouteForCurrentUser(MeRepository repo) async {
  try {
    final me = await repo.getMe();
    return me.role == 'giver' ? '/giver' : '/worker';
  } catch (_) {
    return '/worker';
  }
}
