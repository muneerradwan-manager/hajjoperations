import '../../../core/l10n/localized_name.dart';
import 'job_title.dart';
import 'profile_enums.dart';

/// A single employee profile row (public.profiles).
class Profile {
  const Profile({
    required this.id,
    this.firstName,
    this.surname,
    this.fatherName,
    this.photoUrl,
    this.jobTitleId,
    this.gender,
    this.dateOfBirth,
    this.missionType,
    this.phoneSy,
    this.phoneSa,
    this.passportImageUrl,
    this.visaImageUrl,
    this.nusukCardImageUrl,
    required this.accountStatus,
    this.rejectionReason,
    this.isAdmin = false,
    this.isSuspended = false,
    this.isExternal = false,
    this.externalOrganization,
    this.externalTitle,
    this.jobTitleName,
    this.cityId,
    this.cityName,
    this.email,
  });

  final String id;
  final String? firstName;
  final String? surname;
  final String? fatherName;
  final String? photoUrl;
  final String? jobTitleId;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final MissionType? missionType;
  final String? phoneSy;
  final String? phoneSa;
  final String? passportImageUrl;
  final String? visaImageUrl;
  final String? nusukCardImageUrl;
  final AccountStatus accountStatus;
  final String? rejectionReason;
  final bool isAdmin;
  final bool isSuspended;
  final bool isExternal;
  final String? externalOrganization;
  final String? externalTitle;

  /// Joined from `job_titles(name, name_en)` when the query embeds it, in both
  /// languages — a job title is content, and reads in whichever one the app is
  /// set to.
  final LocalizedName? jobTitleName;

  /// The Syrian city this employee is from — an entry of the admin-managed
  /// `syrian_cities` list. Null for the accounts that registered before the
  /// question was asked.
  final String? cityId;

  /// Joined from reference_items when the query embeds it.
  final LocalizedName? cityName;

  /// Joined from the auth user when available (admin views).
  final String? email;

  String get fullName => [
    firstName,
    fatherName,
    surname,
  ].where((p) => p != null && p.isNotEmpty).join(' ');

  Profile copyWith({
    bool? isSuspended,
    bool? isExternal,
    String? externalOrganization,
    String? externalTitle,
    AccountStatus? accountStatus,
  }) {
    return Profile(
      id: id,
      firstName: firstName,
      surname: surname,
      fatherName: fatherName,
      photoUrl: photoUrl,
      jobTitleId: jobTitleId,
      gender: gender,
      dateOfBirth: dateOfBirth,
      missionType: missionType,
      phoneSy: phoneSy,
      phoneSa: phoneSa,
      passportImageUrl: passportImageUrl,
      visaImageUrl: visaImageUrl,
      nusukCardImageUrl: nusukCardImageUrl,
      accountStatus: accountStatus ?? this.accountStatus,
      rejectionReason: rejectionReason,
      isAdmin: isAdmin,
      isSuspended: isSuspended ?? this.isSuspended,
      isExternal: isExternal ?? this.isExternal,
      externalOrganization: externalOrganization ?? this.externalOrganization,
      externalTitle: externalTitle ?? this.externalTitle,
      jobTitleName: jobTitleName,
      cityId: cityId,
      cityName: cityName,
      email: email,
    );
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      firstName: map['first_name'] as String?,
      surname: map['surname'] as String?,
      fatherName: map['father_name'] as String?,
      photoUrl: map['photo_url'] as String?,
      jobTitleId: map['job_title_id'] as String?,
      gender: Gender.fromDb(map['gender'] as String?),
      dateOfBirth: map['date_of_birth'] == null
          ? null
          : DateTime.parse(map['date_of_birth'] as String),
      missionType: MissionType.fromDb(map['mission_type'] as String?),
      phoneSy: map['phone_sy'] as String?,
      phoneSa: map['phone_sa'] as String?,
      passportImageUrl: map['passport_image_url'] as String?,
      visaImageUrl: map['visa_image_url'] as String?,
      nusukCardImageUrl: map['nusuk_card_image_url'] as String?,
      accountStatus: AccountStatus.fromDb(map['account_status'] as String?),
      rejectionReason: map['rejection_reason'] as String?,
      isAdmin: (map['is_admin'] as bool?) ?? false,
      isSuspended: (map['is_suspended'] as bool?) ?? false,
      isExternal: (map['is_external'] as bool?) ?? false,
      externalOrganization: map['external_organization'] as String?,
      externalTitle: map['external_title'] as String?,
      jobTitleName: jobTitleNameOrNull(map),
      cityId: map['city_id'] as String?,
      cityName: map['reference_items'] is Map
          ? LocalizedName.fromMap(
              (map['reference_items'] as Map).cast<String, dynamic>(),
            )
          : null,
      email: map['email'] as String?,
    );
  }
}
