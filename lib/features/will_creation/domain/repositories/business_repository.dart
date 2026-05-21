import '../../data/models/business_models.dart';

abstract class BusinessRepository {
  // ==================== LAW FIRMS ====================
  
  /// Get all law firms
  Future<LawFirmsResponse> getLawFirms();
  
  // ==================== LAWYERS ====================
  
  /// Get all lawyers for a specific law firm
  Future<LawyersResponse> getLawyers(String lawFirmId);
  
  // ==================== PROFESSIONAL LAWYER ASSIGNMENT ====================
  
  /// Assign a professional lawyer to a will
  Future<BusinessResponse<String>> assignProfessionalLawyer(AssignProfessionalLawyerRequest request);
  
  /// Get assigned lawyers for a will
  Future<LawyersListResponse> getAssignedLawyers(String willId);
  
  // ==================== PERSONAL LAWYER ====================
  
  /// Create or update a personal lawyer for a will
  Future<BusinessResponse<String>> savePersonalLawyer(PersonalLawyerRequest request);
}
