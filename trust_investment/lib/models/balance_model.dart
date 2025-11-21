class BalanceModel {
  final int customerId;
  final double amount;

  BalanceModel({
    required this.customerId,
    required this.amount,
  });

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    return BalanceModel(
      customerId: json['customer'],
      amount: double.parse(json['amount'].toString()),
    );
  }
}
