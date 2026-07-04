// Core
export 'src/core/capability_registry.dart' show CapabilityRegistry;

// Compound – models
export 'src/compound/models/compound_frequency.dart';
export 'src/compound/models/compound_input.dart';
export 'src/compound/models/compound_result.dart';
export 'src/compound/models/contribution_config.dart';
export 'src/compound/models/withdrawal_config.dart';
export 'src/compound/models/payment_config.dart';

// Compound – calculators
export 'src/compound/calculators/compound_interfaces.dart';
export 'src/compound/calculators/compound_calculator.dart';
export 'src/compound/calculators/compound_calculator_factory.dart';

// Loan – models
export 'src/loan/models/loan.dart';
export 'src/loan/models/amortization_entry.dart';
export 'src/loan/models/loan_fees.dart';
export 'src/loan/models/prepayment_config.dart';
export 'src/loan/models/prepayment_result.dart';

// Loan – calculators
export 'src/loan/calculators/loan_interfaces.dart';
export 'src/loan/calculators/loan_calculator_factory.dart';
export 'src/loan/calculators/prepayment_calculator.dart';
export 'src/loan/calculators/foreclosure_planner.dart';

// Loan – models (Planner)
export 'src/loan/models/foreclosure_planner_models.dart';

// GST – models
export 'src/gst/models/gst_calculation_type.dart';
export 'src/gst/models/gst_result.dart';

// GST – calculators
export 'src/gst/calculators/gst_interfaces.dart';
export 'src/gst/calculators/gst_calculator.dart';
export 'src/gst/calculators/gst_calculator_factory.dart';

// XIRR – models
export 'src/xirr/models/xirr_cash_flow.dart';
export 'src/xirr/models/xirr_result.dart';

// XIRR – calculators
export 'src/xirr/calculators/xirr_interfaces.dart';
export 'src/xirr/calculators/xirr_calculator.dart';
export 'src/xirr/calculators/xirr_calculator_factory.dart';

// Inflation – models
export 'src/inflation/models/inflation_result.dart';

// Inflation – calculators
export 'src/inflation/calculators/inflation_interfaces.dart';
export 'src/inflation/calculators/inflation_calculator.dart';
export 'src/inflation/calculators/inflation_calculator_factory.dart';

// HRA – models
export 'src/hra/models/city_type.dart';
export 'src/hra/models/hra_result.dart';

// HRA – calculators
export 'src/hra/calculators/hra_interfaces.dart';
export 'src/hra/calculators/hra_calculator.dart';
export 'src/hra/calculators/hra_calculator_factory.dart';

// Income Tax – models
export 'src/income_tax/models/tax_regime.dart';
export 'src/income_tax/models/deductions.dart';
export 'src/income_tax/models/tax_slab_entry.dart';
export 'src/income_tax/models/income_tax_result.dart';

// Income Tax – calculators
export 'src/income_tax/calculators/income_tax_interfaces.dart';
export 'src/income_tax/calculators/income_tax_calculator.dart';
export 'src/income_tax/calculators/income_tax_calculator_factory.dart';

// PPF – models
export 'src/ppf/models/ppf_input.dart';
export 'src/ppf/models/ppf_result.dart';

// PPF – calculators
export 'src/ppf/calculators/ppf_interfaces.dart';
export 'src/ppf/calculators/ppf_calculator.dart';
export 'src/ppf/calculators/ppf_calculator_factory.dart';

// EPF – models
export 'src/epf/models/epf_input.dart';
export 'src/epf/models/epf_result.dart';

// EPF – calculators
export 'src/epf/calculators/epf_interfaces.dart';
export 'src/epf/calculators/epf_calculator.dart';
export 'src/epf/calculators/epf_calculator_factory.dart';

// NPS – models
export 'src/nps/models/nps_input.dart';
export 'src/nps/models/nps_result.dart';

// NPS – calculators
export 'src/nps/calculators/nps_interfaces.dart';
export 'src/nps/calculators/nps_calculator.dart';
export 'src/nps/calculators/nps_calculator_factory.dart';
