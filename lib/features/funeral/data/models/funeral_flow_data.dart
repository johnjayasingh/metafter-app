import '../models/funeral_models.dart';

/// Class to hold funeral flow data as user progresses through screens
class FuneralFlowData {
  FuneralPreference? funeralPreference;
  FuneralPreferenceData? funeralPreferenceData;
  String? serviceLocation;
  DateTime? dateTimePreference;
  int? musicId;
  String? specialInstruction;
  String? legacyMessage;
  String? legacyMessageVideoUrl;
  List<FuneralAttendeeModel>? attendees;

  FuneralFlowData({
    this.funeralPreference,
    this.funeralPreferenceData,
    this.serviceLocation,
    this.dateTimePreference,
    this.musicId,
    this.specialInstruction,
    this.legacyMessage,
    this.legacyMessageVideoUrl,
    this.attendees,
  });

  /// Convert to FuneralModel for API submission
  FuneralModel toFuneralModel() {
    return FuneralModel(
      funeralPreference: funeralPreference ?? FuneralPreference.noPreference,
      funeralPreferenceData: funeralPreferenceData,
      serviceLocation: serviceLocation,
      dateTimePreference: dateTimePreference,
      musicId: musicId,
      specialInstruction: specialInstruction,
      legacyMessage: legacyMessage,
    );
  }

  /// Create from existing funeral model (for editing)
  factory FuneralFlowData.fromFuneralModel(FuneralModel model) {
    return FuneralFlowData(
      funeralPreference: model.funeralPreference,
      funeralPreferenceData: model.funeralPreferenceData,
      serviceLocation: model.serviceLocation,
      dateTimePreference: model.dateTimePreference,
      musicId: model.musicId,
      specialInstruction: model.specialInstruction,
      legacyMessage: model.legacyMessage,
      legacyMessageVideoUrl: model.legacyMessageVideoUrl,
      attendees: model.attendees,
    );
  }

  FuneralFlowData copyWith({
    FuneralPreference? funeralPreference,
    FuneralPreferenceData? funeralPreferenceData,
    String? serviceLocation,
    DateTime? dateTimePreference,
    int? musicId,
    String? specialInstruction,
    String? legacyMessage,
    String? legacyMessageVideoUrl,
    List<FuneralAttendeeModel>? attendees,
  }) {
    return FuneralFlowData(
      funeralPreference: funeralPreference ?? this.funeralPreference,
      funeralPreferenceData:
          funeralPreferenceData ?? this.funeralPreferenceData,
      serviceLocation: serviceLocation ?? this.serviceLocation,
      dateTimePreference: dateTimePreference ?? this.dateTimePreference,
      musicId: musicId ?? this.musicId,
      specialInstruction: specialInstruction ?? this.specialInstruction,
      legacyMessage: legacyMessage ?? this.legacyMessage,
      legacyMessageVideoUrl: legacyMessageVideoUrl ?? this.legacyMessageVideoUrl,
      attendees: attendees ?? this.attendees,
    );
  }
}
