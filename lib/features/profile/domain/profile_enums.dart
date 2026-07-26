// Domain enums mirroring the Postgres enum types.

enum AccountStatus {
  incomplete,
  pending,
  approved,
  rejected;

  static AccountStatus fromDb(String? value) => switch (value) {
    'incomplete' => AccountStatus.incomplete,
    'pending' => AccountStatus.pending,
    'approved' => AccountStatus.approved,
    'rejected' => AccountStatus.rejected,
    _ => AccountStatus.incomplete,
  };

  String get db => name;
}

enum Gender {
  male,
  female;

  static Gender? fromDb(String? value) => switch (value) {
    'male' => Gender.male,
    'female' => Gender.female,
    _ => null,
  };

  String get db => name;
  String get arabicLabel => this == Gender.male ? 'ذكر' : 'أنثى';
}

enum MissionType {
  administrative,
  religious,
  medical;

  static MissionType? fromDb(String? value) => switch (value) {
    'administrative' => MissionType.administrative,
    'religious' => MissionType.religious,
    'medical' => MissionType.medical,
    _ => null,
  };

  String get db => name;
  String get arabicLabel => switch (this) {
    MissionType.administrative => 'البعثة الإدارية',
    MissionType.religious => 'البعثة الدينية',
    MissionType.medical => 'البعثة الطبية',
  };
}
