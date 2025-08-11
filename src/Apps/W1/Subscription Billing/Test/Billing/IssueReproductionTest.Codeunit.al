namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.Customer;

codeunit 139999 "Issue Reproduction Test"
{
    Subtype = Test;
    TestType = Unit;
    TestPermissions = Disabled;
    Access = Internal;

    var
        ServiceCommitment: Record "Subscription Line";
        Assert: Codeunit Assert;

    [Test]
    procedure TestQuarterlyBillingAlignToEndOfMonthIssue4401()
    var
        PeriodFormula: DateFormula;
        ActualEndDate: Date;
        ExpectedEndDate: Date;
        StartDate: Date;
        BillingFromDate: Date;
    begin
        // [SCENARIO] Test the specific issue from bug report #4401
        // The issue: When billing from 01.03.2020 for a subscription starting 27.02.2020,
        // quarterly billing should result in 28.05.2020 (not 27.06.2020)

        // [GIVEN] Subscription Line Start Date is 27.02.2020 
        StartDate := 20200227D;
        // [GIVEN] Billing from date is 01.03.2020 (after manual split of first period)
        BillingFromDate := 20200301D;
        // [GIVEN] Expected end date is 28.05.2020 as per issue description
        ExpectedEndDate := 20200528D;

        // [GIVEN] Quarterly billing rhythm (3M)
        Evaluate(PeriodFormula, '<3M>');

        // [GIVEN] Service commitment with "Align to End of Month" setting
        ServiceCommitment.Init();
        ServiceCommitment."Subscription Line Start Date" := StartDate;
        ServiceCommitment."Period Calculation" := ServiceCommitment."Period Calculation"::"Align to End of Month";

        // [WHEN] Calculating the next billing to date from 01.03.2020
        ActualEndDate := ServiceCommitment.CalculateNextToDate(PeriodFormula, BillingFromDate);

        // [THEN] The end date should be 28.05.2020 (maintaining the original quarterly alignment)
        // Note: With my fix, this should now calculate correctly
        Assert.AreEqual(ExpectedEndDate, ActualEndDate, 
            StrSubstNo('Quarterly billing from %1 for subscription starting %2 should result in %3 but got %4', 
                BillingFromDate, StartDate, ExpectedEndDate, ActualEndDate));
    end;

    [Test]
    procedure TestQuarterlyBillingAlignToEndOfMonthIssue4401_SecondExample()
    var
        PeriodFormula: DateFormula;
        ActualEndDate: Date;
        ExpectedEndDate: Date;
        StartDate: Date;
        BillingFromDate: Date;
    begin
        // [SCENARIO] Test a different scenario: 
        // Start Date: 29.03.2020, billing from same date, should result in 28.06.2020

        // [GIVEN] Start date is 29.03.2020 (29th March 2020)
        StartDate := 20200329D;
        BillingFromDate := StartDate; // Billing from the start date
        ExpectedEndDate := 20200628D; // 28.06.2020 as per issue description

        // [GIVEN] Quarterly billing rhythm (3M)
        Evaluate(PeriodFormula, '<3M>');

        // [GIVEN] Service commitment with "Align to End of Month" setting
        ServiceCommitment.Init();
        ServiceCommitment."Subscription Line Start Date" := StartDate;
        ServiceCommitment."Period Calculation" := ServiceCommitment."Period Calculation"::"Align to End of Month";

        // [WHEN] Calculating the next billing to date
        ActualEndDate := ServiceCommitment.CalculateNextToDate(PeriodFormula, BillingFromDate);

        // [THEN] The end date should be 28.06.2020 (maintaining distance to end of month alignment)
        Assert.AreEqual(ExpectedEndDate, ActualEndDate, 
            StrSubstNo('Quarterly billing for start date %1 should result in %2 but got %3', 
                StartDate, ExpectedEndDate, ActualEndDate));
    end;

    [Test]
    procedure TestQuarterlyBillingAlignToEndOfMonthIssue4401_ThirdExample()
    var
        PeriodFormula: DateFormula;
        ActualEndDate: Date;
        ExpectedEndDate: Date;
        StartDate: Date;
    begin
        // [SCENARIO] Test the third example from bug report #4401
        // Start Date: 26.02.2020, quarterly billing, should result in 27.05.2020

        // [GIVEN] Start date is 26.02.2020 (26th February 2020)
        StartDate := 20200226D;
        ExpectedEndDate := 20200527D; // 27.05.2020 as per issue description

        // [GIVEN] Quarterly billing rhythm (3M)
        Evaluate(PeriodFormula, '<3M>');

        // [GIVEN] Service commitment with "Align to End of Month" setting
        ServiceCommitment.Init();
        ServiceCommitment."Subscription Line Start Date" := StartDate;
        ServiceCommitment."Period Calculation" := ServiceCommitment."Period Calculation"::"Align to End of Month";

        // [WHEN] Calculating the next billing to date
        ActualEndDate := ServiceCommitment.CalculateNextToDate(PeriodFormula, StartDate);

        // [THEN] The end date should be 27.05.2020 (maintaining distance to end of month + 1 day)
        Assert.AreEqual(ExpectedEndDate, ActualEndDate, 
            StrSubstNo('Quarterly billing for start date %1 should result in %2 but got %3', 
                StartDate, ExpectedEndDate, ActualEndDate));
    end;

    [Test]
    procedure TestMonthlyBillingAlignToEndOfMonth_VerifyBehaviorConsistency()
    var
        PeriodFormula: DateFormula;
        ActualEndDate: Date;
        ExpectedEndDate: Date;
        StartDate: Date;
    begin
        // [SCENARIO] Verify the fix is consistent with the updated test expectations
        
        // [GIVEN] Start date is 27.02.2024 (distance to end = 2 days)
        StartDate := 20240227D;
        ExpectedEndDate := 20240329D; // Should be 29.03.2024 after the fix

        // [GIVEN] Monthly billing rhythm (1M)
        Evaluate(PeriodFormula, '<1M>');

        // [GIVEN] Service commitment with "Align to End of Month" setting
        ServiceCommitment.Init();
        ServiceCommitment."Subscription Line Start Date" := StartDate;
        ServiceCommitment."Period Calculation" := ServiceCommitment."Period Calculation"::"Align to End of Month";

        // [WHEN] Calculating the next billing to date
        ActualEndDate := ServiceCommitment.CalculateNextToDate(PeriodFormula, StartDate);

        // [THEN] The end date should match the updated test expectation
        Assert.AreEqual(ExpectedEndDate, ActualEndDate, 
            StrSubstNo('Monthly billing for start date %1 should result in %2 but got %3', 
                StartDate, ExpectedEndDate, ActualEndDate));
    end;
}