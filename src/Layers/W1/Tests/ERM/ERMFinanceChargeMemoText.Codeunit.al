codeunit 134906 "ERM Finance Charge Memo Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Finance Charge Memo]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFinanceChargeMemo: Codeunit "Library - Finance Charge Memo";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        BeginningTextNew: Label 'Posting Date must be %1.';
        EndingTextNew: Label 'Please pay the total of %1.';
        PrecisionText: Label '<Precision,%1><Standard format,0>', Locked = true;
        DescriptionError: Label 'Wrong Description updated in Finance Charge Memo Line.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Finance Charge Memo Text");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Finance Charge Memo Text");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Finance Charge Memo Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoDescription()
    var
        Customer: Record Customer;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        DocumentDate: Date;
        Description: Text[100];
        EndingText: Text[100];
        PostedDocumentNo: Code[20];
    begin
        // Check Line Description, Beginning Text and Ending Text after suggesting Lines for a Finance Charge Memo.

        // Setup: Create Finance Charge Terms with Beginning and Ending Texts, update it on Customer. Create and Post Sales Invoice.
        Initialize();
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        CreateCustomer(Customer, FinanceChargeTerms.Code, CreateCurrency());
        PostedDocumentNo := CreateAndPostSalesInvoice(Customer."No.");
        LibraryFinanceChargeMemo.ComputeDescription(FinanceChargeTerms, Description, DocumentDate, PostedDocumentNo);

        // Exercise: Create Finance Charge Memo and Suggest Lines for Customer on Calculated Document Date.
        CreateSuggestFinanceChargeMemo(FinanceChargeMemoHeader, Customer."No.", DocumentDate);
        EndingText := ComputeEndingText(FinanceChargeMemoHeader."No.", Customer."Currency Code");

        // Verify: Verify Finance Charge Memo Line Description, Beginning and Ending Text.
        VerifyLineDescription(FinanceChargeMemoHeader."No.", Description);
        VerifyBeginningEndingText(
          FinanceChargeMemoHeader."No.", StrSubstNo(BeginningTextNew, FinanceChargeMemoHeader."Posting Date"),
          FinanceChargeMemoLine."Line Type"::"Beginning Text");
        VerifyBeginningEndingText(FinanceChargeMemoHeader."No.", EndingText, FinanceChargeMemoLine."Line Type"::"Ending Text");

        // Tear Down: Delete the earlier created Finance Charge Memo and Finance Charge Terms.
        FinanceChargeMemoHeader.Find();
        FinanceChargeMemoHeader.Delete(true);
        FinanceChargeTerms.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoFromRefund()
    var
        Customer: Record Customer;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        Amount: Decimal;
        CalculatedAmount: Decimal;
    begin
        // Test Finance Charge Memo Lines after Suggesting Lines for Finance Charge Memo.

        // 1. Setup: Create Finance Charge Terms, Create Customer, Create and Post General Journal Line for Refund.
        Initialize();
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        CreateCustomer(Customer, FinanceChargeTerms.Code, '');
        Amount := CreateAndPostGeneralJournal(Customer."No.");

        // 2. Exercise: Create Finance Charge Memo Header and Suggest Lines.
        CreateSuggestFinanceChargeMemo(
          FinanceChargeMemoHeader, Customer."No.",
          CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'Y>', CalcDate(FinanceChargeTerms."Due Date Calculation", WorkDate())));
        CalculatedAmount :=
          Round(Amount * (FinanceChargeMemoHeader."Document Date" - WorkDate()) /
            FinanceChargeTerms."Interest Period (Days)" * FinanceChargeTerms."Interest Rate" / 100);

        // 3. Verify: Verify Finance Charge Memo Lines.
        VerifyFinanceChargeMemoLine(
          FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::"Customer Ledger Entry", Amount, CalculatedAmount);
        VerifyFinanceChargeMemoLine(
          FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::"G/L Account", 0, FinanceChargeTerms."Additional Fee (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssuedFinanceChargeMemo()
    var
        Customer: Record Customer;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        Amount: Decimal;
        CalculatedAmount: Decimal;
    begin
        // Test Issued Finance Charge Memo Lines after Issuing Finance Charge Memo.

        // 1. Setup: Create Finance Charge Terms, Create Customer, Create and Post General Journal Line for Refund, Create Finance Charge
        // Memo Header and Suggest Lines.
        Initialize();
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        CreateCustomer(Customer, FinanceChargeTerms.Code, '');
        Amount := CreateAndPostGeneralJournal(Customer."No.");
        CreateSuggestFinanceChargeMemo(
          FinanceChargeMemoHeader, Customer."No.",
          CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'Y>', CalcDate(FinanceChargeTerms."Due Date Calculation", WorkDate())));
        CalculatedAmount :=
          Round(Amount * (FinanceChargeMemoHeader."Document Date" - WorkDate()) /
            FinanceChargeTerms."Interest Period (Days)" * FinanceChargeTerms."Interest Rate" / 100);

        // 2. Exercise: Issue Finance Charge Memo.
        IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No.");

        // 3. Verify: Verify Issued Finance Charge Memo Lines.
        IssuedFinChargeMemoHeader.SetRange("Pre-Assigned No.", FinanceChargeMemoHeader."No.");
        IssuedFinChargeMemoHeader.FindFirst();
        VerifyIssuedChargeMemoLine(
          IssuedFinChargeMemoHeader."No.", IssuedFinChargeMemoLine.Type::"Customer Ledger Entry", Amount, CalculatedAmount);
        VerifyIssuedChargeMemoLine(
          IssuedFinChargeMemoHeader."No.", IssuedFinChargeMemoLine.Type::"G/L Account", 0, FinanceChargeTerms."Additional Fee (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFinanceChargeTermsFiveDecimalPlaces();
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeTerms_page: TestPage "Finance Charge Terms";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 337388] Finance Charge Terms has five decimal places

        // [GIVEN]  Created Finance Charge Terms
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);

        // [GIVEN] Page "Finance Charge Terms" was opened
        FinanceChargeTerms_page.Openedit();
        FinanceChargeTerms_page.Filter.Setfilter(Code, FinanceChargeTerms.Code);
        FinanceChargeTerms_page.First();

        // [WHEN] Set value with 5 decimal places.
        FinanceChargeTerms_page."Interest Rate".Setvalue(9.12345);

        // [THEN] The value was set
        FinanceChargeTerms_page."Interest Rate".Assertequals(9.12345);
    end;

    local procedure ComputeEndingText(FinanceChargeMemoNo: Code[20]; CurrencyCode: Code[10]): Text[100]
    var
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        Currency: Record Currency;
        FinChrgMemoTotal: Decimal;
    begin
        // To fetch the Decimal Places from the computed Amount, used Format with Currency Decimal Precision.
        Currency.Get(CurrencyCode);

        FinChrgMemoHeader.Get(FinanceChargeMemoNo);
        FinChrgMemoHeader.CalcFields(
          "Remaining Amount", "Interest Amount", "Additional Fee", "VAT Amount");
        FinChrgMemoTotal :=
          FinChrgMemoHeader."Remaining Amount" + FinChrgMemoHeader."Interest Amount" +
          FinChrgMemoHeader."Additional Fee" + FinChrgMemoHeader."VAT Amount";

        exit(
          StrSubstNo(EndingTextNew, Format(FinChrgMemoTotal, 0, StrSubstNo(PrecisionText, Currency."Amount Decimal Places"))));
    end;

    local procedure CreateAndPostGeneralJournal(AccountNo: Code[20]): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalBatch(GenJournalBatch);

        // Use Random because value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, AccountNo, LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine.Amount);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Take Random Quantity for Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; FinChargeTermsCode: Code[10]; CurrencyCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Fin. Charge Terms Code", FinChargeTermsCode);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Create an Item with Random Unit Price. Take Amount more than 2000 so that Finance Charge Memo Amount can be generated.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", 2000 + LibraryRandom.RandInt(100));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSuggestFinanceChargeMemo(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; CustomerNo: Code[20]; DocumentDate: Date)
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CustomerNo);
        FinanceChargeMemoHeader.Validate("Document Date", DocumentDate);
        FinanceChargeMemoHeader.Modify(true);
        SuggestFinanceChargeMemoLines(FinanceChargeMemoHeader);
    end;

    local procedure FindFinanceChargeMemoLine(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeMemoNo: Code[20]; Type: Option)
    begin
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoNo);
        FinanceChargeMemoLine.SetRange(Type, Type);
        FinanceChargeMemoLine.FindFirst();
    end;

    local procedure GetLineDescription(FinanceChargeMemoNo: Code[20]; LineType: Option): Text[100]
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoNo);
        FinanceChargeMemoLine.SetRange("Line Type", LineType);
        FinanceChargeMemoLine.SetFilter(Description, '<>''''');
        FinanceChargeMemoLine.FindFirst();
        exit(FinanceChargeMemoLine.Description);
    end;

    local procedure IssuingFinanceChargeMemos(FinanceChargeMemoHeaderNo: Code[20])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        FinanceChargeMemoHeader.Get(FinanceChargeMemoHeaderNo);
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);
    end;

    local procedure SuggestFinanceChargeMemoLines(FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        SuggestFinChargeMemoLines: Report "Suggest Fin. Charge Memo Lines";
    begin
        FinanceChargeMemoHeader.SetRange("No.", FinanceChargeMemoHeader."No.");
        SuggestFinChargeMemoLines.SetTableView(FinanceChargeMemoHeader);
        SuggestFinChargeMemoLines.UseRequestPage(false);
        SuggestFinChargeMemoLines.Run();
    end;

    local procedure VerifyLineDescription(FinanceChargeMemoNo: Code[20]; Description: Text[100])
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoNo);
        FinanceChargeMemoLine.SetRange(Type, FinanceChargeMemoLine.Type::"Customer Ledger Entry");
        FinanceChargeMemoLine.FindFirst();
        Assert.AreEqual(Description, FinanceChargeMemoLine.Description, DescriptionError);
    end;

    local procedure VerifyBeginningEndingText(FinanceChargeMemoHeaderNo: Code[20]; ExpectedText: Text[100]; LineType: Option)
    begin
        Assert.AreEqual(ExpectedText, GetLineDescription(FinanceChargeMemoHeaderNo, LineType), DescriptionError);
    end;

    local procedure VerifyFinanceChargeMemoLine(FinanceChargeMemoNo: Code[20]; Type: Option; RemainingAmount: Decimal; Amount: Decimal)
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FindFinanceChargeMemoLine(FinanceChargeMemoLine, FinanceChargeMemoNo, Type);
        FinanceChargeMemoLine.TestField("Remaining Amount", RemainingAmount);
        FinanceChargeMemoLine.TestField(Amount, Amount);
    end;

    local procedure VerifyIssuedChargeMemoLine(FinanceChargeMemoNo: Code[20]; Type: Option; RemainingAmount: Decimal; Amount: Decimal)
    var
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoNo);
        IssuedFinChargeMemoLine.SetRange(Type, Type);
        IssuedFinChargeMemoLine.FindFirst();
        IssuedFinChargeMemoLine.TestField("Remaining Amount", RemainingAmount);
        IssuedFinChargeMemoLine.TestField(Amount, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssueAndCancelFinChargeMemoWithInvRoundingAndWithoutAdditionalFeePosting()
    var
        Customer: Record Customer;
        FinanceChargeTerm: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        CancelIssuedFinChargeMemo: Codeunit "Cancel Issued Fin. Charge Memo";
    begin
        // [SCENARIO 450977] Issue Finance Charge Memo with Invoice Rounding and Cancel it.
        Initialize();

        // [GIVEN] Invoice Rounding Precision =1 in G/L Setup        
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", 1.00);
        GeneralLedgerSetup.Modify();

        // [GIVEN] Finance Charge Term with Interest Rate 5 and Minimum Amount (LCY)=10 and Post Additional Fee = false
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerm);
        FinanceChargeTerm."Minimum Amount (LCY)" := 10;
        FinanceChargeTerm."Interest Rate" := 5;
        FinanceChargeTerm."Post Interest" := true;
        FinanceChargeTerm."Post Additional Fee" := false;
        FinanceChargeTerm.Modify();

        // [GIVEN] Customer and Customer Ledger Entries
        CreateCustomer(Customer, FinanceChargeTerm.Code, '');
        CreateAndPostGenJournalLine(Customer."No.", Customer."Currency Code", LibraryRandom.RandDec(1000, 2));
        CreateAndPostGenJournalLine(Customer."No.", Customer."Currency Code", LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Created Fin. Charge Memo Header and generated lines
        CreateSuggestFinanceChargeMemo(FinanceChargeMemoHeader, Customer."No.",
                  CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'Y>',
                  CalcDate(FinanceChargeTerm."Due Date Calculation", WorkDate())));

        // [GIVEN] Issue Finance Charge Memo.
        IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No.");
        IssuedFinChargeMemoHeader.SetRange("Customer No.", FinanceChargeMemoHeader."Customer No.");
        IssuedFinChargeMemoHeader.SetRange("Pre-Assigned No.", FinanceChargeMemoHeader."No.");
        IssuedFinChargeMemoHeader.FindLast();

        // [WHEN] Issue Finance Charge Memo is canceled
        CancelIssuedFinChargeMemo.SetParameters(true, false, WorkDate(), false);
        CancelIssuedFinChargeMemo.Run(IssuedFinChargeMemoHeader);

        // [THEN] Remaining amount on all Cust. Ledger Entries should be 0
        CheckCustLedgerEntriesForIssuedFinancedChargeMemo(IssuedFinChargeMemoHeader);
    end;

    local procedure CreateAndPostGenJournalLine(CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CheckCustLedgerEntriesForIssuedFinancedChargeMemo(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetCurrentKey("Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetRange("Customer No.", IssuedFinChargeMemoHeader."Customer No.");
        CustLedgerEntry.SetRange("Document No.", IssuedFinChargeMemoHeader."No.");
        CustLedgerEntry.SetFilter("Remaining Amount", '<>0');
        Assert.IsTrue(CustLedgerEntry.IsEmpty, 'Canceled Issued Fin. Charge Memo - Exist Remaining Amount on CLE');
    end;
}

