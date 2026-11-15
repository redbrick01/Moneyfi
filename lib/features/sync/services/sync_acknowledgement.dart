/// Require an acknowledgement for every row before reporting cloud success.
bool syncPayloadWasAccepted(
  Map<String, Object?> payload,
  Map<String, Object?> response,
) {
  final accepted = response['accepted_client_ids'];
  final conflicts = response['conflict_count'];
  if (response['ok'] != true ||
      accepted is! Map ||
      (conflicts is num && conflicts > 0)) {
    return false;
  }
  for (final entry in payload.entries) {
    if (entry.value is! List) continue;
    final rows = (entry.value as List).whereType<Map>();
    if (rows.isEmpty) continue;
    final ids = accepted[entry.key];
    if (ids is! List) return false;
    final key = entry.key == 'snapshot_notes' ? 'snapshot_date' : 'client_id';
    if (rows.any((row) => row[key] == null || !ids.contains(row[key]))) {
      return false;
    }
  }
  return true;
}
