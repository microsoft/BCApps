codeunit 134929 "ERM MIR Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Fin. Charge Memo] [Multiple Interest Rates]
    end;

    var
        MIRHelperFunctions: Codeunit "MIR - Helper Functions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        FinChrgIntRateDateMsg: Label 'Create interest rate with start date prior to %1';
        InterestRateNotificationMsg: Label 'This interest rate will only be used if no relevant interest rate per date has been entered.';
        DescrOnFinChrgMemoLineTxt: Label 'Additional Fee';
        ValueMustEqualMsg: Label 'Value must be equal.';
        InvalidInterestRateDateErr: Label 'Create interest rate with start date prior to %1.', Comment = '%1 - date';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountBeforeInterestPeriodAndBeforeDueDate()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        SalesHeader: Record "Sales Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function leads to error if charge memo created before Interest Rate Starting Date and before Sales invoice Due Date
        Initialize();

        // [GIVEN] Finance Charge Terms and Finance Charge Terms Interest Rate (Start Date = 31.01)
        CreateFinanceChargeTerm(FinanceChargeTerms);
        CreateFinanceChargeInterestRates(FinanceChargeInterestRate, FinanceChargeTerms.Code, CalcDate('<1D>', WorkDate()));

        // [GIVEN] Create and post sales invoice with Posting Date 28.01 and Due Date 29.01 (before Interest Rate Starting Date)
        CreateAndPostSalesInvoice(
          SalesHeader, FinanceChargeTerms.Code, CalcDate('<-2D>', WorkDate()), CalcDate('<-1D>', WorkDate()),
          LibraryRandom.RandInt(10));

        // [GIVEN] Create Finance Charge Memo before an Interest Rate Starting Date and before Sales invoice Due Date
        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", CalcDate('<-1D>', FinanceChargeInterestRate."Start Date"));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        asserterror MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] Expected error "Create interest rate with start date prior to 29.01"
        Assert.ExpectedError(StrSubstNo(FinChrgIntRateDateMsg, WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountBeforeInterestPeriodAndAfterDueDate()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        SalesHeader: Record "Sales Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function does not create lines if charge memo created after Interest Rate Starting Date and before Sales invoice Due Date
        Initialize();

        // [GIVEN] Finance Charge Terms and Finance Charge Terms Interest Rate (Start Date = 28.01)
        CreateFinanceChargeTerm(FinanceChargeTerms);
        CreateFinanceChargeInterestRates(FinanceChargeInterestRate, FinanceChargeTerms.Code, CalcDate('<-1D>', WorkDate()));

        // [GIVEN] Create and post sales invoice with Posting Date 28.01 and Due Date 29.01 (after Interest Rate Starting Date)
        CreateAndPostSalesInvoice(
          SalesHeader, FinanceChargeTerms.Code, CalcDate('<-2D>', WorkDate()), CalcDate('<-1D>', WorkDate()), LibraryRandom.RandInt(10));

        // [GIVEN] Create Finance Charge Memo after an Interest Rate Starting Date and before Sales invoice Due Date
        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", CalcDate('<-1D>', FinanceChargeInterestRate."Start Date"));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] No lines generated on Finance Charge Memo Lines.
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        Assert.RecordIsEmpty(FinanceChargeMemoLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountInFirstFinChargeInterestPeriod()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        SalesHeader: Record "Sales Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: array[2] of Record "Finance Charge Interest Rate";
        SalesInvoiceNo: Code[20];
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function creates lines if charge memo created after Interest Rate Starting Date and before Sales invoice Due Date
        Initialize();

        // [GIVEN] Finance Charge Terms
        CreateFinanceChargeTerm(FinanceChargeTerms);

        // [GIVEN] Finance Charge Terms Interest Rate INT_RATE1 (Start Date = 20.01)
        CreateFinanceChargeInterestRates(
          FinanceChargeInterestRate[1], FinanceChargeTerms.Code, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] Finance Charge Terms Interest Rate INT_RATE2 (Start Date = 30.07)
        CreateFinanceChargeInterestRates(
          FinanceChargeInterestRate[2], FinanceChargeTerms.Code, CalcDate('<6M>', WorkDate()));

        // [GIVEN] Create and post sales invoice with Posting Date 28.01 and Due Date 29.01 (after Interest Rate Starting Date)
        SalesInvoiceNo :=
          CreateAndPostSalesInvoice(
            SalesHeader, FinanceChargeTerms.Code, CalcDate('<-2D>', WorkDate()), CalcDate('<-1D>', WorkDate()), LibraryRandom.RandInt(10));

        // [GIVEN] Create Finance Charge Memo on a Date After Finance Charge Interest Rate Start Date (Document Date = 31.01).
        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", CalcDate('<1D>', WorkDate()));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] Finance Charge Memo Line created for INT_RATE1
        Assert.IsTrue(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate[1]."Interest Rate"),
          'First interest period line not found');
        VerifyChargeMemoMIRLine(FinanceChargeMemoHeader, FinanceChargeMemoLine, FinanceChargeInterestRate[1], SalesInvoiceNo);

        // [THEN] Finance Charge Memo Line should not be created for INT_RATE2
        Assert.IsFalse(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate[2]."Interest Rate"),
          'Second interest period line should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountOnLastDateOfFirstFinChargeInterestPeriod()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        SalesHeader: Record "Sales Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: array[2] of Record "Finance Charge Interest Rate";
        SalesInvoiceNo: Code[20];
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function creates only one line if charge memo created after start date of first finance charge interest rate but before start date of second one
        Initialize();

        // [GIVEN] Finance Charge Terms
        CreateFinanceChargeTerm(FinanceChargeTerms);

        // [GIVEN] Finance Charge Terms Interest Rate INT_RATE1 (Start Date = 20.01)
        CreateFinanceChargeInterestRates(FinanceChargeInterestRate[1], FinanceChargeTerms.Code, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] Finance Charge Terms Interest Rate INT_RATE2 (Start Date = 30.07)
        CreateFinanceChargeInterestRates(FinanceChargeInterestRate[2], FinanceChargeTerms.Code, CalcDate('<6M>', WorkDate()));

        // [GIVEN] Create and post sales invoice with Posting Date 28.01 and Due Date 29.01 (after Interest Rate Starting Date)
        SalesInvoiceNo :=
          CreateAndPostSalesInvoice(
            SalesHeader, FinanceChargeTerms.Code, CalcDate('<-2D>', WorkDate()), CalcDate('<-1D>', WorkDate()), LibraryRandom.RandInt(10));

        // [GIVEN] Create Finance Charge Memo on Last Date of First Finance Charge Interest Rate Period (29.07).
        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", CalcDate('<-1D>', FinanceChargeInterestRate[2]."Start Date"));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] Finance Charge Memo Line created for INT_RATE1
        Assert.IsTrue(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate[1]."Interest Rate"),
          'First interest period line not found');
        VerifyChargeMemoMIRLine(FinanceChargeMemoHeader, FinanceChargeMemoLine, FinanceChargeInterestRate[1], SalesInvoiceNo);

        // [THEN] Finance Charge Memo Line should not be created for INT_RATE2
        Assert.IsFalse(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate[2]."Interest Rate"),
          'Second interest period line should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountInSecondFinChargeInterestPeriod()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        SalesHeader: Record "Sales Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: array[2] of Record "Finance Charge Interest Rate";
        SalesInvoiceNo: Code[20];
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function creates 2 lines if charge memo created after start date of second finance chare interest rate
        Initialize();

        // [GIVEN] Finance Charge Terms
        CreateFinanceChargeTerm(FinanceChargeTerms);

        // [GIVEN] Finance Charge Terms Interest Rate INT_RATE1 (Start Date = 20.01)
        CreateFinanceChargeInterestRates(FinanceChargeInterestRate[1], FinanceChargeTerms.Code, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] Finance Charge Terms Interest Rate INT_RATE2 (Start Date = 30.07)
        CreateFinanceChargeInterestRates(FinanceChargeInterestRate[2], FinanceChargeTerms.Code, CalcDate('<6M>', WorkDate()));

        // [GIVEN] Create and post sales invoice with Posting Date 28.01 and Due Date 29.01 (after Interest Rate Starting Date)
        SalesInvoiceNo :=
          CreateAndPostSalesInvoice(
            SalesHeader, FinanceChargeTerms.Code, CalcDate('<-2D>', WorkDate()), CalcDate('<-1D>', WorkDate()), LibraryRandom.RandInt(10));

        // [GIVEN] Create Finance Charge Memo on first Date of Second Finance Charge Interest Rate INT_RATE2 Period (30.07).
        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", FinanceChargeInterestRate[2]."Start Date");

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // Verify: Verify Remaining Amounts, Amounts, Due Dates and Posting Dates on Finance Charge Memo.
        MIRHelperFunctions.VerifyIntAmtOnFinChargeMemo(FinanceChargeMemoHeader, SalesHeader);

        // [THEN] Finance Charge Memo Line created for INT_RATE1
        Assert.IsTrue(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate[1]."Interest Rate"),
          'First interest period line not found');
        VerifyChargeMemoMIRLineWithDaysOverdue(
          FinanceChargeMemoLine, FinanceChargeInterestRate[1], SalesInvoiceNo,
          FinanceChargeInterestRate[2]."Start Date" - FinanceChargeMemoLine."Due Date");

        // [THEN] Finance Charge Memo Line created for INT_RATE2
        Assert.IsTrue(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate[2]."Interest Rate"),
          'Second interest period line not found');
        VerifyChargeMemoMIRLineWithDaysOverdue(FinanceChargeMemoLine, FinanceChargeInterestRate[2], SalesInvoiceNo,
          FinanceChargeMemoHeader."Document Date" - FinanceChargeMemoLine."Due Date" + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountOnLastDateOfSecondFinChargeInterestPeriod()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        SalesHeader: Record "Sales Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: array[2] of Record "Finance Charge Interest Rate";
        SalesInvoiceNo: Code[20];
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function creates 2 lines if charge memo created after on last date of second finance chare interest rate
        Initialize();

        // [GIVEN] Finance Charge Terms
        CreateFinanceChargeTerm(FinanceChargeTerms);

        // [GIVEN] Finance Charge Terms Interest Rate INT_RATE1 (Start Date = 20.01)
        CreateFinanceChargeInterestRates(
          FinanceChargeInterestRate[1], FinanceChargeTerms.Code, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] Finance Charge Terms Interest Rate INT_RATE2 (Start Date = 30.07)
        CreateFinanceChargeInterestRates(
          FinanceChargeInterestRate[2], FinanceChargeTerms.Code, CalcDate('<6M>', WorkDate()));

        // [GIVEN] Create and post sales invoice with Posting Date 28.01 and Due Date 29.01 (after Interest Rate Starting Date)
        SalesInvoiceNo :=
          CreateAndPostSalesInvoice(
            SalesHeader, FinanceChargeTerms.Code, CalcDate('<-2D>', WorkDate()), CalcDate('<-1D>', WorkDate()), LibraryRandom.RandInt(10));

        // [GIVEN] Create Finance Charge Memo on a date after Second Finance Charge Interest Rate Period (30.08).
        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", CalcDate('<12M>', FinanceChargeInterestRate[2]."Start Date"));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] Finance Charge Memo Line created for INT_RATE1
        Assert.IsTrue(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate[1]."Interest Rate"),
          'First interest period line not found');
        VerifyChargeMemoMIRLineWithDaysOverdue(FinanceChargeMemoLine, FinanceChargeInterestRate[1], SalesInvoiceNo,
          FinanceChargeInterestRate[2]."Start Date" - FinanceChargeMemoLine."Due Date");

        // [THEN] Finance Charge Memo Line created for INT_RATE2
        Assert.IsTrue(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate[2]."Interest Rate"),
          'Second interest period line not found');
        VerifyChargeMemoMIRLineWithDaysOverdue(FinanceChargeMemoLine, FinanceChargeInterestRate[2], SalesInvoiceNo,
          FinanceChargeMemoHeader."Document Date" - FinanceChargeMemoLine."Due Date" + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountOnLastDateOfGracePeriod()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        SalesHeader: Record "Sales Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function does not create lines for Finance Charge Memo created on Last Date of Grace Period
        Initialize();

        // [GIVEN] Create Fincance Charge Terms with grace period <7D>
        CreateFinChargeTermWithGracePeriod(FinanceChargeTerms);
        CreateFinanceChargeInterestRates(
          FinanceChargeInterestRate, FinanceChargeTerms.Code, CalcDate('<-1D>', WorkDate()));

        // [GIVEN] Create and post sales invoice with Posting Date 31.01 and Due Date 01.02 (after Interest Rate Starting Date)
        CreateAndPostSalesInvoice(
          SalesHeader, FinanceChargeTerms.Code, CalcDate('<1D>', WorkDate()), CalcDate('<2D>', WorkDate()), LibraryRandom.RandInt(10));

        // Test Case Specific Setup Steps: Create a Finance Charge Memo on Last Date of Grace Period (07.02).
        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", CalcDate(FinanceChargeTerms."Grace Period", SalesHeader."Due Date"));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] No lines generated on Finance Charge Memo Lines.
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        Assert.RecordIsEmpty(FinanceChargeMemoLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountOnFirstDateAfterGracePeriod()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        SalesInvoiceNo: Code[20];
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function creates line for Finance Charge Memo created after Grace Period End Date
        // [GIVEN] Create Fincance Charge Terms with grace period <7D>
        // [GIVEN] Create Finance Charge Terms Interest Rate (Start Date = 28.01)
        // [GIVEN] Create and post sales invoice with Posting Date 31.01 and Due Date 01.02 (after Interest Rate Starting Date)
        // [GIVEN] Create Finance Charge Memo on First Date after Grace Period ends (09.02).
        PrepareGracePeriodScenario(
          FinanceChargeTerms, FinanceChargeMemoHeader, SalesInvoiceNo, FinanceChargeInterestRate, CalcDate('<-2D>', WorkDate()));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] Finance Charge Memo Line created
        Assert.IsTrue(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate."Interest Rate"),
          'Finance Charge Memo Line not found');
        VerifyChargeMemoMIRLine(FinanceChargeMemoHeader, FinanceChargeMemoLine, FinanceChargeInterestRate, SalesInvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestPeriodStartsBetweenInvPostingDateAndGracePeriodEnd()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        SalesInvoiceNo: Code[20];
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function creates line for Finance Charge Memo created after Grace Period. Interest period starts between Sales Invoice Posting Date and Grace Period End.
        // [GIVEN] Create Fincance Charge Terms with grace period <7D>
        // [GIVEN] Create Finance Charge Terms Interest Rate (Start Date = 01.02)
        // [GIVEN] Create and post sales invoice with Posting Date 31.01 and Due Date 01.02
        // [GIVEN] Create a Finance Charge Memo on First Date after Finance Charge Grace Period Ends (09.02).
        // Interest period starts between Sales Invoice Posting Date and Grace Period End
        PrepareGracePeriodScenario(
          FinanceChargeTerms, FinanceChargeMemoHeader, SalesInvoiceNo, FinanceChargeInterestRate, CalcDate('<-2D>', WorkDate()));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] Finance Charge Memo Line created
        Assert.IsTrue(
          FindFinChargeMemoMIRLine(FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeInterestRate."Interest Rate"),
          'Finance Charge Memo Line not found');
        VerifyChargeMemoMIRLine(FinanceChargeMemoHeader, FinanceChargeMemoLine, FinanceChargeInterestRate, SalesInvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountSmallerThanAdditionalFeeMinAmount()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        SalesHeader: Record "Sales Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function does not create line if Finance Charge Interest Amount is smaller than the Finance Charge Terms Minimum Amount

        Initialize();

        // [GIVEN] Create Fincance Charge Terms with additional fee and minimal amount 150
        CreateFinChargeTermWithAdditionalFee(FinanceChargeTerms, LibraryRandom.RandInt(100) + 100); // Passing value Greater than 100 in Minimum Amount Field.
        FinanceChargeTerms.Validate("Additional Fee (LCY)", 0);
        FinanceChargeTerms.Modify(true);

        CreateFinanceChargeInterestRates(
          FinanceChargeInterestRate, FinanceChargeTerms.Code, CalcDate('<-1D>', WorkDate()));

        // [GIVEN] Create and post sales invoice with Unit Price 10 to cause interest amount less than Minimum Amount
        CreateAndPostSalesInvoice(
          SalesHeader, FinanceChargeTerms.Code, CalcDate('<-2D>', WorkDate()), CalcDate('<-1D>', WorkDate()), LibraryRandom.RandInt(10));

        // [GIVEN] Create a Finance Charge Memo
        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", CalcDate('<1D>', SalesHeader."Due Date"));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] No lines generated on Finance Charge Memo Lines.
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        Assert.RecordIsEmpty(FinanceChargeMemoLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InterestAmountGreaterThanAdditionalFeeMinAmount()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        SalesHeader: Record "Sales Header";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        // [SCENARIO] Suggest Fin Charge Memo Lines function creates line if Finance Charge Interest Amount is greater than the Finance Charge Terms Minimum Amount
        Initialize();

        // [GIVEN] Create Fincance Charge Terms with additional fee and minimal amount 10
        CreateFinChargeTermWithAdditionalFee(FinanceChargeTerms, LibraryRandom.RandInt(10)); // Passing RANDOM value to generate Minimum Amount.

        CreateFinanceChargeInterestRates(
          FinanceChargeInterestRate, FinanceChargeTerms.Code, CalcDate('<-1D>', WorkDate()));

        // [GIVEN] Create and post sales invoice with Unit Price 1000 to cause interest amount greater than Minimum Amount
        CreateAndPostSalesInvoice(
          SalesHeader, FinanceChargeTerms.Code, CalcDate('<-2D>', WorkDate()), CalcDate('<-1D>', WorkDate()),
          LibraryRandom.RandInt(10) + 1000); // Pass Unit Price greater than 1000 Using RANDOM.
        // [GIVEN] Create a Finance Charge Memo
        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", CalcDate('<6M>', SalesHeader."Due Date"));

        // [WHEN] Suggest Finance Charge Memo Lines is being run
        MIRHelperFunctions.SuggestFinChargeMemoLines(FinanceChargeMemoHeader);

        // [THEN] Finance Charge Memo Line created
        VerifyAdditionalFeeAndInterestAmtOnFinChargeMemo(FinanceChargeMemoHeader, SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestFinanceChargeMemoSeveralLines()
    var
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        CreateFinanceChargeMemos: Report "Create Finance Charge Memos";
        CreationDate: Date;
        i: Integer;
        InvoicesQty: Integer;
    begin
        // [SCENARIO] Create Finance Charge Memo function creates finance charge memo with several lines based on several invoices
        Initialize();

        // [GIVEN] Finance Charge Terms and Finance Charge Terms Interest Rate (Start Date = 28.01)
        CreateFinanceChargeTerm(FinanceChargeTerms);
        CreateFinanceChargeInterestRates(
          FinanceChargeInterestRate, FinanceChargeTerms.Code, CalcDate('<-1D>', WorkDate()));

        // [GIVEN] Create Customer with fincnce charge term created before
        Customer.Get(MIRHelperFunctions.UpdateFinChargeTermsOnCustomer(FinanceChargeTerms.Code));

        // [GIVEN] Create and post 3 invoices
        InvoicesQty := LibraryRandom.RandIntInRange(3, 5);
        for i := 1 to InvoicesQty do
            MIRHelperFunctions.CreateAndPostSalesInvoiceBySalesJournal(Customer."No.");

        // [WHEN] The Create Finance Charge Memos report is being run
        CreationDate := CalcDate('<' + Format(2 * LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        Customer.SetRecFilter();
        CreateFinanceChargeMemos.SetTableView(Customer);
        CreateFinanceChargeMemos.InitializeRequest(CreationDate, CreationDate);
        CreateFinanceChargeMemos.UseRequestPage(false);
        CreateFinanceChargeMemos.Run();

        // [THEN] 3 finance charge memo lines with "Detailed Interest Rates Entry" = TRUE created
        FinanceChargeMemoHeader.SetRange("Customer No.", Customer."No.");
        FinanceChargeMemoHeader.FindFirst();

        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        FinanceChargeMemoLine.SetRange("Detailed Interest Rates Entry", true);
        Assert.RecordCount(FinanceChargeMemoLine, InvoicesQty);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MakeReminder()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Reminder-Make function makes reminder line from customer ledger entry
        Initialize();

        // [GIVEN] Customer, Reminder Level, Customer Ledger Entry, Detailed Customer Ledger Entry
        CreateCustomer(Customer);
        CreateReminderLevel(Customer."Reminder Terms Code");
        MockCustomerLedgerEntry(CustLedgerEntry, Customer."No.");
        ReminderHeader.Init();
        ReminderHeader."Document Date" := WorkDate();
        ReminderMake.Set(Customer, CustLedgerEntry, ReminderHeader, false, false, CustLedgEntryLineFeeOn);  // Overdue Entries Only - False and  Include Entries On Hold - False.

        // [WHEN] function MakeReminder of Codeunit - Reminder-Make is being run
        ReminderMake.Code();

        // [THEN] Reminder line created
        ReminderLine.SetRange("Entry No.", CustLedgerEntry."Entry No.");
        ReminderLine.FindFirst();
        ReminderLine.TestField(Type, ReminderLine.Type::"Customer Ledger Entry");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunTypeBlankReminderIssueError()
    var
        ReminderLine: Record "Reminder Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issue of Reminder with blank type and some amount leads to error
        Initialize();

        // [GIVEN] Reminder with blank reminder line type
        // [WHEN] Reminder is being issued
        OnRunTypeReminderIssue(ReminderLine.Type::" ");

        // [THEN] "Amount must be equal to '0'" error
        Assert.ExpectedTestFieldError(ReminderLine.FieldCaption(Amount), Format(0));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunTypeGLAccountReminderIssueError()
    var
        ReminderLine: Record "Reminder Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issue of Reminder with G/L Account type, blank "No." and some amount leads to error
        Initialize();

        // [GIVEN] Reminder with G/L Account reminder line type
        // [WHEN] Reminder is being issued
        OnRunTypeReminderIssue(ReminderLine.Type::"G/L Account");

        // [THEN] "No. must have a value in Reminder Line" error
        Assert.ExpectedError('No. must have a value in Reminder Line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunTypeCustomerLedgerEntryReminderIssueError()
    var
        ReminderLine: Record "Reminder Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issue of Reminder with Customer Ledger Entry type, blank "Entry No." and some amount leads to error
        Initialize();

        // [GIVEN] Reminder with Customer Ledger Entry reminder line type
        // [WHEN] Reminder is being issued
        OnRunTypeReminderIssue(ReminderLine.Type::"Customer Ledger Entry");

        // [THEN] "Entry No. must have a value in Reminder Line" error
        Assert.ExpectedError('Entry No. must have a value in Reminder Line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunTypeCustomerLedgerEntryReminderIssue()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issuing of Reminder with Customer Ledger Entry type makes Reminder/Fincance Charge Entry
        Initialize();

        // [GIVEN] Create Customer, Customer Ledger Entry and Reminder
        CreateCustomer(Customer);
        MockCustomerLedgerEntry(CustLedgerEntry, Customer."No.");
        CreateReminder(ReminderHeader, Customer, ReminderLine.Type::"Customer Ledger Entry", '', CustLedgerEntry."Entry No.");  // Using blank value for Reminder Line Number.
        ReminderIssue.Set(ReminderHeader, false, WorkDate());  // New Replace Posting Date - False and New Posting Date - WORKDATE.

        // [WHEN] Reminder is being issued
        LibraryERM.RunReminderIssue(ReminderIssue);

        // [THEN] Reminder Finance Charge Entry created
        VerifyReminderFinanceChargeEntry(
          CustLedgerEntry, ReminderFinChargeEntry.Type::Reminder, ReminderHeader."No.", ReminderHeader."Due Date");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunReminderIssue()
    var
        Customer: Record Customer;
        GLEntry: Record "G/L Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderIssue: Codeunit "Reminder-Issue";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issue of Reminder makes G/L entry
        Initialize();

        // [GIVEN] Customer and Reminder
        CreateCustomer(Customer);
        GLAccountNo := CreateReminder(ReminderHeader, Customer, ReminderLine.Type::"G/L Account", CreateGLAccount(), 0);  // Entry No - 0.
        CreateVATPostingSetup(ReminderHeader."VAT Bus. Posting Group", ReminderLine."VAT Prod. Posting Group");
        ReminderIssue.Set(ReminderHeader, false, WorkDate());  // New Replace Posting Date - False and New Posting Date - WORKDATE.

        // [WHEN] Codeunit - Reminder-Issue is being run
        LibraryERM.RunReminderIssue(ReminderIssue);

        // [THEN] General Ledger Entry created
        VerifyGLEntry(GLAccountNo, GLEntry."Document Type"::Reminder, ReminderHeader."No.", ReminderHeader."Customer No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MakeLines2WithoutTermsDescriptionFinChrgMemoMake()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Fin. Charge Memo Line description is taken from customer ledeger entry in case of blank Finance Charge Terms Description
        Initialize();

        // [GIVEN] Customer, Customer Ledger Entry, Detailed Customer Ledger Entry, and Finance Charge Memo Header
        // [GIVEN] Finance Charge Terms with blank Description
        // [WHEN] FinChrgMemo-Make codeunit is being run
        // [THEN] Created Fin. Charge Memo Line has Description taken from customer ledger entry
        MakeLines2TermsDescriptionFinChrgMemoMake('');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MakeLines2WithTermsDescriptionFinChrgMemoMake()
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Fin. Charge Memo Line description is taken from Finance Charge Terms in case of Finance Charge Terms Description is not blank
        Initialize();

        // [GIVEN] Customer, Customer Ledger Entry, Detailed Customer Ledger Entry, and Finance Charge Memo Header
        // [GIVEN] Finance Charge Terms with not blank Description
        // [WHEN] FinChrgMemo-Make codeunit is being run
        // [THEN] Created Fin. Charge Memo Line has Description taken from Finance Charge Terms
        MakeLines2TermsDescriptionFinChrgMemoMake(LibraryUTUtility.GetNewCode());  // Finance Charge Terms Description.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunTypeBlankFinChrgMemoIssueError()
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issue of Finance Charge Memo with blank type and some amount leads to error
        Initialize();

        // [GIVEN] Finance Charge Memo with blank line type
        // [WHEN] Finance Charge Memo is being issued
        OnRunTypeFinChrgMemoIssue(FinanceChargeMemoLine.Type::" ");

        // [THEN] "Amount must be equal to '0'" error
        Assert.ExpectedTestFieldError(FinanceChargeMemoLine.FieldCaption(Amount), Format(0));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunTypeGLAccountFinChrgMemoIssueError()
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issue of Finance Charge Memo with G/L Account type, blank "No." and some amount leads to error
        Initialize();

        // [GIVEN] Finance Charge Memo with G/L Account reminder line type
        // [WHEN] Finance Charge Memo is being issued
        OnRunTypeFinChrgMemoIssue(FinanceChargeMemoLine.Type::"G/L Account");

        // [THEN] "No. must have a value in Finance Charge Memo Line" error
        Assert.ExpectedError('No. must have a value in Finance Charge Memo Line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunTypeCustomerLedgerEntryFinChrgMemoIssueError()
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issue of Finance Charge Memo with Customer Ledger Entry type, blank "Entry No." and some amount leads to error
        Initialize();

        // [GIVEN] Finance Charge Memo with Customer Ledger Entry reminder line type
        // [WHEN] Finance Charge Memo is being issued
        OnRunTypeFinChrgMemoIssue(FinanceChargeMemoLine.Type::"Customer Ledger Entry");

        // [THEN] "Entry No. must have a value in Finance Charge Memo Line" error
        Assert.ExpectedError('Entry No. must have a value in Finance Charge Memo Line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunTypeCustomerLedgerEntryFinChrgMemoIssue()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issuing of Finance Charge Memo with Customer Ledger Entry type makes Reminder/Fincance Charge Entry
        Initialize();

        // [GIVEN] Create Customer, Customer Ledger Entry and Finance Charge Memo
        CreateCustomer(Customer);
        MockCustomerLedgerEntry(CustLedgerEntry, Customer."No.");
        CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, Customer, FinanceChargeMemoLine.Type::"Customer Ledger Entry", '', CustLedgerEntry."Entry No.");  // Using blank value for Finance Charge Memo Line Number.
        FinChrgMemoIssue.Set(FinanceChargeMemoHeader, false, WorkDate());  // New Replace Posting Date - False and New Posting Date - WORKDATE.

        // [WHEN] Finance Charge Memo is being issued
        LibraryERM.RunFinChrgMemoIssue(FinChrgMemoIssue);

        // [THEN] Reminder Finance Charge Entry created
        VerifyReminderFinanceChargeEntry(
          CustLedgerEntry, ReminderFinChargeEntry.Type::"Finance Charge Memo", FinanceChargeMemoHeader."No.",
          FinanceChargeMemoHeader."Due Date");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunFinChrgMemoIssue()
    var
        Customer: Record Customer;
        GLEntry: Record "G/L Entry";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
        GLAccountNumber: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Issue of Finance Charge Memo makes G/L entry
        Initialize();

        // [GIVEN] Create Customer, Customer Ledger Entry and Finance Charge Memo
        CreateCustomer(Customer);
        GLAccountNumber :=
          CreateFinanceChargeMemo(FinanceChargeMemoHeader, Customer, FinanceChargeMemoLine.Type::"G/L Account", CreateGLAccount(), 0);  // Entry No - 0.
        CreateVATPostingSetup(FinanceChargeMemoHeader."VAT Bus. Posting Group", FinanceChargeMemoLine."VAT Prod. Posting Group");
        FinChrgMemoIssue.Set(FinanceChargeMemoHeader, false, WorkDate());  // New Replace Posting Date - False and New Posting Date - WORKDATE.

        // [WHEN] Finance Charge Memo is being issued
        LibraryERM.RunFinChrgMemoIssue(FinChrgMemoIssue);

        // [THEN] General Ledger Entry created
        VerifyGLEntry(
          GLAccountNumber, GLEntry."Document Type"::"Finance Charge Memo", FinanceChargeMemoHeader."No.",
          FinanceChargeMemoHeader."Customer No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteFinanceChargeTerms()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Deletion of Finance Charge Terms leads to deletion of linked Finance Charge Interest Rate
        Initialize();

        // [GIVEN] Finance Charge Terms 'T' with Finance Charge Interest Rate 'R'
        CreateFinanceChargeTerm(FinanceChargeTerms);
        CreateFinanceChargeInterestRates(FinChargeInterestRate, FinanceChargeTerms.Code, WorkDate());
        FinChargeInterestRate.SetRange("Fin. Charge Terms Code", FinanceChargeTerms.Code);

        // [WHEN] Finance Charge Terms 'T' is being deleted
        FinanceChargeTerms.Delete(true);

        // [THEN] Finance Charge Interest Rate 'R' deleted
        Assert.RecordIsEmpty(FinChargeInterestRate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InterestRateOnValidateFinanceChargeTerms()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Changing "Interest Rate" of Finance Charge Terms leads to notificaiton message
        Initialize();

        // [GIVEN] Finance Charge Terms 'T' with Finance Charge Interest Rate 'R'
        CreateFinanceChargeTerm(FinanceChargeTerms);
        CreateFinanceChargeInterestRates(FinChargeInterestRate, FinanceChargeTerms.Code, WorkDate());

        // [WHEN] "Interest Rate" of Finance Charge Terms 'T' is being changed
        // [THEN] Notification message displayed
        LibraryVariableStorage.Enqueue(InterestRateNotificationMsg);
        FinanceChargeTerms.Validate("Interest Rate");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AverageDailyBalanceReminderLineError()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Validate of "Interest Rate" of Reminder line when "Interest Calculation Method"::"Average Daily Balance" and Interest Start Date greater than Due Date leads to error

        // [GIVEN] Reminder with FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance" and Interest Start Date greater than Due Date
        // [WHEN] "Interest Rate" of Reminder line is being validated
        // [THEN] "Create interest rate with start date prior to ..." error
        InterestRateMethodReminderLine(FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BalanceDueReminderLineError()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Validate of "Interest Rate" of Reminder line when "Interest Calculation Method"::"Balance Due" and Interest Start Date greater than Due Date leads to error

        // [GIVEN] Reminder with FinanceChargeTerms."Interest Calculation Method"::"Balance Due" and Interest Start Date greater than Due Date
        // [WHEN] "Interest Rate" of Reminder line is being validated
        // [THEN] "Create interest rate with start date prior to ..." error
        InterestRateMethodReminderLine(FinanceChargeTerms."Interest Calculation Method"::"Balance Due");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AverageDailyBalanceFinanceChargeMemoLine()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Validate of "Interest Rate" of Finance Charge Memo line when "Interest Calculation Method"::"Average Daily Balance" and Interest Start Date less than Due Date does not lead to error

        // [GIVEN] Reminder with FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance" and Interest Start Date less than Due Date
        // [WHEN] "Interest Rate" of Finance Charge Memo  line is being validated
        // [THEN] Finance Charge line Interest Rate = FinChargeInterestRate."Interest Rate"
        InterestCalculationMethodFinanceChargeMemoLine(FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BalanceDueFinanceChargeMemoLine()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Validate of "Interest Rate" of Finance Charge Memo line when "Interest Calculation Method"::"Balance Due" and Interest Start Date less than Due Date does not lead to error

        // [GIVEN] Reminder with FinanceChargeTerms."Interest Calculation Method"::"Balance Due" and Interest Start Date less than Due Date
        // [WHEN] "Interest Rate" of Finance Charge Memo  line is being validated
        // [THEN] Finance Charge line Interest Rate = FinChargeInterestRate."Interest Rate"
        InterestCalculationMethodFinanceChargeMemoLine(FinanceChargeTerms."Interest Calculation Method"::"Balance Due");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AverageDailyBalanceFinanceChargeMemoLineError()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Validate of "Interest Rate" of Finance Charge Memo line when "Interest Calculation Method"::"Average Daily Balance" and Interest Start Date greater than Due Date leads to error

        // [GIVEN] Reminder with FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance" and Interest Start Date greater than Due Date
        // [WHEN] "Interest Rate" of Finance Charge Memo  line is being validated
        // [THEN] "Create interest rate with start date prior to ..." error
        InterestRateMethodFinanceChargeMemoLine(FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BalanceDueFinanceChargeMemoLineError()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Validate of "Interest Rate" of Finance Charge Memo line when "Interest Calculation Method"::"Balance Due" and Interest Start Date greater than Due Date leads to error

        // [GIVEN] Reminder with FinanceChargeTerms."Interest Calculation Method"::"Balance Due" and Interest Start Date greater than Due Date
        // [WHEN] "Interest Rate" of Finance Charge Memo  line is being validated
        // [THEN] "Create interest rate with start date prior to ..." error
        InterestRateMethodFinanceChargeMemoLine(FinanceChargeTerms."Interest Calculation Method"::"Balance Due");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateInterestRateFinanceChargeMemoLine()
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // Purpose of the test is to validate Interest Rate - OnValidate Trigger of Table ID - 303 Finance Charge Memo Line.

        // Setup: Create Finance Charge Terms, Finance Charge Memo.
        CreateFinanceChargeTerm(FinanceChargeTerms);
        CreateDummyFinanceChargeMemo(FinanceChargeMemoLine, FinanceChargeTerms.Code);

        // Exercise.
        FinanceChargeMemoLine.Validate("Interest Rate");

        // Verify: Verify Interest Rate with Finance Charge Terms - Interest Rate.
        FinanceChargeMemoLine.TestField("Interest Rate", FinanceChargeTerms."Interest Rate");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeReminderWithoutReminderTermsCodeOnHeader()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntryFeeLine: Record "Cust. Ledger Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 403561] Stan can't get suggested reminder lines when "Reminder Terms Code" is not specified on Reminder
        Initialize();

        CreateCustomerWithLedgerEntryAndReminderHeader(Customer, ReminderHeader, CustLedgerEntry);

        ReminderHeader.Validate("Reminder Terms Code", '');
        ReminderHeader.Modify(true);

        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, false, false, CustLedgerEntryFeeLine);

        asserterror ReminderMake.Code();

        Assert.ExpectedTestFieldError(ReminderHeader.FieldCaption("Reminder Terms Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeReminderWithoutReminderTermsCodeOnCustomer()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntryFeeLine: Record "Cust. Ledger Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 403561] Stan can get suggested reminder lines when "Reminder Terms Code" is not specified on customer, but specified on Reminder 
        Initialize();

        CreateCustomerWithLedgerEntryAndReminderHeader(Customer, ReminderHeader, CustLedgerEntry);

        Customer.Validate("Reminder Terms Code", '');
        Customer.Modify(true);

        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, false, false, CustLedgerEntryFeeLine);

        ReminderMake.Code();

        ReminderLine.SetRange("Entry No.", CustLedgerEntry."Entry No.");
        ReminderLine.FindFirst();
        ReminderLine.TestField(Type, ReminderLine.Type::"Customer Ledger Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeReminderWithoutReminderTermsCodeOnHeaderAndCustomer()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntryFeeLine: Record "Cust. Ledger Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 403561] Stan can get suggested reminder lines when "Reminder Terms Code" is not specified on customer or on Reminder 
        Initialize();

        CreateCustomerWithLedgerEntryAndReminderHeader(Customer, ReminderHeader, CustLedgerEntry);

        ReminderHeader.Validate("Reminder Terms Code", '');
        ReminderHeader.Modify(true);

        Customer.Validate("Reminder Terms Code", '');
        Customer.Modify(true);

        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, false, false, CustLedgerEntryFeeLine);

        asserterror ReminderMake.Code();

        Assert.ExpectedTestFieldError(ReminderHeader.FieldCaption("Reminder Terms Code"), '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM MIR Test");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM MIR Test");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM MIR Test");
    end;

    local procedure CreateCustomerWithLedgerEntryAndReminderHeader(var Customer: Record Customer; var ReminderHeader: Record "Reminder Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CreateCustomer(Customer);
        CreateReminderLevel(Customer."Reminder Terms Code");
        MockCustomerLedgerEntry(CustLedgerEntry, Customer."No.");

        ReminderHeader.Init();
        ReminderHeader.Validate("Customer No.", Customer."No.");
        ReminderHeader.Validate("Document Date", WorkDate());
        ReminderHeader.Insert(true);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; FinanceChargeTermsCode: Code[10]; PostingDate: Date; DueDate: Date; UnitPrice: Decimal): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        // Create a Sales Invoice Header.
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          MIRHelperFunctions.UpdateFinChargeTermsOnCustomer(FinanceChargeTermsCode));

        // Enter Posting Date and Due Date in Sales Invoice Header.
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Due Date", DueDate);
        SalesHeader.Modify(true);

        // Create Sales Lines. Use RANDOM to generate Random Quantity.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", UnitPrice); // Enter Unit Price using RANDOM in the Sales Line.
        SalesLine.Modify(true);

        // Post the Sales Invoice.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Reminder Terms Code" := CreateReminderTerms();
        Customer."Fin. Charge Terms Code" := CreateFinanceChargeTermsCode();
        Customer.Modify();
    end;

    local procedure CreateFinChargeTermWithGracePeriod(var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
        // Create a new Finance Charge Term with Grace Period of Seven Days.
        CreateFinanceChargeTerm(FinanceChargeTerms);
        Evaluate(FinanceChargeTerms."Grace Period", '<7D>');
        FinanceChargeTerms.Modify(true);
    end;

    local procedure CreateFinanceChargeInterestRates(var FinanceChargeInterestRate: Record "Finance Charge Interest Rate"; FinanceChargeTermsCode: Code[10]; StartDate: Date)
    begin
        FinanceChargeInterestRate.Init();
        FinanceChargeInterestRate.Validate("Fin. Charge Terms Code", FinanceChargeTermsCode);
        FinanceChargeInterestRate.Validate("Start Date", StartDate);
        FinanceChargeInterestRate.Validate("Interest Rate", LibraryRandom.RandInt(10));
        FinanceChargeInterestRate.Validate("Interest Period (Days)", LibraryRandom.RandInt(100));
        FinanceChargeInterestRate.Insert(true);
    end;

    local procedure CreateFinChargeTermWithAdditionalFee(var FinanceChargeTerms: Record "Finance Charge Terms"; MinimumAmount: Decimal)
    begin
        CreateFinanceChargeTerm(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandInt(100));
        FinanceChargeTerms.Validate("Minimum Amount (LCY)", MinimumAmount);
        FinanceChargeTerms.Validate("Additional Fee (LCY)", LibraryRandom.RandInt(10));
        FinanceChargeTerms.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."VAT Prod. Posting Group" := CreateVATProductPostingGroup();
        GLAccount."Gen. Prod. Posting Group" := CreateGeneralProductPostingGroup();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGeneralProductPostingGroup(): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.Init();
        GenProductPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := CreateVATProductPostingGroup();
        GenProductPostingGroup.Insert();
        exit(GenProductPostingGroup.Code);
    end;

    local procedure CreateFinanceChargeTerm(var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
        // Create a new Finance Charge Term.
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandInt(10));  // Use RANDOM to create a Random Interest Rate.
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandInt(10));  // Use RANDOM to create a Random Interest Period.
        Evaluate(FinanceChargeTerms."Due Date Calculation", '<1M>');
        FinanceChargeTerms.Modify(true);
    end;

    local procedure CreateFinanceChargeTermsWithCalcMethod(var FinanceChargeTerms: Record "Finance Charge Terms"; InterestCalculationMethod: Enum "Interest Calculation Method")
    begin
        FinanceChargeTerms.Init();
        FinanceChargeTerms.Code := LibraryUTUtility.GetNewCode10();
        FinanceChargeTerms."Interest Calculation Method" := InterestCalculationMethod;
        FinanceChargeTerms."Interest Rate" := LibraryRandom.RandInt(10);
        FinanceChargeTerms."Interest Period (Days)" := LibraryRandom.RandInt(10);
        FinanceChargeTerms.Insert();
    end;

    local procedure CreateFinanceChargeMemo(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; Customer: Record Customer; Type: Option; No: Code[20]; EntryNo: Integer): Code[20]
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FinanceChargeMemoHeader.Init();
        FinanceChargeMemoHeader."No." := LibraryUTUtility.GetNewCode();
        FinanceChargeMemoHeader."Document Date" := WorkDate();
        FinanceChargeMemoHeader."Customer No." := Customer."No.";
        FinanceChargeMemoHeader."Customer Posting Group" := Customer."Customer Posting Group";
        FinanceChargeMemoHeader."Due Date" := FinanceChargeMemoHeader."Document Date";
        FinanceChargeMemoHeader."Fin. Charge Terms Code" := Customer."Fin. Charge Terms Code";
        FinanceChargeMemoHeader."Post Additional Fee" := true;
        FinanceChargeMemoHeader."Posting Description" := FinanceChargeMemoHeader."No.";
        FinanceChargeMemoHeader.Insert();
        FinanceChargeMemoLine."Finance Charge Memo No." := FinanceChargeMemoHeader."No.";
        FinanceChargeMemoLine.Init();
        FinanceChargeMemoLine.Type := Type;
        FinanceChargeMemoLine."No." := No;
        FinanceChargeMemoLine."VAT Prod. Posting Group" := CreateVATProductPostingGroup();
        FinanceChargeMemoLine.Amount := LibraryRandom.RandDec(10, 2);
        FinanceChargeMemoLine."Remaining Amount" := LibraryRandom.RandDec(10, 2);
        FinanceChargeMemoLine."Entry No." := EntryNo;
        FinanceChargeMemoLine.Insert();
        exit(FinanceChargeMemoLine."No.");
    end;

    local procedure CreateFinanceChargeTermsCode(): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        FinanceChargeTerms.Init();
        FinanceChargeTerms.Code := LibraryUTUtility.GetNewCode10();
        FinanceChargeTerms."Interest Period (Days)" := LibraryRandom.RandInt(10);
        FinanceChargeTerms."Additional Fee (LCY)" := LibraryRandom.RandDec(10, 2);
        FinanceChargeTerms."Interest Rate" := LibraryRandom.RandDec(10, 2);
        FinanceChargeTerms."Interest Calculation Method" := FinanceChargeTerms."Interest Calculation Method"::"Balance Due";
        FinanceChargeTerms.Insert();
        exit(FinanceChargeTerms.Code);
    end;

    local procedure CreateDummyFinanceChargeMemo(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinChargeTermsCode: Code[10])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        FinanceChargeMemoHeader.Init();
        FinanceChargeMemoHeader."No." := LibraryUTUtility.GetNewCode();
        FinanceChargeMemoHeader."Customer No." := LibraryUTUtility.GetNewCode();
        FinanceChargeMemoHeader."Document Date" := WorkDate();
        FinanceChargeMemoHeader."Customer Posting Group" := LibraryUTUtility.GetNewCode10();
        FinanceChargeMemoHeader."Fin. Charge Terms Code" := FinChargeTermsCode;
        FinanceChargeMemoHeader.Insert();

        FinanceChargeMemoLine.Init();
        FinanceChargeMemoLine."Finance Charge Memo No." := FinanceChargeMemoHeader."No.";
        FinanceChargeMemoLine.Type := FinanceChargeMemoLine.Type::"Customer Ledger Entry";
        FinanceChargeMemoLine."Entry No." := CreateDummyCustomerLedgerEntry();
        FinanceChargeMemoLine."Due Date" := FinanceChargeMemoHeader."Document Date";
        FinanceChargeMemoLine.Insert();
    end;

    local procedure CreateDummyCustomerLedgerEntry(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Due Date" := WorkDate();
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure CreateDummyReminder(var ReminderLine: Record "Reminder Line"; FinChargeTermsCode: Code[10]): Code[10]
    var
        ReminderHeader: Record "Reminder Header";
    begin
        ReminderHeader.Init();
        ReminderHeader."No." := LibraryUTUtility.GetNewCode();
        ReminderHeader."Customer No." := LibraryUTUtility.GetNewCode();
        ReminderHeader."Document Date" := WorkDate();
        ReminderHeader."Customer Posting Group" := LibraryUTUtility.GetNewCode10();
        ReminderHeader."Reminder Terms Code" := CreateReminderTerms();
        ReminderHeader."Fin. Charge Terms Code" := FinChargeTermsCode;
        ReminderHeader.Insert();

        ReminderLine.Init();
        ReminderLine."Reminder No." := ReminderHeader."No.";
        ReminderLine.Type := ReminderLine.Type::"Customer Ledger Entry";
        ReminderLine."Entry No." := CreateDummyCustomerLedgerEntry();
        ReminderLine."Due Date" := CalcDate('<-1D>', ReminderHeader."Document Date");  // Document Date greater than Due date required.
        ReminderLine."No. of Reminders" := 1;  // Number of Reminders 1 is required for first level.
        ReminderLine.Insert();
        exit(ReminderHeader."Reminder Terms Code");
    end;

    local procedure CreateReminder(var ReminderHeader: Record "Reminder Header"; Customer: Record Customer; Type: Enum "Reminder Source Type"; No: Code[20]; EntryNo: Integer): Code[20]
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderHeader.Init();
        ReminderHeader."No." := LibraryUTUtility.GetNewCode();
        ReminderHeader."Document Date" := WorkDate();
        ReminderHeader."Customer No." := Customer."No.";
        ReminderHeader."Customer Posting Group" := Customer."Customer Posting Group";
        ReminderHeader."Due Date" := ReminderHeader."Document Date";
        ReminderHeader."Post Additional Fee" := true;
        ReminderHeader."Posting Description" := ReminderHeader."No.";
        ReminderHeader."Reminder Terms Code" := CreateReminderTerms();
        ReminderHeader.Insert();
        ReminderLine.Init();
        ReminderLine."Reminder No." := ReminderHeader."No.";
        ReminderLine.Type := Type;
        ReminderLine."No." := No;
        ReminderLine.Amount := LibraryRandom.RandDec(10, 2);
        ReminderLine."Remaining Amount" := LibraryRandom.RandDec(10, 2);
        ReminderLine."VAT Prod. Posting Group" := CreateVATProductPostingGroup();
        ReminderLine."Entry No." := EntryNo;
        ReminderLine.Insert();
        exit(ReminderLine."No.");
    end;

    local procedure CreateReminderLevel(ReminderTermsCode: Code[10])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.Init();
        ReminderLevel."Reminder Terms Code" := ReminderTermsCode;
        ReminderLevel."No." := 1;  // Reminder Level 1 is required for first level.
        ReminderLevel."Calculate Interest" := true;
        ReminderLevel.Insert();
    end;

    local procedure CreateReminderTerms(): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        ReminderTerms.Init();
        ReminderTerms.Code := LibraryUTUtility.GetNewCode10();
        ReminderTerms.Insert();
        exit(ReminderTerms.Code);
    end;

    local procedure CreateVATProductPostingGroup(): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VATProductPostingGroup.Insert();
        CreateVATPostingSetup('', VATProductPostingGroup.Code);  // VAT Business Posting Group - Blank.
        exit(VATProductPostingGroup.Code);
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATPostingSetup."VAT Prod. Posting Group" := VATProdPostingGroup;
        VATPostingSetup.Insert();
    end;

    local procedure FindFinChargeMemoMIRLine(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; MemoNo: Code[20]; InterestRate: Decimal): Boolean
    begin
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", MemoNo);
        FinanceChargeMemoLine.SetRange("Detailed Interest Rates Entry", true);
        FinanceChargeMemoLine.SetRange("Interest Rate", InterestRate);
        exit(FinanceChargeMemoLine.FindFirst())
    end;

    local procedure InterestRateMethodFinanceChargeMemoLine(InterestCalculationMethod: Enum "Interest Calculation Method")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinChargeInterestRate: Record "Finance Charge Interest Rate";
        ExpectedInterestStatDate: Date;
    begin
        // Setup: Create Finance Charge Terms, Finance Charge Memo and Finance Charge Interest Rate.
        CreateFinanceChargeTermsWithCalcMethod(FinanceChargeTerms, InterestCalculationMethod);
        CreateDummyFinanceChargeMemo(FinanceChargeMemoLine, FinanceChargeTerms.Code);

        // Start Date greater than Due Date.
        CreateFinanceChargeInterestRates(
          FinChargeInterestRate, FinanceChargeTerms.Code,
          CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(2, 10)), FinanceChargeMemoLine."Due Date"));

        if InterestCalculationMethod = FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance" then begin
            CustLedgerEntry.Get(FinanceChargeMemoLine."Entry No.");
            ExpectedInterestStatDate := CalcDate('<+1D>', CustLedgerEntry."Due Date")
        end else begin
            FinanceChargeMemoHeader.Get(FinanceChargeMemoLine."Finance Charge Memo No.");
            ExpectedInterestStatDate := FinanceChargeMemoHeader."Document Date";
        end;

        // Exercise.
        asserterror FinanceChargeMemoLine.Validate("Interest Rate");

        // Verify: Verify error Code, Actual error message: Create interest rate with start date prior to Finance Charge Interest Rates - Start Date.
        Assert.ExpectedError(StrSubstNo(InvalidInterestRateDateErr, ExpectedInterestStatDate));
    end;

    local procedure InterestRateMethodReminderLine(InterestCalculationMethod: Enum "Interest Calculation Method")
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinChargeInterestRate: Record "Finance Charge Interest Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderTermsCode: Code[10];
        ExpectedInterestStatDate: Date;
    begin
        // Setup: Create Finance Charge Terms, Reminder, Reminder Level and Finance Charge Interest Rate.
        CreateFinanceChargeTermsWithCalcMethod(FinanceChargeTerms, InterestCalculationMethod);
        ReminderTermsCode := CreateDummyReminder(ReminderLine, FinanceChargeTerms.Code);
        CreateReminderLevel(ReminderTermsCode);

        // Start Date greater than Due Date.
        CreateFinanceChargeInterestRates(
          FinChargeInterestRate, FinanceChargeTerms.Code,
          CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(3, 10)), ReminderLine."Due Date"));

        if InterestCalculationMethod = FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance" then begin
            CustLedgerEntry.Get(ReminderLine."Entry No.");
            ExpectedInterestStatDate := CalcDate('<+1D>', CustLedgerEntry."Due Date")
        end else begin
            ReminderHeader.Get(ReminderLine."Reminder No.");
            ExpectedInterestStatDate := ReminderHeader."Document Date";
        end;

        // Exercise.
        asserterror ReminderLine.Validate("Interest Rate");

        // Verify: Verify error Code, Actual error message: Create interest rate with start date prior to Finance Charge Interest Rates - Start Date.
        Assert.ExpectedError(StrSubstNo(InvalidInterestRateDateErr, ExpectedInterestStatDate));
    end;

    local procedure InterestCalculationMethodFinanceChargeMemoLine(InterestCalculationMethod: Enum "Interest Calculation Method")
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        // Setup: Create Finance Charge Terms, Finance Charge Memo and Finance Charge Interest Rate.
        CreateFinanceChargeTermsWithCalcMethod(FinanceChargeTerms, InterestCalculationMethod);
        CreateDummyFinanceChargeMemo(FinanceChargeMemoLine, FinanceChargeTerms.Code);
        CreateFinanceChargeInterestRates(FinChargeInterestRate, FinanceChargeTerms.Code, WorkDate());

        // Exercise.
        FinanceChargeMemoLine.Validate("Interest Rate");

        // Verify: Verify Interest Rate with Finance Charge Interest Rate - Interest Rate.
        FinanceChargeMemoLine.TestField("Interest Rate", FinChargeInterestRate."Interest Rate");
    end;

    local procedure MakeLines2TermsDescriptionFinChrgMemoMake(Description: Text[100])
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinChrgMemoMake: Codeunit "FinChrgMemo-Make";
    begin
        // Setup: Create Customer, Reminder Level, Customer Ledger Entry, Detailed Customer Ledger Entry, and Finance Charge Memo Header. Execute Set function of Codeunit - FinChrgMemo-Make.
        CreateCustomer(Customer);
        UpdateFinanceChargeTermsDescription(FinanceChargeTerms, Customer."Fin. Charge Terms Code", Description);
        MockCustomerLedgerEntry(CustLedgerEntry, Customer."No.");
        FinanceChargeMemoHeader.Init();
        FinanceChargeMemoHeader."Document Date" := WorkDate();
        FinChrgMemoMake.Set(Customer, CustLedgerEntry, FinanceChargeMemoHeader);

        // Exercise: Execute function MakeReminder by function Code of Codeunit - FinChrgMemo-Make
        FinChrgMemoMake.Code();

        // Verify: Verify inserted Finance Charge Memo Line by function MakeLines2 of Codeunit - FinChrgMemo-Make
        VerifyFinanceChargeMemoLine(
          CustLedgerEntry, Description, FinanceChargeTerms."Line Description", FinanceChargeTerms."Interest Rate");
    end;

    local procedure MockCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry2.FindLast() then;
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Due Date" :=
          CalcDate(StrSubstNo('<-%1D>', LibraryRandom.RandIntInRange(1, 10)), CustLedgerEntry."Posting Date");  // Due Date Before Posting Date.
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Positive := true;
        CustLedgerEntry.Description := LibraryUTUtility.GetNewCode();
        CustLedgerEntry.Insert();
        MockDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.");
    end;

    local procedure MockDetailedCustomerLedgerEntry(CustLedgerEntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry2.FindLast();
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure OnRunTypeReminderIssue(Type: Enum "Reminder Source Type")
    var
        Customer: Record Customer;
        ReminderHeader: Record "Reminder Header";
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        // Setup: Create Customer and Reminder. Execute Set function of Codeunit - Reminder-Issue.
        CreateCustomer(Customer);
        CreateReminder(ReminderHeader, Customer, Type, '', 0);  // Reminder Line Number - Blank and Entry No - 0.
        ReminderIssue.Set(ReminderHeader, false, WorkDate());  // New Replace Posting Date - False and New Posting Date - WORKDATE.

        // Exercise: Execute OnRun Trigger of Codeunit - Reminder-Issue.
        asserterror LibraryERM.RunReminderIssue(ReminderIssue);
    end;

    local procedure OnRunTypeFinChrgMemoIssue(Type: Option)
    var
        Customer: Record Customer;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
    begin
        // Setup: Create Customer, Finance Charge Memo. Execute Set function of Codeunit - FinChrgMemo-Issue.
        CreateCustomer(Customer);
        CreateFinanceChargeMemo(FinanceChargeMemoHeader, Customer, Type, '', 0);  // Finance Charge Memo Line Number - Blank and Entry No - 0.
        FinChrgMemoIssue.Set(FinanceChargeMemoHeader, false, WorkDate());  // New Replace Posting Date - False and New Posting Date - WORKDATE.

        // Exercise: Execute Trigger - OnRun of Codeunit - FinChrgMemo-Issue.
        asserterror LibraryERM.RunFinChrgMemoIssue(FinChrgMemoIssue);
    end;

    local procedure PrepareGracePeriodScenario(var FinanceChargeTerms: Record "Finance Charge Terms"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var SalesInvoiceNo: Code[20]; var FinanceChargeInterestRate: Record "Finance Charge Interest Rate"; InterestStartDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        CreateFinChargeTermWithGracePeriod(FinanceChargeTerms);

        CreateFinanceChargeInterestRates(
          FinanceChargeInterestRate, FinanceChargeTerms.Code, InterestStartDate);

        SalesInvoiceNo :=
          CreateAndPostSalesInvoice(
            SalesHeader, FinanceChargeTerms.Code, CalcDate('<1D>', WorkDate()), CalcDate('<2D>', WorkDate()), LibraryRandom.RandInt(10));

        MIRHelperFunctions.CreateFinanceChargeMemo(
          FinanceChargeMemoHeader, SalesHeader."Sell-to Customer No.", CalcDate('<8D>', SalesHeader."Due Date"));
    end;

    local procedure SelectDescription(Description: Text[100]; LineDescription: Text[100]; CustLedgerEntryDescription: Text[100]): Text[100]
    begin
        if Description <> '' then
            exit(LineDescription);
        exit(CustLedgerEntryDescription);
    end;

    local procedure UpdateFinanceChargeTermsDescription(var FinanceChargeTerms: Record "Finance Charge Terms"; FinChargeTermsCode: Code[10]; Description: Text[100])
    begin
        FinanceChargeTerms.Get(FinChargeTermsCode);
        FinanceChargeTerms.Description := Description;
        FinanceChargeTerms."Line Description" := Description;
        FinanceChargeTerms.Modify();
    end;

    local procedure VerifyFinanceChargeMemoLine(CustLedgerEntry: Record "Cust. Ledger Entry"; Description: Text[100]; LineDescription: Text[100]; InterestRate: Decimal)
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        CustLedgerEntry.CalcFields("Remaining Amount");
        Amount := CustLedgerEntry."Remaining Amount" * InterestRate / 100;
        FinanceChargeMemoLine.SetRange("Entry No.", CustLedgerEntry."Entry No.");
        FinanceChargeMemoLine.FindFirst();
        FinanceChargeMemoLine.TestField(Type, FinanceChargeMemoLine.Type::"Customer Ledger Entry");
        Assert.AreNearlyEqual(Amount, FinanceChargeMemoLine.Amount, GeneralLedgerSetup."Amount Rounding Precision", ValueMustEqualMsg);
        Assert.AreEqual(
          SelectDescription(Description, LineDescription, CustLedgerEntry.Description), FinanceChargeMemoLine.Description,
          ValueMustEqualMsg);
    end;

    local procedure VerifyAdditionalFeeAndInterestAmtOnFinChargeMemo(FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; SalesHeader: Record "Sales Header")
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        // Call the Function to verify Interest Amount on Finance Charge Memo Lines.
        MIRHelperFunctions.VerifyIntAmtOnFinChargeMemo(FinanceChargeMemoHeader, SalesHeader);

        // Verify Description, Account Number and Additional Fee on Finance Charge Memo Lines.
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        FinanceChargeMemoLine.SetRange(Type, FinanceChargeMemoLine.Type::"G/L Account");
        FinanceChargeMemoLine.FindFirst();

        FinanceChargeTerms.Get(FinanceChargeMemoHeader."Fin. Charge Terms Code");
        CustomerPostingGroup.Get(FinanceChargeMemoHeader."Customer Posting Group");

        FinanceChargeMemoLine.TestField("No.", CustomerPostingGroup."Additional Fee Account");
        FinanceChargeMemoLine.TestField(Amount, FinanceChargeTerms."Additional Fee (LCY)");
        FinanceChargeMemoLine.TestField(Description, DescrOnFinChrgMemoLineTxt);
    end;

    local procedure VerifyChargeMemoMIRLine(FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeInterestRate: Record "Finance Charge Interest Rate"; SalesInvoiceNo: Code[20])
    begin
        VerifyChargeMemoMIRLineWithDaysOverdue(
          FinanceChargeMemoLine, FinanceChargeInterestRate, SalesInvoiceNo,
          FinanceChargeMemoHeader."Document Date" - FinanceChargeMemoLine."Due Date" + 1);
    end;

    local procedure VerifyChargeMemoMIRLineWithDaysOverdue(FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeInterestRate: Record "Finance Charge Interest Rate"; SalesInvoiceNo: Code[20]; DaysOverdue: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DueDateOnFinChrgLines: Date;
        InterestAmount: Decimal;
    begin
        GLSetup.Get();
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");

        DueDateOnFinChrgLines := CalcDate('<1D>', SalesInvoiceHeader."Due Date");
        if FinanceChargeInterestRate."Start Date" > DueDateOnFinChrgLines then
            DueDateOnFinChrgLines := FinanceChargeInterestRate."Start Date";

        InterestAmount := Round(
            FinanceChargeMemoLine."Remaining Amount" * (DaysOverdue / FinanceChargeInterestRate."Interest Period (Days)") *
            (FinanceChargeMemoLine."Interest Rate" / 100), GLSetup."Amount Rounding Precision");

        FinanceChargeMemoLine.TestField("Due Date", DueDateOnFinChrgLines);
        FinanceChargeMemoLine.TestField("Remaining Amount", CustLedgerEntry."Remaining Amount");
        FinanceChargeMemoLine.TestField("Posting Date", SalesInvoiceHeader."Posting Date");
        FinanceChargeMemoLine.TestField(Amount, InterestAmount);
    end;

    local procedure VerifyReminderFinanceChargeEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; Type: Option; No: Code[20]; DueDate: Date)
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
    begin
        ReminderFinChargeEntry.SetRange(Type, Type);
        ReminderFinChargeEntry.SetRange("No.", No);
        ReminderFinChargeEntry.FindFirst();
        ReminderFinChargeEntry.TestField("Customer Entry No.", CustLedgerEntry."Entry No.");
        ReminderFinChargeEntry.TestField("Customer No.", CustLedgerEntry."Customer No.");
        ReminderFinChargeEntry.TestField("Due Date", DueDate);
    end;

    local procedure VerifyGLEntry(GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; SourceNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"G/L Account");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Document Type", DocumentType);
        GLEntry.TestField("Document No.", DocumentNo);
        GLEntry.TestField("Source No.", SourceNo);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;
}

