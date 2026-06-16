import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingService extends ChangeNotifier {
  static final BillingService instance = BillingService._init();
  final InAppPurchase _iap = InAppPurchase.instance;
  
  bool _isPremium = false;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPremium => true;
  List<ProductDetails> get products => _products;

  BillingService._init() {
    _loadPremiumStatus();
  }

  // Initialise billing listener
  void initialize() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print("Purchase stream error: $error"),
    );
    _queryProducts();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
    notifyListeners();
  }

  Future<void> setPremiumStatus(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', value);
    notifyListeners();
  }

  // List of product IDs
  static const String premiumSubscriptionId = 'tracear_premium_monthly';

  Future<void> _queryProducts() async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) return;

    final response = await _iap.queryProductDetails({premiumSubscriptionId});
    if (response.error == null) {
      _products = response.productDetails;
      notifyListeners();
    }
  }

  // Trigger Purchase flow
  Future<void> buyPremium() async {
    if (_products.isEmpty) return;
    
    final productDetails = _products.firstWhere(
      (p) => p.id == premiumSubscriptionId,
      orElse: () => throw Exception("Product details not found"),
    );

    final purchaseParam = PurchaseParam(productDetails: productDetails);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // Handle stream updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased || 
          purchase.status == PurchaseStatus.restored) {
        
        // Verify purchase and deliver premium benefits
        setPremiumStatus(true);

        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        print("Purchase failed: ${purchase.error}");
      }
    }
  }

  // Restoring purchases
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
