import '../../../core/supabase/supabase_client.dart';
import '../../profile/domain/profile.dart';
import '../domain/permission.dart';

class PermissionsRepository {
  /// Approved, non-admin employees (admins already have every permission).
  Future<List<Profile>> fetchEmployees() async {
    final rows = await supabase
        .from('profiles')
        .select('*, job_titles(name, name_en)')
        .eq('account_status', 'approved')
        .eq('is_admin', false)
        .order('first_name');
    return (rows as List)
        .map((r) => Profile.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// The full permission catalog, ordered for hierarchical display.
  Future<List<Permission>> fetchCatalog() async {
    final rows = await supabase
        .from('permissions')
        .select()
        .order('sort_order');
    return (rows as List)
        .map((r) => Permission.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Permission ids currently granted to [userId].
  Future<Set<String>> fetchGranted(String userId) async {
    final rows = await supabase
        .from('user_permissions')
        .select('permission_id')
        .eq('user_id', userId);
    return (rows as List).map((r) => r['permission_id'] as String).toSet();
  }

  Future<void> grant(String userId, String permissionId) async {
    await supabase.from('user_permissions').insert({
      'user_id': userId,
      'permission_id': permissionId,
      'granted_by': supabase.auth.currentUser?.id,
    });
  }

  Future<void> revoke(String userId, String permissionId) async {
    await supabase
        .from('user_permissions')
        .delete()
        .eq('user_id', userId)
        .eq('permission_id', permissionId);
  }
}
