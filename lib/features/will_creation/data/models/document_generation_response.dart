class DocumentGenerationResponse {
  final String status;
  final String message;
  final DocumentGenerationData? data;

  DocumentGenerationResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory DocumentGenerationResponse.fromJson(Map<String, dynamic> json) {
    return DocumentGenerationResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? DocumentGenerationData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }

  bool get isSuccess => status == 'success';
}

class DocumentGenerationData {
  final String url;
  final String watermarkedUrl;
  final String coverUrl;
  final String documentId;

  DocumentGenerationData({
    required this.url,
    required this.watermarkedUrl,
    required this.coverUrl,
    required this.documentId,
  });

  factory DocumentGenerationData.fromJson(Map<String, dynamic> json) {
    return DocumentGenerationData(
      url: json['url'] as String? ?? '',
      watermarkedUrl: json['watermarked_url'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      documentId: json['document_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'watermarked_url': watermarkedUrl,
      'cover_url': coverUrl,
      'document_id': documentId,
    };
  }
}
