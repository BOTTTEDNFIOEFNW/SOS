class PaginationMetaModel {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  PaginationMetaModel({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) {
    return PaginationMetaModel(
      page: int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      limit: int.tryParse(json['limit']?.toString() ?? '10') ?? 10,
      totalItems: int.tryParse(json['totalItems']?.toString() ?? '0') ?? 0,
      totalPages: int.tryParse(json['totalPages']?.toString() ?? '1') ?? 1,
    );
  }
}
