// services/subscription_service.dart
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final _supabase = Supabase.instance.client;
  
  // RevenueCat API keys
  static const String _revenueCatApiKeyIOS = 'your_revenuecat_ios_api_key';
  static const String _revenueCatApiKeyAndroid = 'your_revenuecat_android_api_key';
  
  // Subscription entitlements and offering identifiers
  static const String _proEntitlementID = 'pro_subscription';
  static const String _mainOfferingID = 'launchpad_subscription';
  
  // Initialize RevenueCat
  Future<void> init() async {
    await Purchases.setDebugLogsEnabled(true);
    
    if (Platform.isIOS) {
      await Purchases.setup(_revenueCatApiKeyIOS);
    } else if (Platform.isAndroid) {
      await Purchases.setup(_revenueCatApiKeyAndroid);
    }
    
    // Set user ID if authenticated
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await Purchases.logIn(user.id);
    }
  }
  
  // Login to RevenueCat with Supabase user ID
  Future<void> login(String userId) async {
    await Purchases.logIn(userId);
  }
  
  // Logout from RevenueCat
  Future<void> logout() async {
    await Purchases.logOut();
  }
  
  // Get subscription offerings
  Future<Offerings> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      throw Exception('Failed to get offerings: $e');
    }
  }
  
  // Get customer info
  Future<CustomerInfo> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      throw Exception('Failed to get customer info: $e');
    }
  }
  
  // Purchase package
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      return purchaseResult.customerInfo;
    } catch (e) {
      throw Exception('Failed to purchase package: $e');
    }
  }
  
  // Check if user is Pro subscriber
  Future<bool> isProSubscriber() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(_proEntitlementID);
    } catch (e) {
      return false;
    }
  }
  
  // Restore purchases
  Future<CustomerInfo> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      throw Exception('Failed to restore purchases: $e');
    }
  }
  
  // Update subscription status in Supabase
  Future<void> updateSubscriptionStatus(bool isPro) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('profiles').update({
        'subscription_tier': isPro ? 'pro' : 'free',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    }
  }
}

// models/subscription_plan.dart
import 'package:flutter/material.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String period;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
  });
}

// screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/subscription_service.dart';
import '../utils/constants.dart';
import '../models/subscription_plan.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  bool _isProSubscriber = false;
  Offerings? _offerings;
  
  // Mock plans for display when RevenueCat isn't available
  final List<SubscriptionPlan> _mockPlans = [
    SubscriptionPlan(
      id: 'monthly',
      name: 'Pro Monthly',
      description: 'Full access to all premium features',
      price: 9.99,
      period: 'month',
      features: [
        'Unlimited ideas',
        'Server-side API key protection',
        'AI-powered features',
        'Priority support',
      ],
    ),
    SubscriptionPlan(
      id: 'yearly',
      name: 'Pro Yearly',
      description: 'Save 16% compared to monthly',
      price: 99.99,
      period: 'year',
      features: [
        'All monthly features',
        'Exclusive content',
        'Early access to new features',
        'Annual review by our team',
      ],
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }
  
  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _isProSubscriber = await _subscriptionService.isProSubscriber();
      _offerings = await _subscriptionService.getOfferings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load subscription data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _purchasePackage(Package package) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final customerInfo = await _subscriptionService.purchasePackage(package);
      final isPro = customerInfo.entitlements.active.containsKey('pro_subscription');
      
      // Update subscription status in Supabase
      await _subscriptionService.updateSubscriptionStatus(isPro);
      
      setState(() {
        _isProSubscriber = isPro;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPro 
            ? 'Successfully subscribed to Pro plan!' 
            : 'Purchase completed, but subscription is not active.'),
          backgroundColor: isPro ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete purchase: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final customerInfo = await _subscriptionService.restorePurchases();
      final isPro = customerInfo.entitlements.active.containsKey('pro_subscription');
      
      // Update subscription status in Supabase
      await _subscriptionService.updateSubscriptionStatus(isPro);
      
      setState(() {
        _isProSubscriber = isPro;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPro 
            ? 'Successfully restored Pro subscription!' 
            : 'No active subscriptions found.'),
          backgroundColor: isPro ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore purchases: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isProSubscriber
              ? _buildProSubscriberContent()
              : _buildSubscriptionOptions(),
    );
  }
  
  Widget _buildProSubscriberContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'re a Pro Subscriber!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Thank you for supporting LaunchPad Notebook. You have full access to all premium features.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Your Pro Benefits:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildFeatureList([
              'Unlimited ideas',
              'Server-side API key protection',
              'AI-powered features',
              'Priority support',
              'Early access to new features',
            ]),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                // Navigate to manage subscription on app store
                // This would typically open the app store subscription management page
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Manage Subscription'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubscriptionOptions() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24.0),
          color: AppConstants.primaryColor.withOpacity(0.1),
          child: Column(
            children: [
              const Text(
                'Upgrade to Pro',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Get unlimited access to all premium features',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Plans
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Free tier
                _buildPlanCard(
                  title: 'Free',
                  price: 'Free',
                  features: [
                    'Up to 3 active ideas',
                    'Basic AI features (30 calls/month)',
                    'Requires your own OpenAI API key',
                  ],
                  isCurrentPlan: true,
                  onUpgrade: null,
                ),
                const SizedBox(height: 16),
                
                // Pro plans from RevenueCat or mock data
                if (_offerings != null && _offerings!.current != null)
                  ...(_offerings!.current!.availablePackages).map((package) {
                    return Column(
                      children: [
                        _buildPlanCard(
                          title: package.storeProduct.title,
                          price: package.storeProduct.priceString,
                          features: _getProFeatures(),
                          isCurrentPlan: false,
                          onUpgrade: () => _purchasePackage(package),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList()
                else
                  ..._mockPlans.map((plan) {
                    return Column(
                      children: [
                        _buildPlanCard(
                          title: plan.name,
                          price: '\$${plan.price}/${plan.period}',
                          features: plan.features,
                          isCurrentPlan: false,
                          onUpgrade: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('In-app purchases not available in demo mode'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                
                // Restore purchases button
                TextButton(
                  onPressed: _restorePurchases,
                  child: const Text('Restore Purchases'),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Subscriptions will automatically renew unless canceled within 24 hours before the end of the current period. You can cancel anytime in your store account settings.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isCurrentPlan,
    required void Function()? onUpgrade,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentPlan 
              ? AppConstants.primaryColor 
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildFeatureList(features),
            const SizedBox(height: 16),
            if (onUpgrade != null)
              ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(45),
                ),
                child: const Text('Upgrade'),
              ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildFeatureList(List<String> features) {
    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(feature),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  List<String> _getProFeatures() {
    return [
      'Unlimited ideas',
      'Server-side API key protection',
      'AI-powered features',
      'Priority support',
      'Early access to new features',
    ];
  }
}