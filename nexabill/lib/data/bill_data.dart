class BillData {
  // 🔹 Mart Information (loaded from admin's profile)
  static String martName = "";
  static String martAddress = ""; // Street + Area
  static String martState = ""; // State
  static String martContact = ""; // Phone
  static String martGSTIN = ""; // GST No.
  static String martCIN = ""; // CIN No.
  static String martNote = "No returns after 7 days with a valid bill.";

  // 🔹 Bill Header Details
  static String billNo = ""; // e.g., BILL#123
  static String counterNo = "Counter No:"; // Display label only
  static String billDate = ""; // e.g., 12-04-2025
  static String session = ""; // e.g., 03:30 PM

  // 🔹 Customer Details
  static String customerName = ""; // e.g., Customer: Rohit Arer
  static String customerMobile = ""; // e.g., Mobile: +91 98861xxxx
  static String cashier = "Cashier:"; // Display label only

  // 🔹 Scanned Product List
  static List<Map<String, dynamic>> products = [];

  // 🔹 Total Amount Calculation
  static double getTotalAmount() {
    return products.fold(
      0.0,
      (sum, item) =>
          sum + (item["price"] as double) * (item["quantity"] as int),
    );
  }

  static int getTotalQuantity() {
    return products.fold(0, (sum, item) => sum + (item["quantity"] as int));
  }

  static double getTotalGST() => getTotalAmount() * 0.05;

  static double getNetAmountDue() => getTotalAmount() - getTotalGST();

  // 🔹 Payment Tracking
  static double amountPaid = 0.0;

  static double getBalanceAmount() {
    final balance = amountPaid - getTotalAmount();
    return balance < 0 ? balance.abs() : balance;
  }

  // 🔹 Footer
  static const String footerMessage = "THANK YOU, VISIT AGAIN!";
}
