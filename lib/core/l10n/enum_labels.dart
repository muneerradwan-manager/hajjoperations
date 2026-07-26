import '../../features/profile/domain/profile_enums.dart';
import '../../l10n/app_localizations.dart';

/// Locale-aware labels for domain enums.
extension GenderL10n on Gender {
  String label(AppLocalizations l) =>
      this == Gender.male ? l.genderMale : l.genderFemale;
}

extension MissionTypeL10n on MissionType {
  String label(AppLocalizations l) => switch (this) {
    MissionType.administrative => l.missionAdministrative,
    MissionType.religious => l.missionReligious,
    MissionType.medical => l.missionMedical,
  };
}
