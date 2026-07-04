# Compound Input Structure

Here is a visual breakdown of the updated `CompoundInput` model, showcasing the new structurally safe `StepUpFrequency`.

```mermaid
classDiagram
    class CompoundInput {
        +double principal
        +double annualRate
        +int tenureMonths
        +CompoundFrequency compoundFrequency
        +int? customCompoundPeriods
        +ContributionConfig? contribution
        +WithdrawalConfig? withdrawal
    }

    class ContributionConfig {
        +double amount
        +PaymentFrequency frequency
        +PaymentTiming timing
        +ContributionStepUp? stepUp
    }

    class WithdrawalConfig {
        +double amount
        +PaymentFrequency frequency
        +WithdrawalType type
        +WithdrawalStepUp? stepUp
    }

    class CompoundFrequency {
        <<enumeration>>
        daily(365)
        daily360(360)
        semiWeekly(104)
        weekly(52)
        biWeekly(26)
        semiMonthly(24)
        monthly(12)
        biMonthly(6)
        quarterly(4)
        halfYearly(2)
        yearly(1)
        custom(-1)
    }

    class PaymentFrequency {
        <<enumeration>>
        daily(365)
        semiWeekly(104)
        weekly(52)
        biWeekly(26)
        semiMonthly(24)
        monthly(12)
        biMonthly(6)
        quarterly(4)
        halfYearly(2)
        yearly(1)
    }

    class StepUpFrequency {
        <<enumeration>>
        monthly(12)
        quarterly(4)
        halfYearly(2)
        yearly(1)
    }

    class WithdrawalType {
        <<enumeration>>
        fixedAmount
        percentageOfBalance
        percentageOfEarnings
    }
    
    class PaymentTiming {
        <<enumeration>>
        beginning
        end
    }

    class ContributionStepUp {
        <<sealed>>
        +StepUpFrequency stepUpFrequency
    }
    class FixedStepUp {
        +double amount
    }
    class PercentageStepUp {
        +double percent
    }

    class WithdrawalStepUp {
        <<sealed>>
        +StepUpFrequency stepUpFrequency
    }
    class FixedWithdrawalStepUp {
        +double amount
    }
    class PercentageWithdrawalStepUp {
        +double percent
    }

    CompoundInput *-- CompoundFrequency : uses
    CompoundInput *-- ContributionConfig : optional
    CompoundInput *-- WithdrawalConfig : optional

    ContributionConfig *-- PaymentFrequency : uses
    ContributionConfig *-- PaymentTiming : uses
    ContributionConfig *-- ContributionStepUp : optional
    ContributionStepUp <|-- FixedStepUp
    ContributionStepUp <|-- PercentageStepUp
    ContributionStepUp *-- StepUpFrequency : uses

    WithdrawalConfig *-- PaymentFrequency : uses
    WithdrawalConfig *-- WithdrawalType : uses
    WithdrawalConfig *-- WithdrawalStepUp : optional
    WithdrawalStepUp <|-- FixedWithdrawalStepUp
    WithdrawalStepUp <|-- PercentageWithdrawalStepUp
    WithdrawalStepUp *-- StepUpFrequency : uses
```

### Key Takeaways
1. **The StepUp Safety**: Notice how `ContributionStepUp` and `WithdrawalStepUp` no longer point to the large `PaymentFrequency` enum. They strictly point to `StepUpFrequency`, locking out mathematically invalid sub-monthly periods from ever being instantiated.
2. **The Core Input (`CompoundInput`)**: The single source of truth passed to the calculator. It holds all base values (principal, rate, tenure) and the optional configs.
3. **The Withdrawal Types**: `WithdrawalConfig` relies on the `WithdrawalType` enum to determine if its `amount` field is a fixed currency value (₹) or a percentage multiplier (%).
4. **High Frequencies**: Both `CompoundFrequency` and `PaymentFrequency` now contain the full range of high-frequency options (weekly, semi-monthly, etc.).
