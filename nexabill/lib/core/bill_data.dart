// class BillData {
//   static String martName = "";
//   static String martAddress = "";
//   static String martContact = "";
//   static String martGSTIN = "";
//   static String martCIN = "";

//   static String billNo = "";
//   static String billDate = "";
//   static String session = "";

//   static String customerName = "";
//   static String customerMobile = "";

//   static String counterNo = "";
//   static String cashier = "";

//   static double amountPaid = 0;
//   static String footerMessage = "Thank you for shopping with us!";

//   static List<Map<String, dynamic>> products = [];

//   static int quantity = 1; // Default quantity used for text/mic input

//   static int getTotalQuantity() {
//     return products.fold(0, (sum, item) {
//       final qty = item["quantity"] ?? 1;
//       return sum + (qty as int);
//     });
//   }

//   static double getTotalAmount() {
//     return products.fold(0.0, (sum, item) {
//       final price = item["price"] ?? 0.0;
//       final qty = item["quantity"] ?? 1;
//       return sum + (price as double) * (qty as int);
//     });
//   }

//   static double getTotalGST() {
//     return products.fold(0.0, (sum, item) {
//       final gst = item["gst"] ?? 0.0;
//       final price = item["price"] ?? 0.0;
//       final qty = item["quantity"] ?? 1;
//       return sum + ((gst as double) * (price as double) * (qty as int)) / 100;
//     });
//   }

//   static double getNetAmountDue() {
//     return getTotalAmount() + getTotalGST();
//   }

//   static double getBalanceAmount() {
//     return getNetAmountDue() - amountPaid;
//   }

//   static List<String> getProductIds() {
//     return products.map((item) => item["productId"]?.toString() ?? "").toList();
//   }

//   static List<String> getProductVariants() {
//     return products.map((item) => item["variant"]?.toString() ?? "").toList();
//   }
// }
