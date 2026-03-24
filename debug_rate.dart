import 'dart:math';

double calculateEmi(double principal, double annualRate, int tenureMonths) {
  final r = annualRate / 12 / 100;
  return (principal * r * pow(1 + r, tenureMonths)) / (pow(1 + r, tenureMonths) - 1);
}

void testNraphson() {
  final p = 1000000.0;
  final emi = calculateEmi(p, 8.5, 240);
  print('Target EMI: $emi');
  
  double r = emi / p;
  final n = 240;
  for (int i = 0; i < 50; i++) {
    final factor = pow(1 + r, n).toDouble();
    final f = (p * r * factor) / (factor - 1) - emi;
    final numerator = factor * (n * r - (1 + r) * ((factor - 1) / factor)) + n * r;
    final denominator = pow(factor - 1, 2).toDouble();
    final fPrime = p * numerator / denominator;
    
    final next = r - f / fPrime;
    if ((next - r).abs() < 1e-12) {
      print('Converged to r = $next -> Annual: ${next * 12 * 100}%');
      return;
    }
    r = next;
  }
}

void testBisect() {
  final p = 1000000.0;
  final emi = calculateEmi(p, 8.5, 240);
  
  double low = 0.0, high = 0.5, mid = 0.0;
  for (int i = 0; i < 100; i++) {
    mid = (low + high) / 2;
    final calculatedEmi = (p * mid * pow(1 + mid, 240)) / (pow(1 + mid, 240) - 1);
    if (calculatedEmi > emi) high = mid;
    else low = mid;
  }
  print('Bisection converged to r = $mid -> Annual: ${mid * 12 * 100}%');
}

void main() {
  testNraphson();
  testBisect();
}
