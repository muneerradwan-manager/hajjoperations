import '../../../core/supabase/supabase_client.dart';
import '../../profile/domain/profile.dart';
import '../domain/season.dart';

class SeasonsRepository {
  /// Ensures a season row exists for [hijriYear] and makes it current if newer.
  /// Admin-only (enforced by the RPC). Returns the season id.
  Future<String?> ensureCurrentSeason(int hijriYear, String label) async {
    final id = await supabase.rpc(
      'ensure_current_season',
      params: {'p_hijri_year': hijriYear, 'p_label': label},
    );
    return id as String?;
  }

  Future<List<Season>> fetchSeasons() async {
    final rows = await supabase
        .from('seasons')
        .select()
        .order('hijri_year', ascending: false);
    return (rows as List)
        .map((r) => Season.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Makes [seasonId] the current season. [pinnedForHijriYear] records the Hijri
  /// year this choice was made in, so the yearly auto-advance in
  /// [ensureCurrentSeason] does not immediately override it.
  Future<void> setCurrent(String seasonId, {int? pinnedForHijriYear}) async {
    await supabase.rpc(
      'set_current_season',
      params: {
        'p_season_id': seasonId,
        'p_pinned_for_hijri_year': pinnedForHijriYear,
      },
    );
  }

  Future<Season?> fetchCurrentSeason() async {
    final row = await supabase
        .from('seasons')
        .select()
        .eq('is_current', true)
        .maybeSingle();
    return row == null ? null : Season.fromMap(row);
  }

  /// Active participants of a season, with profile + job title.
  Future<List<Profile>> fetchParticipants(String seasonId) async {
    final rows = await supabase
        .from('season_participants')
        .select('profiles!inner(*, job_titles(name))')
        .eq('season_id', seasonId)
        .eq('status', 'active');
    return (rows as List)
        .map(
          (r) => Profile.fromMap(
            (r as Map<String, dynamic>)['profiles'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Ids of profiles actively participating in the season.
  Future<Set<String>> fetchParticipantIds(String seasonId) async {
    final rows = await supabase
        .from('season_participants')
        .select('profile_id')
        .eq('season_id', seasonId)
        .eq('status', 'active');
    return (rows as List).map((r) => r['profile_id'] as String).toSet();
  }

  /// Seasons a profile is actively taking part in, newest first. Withdrawn rows
  /// are left out: they record a removal, not a participation.
  Future<List<Season>> fetchParticipationHistory(String profileId) async {
    final rows = await supabase
        .from('season_participants')
        .select('seasons!inner(*)')
        .eq('profile_id', profileId)
        .eq('status', 'active');
    final seasons = (rows as List)
        .map(
          (r) => Season.fromMap(
            (r as Map<String, dynamic>)['seasons'] as Map<String, dynamic>,
          ),
        )
        .toList();
    seasons.sort((a, b) => b.hijriYear.compareTo(a.hijriYear));
    return seasons;
  }

  /// Approved employees assignable to a season.
  Future<List<Profile>> fetchAssignableEmployees() async {
    final rows = await supabase
        .from('profiles')
        .select('*, job_titles(name)')
        .eq('account_status', 'approved')
        .order('first_name');
    return (rows as List)
        .map((r) => Profile.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Adds (or reactivates) a participant.
  Future<void> addParticipant(String seasonId, String profileId) async {
    await supabase.from('season_participants').upsert({
      'season_id': seasonId,
      'profile_id': profileId,
      'status': 'active',
    }, onConflict: 'season_id,profile_id');
  }

  /// Withdraws a participant — never deletes, to preserve history.
  Future<void> removeParticipant(String seasonId, String profileId) async {
    await supabase
        .from('season_participants')
        .update({'status': 'withdrawn'})
        .eq('season_id', seasonId)
        .eq('profile_id', profileId);
  }
}
