codeunit 144181 "ERM NO KID Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Report] [KID]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        TotalTxt: Label 'Total %1';
        AddnlFeeTxt: Label 'Additional Fee';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2';
        ValueNotFoundErrorTxt: Label 'Value %1 not found in report.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        KundeIDTxt: Label 'KID', Comment = 'Kundenummer';

    [Test]
    [HandlerFunctions('StandardSalesInvoiceReqPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceNoKID()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 332472] 'Standard Sales - Invoice' report printing without Kunde ID
        Initialize();

        // [GIVEN] Sales Setup has settings in KID Setup
        ResetSalesSetupKID();

        // [GIVEN] Posted Sales Invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run Standard Sales Invoice report for the invoice
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] KundeID and KundeIDCaption are printed in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('KundeIDCaption', '');
        LibraryReportDataset.AssertElementWithValueExists('KundeID', '');
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemo')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoNoKID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        IssuedFinChargeMemoNo: Code[20];
        FinChargeMemoNo: Code[20];
    begin
        // [FEATURE] [Finance Charge Memo]
        // [SCENARIO 332472] Finance Charge Memo printing without Kunde ID
        Initialize();
        ResetSalesSetupKID();

        // [GIVEN] Issued Finance Charge Memo for a Customer
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        FinChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");
        IssuedFinChargeMemoNo := IssueAndGetFinChargeMemoNo(FinChargeMemoNo);

        // [WHEN] Run Finance Charge Memo Report with Show Internal Information and Interaction Log as FALSE.
        RunReportFinanceChargeMemo(IssuedFinChargeMemoNo);

        // [THEN] All amount printed in the report
        // [THEN] KundeID and KundeIDCaption printed with blank values
        VerifyFinanceChargeMemo(IssuedFinChargeMemoNo, '', '');
    end;

    [Test]
    [HandlerFunctions('RHReminder')]
    [Scope('OnPrem')]
    procedure ReminderReportNoKID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 332472] Reminder report printing without Kunde ID
        Initialize();
        ResetSalesSetupKID();

        // [GIVEN] Issued Reminder
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        ReminderNo := CreateReminder(GenJournalLine."Document No.", GenJournalLine."Account No.");
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderNo);

        // [WHEN] Run Reminder report
        LibraryVariableStorage.Enqueue(IssuedReminderNo);
        Commit();
        REPORT.Run(REPORT::Reminder);

        // [THEN] All amount printed in the report
        // [THEN] KundeID and KundeIDCaption printed with blank values
        VerifyReminderReport(IssuedReminderNo, '', '');
    end;

    [Test]
    [HandlerFunctions('RHFinanceChargeMemo')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoKID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        IssuedFinChargeMemoNo: Code[20];
        FinChargeMemoNo: Code[20];
    begin
        // [FEATURE] [Finance Charge Memo]
        // [SCENARIO 332472] Finance Charge Memo printing with Kunde ID
        Initialize();

        // [GIVEN] Sales Setup has settings in KID Setup
        UpdateSalesSetupKID();

        // [GIVEN] Issued Finance Charge Memo for a Customer
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        FinChargeMemoNo := CreateSuggestFinanceChargeMemo(GenJournalLine."Account No.", GenJournalLine."Document No.");
        IssuedFinChargeMemoNo := IssueAndGetFinChargeMemoNo(FinChargeMemoNo);

        // [WHEN] Run Finance Charge Memo Report with Show Internal Information and Interaction Log as FALSE.
        RunReportFinanceChargeMemo(IssuedFinChargeMemoNo);

        // [THEN] All amount printed in the report
        // [THEN] KundeID and KundeIDCaption are printed in the report
        VerifyFinanceChargeMemo(IssuedFinChargeMemoNo, KundeIDTxt, GetKundeID(2, IssuedFinChargeMemoNo, ''));
    end;

    [Test]
    [HandlerFunctions('RHReminder')]
    [Scope('OnPrem')]
    procedure ReminderReportKID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 332472] Reminder report printing with Kunde ID
        Initialize();

        // [GIVEN] Sales Setup has settings in KID Setup
        UpdateSalesSetupKID();

        // [GIVEN] Issued Reminder
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(), LibraryRandom.RandDec(1000, 2));
        ReminderNo := CreateReminder(GenJournalLine."Document No.", GenJournalLine."Account No.");
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderNo);

        // [WHEN] Run Reminder report
        LibraryVariableStorage.Enqueue(IssuedReminderNo);
        Commit();
        REPORT.Run(REPORT::Reminder);

        // [THEN] All amount printed in the report
        // [THEN] KundeID and KundeIDCaption are printed in the report
        VerifyReminderReport(IssuedReminderNo, KundeIDTxt, GetKundeID(3, IssuedReminderNo, ''));
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceReqPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceKID()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 332472] 'Standard Sales - Invoice' report printing with Kunde ID
        Initialize();

        // [GIVEN] Sales Setup has settings in KID Setup
        UpdateSalesSetupKID();

        // [GIVEN] Posted Sales Invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run Standard Sales Invoice report for the invoice
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] KundeID and KundeIDCaption are printed in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('KundeIDCaption', KundeIDTxt);
        LibraryReportDataset.AssertElementWithValueExists(
          'KundeID', GetKundeID(1, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Customer No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillPaymentExportDataGenJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataExch: Record "Data Exch.";
        Vendor: Record "Vendor";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PaymentExportData: Record "Payment Export Data";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 452398] Fill Payment Export Buffer via Exp. Pre-Mapping Gen. Jnl. 
        DataExch.Init();
        DataExch.Insert();
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateGUID();
        Vendor.Insert();
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetup.Insert();
        BankAccount.Init();
        BankAccount."No." := LibraryUtility.GenerateGUID();
        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Insert();

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := LibraryUtility.GenerateGUID();
        GenJournalLine."Journal Batch Name" := LibraryUtility.GenerateGUID();
        GenJournalLine."Line No." := 10000;
        GenJournalLine."Data Exch. Entry No." := DataExch."Entry No.";
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := Vendor."No.";
        GenJournalLine."Bal. Account No." := BankAccount."No.";
        GenJournalLine.KID := LibraryUtility.GenerateGUID();
        GenJournalLine.Insert();

        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Gen. Jnl.", DataExch);

        PaymentExportData.SetRange("Data Exch Entry No.", DataExch."Entry No.");
        PaymentExportData.FindFirst();
        PaymentExportData.TestField(KID, GenJournalLine.KID);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryVariableStorage);
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SaveSalesSetup();
        IsInitialized := true;
    end;

    local procedure CalculateFinanceChargeMemoDate(DocumentNo: Code[20]; "Code": Code[10]) DocumentDate: Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        FinanceChargeTerms.Get(Code);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        DocumentDate := CalcDate('<1D>', CalcDate(FinanceChargeTerms."Due Date Calculation", CustLedgerEntry."Due Date"));
    end;

    local procedure ClearGeneralJournalLines(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGeneralJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.SetFilter("Additional Fee (LCY)", '<>%1', 0);
        ReminderLevel.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", ReminderLevel."Reminder Terms Code");
        Customer.Validate("Fin. Charge Terms Code", CreateFinanceChargeTerms());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateFinanceChargeTerms(): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // Create Finance Charge Term with Random Interest Rate, Minimum Amount, Additional Amount, Grace Period, Interest Period and
        // Due Date Calculation.
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandDec(10, 2));
        FinanceChargeTerms.Validate("Additional Fee (LCY)", LibraryRandom.RandDec(1000, 2));
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandInt(30));
        Evaluate(FinanceChargeTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(20)) + 'D>');
        FinanceChargeTerms.Validate("Post Additional Fee", true);
        FinanceChargeTerms.Validate("Post Interest", true);
        FinanceChargeTerms.Modify(true);
        exit(FinanceChargeTerms.Code);
    end;

    local procedure CreateReminder(DocumentNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLevel: Record "Reminder Level";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
        DocumentDate: Date;
    begin
        Customer.Get(CustomerNo);
        FindReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        // Calculate Document Date according to Reminder Level's Grace Period and add One day.
        DocumentDate := CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", CustLedgerEntry."Due Date"));
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Posting Date", DocumentDate);
        ReminderHeader.Validate("Document Date", DocumentDate);
        ReminderHeader.Modify(true);
        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, false, false, CustLedgEntryLineFeeOn);
        ReminderMake.Code();
        exit(ReminderHeader."No.");
    end;

    local procedure CreateSuggestFinanceChargeMemo(CustomerNo: Code[20]; DocumentNo: Code[20]): Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        DocumentDate: Date;
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CustomerNo);
        DocumentDate := CalculateFinanceChargeMemoDate(DocumentNo, FinanceChargeMemoHeader."Fin. Charge Terms Code");
        FinanceChargeMemoHeader.Validate("Posting Date", DocumentDate);
        FinanceChargeMemoHeader.Validate("Document Date", DocumentDate);
        FinanceChargeMemoHeader.Modify(true);
        SuggestFinanceChargeMemoLines(FinanceChargeMemoHeader);
        exit(FinanceChargeMemoHeader."No.");
    end;

    local procedure FindFinChargeMemoLine(var IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line"; FinanceChargeMemoNo: Code[20]; Type: Option): Decimal
    begin
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoNo);
        IssuedFinChargeMemoLine.SetRange(Type, Type);
        IssuedFinChargeMemoLine.FindFirst();
        exit(IssuedFinChargeMemoLine.Amount);
    end;

    local procedure FindReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10])
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindFirst();
    end;

    local procedure GetKundeID(DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20]) KundeID: Text[25]
    var
        DocumentTools: Codeunit DocumentTools;
        KundeTxt: Text;
    begin
        DocumentTools.GetKundeID(KundeTxt, KundeID, DocumentType, DocumentNo, CustomerNo);
    end;

    local procedure IssueAndGetFinChargeMemoNo(No: Code[20]) IssuedDocNo: Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        NoSeries: Codeunit "No. Series";
    begin
        FinanceChargeMemoHeader.Get(No);
        IssuedDocNo := NoSeries.PeekNextNo(FinanceChargeMemoHeader."Issuing No. Series");
        IssueFinChargeMemo(FinanceChargeMemoHeader);
    end;

    local procedure IssueFinChargeMemo(FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
    begin
        FinChrgMemoIssue.Set(FinanceChargeMemoHeader, false, FinanceChargeMemoHeader."Document Date");
        FinChrgMemoIssue.Run();
    end;

    local procedure IssueReminder(ReminderHeader: Record "Reminder Header")
    var
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        ReminderIssue.Set(ReminderHeader, false, ReminderHeader."Document Date");
        ReminderIssue.Run();
    end;

    local procedure IssueReminderAndGetIssuedNo(ReminderNo: Code[20]) IssuedReminderNo: Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        NoSeries: Codeunit "No. Series";
    begin
        ReminderHeader.Get(ReminderNo);
        IssuedReminderNo := NoSeries.PeekNextNo(ReminderHeader."Issuing No. Series");
        IssueReminder(ReminderHeader);
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

    local procedure ResetSalesSetupKID()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."KID Setup" := SalesReceivablesSetup."KID Setup"::"Do not use";
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdateSalesSetupKID()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."KID Setup" := SalesReceivablesSetup."KID Setup"::"Document Type+Document No.";
        SalesReceivablesSetup."Use KID on Fin. Charge Memo" := true;
        SalesReceivablesSetup."Use KID on Reminder" := true;
        SalesReceivablesSetup."Document No. length" := LibraryRandom.RandIntInRange(10, 20);
        SalesReceivablesSetup.Modify();
    end;

    local procedure VerifyFinanceChargeMemo(No: Code[20]; KundeIDCaption: Text; KundeID: Text[25])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        AddnlFeeAmount: Decimal;
        LineAmount: Decimal;
        TotalAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        LineAmount := FindFinChargeMemoLine(IssuedFinChargeMemoLine, No, IssuedFinChargeMemoLine.Type::"Customer Ledger Entry");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('KundeIDCaption', KundeIDCaption);
        LibraryReportDataset.AssertElementWithValueExists('KundeID', KundeID);
        LibraryReportDataset.SetRange('DocDt_IssuFinChrgMemoLine', Format(IssuedFinChargeMemoLine."Document Date"));
        Assert.IsTrue(
          LibraryReportDataset.GetNextRow(),
          StrSubstNo(RowNotFoundErr, 'DocDate_IssuedFinChrgMemoLine', Format(IssuedFinChargeMemoLine."Document Date")));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_IssuFinChrgMemoLine', IssuedFinChargeMemoLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_IssuFinChrgMemoLine', IssuedFinChargeMemoLine.Amount);
        AddnlFeeAmount := FindFinChargeMemoLine(IssuedFinChargeMemoLine, No, IssuedFinChargeMemoLine.Type::"G/L Account");
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Desc_IssuFinChrgMemoLine', AddnlFeeTxt);
        Assert.IsTrue(
          LibraryReportDataset.GetNextRow(),
          StrSubstNo(RowNotFoundErr, 'Desc_IssuFinChrgMemoLine', AddnlFeeTxt));
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_IssuFinChrgMemoLine', IssuedFinChargeMemoLine.Amount);
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('TotalText', StrSubstNo(TotalTxt, GeneralLedgerSetup."LCY Code"));
        TotalAmount := LibraryReportDataset.Sum('TotalAmount');
        TotalAmount := LibraryReportDataset.Sum('Amt_IssuFinChrgMemoLine');
        Assert.AreEqual(LineAmount + AddnlFeeAmount, TotalAmount, StrSubstNo(ValueNotFoundErrorTxt, LineAmount + AddnlFeeAmount));
    end;

    local procedure VerifyReminderReport(No: Code[20]; KundeIDCaption: Text; KundeID: Text[25])
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("Reminder No.", No);
        IssuedReminderLine.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('KundeIDCaption', KundeIDCaption);
        LibraryReportDataset.AssertElementWithValueExists('KundeID', KundeID);
        LibraryReportDataset.SetRange('DocDate_IssuedReminderLine', Format(IssuedReminderLine."Document Date"));
        Assert.IsTrue(
          LibraryReportDataset.GetNextRow(),
          StrSubstNo(RowNotFoundErr, 'DocDate_IssuedReminderLine', Format(IssuedReminderLine."Document Date")));
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_IssuedReminderLine', IssuedReminderLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt_IssuedReminderLine', IssuedReminderLine."Original Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('RemAmt_IssuedReminderLine', IssuedReminderLine."Remaining Amount");
    end;

    local procedure RunReportFinanceChargeMemo(FinanceChargeMemoNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(FinanceChargeMemoNo);
        Commit();
        REPORT.Run(REPORT::"Finance Charge Memo");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHReminder(var Reminder: TestRequestPage Reminder)
    var
        ReminderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ReminderNo);
        Reminder."Issued Reminder Header".SetFilter("No.", ReminderNo);
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFinanceChargeMemo(var FinanceChargeMemo: TestRequestPage "Finance Charge Memo")
    var
        IssuedFinChargeMemoNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(IssuedFinChargeMemoNo);

        FinanceChargeMemo."Issued Fin. Charge Memo Header".SetFilter("No.", IssuedFinChargeMemoNo);
        FinanceChargeMemo.ShowInternalInformation.SetValue(false);
        FinanceChargeMemo.LogInteraction.SetValue(false);
        FinanceChargeMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceReqPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

