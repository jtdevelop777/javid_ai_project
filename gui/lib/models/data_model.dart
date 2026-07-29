class DataModel {
  final String id;
  final String status;
  final double estimate;

  DataModel({
    required this.id,
    required this.status,
    required this.estimate,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      estimate: (json['estimate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'estimate': estimate,
    };
  }
}