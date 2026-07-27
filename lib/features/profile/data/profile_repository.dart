import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/city.dart';
import '../domain/job_title.dart';
import '../domain/profile.dart';
import '../domain/profile_enums.dart';

class ProfileRepository {
  /// The signed-in user's own profile, or null if the row is not readable yet.
  Future<Profile?> fetchMine() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await supabase
        .from('profiles')
        .select('*, job_titles(name), reference_items(name_ar, name_en)')
        .eq('id', uid)
        .maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  /// The Syrian cities an employee may say they are from — the admin-managed
  /// `syrian_cities` list, which a signed-in account can read before it is
  /// approved because the registration form itself needs it.
  Future<List<City>> fetchSyrianCities() async {
    final rows = await supabase
        .from('reference_items')
        .select('id, name_ar, name_en, reference_sets!inner(code)')
        .eq('reference_sets.code', 'syrian_cities')
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((r) => City.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<JobTitle>> fetchActiveJobTitles() async {
    final rows = await supabase
        .from('job_titles')
        .select()
        .eq('is_active', true)
        .order('name');
    return (rows as List)
        .map((r) => JobTitle.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Uploads a local file to [bucket] under `{uid}/{name}` and returns a URL.
  /// For the public `avatars` bucket a public URL; for private `documents`,
  /// the storage path (read through signed URLs / RLS on demand).
  Future<String> uploadImage({
    required String bucket,
    required String name,
    required File file,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final path = '$uid/$name';
    await supabase.storage
        .from(bucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    if (bucket == 'avatars') {
      return supabase.storage.from(bucket).getPublicUrl(path);
    }
    return path;
  }

  /// Updates the signed-in user's editable profile fields WITHOUT changing the
  /// account status (used when an already-approved user edits their profile).
  Future<void> updateOwnProfile({
    required String firstName,
    required String surname,
    required String fatherName,
    required String jobTitleId,
    required Gender gender,
    required DateTime dateOfBirth,
    required MissionType missionType,
    required String phoneSy,
    String? phoneSa,
    String? cityId,
    String? photoUrl,
    String? passportImageUrl,
    String? visaImageUrl,
    String? nusukCardImageUrl,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final data = <String, dynamic>{
      'first_name': firstName,
      'surname': surname,
      'father_name': fatherName,
      'job_title_id': jobTitleId,
      'gender': gender.db,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'mission_type': missionType.db,
      'phone_sy': phoneSy,
      'phone_sa': phoneSa,
      'city_id': cityId,
    };
    // Only overwrite images when a new one was provided.
    if (photoUrl != null) data['photo_url'] = photoUrl;
    if (passportImageUrl != null) data['passport_image_url'] = passportImageUrl;
    if (visaImageUrl != null) data['visa_image_url'] = visaImageUrl;
    if (nusukCardImageUrl != null) {
      data['nusuk_card_image_url'] = nusukCardImageUrl;
    }
    await supabase.from('profiles').update(data).eq('id', uid);
  }

  /// Persists the profile fields and moves the account to `pending`.
  Future<void> submitForApproval({
    required String firstName,
    required String surname,
    required String fatherName,
    required String photoUrl,
    required String jobTitleId,
    required Gender gender,
    required DateTime dateOfBirth,
    required MissionType missionType,
    required String phoneSy,
    String? phoneSa,
    String? cityId,
    String? passportImageUrl,
    String? visaImageUrl,
    String? nusukCardImageUrl,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    await supabase
        .from('profiles')
        .update({
          'first_name': firstName,
          'surname': surname,
          'father_name': fatherName,
          'photo_url': photoUrl,
          'job_title_id': jobTitleId,
          'gender': gender.db,
          'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
          'mission_type': missionType.db,
          'phone_sy': phoneSy,
          'phone_sa': phoneSa,
          'city_id': cityId,
          'passport_image_url': passportImageUrl,
          'visa_image_url': visaImageUrl,
          'nusuk_card_image_url': nusukCardImageUrl,
          'account_status': AccountStatus.pending.db,
        })
        .eq('id', uid);
  }
}
