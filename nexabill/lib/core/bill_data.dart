class BillData {
  static String martName = "";
  static String martAddress = "";
  static String martContact = "";
  static String martGSTIN = "";
  static String martCIN = "";

  static String billNo = "";
  static String billDate = "";
  static String session = "";

  static String customerName = "";
  static String customerMobile = "";

  static String counterNo = "";
  static String cashier = "";

  static double amountPaid = 0;
  static String footerMessage = "Thank you for shopping with us!";

  static List<Map<String, dynamic>> products = [];

  static int getTotalQuantity() {
    return products.fold(0, (sum, item) => sum + (item["quantity"] as int));
  }

  static double getTotalAmount() {
    return products.fold(0.0, (sum, item) {
      return sum + (item["price"] as double) * (item["quantity"] as int);
    });
  }

  static double getTotalGST() {
    return products.fold(0.0, (sum, item) {
      return sum +
          ((item["gst"] as double) *
                  (item["price"] as double) *
                  (item["quantity"] as int)) /
              100;
    });
  }

  static double getNetAmountDue() {
    return getTotalAmount() + getTotalGST();
  }

  static double getBalanceAmount() {
    return getNetAmountDue() - amountPaid;
  }
}
