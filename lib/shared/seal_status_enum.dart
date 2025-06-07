enum BillSealStatus { none, sealed, rejected }

extension BillSealStatusExtension on BillSealStatus {
  String get value {
    switch (this) {
      case BillSealStatus.sealed:
        return 'sealed';
      case BillSealStatus.rejected:
        return 'rejected';
      default:
        return 'none';
    }
  }

  static BillSealStatus fromString(String value) {
    switch (value) {
      case 'sealed':
        return BillSealStatus.sealed;
      case 'rejected':
        return BillSealStatus.rejected;
      default:
        return BillSealStatus.none;
    }
  }
}
