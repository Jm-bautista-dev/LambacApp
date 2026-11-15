/// Payload DTO for auditing & voiding an erroneous sales transaction
class VoidSaleRequest {
  final String saleId;
  final String voidReason;

  const VoidSaleRequest({
    required this.saleId,
    required this.voidReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'void_reason': voidReason.trim(),
    };
  }
}
