import 'package:flutter/material.dart';
import 'package:pushable_button/pushable_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'api_service.dart';
import 'order_page.dart';

class VipProductsPage extends StatefulWidget {
  final String token;

  const VipProductsPage({super.key, required this.token});

  @override
  State<VipProductsPage> createState() => _VipProductsPageState();
}

class _VipProductsPageState extends State<VipProductsPage> {
  late Future<List<Map<String, dynamic>>> _vipProductsFuture;
  bool _isBuying = false;
  int? _selectedVipId;

  final List<Map<String, dynamic>> vipLevels = [
    {
      "name": "VIP Starter Boost",
      "color": [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      "image": "assets/images/vip_1.jpg"
    },
    {
      "name": "VIP Power Rise",
      "color": [Color(0xFF6A11CB), Color(0xFF2575FC)],
      "image": "assets/images/vip_2.jpg"
    },
    {
      "name": "VIP Momentum X",
      "color": [Color(0xFFFF512F), Color(0xFFDD2476)],
      "image": "assets/images/vip_3.jpg"
    },
    {
      "name": "VIP Velocity Pro",
      "color": [Color(0xFF00B09B), Color(0xFF96C93D)],
      "image": "assets/images/vip_4.jpg"
    },
    {
      "name": "VIP Turbo Edge",
      "color": [Color(0xFF43C6AC), Color(0xFF191654)],
      "image": "assets/images/vip_5.jpg"
    },
    {
      "name": "VIP Galaxy Prime",
      "color": [Color(0xFFDA22FF), Color(0xFF9733EE)],
      "image": "assets/images/vip_6.jpg"
    },
    {
      "name": "VIP Infinity Plus",
      "color": [Color(0xFFFFA17F), Color(0xFF00223E)],
      "image": "assets/images/vip_7.jpg"
    },
    {
      "name": "VIP Titan Max",
      "color": [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      "image": "assets/images/vip_8.jpg"
    },
    {
      "name": "VIP Nova Legend",
      "color": [Color(0xFFFF5F6D), Color(0xFFFFC371)],
      "image": "assets/images/vip_9.jpg"
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadVipProducts();
  }

  void _loadVipProducts() {
    _vipProductsFuture = ApiService.getVipProducts(widget.token)
        .then((list) => List<Map<String, dynamic>>.from(list));
  }

  Future<void> _buyProduct(Map<String, dynamic> vip) async {
    if (_isBuying) return;

    setState(() {
      _isBuying = true;
      _selectedVipId = vip['id'] ?? -1;
    });

    final productName = vip['title'] ?? 'VIP Product';
    final vipId = vip['id'] ?? 0;

    final result = await ApiService.buyVipProduct(widget.token, vipId);

    if (!mounted) return;

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully purchased $productName",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderPage(token: widget.token, vipData: vip),
        ),
      );
    } else if (result == "insufficient") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Insufficient balance! Please recharge",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pushNamed(context, '/recharge');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Purchase failed! Please try again.",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isBuying = false;
      _selectedVipId = null;
      _loadVipProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: RefreshIndicator(
        onRefresh: () async => _loadVipProducts(),
        child: Column(
          children: [
            // HEADER PURPLE
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.purple,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20, top: 40),
              child: Text(
                'VIP Investment Plans',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _vipProductsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _loadingShimmer();
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      );
                    }

                    final vipProducts = snapshot.data ?? [];

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: vipProducts.length,
                      itemBuilder: (context, index) {
                        final vip = vipProducts[index];
                        final level = vipLevels[index % vipLevels.length];
                        final gradient = level['color'] as List<Color>;

                        final image = level['image'];
                        final name = vip['title'] ?? level['name'];

                        final price = vip['price'] ?? 0;
                        final daily = vip['dailyEarnings'] ?? 0;
                        final days = vip['validityDays'] ?? 0;
                        final total = vip['totalIncome'] ?? (daily * days);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                                color: Colors.black26,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              // VIP TITLE
                              Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      image,
                                      height: 95,
                                      width: 95,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      children: [
                                        _centerInfo("Price", "Br $price"),
                                        _centerInfo("Duration", "$days days"),
                                        _centerInfo("Daily", "Br $daily"),
                                        _centerInfo("Total", "Br $total"),
                                      ],
                                    ),
                                  ),

                                  // BUY BUTTON
                                  SizedBox(
                                    width: 90,
                                    child: PushableButton(
                                      height: 40,
                                      elevation: 8,
                                      hslColor: HSLColor.fromAHSL(
                                          1.0, 270, 0.6, 0.45),
                                      shadow: BoxShadow(
                                        color:
                                            Colors.purple.withOpacity(0.5),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                      onPressed: () => _buyProduct(vip),
                                      child: Text(
                                        "BUY",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _centerInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _loadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 110,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
