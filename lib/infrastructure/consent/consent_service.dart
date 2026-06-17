enum ConsentState { unknown, granted, denied }

final class ConsentService {
  ConsentService({
    ConsentState state = ConsentState.unknown,
    this.requiresConsentForNonEssentialTracking = true,
  }) : _state = state;

  factory ConsentService.fromSave({
    required String consentState,
    required bool requiresConsentForNonEssentialTracking,
  }) {
    return ConsentService(
      state: ConsentState.values.byName(consentState),
      requiresConsentForNonEssentialTracking:
          requiresConsentForNonEssentialTracking,
    );
  }

  ConsentState _state;
  final bool requiresConsentForNonEssentialTracking;

  ConsentState get state => _state;

  bool get canTrackNonEssential {
    return !requiresConsentForNonEssentialTracking ||
        state == ConsentState.granted;
  }

  void update(ConsentState state) {
    _state = state;
  }
}
