# finkit

A robust, meticulously tested Dart financial toolkit for calculating EMIs, SIPs, Lumpsums, and Compound Interest. 
Built on solid architectural principles, it supports both **reducing balance** and **flat rate** loans, as well as complex compound simulations like step-up SIPs and SWPs.

## Features

- 🏦 **Loans**: Reducing balance and flat-rate EMI calculations, plus amortization schedules.
- 📈 **Compound Interest**: Lumpsum, SIP, Step-up SIP, and SWP (Systematic Withdrawal Plan).
- 🧩 **Pluggable Architecture**: Clear separation of concerns utilizing a Capability Registry.
- 🛡️ **Type-Safe**: Zero dynamic typing, comprehensive input validation, and strictly final classes.
- ⚡ **Zero Dependencies**: Pure Dart. Runs anywhere (Flutter, Web, Server, CLI).

## Installation

Add it to your `pubspec.yaml`:

```yaml
dependencies:
  finkit: ^1.0.0
```

Then run `dart pub get` or `flutter pub get`.

## Usage Examples

### 1. Loan / EMI Calculator

To calculate an EMI or an amortization schedule, you first create a registry for the type of loan you want (e.g., `LoanType.reducing` or `LoanType.flat`), and ask it for the capability you need.

```dart
import 'package:finkit/finkit.dart';

void main() {
  // 1. Create a registry for a Reducing Balance Loan
  final loanRegistry = LoanCalculatorFactory().create(LoanType.reducing);
  
  // 2. Request the EMI Solver capability
  final emiSolver = loanRegistry.require<EmiSolver>();
  
  // 3. Calculate!
  final emi = emiSolver.calculateEmi(
    principal: 1000000, // 10 Lakhs
    annualRate: 8.5,    // 8.5%
    tenureMonths: 240,  // 20 years
  );
  
  print('Your monthly EMI is: ₹${emi.toStringAsFixed(2)}');
}
```

You can also ask for other solvers from the same registry:

```dart
final rateSolver = loanRegistry.require<RateSolver>();
final amortization = loanRegistry.require<Amortization>();

// Generate a full repayment schedule
final schedule = amortization.generateReport(Loan(
  principal: 1000000,
  annualRate: 8.5,
  tenureMonths: 240,
  emi: emi,
  loanType: LoanType.reducing,
));
```

### 2. Compound Interest (SIP, Lumpsum, SWP)

Use the provided factory constructors on `CompoundInput` for discoverable, foolproof configurations.

```dart
import 'package:finkit/finkit.dart';

void main() {
  // Create a SIP configuration (₹5,000/month for 10 years at 12%)
  final input = CompoundInput.sip(
    monthlyAmount: 5000,
    annualRate: 12,
    tenureMonths: 120, // 10 years
  );

  // Use the universal compound engine
  final calculator = CompoundCalculator();
  final result = calculator.calculate(input);

  print('Total Invested: ₹${result.totalInvested}');
  print('Maturity Amount: ₹${result.maturityAmount.toStringAsFixed(2)}');
  print('Total Earned: ₹${result.totalInterest.toStringAsFixed(2)}');
}
```

Other available configurations on `CompoundInput`:
- `CompoundInput.lumpsum(...)`
- `CompoundInput.stepUpSip(...)`
- `CompoundInput.swp(...)`
- `CompoundInput.lumpsumPlusSip(...)`

## License
MIT License.
