import '../../../core/supabase/supabase_client.dart';
import '../../profile/domain/profile.dart';
import '../../profile/domain/profile_enums.dart';

class EmployeesRepository {
  /// Admin-only: create a brand-new account (auth user + profile) via the
  /// `admin-create-user` Edge Function (which holds the service role). Returns
  /// the new user id.
  Future<String> createEmployee({
    required String email,
    required String password,
    required String firstName,
    required String fatherName,
    required String surname,
    required String jobTitleId,
    required Gender gender,
    required DateTime dateOfBirth,
    required MissionType missionType,
    required String phoneSy,
    String? phoneSa,
    bool isExternal = false,
    String? externalOrganization,
    String? externalTitle,
  }) async {
    final res = await supabase.functions.invoke(
      'admin-create-user',
      body: {
        'email': email.trim(),
        'password': password,
        'first_name': firstName,
        'father_name': fatherName,
        'surname': surname,
        'job_title_id': jobTitleId,
        'gender': gender.db,
        'mission_type': missionType.db,
        'phone_sy': phoneSy,
        'phone_sa': phoneSa,
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        'is_external': isExternal,
        'external_organization': externalOrganization,
        'external_title': externalTitle,
      },
    );
    final data = res.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    return (data is Map ? data['id'] as String? : null) ?? '';
  }

  /// Permanent staff: internal + approved. Uses the permanent_employees view so
  /// the "not external, approved" rule lives in one place.
  Future<List<Profile>> fetchPermanent() async {
    final rows = await supabase
        .from('permanent_employees')
        // `reference_items` is the city: profiles points at it once, through
        // city_id, so the embed needs no disambiguating.
        .select('*, job_titles(name, name_en), reference_items(name_ar, name_en)')
        .order('first_name');
    return (rows as List)
        .map((r) => Profile.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// External participants: approved accounts flagged as external.
  ///
  /// Scoped to [seasonId] when given, and it usually should be. Permanent staff
  /// are permanent — they are the Administration whatever year it is — but an
  /// external is external FOR A SEASON: a delegate from the foreign ministry
  /// this year is not on the mission next year, and listing them all together
  /// says otherwise.
  Future<List<Profile>> fetchExternal({String? seasonId}) async {
    if (seasonId == null) {
      final rows = await supabase
          .from('profiles')
          .select('*, job_titles(name, name_en), reference_items(name_ar, name_en)')
          .eq('account_status', 'approved')
          .eq('is_external', true)
          .order('first_name');
      return (rows as List)
          .map((r) => Profile.fromMap(r as Map<String, dynamic>))
          .toList();
    }

    // Through the participation row: an external belongs to the directory of a
    // season because they were put into that season, not because they exist.
    final rows = await supabase
        .from('season_participants')
        .select(
          'profiles!inner(*, job_titles(name, name_en), reference_items(name_ar, name_en))',
        )
        .eq('season_id', seasonId)
        .eq('status', 'active')
        .eq('profiles.is_external', true)
        .eq('profiles.account_status', 'approved');
    final people = (rows as List)
        .map(
          (r) => Profile.fromMap(
            (r as Map<String, dynamic>)['profiles'] as Map<String, dynamic>,
          ),
        )
        .toList();
    people.sort((a, b) => a.fullName.compareTo(b.fullName));
    return people;
  }

  /// Admin-only: suspend or reactivate an account.
  Future<void> setSuspended(String profileId, bool suspended) async {
    await supabase
        .from('profiles')
        .update({'is_suspended': suspended})
        .eq('id', profileId);
  }

  /// Admin-only: mark/unmark an account as external and set its organization
  /// details. is_external is a guarded column — only admins may change it.
  Future<void> updateExternalStatus({
    required String profileId,
    required bool isExternal,
    String? organization,
    String? externalRole,
  }) async {
    await supabase
        .from('profiles')
        .update({
          'is_external': isExternal,
          'external_organization': isExternal ? organization : null,
          'external_title': isExternal ? externalRole : null,
        })
        .eq('id', profileId);
  }
}
