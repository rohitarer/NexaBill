import 'package:flutter/material.dart';

class BillData {
  // Mart Information
  static const String martName = "DMart";
  static const String martAddress = "Near XYZ Mall, Mumbai, India";
  static const String martContact = "+91 98765 43210";
  static const String martGSTIN = "27AADCD1234F1Z2";
  static const String martCIN = "L12345MH2000PLC123456";
  static const String martNote = "No returns after 7 days with a valid bill.";

  // Bill Details
  static const String billNo = "BILL# 123456";
  static const String counterNo = "Counter No: 5";
  static const String billDate = "14-Mar-2025, 07:45 PM";
  static const String session = "Session: Evening";
  static const String cashier = "Cashier: Rohit Arer";
  static const String customerName = "Customer: Amruta Sontakke";
  static const String customerMobile = "Mobile: +91 9876543210";

  // Products List
  static List<Map<String, dynamic>> products = [
    {
      "serial": 1,
      "name": "Fortune Sunflower Oil 1L",
      "gst": "5%",
      "quantity": 2,
      "discount": "10%",
      "price": 250.00,
    },
    {
      "serial": 2,
      "name": "Amul Butter 500g",
      "gst": "12%",
      "quantity": 1,
      "discount": "5%",
      "price": 245.00,
    },
    {
      "serial": 3,
      "name": "Aashirvaad Whole Wheat Atta 5kg",
      "gst": "5%",
      "quantity": 1,
      "discount": "7%",
      "price": 320.00,
    },
    {
      "serial": 4,
      "name": "Tata Salt 1kg",
      "gst": "5%",
      "quantity": 3,
      "discount": "0%",
      "price": 30.00,
    },
    {
      "serial": 5,
      "name": "Colgate MaxFresh 150g",
      "gst": "18%",
      "quantity": 2,
      "discount": "12%",
      "price": 95.00,
    },
    {
      "serial": 6,
      "name": "Maggi Noodles 280g",
      "gst": "12%",
      "quantity": 5,
      "discount": "8%",
      "price": 48.00,
    },
  ];

  // **Get Total Amount Before Discount**
  static double getTotalAmount() {
    return products.fold(
      0.0,
      (double sum, item) =>
          sum + (item["price"] as double) * (item["quantity"] as int),
    );
  }

  // **Get Total Quantity**
  static int getTotalQuantity() {
    return products.fold(0, (int sum, item) => sum + (item["quantity"] as int));
  }

  // **Get Total GST Amount**
  static double getTotalGST() {
    return getTotalAmount() * 0.05; // Approximate GST at 5%
  }

  // **Get Net Amount Due (Total - GST)**
  static double getNetAmountDue() {
    return getTotalAmount() - getTotalGST();
  }

  // **Payment Details**
  static double amountPaid = 1500.00;
  // static double getBalanceAmount() {
  //   return amountPaid - getTotalAmount();
  // }
  static double getBalanceAmount() {
    double balance = BillData.amountPaid - BillData.getTotalAmount();
    return balance < 0 ? balance.abs() : balance; // Ensures no negative value
  }

  // **Footer Message**
  static const String footerMessage = "THANK YOU, VISIT AGAIN!";
}
