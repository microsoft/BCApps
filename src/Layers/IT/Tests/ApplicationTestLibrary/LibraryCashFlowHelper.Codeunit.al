/// <summary>
/// Provides helper functions for filling and managing cash flow journal entries in test scenarios.
/// </summary>
codeunit 131332 "Library - Cash Flow Helper"
{

    Subtype = Normal;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryCashFlowForecast: Codeunit "Library - Cash Flow";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFA: Codeunit "Library - Fixed Asset";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        DocumentType: Option Sale,Purchase,Service;
        UnhandledDocumentType: Label 'Unhandled document type.';
        UnexpectedCFAmount: Label 'Unexpected cash flow amount.';
        UnexpectedCFDate: Label 'Unexpected cash flow date in Document No. %1.';

    procedure AddAndPostSOPrepaymentInvoice(var SalesHeader: Record "Sales Header"; PrepaymentPercentage: Decimal) PrepmtInvNo: Code[20]
    begin
        AddSOPrepayment(SalesHeader, PrepaymentPercentage);
        PrepmtInvNo := PostSOPrepaymentInvoice(SalesHeader);
    end;

    procedure AddSOPrepayment(var SalesHeader: Record "Sales Header"; PrepaymentPercentage: Decimal)
    begin
        SalesHeader.Validate("Prepayment %", PrepaymentPercentage);
        SalesHeader.Modify(true);
    end;

    procedure PostSOPrepaymentInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.Invoice(SalesHeader);
        exit(SalesHeader."Last Prepayment No.");
    end;

    procedure AddAndPostPOPrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"; PrepaymentPercentage: Decimal; var CheckTotalAmount: Decimal) PrepmtInvNo: Code[20]
    begin
        AddPOPrepayment(PurchaseHeader, PrepaymentPercentage);
        ValidatePOCheckTotal(PurchaseHeader, CheckTotalAmount);
        PrepmtInvNo := PostPOPrepaymentInvoice(PurchaseHeader);
    end;

    procedure AddPOPrepayment(var PurchaseHeader: Record "Purchase Header"; PrepaymentPercentage: Decimal)
    begin
        PurchaseHeader.Validate("Prepayment %", PrepaymentPercentage);
        PurchaseHeader.Modify(true);
    end;

    procedure ValidatePOCheckTotal(var PurchaseHeader: Record "Purchase Header"; var CheckTotalAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        // IT requires the prepayment amount in the Purchase Header Check Total field
        PurchaseHeader.Validate("Check Total",
          Round(GetTotalPurchasePrepaymentAmount(PurchaseHeader), GeneralLedgerSetup."Amount Rounding Precision"));
        CheckTotalAmount := PurchaseHeader."Check Total";
        PurchaseHeader.Modify(true);
    end;

    procedure PostPOPrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        exit(PurchaseHeader."Last Prepayment No.");
    end;

    procedure AssignPaymentTermToCustomer(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        // An empty payment terms code creates a default payment term code
        Customer.Validate("Payment Terms Code", GetPaymentTermsCode(PaymentTermsCode));
        Customer.Modify(true);
    end;

    procedure AssignPaymentTermToVendor(var Vendor: Record Vendor; PaymentTermsCode: Code[10])
    begin
        // An empty payment terms code creates a default payment term code
        Vendor.Validate("Payment Terms Code", GetPaymentTermsCode(PaymentTermsCode));
        Vendor.Modify(true);
    end;

    procedure ApplyInvoicePayment(var GenJournalLine: Record "Gen. Journal Line"; PartnerNo: Code[20]; PartnerAccountType: Enum "Gen. Journal Account Type"; InvoiceNoToApply: Code[20]; AmountToApply: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectAndClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          PartnerAccountType, PartnerNo, AmountToApply);
        // GenJournalLine.VALIDATE("Posting Date",PaymentDate);
        // GenJournalLine.VALIDATE("Document Date",PaymentDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNoToApply);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    procedure CalcDiscAmtFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line"; DiscountPercentage: Decimal): Decimal
    begin
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor then
            GenJnlLine.Amount := -GenJnlLine.Amount;
        exit(CalculateDiscountAmount(GenJnlLine.Amount, DiscountPercentage));
    end;

    procedure CalcCustDiscAmtLCY(CustLedgEntry: Record "Cust. Ledger Entry"; DiscountPercentage: Decimal; ExchRateAmount: Decimal): Decimal
    begin
        exit(
          Round(CalcCustDiscAmt(CustLedgEntry, DiscountPercentage) * ExchRateAmount, LibraryERM.GetAmountRoundingPrecision()));
    end;

    procedure CalcVendDiscAmtLCY(VendLedgEntry: Record "Vendor Ledger Entry"; DiscountPercentage: Decimal; ExchRateAmount: Decimal): Decimal
    begin
        exit(
          Round(CalcVendDiscAmt(VendLedgEntry, DiscountPercentage) * ExchRateAmount, LibraryERM.GetAmountRoundingPrecision()));
    end;

    procedure CalcCustDiscAmt(CustLedgEntry: Record "Cust. Ledger Entry"; DiscountPercentage: Decimal): Decimal
    begin
        exit(
          Round(CustLedgEntry.Amount * DiscountPercentage / 100, LibraryERM.GetAmountRoundingPrecision()));
    end;

    procedure CalcVendDiscAmt(VendLedgEntry: Record "Vendor Ledger Entry"; DiscountPercentage: Decimal): Decimal
    begin
        exit(
          Round(VendLedgEntry.Amount * DiscountPercentage / 100, LibraryERM.GetAmountRoundingPrecision()));
    end;

    procedure CalcSalesExpectedPrepmtAmounts(SalesHeader: Record "Sales Header"; DiscountPercentage: Decimal; var ExpectedOrderAmount: Decimal; var ExpectedPrePmtAmount: Decimal)
    var
        TotalOrderAmount: Decimal;
    begin
        TotalOrderAmount := GetTotalSalesAmount(SalesHeader, false);
        ExpectedPrePmtAmount := Round(TotalOrderAmount / 100 * SalesHeader."Prepayment %");
        ExpectedOrderAmount := TotalOrderAmount - ExpectedPrePmtAmount;
        if DiscountPercentage > 0 then begin
            ExpectedOrderAmount -= CalculateDiscountAmount(ExpectedOrderAmount, DiscountPercentage);
            ExpectedPrePmtAmount -= CalculateDiscountAmount(ExpectedPrePmtAmount, DiscountPercentage);
        end;
    end;

    procedure CalcPurchExpectedPrepmtAmounts(PurchaseHeader: Record "Purchase Header"; DiscountPercentage: Decimal; var ExpectedOrderAmount: Decimal; var ExpectedPrePmtAmount: Decimal)
    var
        TotalOrderAmount: Decimal;
    begin
        TotalOrderAmount := GetTotalPurchaseAmount(PurchaseHeader, false);
        ExpectedPrePmtAmount := Round(TotalOrderAmount / 100 * PurchaseHeader."Prepayment %");
        ExpectedOrderAmount := TotalOrderAmount - ExpectedPrePmtAmount;
        if DiscountPercentage > 0 then begin
            ExpectedOrderAmount -= CalculateDiscountAmount(ExpectedOrderAmount, DiscountPercentage);
            ExpectedPrePmtAmount -= CalculateDiscountAmount(ExpectedPrePmtAmount, DiscountPercentage);
        end;
    end;

    procedure CalculateDiscountAmount(Amount: Decimal; DiscountPercentage: Decimal): Decimal
    begin
        exit(Round(Amount / 100 * DiscountPercentage, LibraryERM.GetAmountRoundingPrecision()));
    end;

    procedure ChangeWorkdateByDateFormula(BaseDateFormula: DateFormula; CustomDateFormula: DateFormula; AdditionalDateFormula: DateFormula) OldWorkDate: Date
    begin
        OldWorkDate := ChangeWorkdate(GenerateDateFromFormulas(WorkDate(), BaseDateFormula, AdditionalDateFormula, CustomDateFormula));
    end;

    procedure ChangeWorkdate(NewWorkDate: Date) OldWorkDate: Date
    begin
        OldWorkDate := WorkDate();
        WorkDate := NewWorkDate;
    end;

    procedure CreateLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; PartnerNo: Code[20]; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectAndClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, PartnerNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    procedure CreateAndApplySalesInvPayment(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; SalesInvoiceAmount: Decimal; AmountToApply: Decimal; DateFormula1: DateFormula; DateFormula2: DateFormula; DateFormula3: DateFormula)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentDate: Date;
    begin
        PaymentDate := GenerateDateFromFormulas(WorkDate(), DateFormula1, DateFormula2, DateFormula3);
        SelectAndClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, SalesInvoiceAmount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, AmountToApply);
        GenJournalLine.Validate("Posting Date", PaymentDate);
        GenJournalLine.Validate("Document Date", PaymentDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    procedure CreateAndApplyVendorInvPmt(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; InvoiceAmount: Decimal; AmountToApply: Decimal; DateFormula1: DateFormula; DateFormula2: DateFormula; DateFormula3: DateFormula)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentDate: Date;
    begin
        PaymentDate := GenerateDateFromFormulas(WorkDate(), DateFormula1, DateFormula2, DateFormula3);
        SelectAndClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, InvoiceAmount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, AmountToApply);
        GenJournalLine.Validate("Posting Date", PaymentDate);
        GenJournalLine.Validate("Document Date", PaymentDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    procedure CreateBudgetEntry(var GLBudgetEntry: Record "G/L Budget Entry"; BudgetDate: Date)
    var
        GLBudgetName: Record "G/L Budget Name";
        GLAccount: Record "G/L Account";
        CFAccount: Record "Cash Flow Account";
    begin
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        FindCFBudgetAccount(CFAccount);
        FindFirstGLAccFromCFAcc(GLAccount, CFAccount);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, BudgetDate, GLAccount."No.", GLBudgetName.Name);
        GLBudgetEntry.Validate(Amount, LibraryRandom.RandDec(100, 2));
        GLBudgetEntry.Modify(true);
    end;

    procedure CreateDefaultPaymentTerms(var PaymentTerms: Record "Payment Terms")
    var
        PaymentLines: Record "Payment Lines";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.GetPaymentLines(PaymentLines, PaymentTerms.Code);
        Evaluate(PaymentLines."Due Date Calculation", '<0D>');
        Evaluate(PaymentLines."Discount Date Calculation", '<0D>');
        PaymentLines.Validate("Discount %", 0);
        PaymentLines.Modify(true);
    end;

    procedure CreateCustWithDsctPmtTerm(var Customer: Record Customer; var PaymentTerms: Record "Payment Terms")
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        AssignPaymentTermToCustomer(Customer, PaymentTerms.Code);
    end;

    procedure CreateVendorWithDsctPmtTerm(var Vendor: Record Vendor; var PaymentTerms: Record "Payment Terms")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        AssignPaymentTermToVendor(Vendor, PaymentTerms.Code);
    end;

    procedure CreateFixedAssetForInvestment(var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; FAPostingDateFormula: DateFormula; InvestmentAmount: Decimal)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        LibraryFA.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("Budgeted Asset", true);
        FixedAsset.Modify(true);
        LibraryFA.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBookCode);
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFA.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFA.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        FAJournalBatch.Modify(true);
        LibraryFA.CreateFAJournalLine(FAJournalLine, FAJournalTemplate.Name, FAJournalBatch.Name);
        FAJournalLine."Document Type" := FAJournalLine."Document Type"::Invoice;
        NoSeries.Get(FAJournalBatch."No. Series");
        FAJournalLine.Validate("Document No.", NoSeriesCodeunit.PeekNextNo(FAJournalBatch."No. Series"));
        FAJournalLine.Validate("FA No.", FixedAsset."No.");
        FAJournalLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FAJournalLine.Validate(Amount, InvestmentAmount);
        FAJournalLine.Validate("FA Posting Date", CalcDate(FAPostingDateFormula, WorkDate()));
        FAJournalLine.Modify(true);
        LibraryFA.PostFAJournalLine(FAJournalLine);
    end;

    procedure CreateFixedAssetForDisposal(var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; DepreciationStartDateFormula: DateFormula; DepreciationEndDateFormula: DateFormula; DisposalDateFormula: DateFormula; ExpDisposalAmount: Decimal)
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFA.CreateFixedAsset(FixedAsset);
        LibraryFA.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBookCode);
        FADepreciationBook."Depreciation Starting Date" := CalcDate(DepreciationStartDateFormula, WorkDate());
        FADepreciationBook."Depreciation Ending Date" := CalcDate(DepreciationEndDateFormula, WorkDate());
        FADepreciationBook."Projected Disposal Date" := CalcDate(DisposalDateFormula, WorkDate());
        FADepreciationBook."Projected Proceeds on Disposal" := ExpDisposalAmount;
        FADepreciationBook.Modify(true);
    end;

    procedure CreateManualPayment(var CFManualExpense: Record "Cash Flow Manual Expense")
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        LibraryCashFlowForecast.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        LibraryCashFlowForecast.CreateManualLinePayment(CFManualExpense, CashFlowAccount."No.");

        Evaluate(CFManualExpense."Recurring Frequency", '<1D>');

        CFManualExpense.Validate(Amount, LibraryRandom.RandInt(500));
        CFManualExpense.Modify(true);
    end;

    procedure CreateManualRevenue(var CFManualRevenue: Record "Cash Flow Manual Revenue")
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        LibraryCashFlowForecast.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        LibraryCashFlowForecast.CreateManualLineRevenue(CFManualRevenue, CashFlowAccount."No.");

        Evaluate(CFManualRevenue."Recurring Frequency", '<1D>');

        CFManualRevenue.Validate(Amount, LibraryRandom.RandInt(500));
        CFManualRevenue.Modify(true);
    end;

    procedure CreateRandomDateFormula(var ResultDateFormula: DateFormula)
    begin
        Evaluate(ResultDateFormula, StrSubstNo('<%1D>', LibraryRandom.RandInt(5)));
    end;

    procedure CreateSpecificCashFlowCard(var CashFlowForecast: Record "Cash Flow Forecast"; ConsiderDiscount: Boolean)
    begin
        LibraryCashFlowForecast.CreateCashFlowCard(CashFlowForecast);
        CashFlowForecast."Manual Payments To" := CashFlowForecast."Manual Payments From";
        CashFlowForecast.Validate("Consider Discount", ConsiderDiscount);
        CashFlowForecast.Modify(true);
    end;

    procedure CreateCashFlowForecastDefault(var CashFlowForecast: Record "Cash Flow Forecast")
    begin
        CreateSpecificCashFlowCard(CashFlowForecast, false);
    end;

    procedure CreateCashFlowForecastConsiderDiscount(var CashFlowForecast: Record "Cash Flow Forecast")
    begin
        CreateSpecificCashFlowCard(CashFlowForecast, true);
    end;

    procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; GLAccount: Record "G/L Account"; PaymentTermsCode: Code[10])
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DueDateCalculation: DateFormula;
        DiscountDateCalculation: DateFormula;
    begin
        Customer.Get(
          LibrarySales.CreateCustomerWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group"));
        AssignPaymentTermToCustomer(Customer, PaymentTermsCode);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        // IT requires a value in the sales header Prepayment Due Date field
        if PaymentTermsCode <> '' then begin
            PaymentTerms.Get(PaymentTermsCode);
            GetPmtTermsDueDateCalculation(DueDateCalculation, PaymentTerms);
            GetPmtTermsDiscountDateCalculation(DiscountDateCalculation, PaymentTerms);
            SalesHeader.Validate("Prepayment Due Date", CalcDate(DueDateCalculation, SalesHeader."Document Date"));
            SalesHeader.Validate("Prepmt. Payment Discount %", GetPmtTermsDiscountPercentage(PaymentTerms));
            SalesHeader.Validate("Prepmt. Pmt. Discount Date", CalcDate(DiscountDateCalculation, SalesHeader."Document Date"));
        end else
            SalesHeader."Prepayment Due Date" := SalesHeader."Document Date";
        SalesHeader.Modify(true);

        CreateSalesLine(SalesHeader, GLAccount);
        CreateSalesLine(SalesHeader, GLAccount);
        CreateSalesLine(SalesHeader, GLAccount);
    end;

    procedure CreateSpecificSalesOrder(var SalesHeader: Record "Sales Header"; PaymentTermsCode: Code[10])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CreateSalesOrder(SalesHeader, GLAccount, PaymentTermsCode);
    end;

    procedure CreateDefaultSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        CreateSpecificSalesOrder(SalesHeader, '');
    end;

    procedure CreatePrepmtSalesOrder(var SalesHeader: Record "Sales Header"; PaymentTermsCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreatePrepaymentVATSetup(GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesOrder(SalesHeader, GLAccount, PaymentTermsCode);
    end;

    procedure CreateSalesLine(SalesHeader: Record "Sales Header"; GLAccount: Record "G/L Account")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := GLAccount."No.";
        if GLAccountNo = '' then begin
            VATPostingSetup.SetRange("VAT Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
            VATPostingSetup.SetFilter("VAT Calculation Type", '<>%1', VATPostingSetup."VAT Calculation Type"::"Full VAT");
            VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
            VATPostingSetup.FindFirst();
            GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        end;
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
    end;

    procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; GLAccount: Record "G/L Account"; PaymentTermsCode: Code[10])
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DueDateCalculation: DateFormula;
        DiscountDateCalculation: DateFormula;
    begin
        Vendor.Get(
          LibraryPurchase.CreateVendorWithBusPostingGroups(
            GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group"));
        AssignPaymentTermToVendor(Vendor, PaymentTermsCode);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        // IT requires a value in the sales header Prepayment Due Date field
        if PaymentTermsCode <> '' then begin
            PaymentTerms.Get(PaymentTermsCode);
            GetPmtTermsDueDateCalculation(DueDateCalculation, PaymentTerms);
            GetPmtTermsDiscountDateCalculation(DiscountDateCalculation, PaymentTerms);
            PurchaseHeader.Validate("Prepayment Due Date", CalcDate(DueDateCalculation, PurchaseHeader."Document Date"));
            PurchaseHeader.Validate("Prepmt. Payment Discount %", GetPmtTermsDiscountPercentage(PaymentTerms)); // default is 0
            PurchaseHeader.Validate("Prepmt. Pmt. Discount Date", CalcDate(DiscountDateCalculation, PurchaseHeader."Document Date"));
        end else
            PurchaseHeader."Prepayment Due Date" := PurchaseHeader."Document Date";
        PurchaseHeader.Validate("Due Date", CalcDate(DueDateCalculation, PurchaseHeader."Prepayment Due Date"));
        PurchaseHeader.Modify(true);

        CreatePurchaseLine(PurchaseHeader, GLAccount);
        CreatePurchaseLine(PurchaseHeader, GLAccount);
        CreatePurchaseLine(PurchaseHeader, GLAccount);
    end;

    procedure CreateSpecificPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; PaymentTermsCode: Code[10])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        CreatePurchaseOrder(PurchaseHeader, GLAccount, PaymentTermsCode);
    end;

    procedure CreateDefaultPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        CreateSpecificPurchaseOrder(PurchaseHeader, '');
    end;

    procedure CreatePrepmtPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; PaymentTermsCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseOrder(PurchaseHeader, GLAccount, PaymentTermsCode);
    end;

    procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; GLAccount: Record "G/L Account")
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
        Handled: Boolean;
    begin
        OnBeforeCreatePurchaseLine(PurchaseHeader, GLAccount, Handled);
        if Handled then
            exit;

        GLAccountNo := GLAccount."No.";
        if GLAccountNo = '' then begin
            LibraryERM.CreateVATPostingSetupWithAccounts(
              VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));
            VATPostingSetup."VAT Bus. Posting Group" := PurchaseHeader."VAT Bus. Posting Group";
            VATPostingSetup.Insert();
            GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        end;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);

        OnAfterCreatePurchaseLine(PurchaseHeader, GLAccount);
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Library Service', '27.0')]
    procedure CreateSpecificServiceOrder(var ServiceHeader: Record "Service Header"; PaymentTermsCode: Code[10])
    var
        LibraryService: Codeunit "Library - Service";
    begin
        LibraryService.CreateSpecificServiceOrder(ServiceHeader, PaymentTermsCode);
    end;
#endif

#if not CLEAN27
    [Obsolete('Moved to codeunit Library Service', '27.0')]
    procedure CreateDefaultServiceOrder(var ServiceHeader: Record "Service Header")
    begin
        CreateSpecificServiceOrder(ServiceHeader, '');
    end;
#endif

#if not CLEAN27
    [Obsolete('Moved to codeunit Library Service', '27.0')]
    procedure CreateServiceLines(ServiceHeader: Record "Service Header")
    var
        LibraryService: Codeunit "Library - Service";
    begin
        LibraryService.CreateServiceLines(ServiceHeader);
    end;
#endif

    procedure CreatePrepaymentAccount(GeneralPostingSetup: Record "General Posting Setup"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    procedure CreateDefaultJob(var Job: Record Job)
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        CreateDefaultJobPlanningLine(JobTask, JobPlanningLine."Line Type"::Budget, JobPlanningLine);
        CreateDefaultJobPlanningLine(JobTask, JobPlanningLine."Line Type"::Billable, JobPlanningLine);
        CreateDefaultJobPlanningLine(JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine);
    end;

    procedure CreateDefaultJobForCustomer(var Job: Record Job; CustomerNo: Code[20])
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        LibraryJob.CreateJob(Job, CustomerNo);
        LibraryJob.CreateJobTask(Job, JobTask);

        CreateDefaultJobPlanningLine(JobTask, JobPlanningLine."Line Type"::Budget, JobPlanningLine);
        CreateDefaultJobPlanningLine(JobTask, JobPlanningLine."Line Type"::Billable, JobPlanningLine);
        CreateDefaultJobPlanningLine(JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine);
    end;

    procedure CreateJobPlanningLine(Job: Record Job; LineType: Enum "Job Planning Line Line Type"; var JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
    begin
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.FindFirst();
        CreateDefaultJobPlanningLine(JobTask, LineType, JobPlanningLine);
    end;

    local procedure CreateDefaultJobPlanningLine(JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; var JobPlanningLine: Record "Job Planning Line")
    begin
        LibraryJob.CreateJobPlanningLine(LineType, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
    end;

    procedure FillJournal(ConsiderSource: array[16] of Boolean; CFNo: Code[20]; GroupByDocumentType: Boolean)
    begin
        LibraryCashFlowForecast.ClearJournal();
        LibraryCashFlowForecast.FillJournal(ConsiderSource, CFNo, GroupByDocumentType);
    end;

    procedure FillJnlOnCertDateFormulas(ConsiderSource: array[16] of Boolean; CFNo: Code[20]; BaseDateFormula: DateFormula; CustomDateFormula: DateFormula; AdditionalDateFormula: DateFormula)
    var
        ForecastDate: Date;
    begin
        ForecastDate := GenerateDateFromFormulas(WorkDate(), BaseDateFormula, AdditionalDateFormula, CustomDateFormula);
        FillJournalOnCertainDate(ConsiderSource, CFNo, ForecastDate);
    end;

    procedure FillJournalOnCertainDate(ConsiderSource: array[16] of Boolean; CFNo: Code[20]; ForecastDate: Date)
    var
        OldWorkDate: Date;
    begin
        OldWorkDate := ChangeWorkdate(ForecastDate);
        FillJournal(ConsiderSource, CFNo, false);
        WorkDate := OldWorkDate;
    end;

    procedure FilterSingleJournalLine(var CFWorksheetLine: Record "Cash Flow Worksheet Line"; DocumentNo: Code[20]; SourceType: Enum "Cash Flow Source Type"; CashFlowNo: Code[20]): Integer
    begin
        // Filters cash flow journal lines based on the given parameters
        // Returns the number of lines found based on the filter

        CFWorksheetLine.SetRange("Cash Flow Forecast No.", CashFlowNo);
        CFWorksheetLine.SetRange("Source Type", SourceType);
        CFWorksheetLine.SetRange("Document No.", DocumentNo);
        if CFWorksheetLine.FindFirst() then;
        exit(CFWorksheetLine.Count);
    end;

    procedure FindCFLiquidFundAccount(var CFAccount: Record "Cash Flow Account")
    begin
        FindFirstCFAccWithGLIntegration(CFAccount, CFAccount."G/L Integration"::Balance);
    end;

    procedure FindCFBudgetAccount(var CFAccount: Record "Cash Flow Account")
    begin
        FindFirstCFAccWithGLIntegration(CFAccount, CFAccount."G/L Integration"::Budget);
    end;

    local procedure FindFirstCFAccWithGLIntegration(var CFAccount: Record "Cash Flow Account"; GLIntegration: Option)
    begin
        CFAccount.SetFilter("G/L Integration", '%1|%2', GLIntegration, CFAccount."G/L Integration"::Both);
        CFAccount.SetFilter("G/L Account Filter", '<>%1', '');
        CFAccount.FindFirst();
    end;

    procedure FindFirstGLAccFromCFAcc(var GLAccount: Record "G/L Account"; CFAccount: Record "Cash Flow Account")
    begin
        GLAccount.SetFilter("No.", CFAccount."G/L Account Filter");
        GLAccount.FindFirst();
    end;

    procedure FilterPaymentLines(var PaymentLines: Record "Payment Lines"; PaymentTermsCode: Code[20])
    begin
        PaymentLines.SetFilter(Type, '%1', PaymentLines.Type::"Payment Terms");
        PaymentLines.SetFilter(Code, '%1', PaymentTermsCode);
        PaymentLines.FindFirst();  // HACK - there might be multiple lines, which one to pick? bug id: 265594
    end;

    procedure FindCustomerCFPaymentTerms(var PaymentTerms: Record "Payment Terms"; PartnerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(PartnerNo);
        PaymentTerms.Get(Customer."Payment Terms Code");
    end;

    procedure FindFirstCustLEFromSO(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesOrderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", SalesOrderNo);
        SalesInvoiceHeader.FindFirst();
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();
    end;

    procedure FindFirstVendorLEFromPO(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchaseOrderNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Order No.", PurchaseOrderNo);
        PurchInvHeader.FindFirst();
        VendorLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.FindFirst();
    end;

    procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
    end;

    procedure GenerateDateFromFormulaArray(BaseDate: Date; DateFormulas: array[3] of DateFormula): Date
    var
        TempDate: Date;
        I: Integer;
    begin
        TempDate := BaseDate;
        for I := 1 to ArrayLen(DateFormulas) do
            TempDate := CalcDate(DateFormulas[I], TempDate);
        exit(TempDate);
    end;

    procedure GenerateDateFromFormulas(BaseDate: Date; DateFormula1: DateFormula; DateFormula2: DateFormula; DateFormula3: DateFormula): Date
    var
        TempDate: Date;
    begin
        TempDate := BaseDate;
        TempDate := CalcDate(DateFormula1, TempDate);
        TempDate := CalcDate(DateFormula2, TempDate);
        TempDate := CalcDate(DateFormula3, TempDate);
        exit(TempDate);
    end;

    procedure GetDifferentDsctPaymentTerms(var PaymentTerms: Record "Payment Terms"; PmtTermsCodeToDifferFrom: Code[20])
    var
        PaymentTermsToDifferFrom: Record "Payment Terms";
        PaymentLines: Record "Payment Lines";
        DueDateToDifferFrom: DateFormula;
        DiscountDateToDifferFrom: DateFormula;
        DiscountPercentageToDifferFrom: Integer;
    begin
        PaymentTermsToDifferFrom.Get(PmtTermsCodeToDifferFrom);
        GetPmtTermsDueDateCalculation(DueDateToDifferFrom, PaymentTermsToDifferFrom);
        GetPmtTermsDiscountDateCalculation(DiscountDateToDifferFrom, PaymentTermsToDifferFrom);
        DiscountPercentageToDifferFrom := GetPmtTermsDiscountPercentage(PaymentTermsToDifferFrom);

        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.GetPaymentLines(PaymentLines, PaymentTerms.Code);
        Evaluate(PaymentLines."Due Date Calculation", Format(DueDateToDifferFrom) +
          '+<' + Format(LibraryRandom.RandInt(2)) + 'M>');
        Evaluate(PaymentLines."Discount Date Calculation", Format(DiscountDateToDifferFrom) +
          '+<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        PaymentLines.Validate("Discount %", DiscountPercentageToDifferFrom +
          LibraryRandom.RandInt(3));
        PaymentLines.Modify(true);
    end;

    procedure GetTotalSalesAmount(SalesHeader: Record "Sales Header"; ConsiderDefaultPmtDiscount: Boolean): Decimal
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        SalesLine: Record "Sales Line";
        TotalAmount: Decimal;
        TotalDiscountAmount: Decimal;
        LineAmount: Decimal;
    begin
        TotalAmount := 0;
        TotalDiscountAmount := 0;
        Customer.Get(SalesHeader."Sell-to Customer No.");
        PaymentTerms.Get(Customer."Payment Terms Code");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindSet();
        repeat
            LineAmount := SalesLine."Outstanding Amount (LCY)";
            TotalAmount += LineAmount;
            if ConsiderDefaultPmtDiscount then
                TotalDiscountAmount +=
                  CalculateDiscountAmount(LineAmount, GetPmtTermsDiscountPercentage(PaymentTerms));
        until SalesLine.Next() = 0;

        exit(TotalAmount - TotalDiscountAmount);
    end;

    procedure GetTotalPurchaseAmount(PurchaseHeader: Record "Purchase Header"; ConsiderDefaultPmtDiscount: Boolean): Decimal
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseLine: Record "Purchase Line";
        TotalAmount: Decimal;
        TotalDiscountAmount: Decimal;
        LineAmount: Decimal;
    begin
        TotalAmount := 0;
        TotalDiscountAmount := 0;
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PaymentTerms.Get(Vendor."Payment Terms Code");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindSet();
        repeat
            LineAmount := PurchaseLine."Outstanding Amount (LCY)";
            TotalAmount += LineAmount;
            if ConsiderDefaultPmtDiscount then
                TotalDiscountAmount +=
                  CalculateDiscountAmount(LineAmount, GetPmtTermsDiscountPercentage(PaymentTerms));
        until PurchaseLine.Next() = 0;

        exit(TotalAmount - TotalDiscountAmount);
    end;

    local procedure GetTotalPurchasePrepaymentAmount(PurchaseHeader: Record "Purchase Header"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        PrepaymentVATPct: Decimal;
        PrepaymentLineAmount: Decimal;
        PrepaymentTotalAmount: Decimal;
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Prepmt. Amt. Inv.", 0);
        PurchaseLine.FindSet();

        PrepaymentVATPct := PurchaseLine."Prepayment VAT %";
        PrepaymentTotalAmount := 0;
        repeat
            if PurchaseHeader."Prices Including VAT" then
                PrepaymentLineAmount := PurchaseLine."Prepmt. Line Amount"
            else
                PrepaymentLineAmount := PurchaseLine."Prepmt. Line Amount" * (1 + PrepaymentVATPct / 100);
            PrepaymentTotalAmount += PrepaymentLineAmount;
        until PurchaseLine.Next() = 0;

        exit(PrepaymentTotalAmount);
    end;

    procedure GetTotalServiceAmount(ServiceHeader: Record "Service Header"; ConsiderDefaultPmtDiscount: Boolean): Decimal
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        ServiceLine: Record "Service Line";
        TotalAmount: Decimal;
        TotalDiscountAmount: Decimal;
        LineAmount: Decimal;
    begin
        TotalAmount := 0;
        TotalDiscountAmount := 0;
        Customer.Get(ServiceHeader."Bill-to Customer No.");
        PaymentTerms.Get(Customer."Payment Terms Code");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.FindSet();
        repeat
            LineAmount := ServiceLine."Outstanding Amount (LCY)";
            TotalAmount += LineAmount;
            if ConsiderDefaultPmtDiscount then
                TotalDiscountAmount +=
                  CalculateDiscountAmount(LineAmount, GetPmtTermsDiscountPercentage(PaymentTerms));
        until ServiceLine.Next() = 0;

        exit(TotalAmount - TotalDiscountAmount);
    end;

    procedure GetTotalAmountForSalesOrderWithCashFlowPaymentTermsDiscount(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        PaymentTermsCashFlow: Record "Payment Terms";
        TotalAmount: Decimal;
        TotalDiscountAmount: Decimal;
        LineAmount: Decimal;
    begin
        Customer.Get(SalesHeader."Sell-to Customer No.");
        PaymentTermsCashFlow.Get(Customer."Cash Flow Payment Terms Code");
        TotalAmount := 0;
        TotalDiscountAmount := 0;
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        if SalesLine.FindSet() then
            repeat
                LineAmount := SalesLine."Outstanding Amount (LCY)";
                TotalAmount += LineAmount;
                TotalDiscountAmount += CalculateDiscountAmount(LineAmount, PaymentTermsCashFlow."Discount %");
            until SalesLine.Next() = 0;
        exit(TotalAmount - TotalDiscountAmount);
    end;

    procedure GetTotalAmountForPurchaseOrderWithCashFlowPaymentTermsDiscount(PurchaseHeader: Record "Purchase Header"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PaymentTermsCashFlow: Record "Payment Terms";
        TotalAmount: Decimal;
        TotalDiscountAmount: Decimal;
        LineAmount: Decimal;
    begin
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PaymentTermsCashFlow.Get(Vendor."Cash Flow Payment Terms Code");
        TotalAmount := 0;
        TotalDiscountAmount := 0;
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        if PurchaseLine.FindSet() then
            repeat
                LineAmount := PurchaseLine."Outstanding Amount (LCY)";
                TotalAmount += LineAmount;
                TotalDiscountAmount += CalculateDiscountAmount(LineAmount, PaymentTermsCashFlow."Discount %");
            until PurchaseLine.Next() = 0;
        exit(TotalAmount - TotalDiscountAmount);
    end;

    procedure GetTotalAmountForServiceOrderWithCashFlowPaymentTermsDiscount(ServiceHeader: Record "Service Header"): Decimal
    var
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        PaymentTermsCashFlow: Record "Payment Terms";
        TotalAmount: Decimal;
        TotalDiscountAmount: Decimal;
        LineAmount: Decimal;
    begin
        Customer.Get(ServiceHeader."Bill-to Customer No.");
        PaymentTermsCashFlow.Get(Customer."Cash Flow Payment Terms Code");
        TotalAmount := 0;
        TotalDiscountAmount := 0;
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        if ServiceLine.FindSet() then
            repeat
                LineAmount := ServiceLine."Outstanding Amount (LCY)";
                TotalAmount += LineAmount;
                TotalDiscountAmount += CalculateDiscountAmount(LineAmount, PaymentTermsCashFlow."Discount %");
            until ServiceLine.Next() = 0;
        exit(TotalAmount - TotalDiscountAmount);
    end;

    procedure GetTotalJobsAmount(Job: Record Job; PlanningDate: Date): Decimal
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        TotalAmount: Decimal;
        TotalInvoicedAmount: Decimal;
        LineAmount: Decimal;
    begin
        TotalAmount := 0;
        TotalInvoicedAmount := 0;
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.FindFirst();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.SetFilter(
          "Line Type", StrSubstNo('%1|%2', JobPlanningLine."Line Type"::Billable, JobPlanningLine."Line Type"::"Both Budget and Billable"));
        JobPlanningLine.SetRange("Planning Date", PlanningDate);
        JobPlanningLine.FindSet();
        repeat
            LineAmount := JobPlanningLine."Line Amount (LCY)";
            TotalAmount += LineAmount;
            JobPlanningLine.CalcFields("Invoiced Amount (LCY)");
            TotalInvoicedAmount += JobPlanningLine."Invoiced Amount (LCY)";
        until JobPlanningLine.Next() = 0;
        exit(TotalAmount - TotalInvoicedAmount);
    end;

    procedure GetTotalTaxAmount(TaxDueDate: Date; SourceTableNum: Integer): Decimal
    var
        CashFlowSetup: Record "Cash Flow Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TotalAmount: Decimal;
        StartDate: Date;
        EndDate: Date;
    begin
        TotalAmount := 0;

        CashFlowSetup.GetTaxPeriodStartEndDates(TaxDueDate, StartDate, EndDate);
        case SourceTableNum of
            DATABASE::"Purchase Header":
                begin
                    PurchaseHeader.SetFilter("Document Date", StrSubstNo('%1..%2', StartDate, EndDate));
                    if PurchaseHeader.FindSet() then
                        repeat
                            PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                            PurchaseLine.CalcSums("Amount Including VAT", Amount);
                            TotalAmount += PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
                        until PurchaseHeader.Next() = 0;
                end;
            DATABASE::"Sales Header":
                begin
                    SalesHeader.SetFilter("Document Date", StrSubstNo('%1..%2', StartDate, EndDate));
                    if SalesHeader.FindSet() then
                        repeat
                            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                            SalesLine.SetRange("Document No.", SalesHeader."No.");
                            SalesLine.CalcSums("Amount Including VAT", Amount);
                            TotalAmount += SalesLine.Amount - SalesLine."Amount Including VAT";
                        until SalesHeader.Next() = 0;
                end;
        end;
        exit(TotalAmount);
    end;

    local procedure GetPaymentTermsCode(PaymentTermsCode: Code[20]): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // An empty payment terms code creates a default payment term code
        if PaymentTermsCode = '' then begin
            CreateDefaultPaymentTerms(PaymentTerms); // no due, no discount
            exit(PaymentTerms.Code);
        end;
        exit(PaymentTermsCode);
    end;

    procedure GetPmtTermsDiscountPercentage(PaymentTerms: Record "Payment Terms"): Decimal
    var
        PaymentLines: Record "Payment Lines";
    begin
        // Special treatment for IT because of different Payment Terms behavior
        // Retrieves the discount % value from the first line found in Payment Lines table.
        // Best used in combination with GetDiscountPaymentTerm function from IT ERM library

        FilterPaymentLines(PaymentLines, PaymentTerms.Code);
        exit(PaymentLines."Discount %");
    end;

    procedure GetPmtTermsDueDateCalculation(var Result: DateFormula; PaymentTerms: Record "Payment Terms")
    var
        PaymentLines: Record "Payment Lines";
    begin
        // Special treatment for IT because of different Payment Terms behavior
        // Initializes the given dateformula with the due date calculation formula from the first line found in Payment Lines table

        FilterPaymentLines(PaymentLines, PaymentTerms.Code);
        Result := PaymentLines."Due Date Calculation";
    end;

    procedure GetPmtTermsDiscountDateCalculation(var Result: DateFormula; PaymentTerms: Record "Payment Terms")
    var
        PaymentLines: Record "Payment Lines";
    begin
        // Special treatment for IT because of different Payment Terms behavior
        // Initializes the given dateformula with the discount date calculation formula from the first line found in Payment Lines table

        FilterPaymentLines(PaymentLines, PaymentTerms.Code);
        Result := PaymentLines."Discount Date Calculation";
    end;

    local procedure GetCFAccountNo(SourceType: Enum "Cash Flow Source Type"): Code[20]
    var
        CFAccount: Record "Cash Flow Account";
    begin
        CFAccount.SetRange("Account Type", CFAccount."Account Type"::Entry);
        CFAccount.FindSet();
        CFAccount.Next(SourceType.AsInteger());
        exit(CFAccount."No.");
    end;

    procedure InsertCFLedgerEntry(CFNo: Code[20]; AccountNo: Code[20]; SourceType: Enum "Cash Flow Source Type"; CFDate: Date; Amount: Decimal)
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        EntryNo: Integer;
    begin
        if CFForecastEntry.FindLast() then
            EntryNo := CFForecastEntry."Entry No.";

        CFForecastEntry.Init();
        CFForecastEntry."Entry No." := EntryNo + 1;
        CFForecastEntry."Cash Flow Forecast No." := CFNo;
        CFForecastEntry."Source Type" := SourceType;
        if AccountNo <> '' then
            CFForecastEntry."Cash Flow Account No." := AccountNo
        else
            CFForecastEntry."Cash Flow Account No." := GetCFAccountNo(SourceType);
        CFForecastEntry."Cash Flow Date" := CFDate;
        CFForecastEntry.Validate("Amount (LCY)", Amount);
        CFForecastEntry.Insert();
    end;

    procedure SelectAndClearGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    procedure SetExpectedDsctAPmtTermValues(DocType: Option; DocumentNo: Code[20]; PartnerNo: Code[20]; CFSourceDate: Date; ConsiderDsctAndCFPmtTerms: Boolean; var ExpectedCFDate: Date; var ExpectedAmount: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        TotalAmount: Decimal;
        DiscountDateCalculation: DateFormula;
        DueDateCalculation: DateFormula;
    begin
        case DocType of
            DocumentType::Sale:
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
                    FindCustomerCFPaymentTerms(PaymentTerms, PartnerNo);
                    TotalAmount := GetTotalSalesAmount(SalesHeader, false);
                end;
            DocumentType::Service:
                begin
                    ServiceHeader.Get(ServiceHeader."Document Type"::Order, DocumentNo);
                    FindCustomerCFPaymentTerms(PaymentTerms, PartnerNo);
                    TotalAmount := GetTotalServiceAmount(ServiceHeader, false);
                end;
            DocumentType::Purchase:
                begin
                    Vendor.Get(PartnerNo);
                    PaymentTerms.Get(Vendor."Payment Terms Code");
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocumentNo);
                    TotalAmount := GetTotalPurchaseAmount(PurchaseHeader, false);
                end;
            else
                Error(UnhandledDocumentType);
        end;

        if ConsiderDsctAndCFPmtTerms then begin
            GetPmtTermsDiscountDateCalculation(DiscountDateCalculation, PaymentTerms);
            ExpectedCFDate := CalcDate(DiscountDateCalculation, CFSourceDate);
            ExpectedAmount := TotalAmount - CalculateDiscountAmount(TotalAmount, GetPmtTermsDiscountPercentage(PaymentTerms));
        end else begin
            GetPmtTermsDueDateCalculation(DueDateCalculation, PaymentTerms);
            ExpectedCFDate := CalcDate(DueDateCalculation, CFSourceDate);
            ExpectedAmount := TotalAmount;
        end;

        if DocType = DocumentType::Purchase then
            ExpectedAmount *= -1;
    end;

    procedure SetDefaultDepreciationBook(DepreciationBookCode: Code[10])
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();

        FASetup.Validate("Default Depr. Book", DepreciationBookCode);
        FASetup.Modify(true);
    end;

    procedure SetPmtToleranceOptionsOnCashFlowForecast(var CashFlowForecast: Record "Cash Flow Forecast"; ConsiderPmtDiscTolDate: Boolean; ConsiderPmtTolAmount: Boolean)
    begin
        CashFlowForecast.Validate("Consider Pmt. Disc. Tol. Date", ConsiderPmtDiscTolDate);
        CashFlowForecast.Validate("Consider Pmt. Tol. Amount", ConsiderPmtTolAmount);
        CashFlowForecast.Modify(true);
    end;

    procedure SetupPmtDsctGracePeriod(NewDscGracePeriodFormula: DateFormula)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Discount Grace Period", NewDscGracePeriodFormula);
        GeneralLedgerSetup.Modify(true);
    end;

    procedure SetupPmtTolPercentage(NewPmtTolPercentage: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", NewPmtTolPercentage);
        GeneralLedgerSetup.Modify(true);
    end;

    procedure SetupPmtTolAmount(NewPmtTolAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", NewPmtTolAmount);
        GeneralLedgerSetup.Modify(true);
    end;

    procedure SetupCustomerPmtTolAmtTestCase(var CashFlowForecast: Record "Cash Flow Forecast"; var Customer: Record Customer; var Amount: Decimal; PmtTolAmtPercentMultiplier: Decimal; PmtTolPercentage: Decimal)
    begin
        LibrarySales.CreateCustomer(Customer);
        SetupPmtTolAmtTestCase(CashFlowForecast, Amount, PmtTolAmtPercentMultiplier, PmtTolPercentage);
    end;

    procedure SetupVendorPmtTolAmtTestCase(var CashFlowForecast: Record "Cash Flow Forecast"; var Vendor: Record Vendor; var Amount: Decimal; PmtTolAmtPercentMultiplier: Decimal; PmtTolPercentage: Decimal)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        SetupPmtTolAmtTestCase(CashFlowForecast, Amount, PmtTolAmtPercentMultiplier, PmtTolPercentage);
    end;

    local procedure SetupPmtTolAmtTestCase(var CashFlowForecast: Record "Cash Flow Forecast"; var Amount: Decimal; PmtTolAmtPercentMultiplier: Decimal; PmtTolPercentage: Decimal)
    begin
        CreateCashFlowForecastDefault(CashFlowForecast);
        SetPmtToleranceOptionsOnCashFlowForecast(CashFlowForecast, false, true);
        Amount := LibraryRandom.RandInt(2000);
        SetupPmtTolPercentage(PmtTolPercentage);
        SetupPmtTolAmount(Round(Amount * PmtTolAmtPercentMultiplier));
    end;

    procedure SetupPmtDsctTolCustLETest(var CashFlowForecast: Record "Cash Flow Forecast"; var Customer: Record Customer; var PaymentTerms: Record "Payment Terms"; NewPmtDiscountGracePeriod: DateFormula; var Amount: Decimal; var DiscountedAmount: Decimal)
    begin
        CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        SetPmtToleranceOptionsOnCashFlowForecast(CashFlowForecast, true, false);
        SetupPmtDsctGracePeriod(NewPmtDiscountGracePeriod);
        CreateCustWithDsctPmtTerm(Customer, PaymentTerms);
        Amount := LibraryRandom.RandDec(2000, 2);
        DiscountedAmount := Amount - CalculateDiscountAmount(Amount, GetPmtTermsDiscountPercentage(PaymentTerms));
    end;

    procedure SetupPmtDsctTolVendorLETest(var CashFlowForecast: Record "Cash Flow Forecast"; var Vendor: Record Vendor; var PaymentTerms: Record "Payment Terms"; NewPmtDiscountGracePeriod: DateFormula; var Amount: Decimal; var DiscountedAmount: Decimal)
    begin
        CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        SetPmtToleranceOptionsOnCashFlowForecast(CashFlowForecast, true, false);
        SetupPmtDsctGracePeriod(NewPmtDiscountGracePeriod);
        CreateVendorWithDsctPmtTerm(Vendor, PaymentTerms);
        Amount := LibraryRandom.RandDec(2000, 2);
        DiscountedAmount := Amount - CalculateDiscountAmount(Amount, GetPmtTermsDiscountPercentage(PaymentTerms));
    end;

    procedure SetupDsctPmtTermsCustLETest(var CashFlowForecast: Record "Cash Flow Forecast"; var Customer: Record Customer; var PaymentTerms: Record "Payment Terms"; var Amount: Decimal; var DiscountedAmount: Decimal)
    begin
        CreateCashFlowForecastConsiderDiscount(CashFlowForecast);
        CreateCustWithDsctPmtTerm(Customer, PaymentTerms);
        Amount := LibraryRandom.RandDec(2000, 2);
        DiscountedAmount := Amount - CalculateDiscountAmount(Amount, GetPmtTermsDiscountPercentage(PaymentTerms));
    end;

    procedure VerifyCFDateOnCFJnlLine(CFWorksheetLine: Record "Cash Flow Worksheet Line"; ExpectedCFDate: Date)
    begin
        Assert.AreEqual(ExpectedCFDate, CFWorksheetLine."Cash Flow Date", StrSubstNo(UnexpectedCFDate, CFWorksheetLine."Document No."));
    end;

    procedure VerifyExpectedCFAmount(ExpectedAmount: Decimal; ActualAmount: Decimal)
    begin
        Assert.AreEqual(ExpectedAmount, ActualAmount, UnexpectedCFAmount);
    end;

    procedure VerifyExpectedCFAmtNearlyEqual(ExpectedAmount: Decimal; ActualAmount: Decimal; Delta: Decimal)
    begin
        Assert.AreNearlyEqual(ExpectedAmount, ActualAmount, Delta, UnexpectedCFAmount);
    end;

    procedure VerifyCFDataOnSnglJnlLine(var CFWorksheetLine: Record "Cash Flow Worksheet Line"; DocumentNo: Code[20]; SourceType: Enum "Cash Flow Source Type"; CFNo: Code[20]; ExpectedCFAmount: Decimal; ExpectedCFDate: Date)
    begin
        VerifyCFDataOnSnglJnlLineWithDates(
          CFWorksheetLine, DocumentNo, SourceType, CFNo, ExpectedCFDate, ExpectedCFAmount, ExpectedCFDate);
    end;

    procedure VerifyCFDataOnSnglJnlLineWithDates(var CFWorksheetLine: Record "Cash Flow Worksheet Line"; DocumentNo: Code[20]; SourceType: Enum "Cash Flow Source Type"; CFNo: Code[20]; DocumentDate: Date; ExpectedCFAmount: Decimal; ExpectedCFDate: Date)
    begin
        FilterSingleJournalLine(CFWorksheetLine, DocumentNo, SourceType, CFNo);
        if SourceType = CFWorksheetLine."Source Type"::Job then begin
            CFWorksheetLine.SetRange("Document No.");
            CFWorksheetLine.SetRange("Source No.", DocumentNo);
            CFWorksheetLine.SetRange("Document Date", DocumentDate);
            if CFWorksheetLine.FindFirst() then;
        end;
        CFWorksheetLine.CalcSums("Amount (LCY)");
        VerifyExpectedCFAmtNearlyEqual(ExpectedCFAmount, CFWorksheetLine."Amount (LCY)", LibraryERM.GetAmountRoundingPrecision());
        VerifyCFDateOnCFJnlLine(CFWorksheetLine, ExpectedCFDate);
    end;

    procedure UpdateDueDateOnCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Validate("Due Date", GetAnyDateAfter(CustLedgerEntry."Due Date"));
        CustLedgerEntry.Modify(true);
    end;

    procedure UpdatePmtDiscountDateOnCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Validate("Pmt. Discount Date", GetAnyDateAfter(CustLedgerEntry."Pmt. Discount Date"));
        CustLedgerEntry.Modify(true);
    end;

    procedure UpdateDueDateOnVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.Validate("Due Date", GetAnyDateAfter(VendorLedgerEntry."Due Date"));
        VendorLedgerEntry.Modify(true);
    end;

    procedure UpdatePmtDiscountDateOnVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.Validate("Pmt. Discount Date", GetAnyDateAfter(VendorLedgerEntry."Pmt. Discount Date"));
        VendorLedgerEntry.Modify(true);
    end;

    local procedure GetAnyDateAfter(ReferenceDate: Date): Date
    var
        DateDelta: DateFormula;
    begin
        Evaluate(DateDelta, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        exit(CalcDate(DateDelta, ReferenceDate));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; GLAccount: Record "G/L Account"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; GLAccount: Record "G/L Account")
    begin
    end;
}

