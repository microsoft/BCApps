codeunit 147534 "Cartera Cust. Overdue Payment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        ValueNotExistsForMultipleApplicationToInvoiceErr: Label 'Report do not contain multiple application to invoice data in case when it covers posting date.';
        ValueNotExistsForMultipleApplicationToPaymentErr: Label 'Report do not contain multiple application to payment data in case when it covers posting date.';
        ShowPayments: Option Overdue,"Legally Overdue",All;
        NoStartDateErr: Label 'You must specify the start date for the period.';
        NoEndDateErr: Label 'You must specify the end date for the period.';
        StartDateAboveEndDateErr: Label 'The start date cannot be later than the end date.';
        ValueExistsErr: Label 'Report contains data in case when it run outside posting date.';
        TotalPaymentWithinDueDateElementNameTxt: Label 'TotalPaymentWithinDueDate';
        ABSAmountElementNameTxt: Label 'ABS_Amount_';

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportRun_GenerateEmptyReport_NoErrors()
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        SaveReportToXml(Customer."No.", WorkDate(), WorkDate() + 1, ShowPayments::All);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RequestPage_NoStartDate_ErrorOccurs()
    begin
        RunRequestPageTest(NoStartDateErr, 0D, WorkDate());
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RequestPage_NoEndDate_ErrorOccurs()
    begin
        RunRequestPageTest(NoEndDateErr, WorkDate(), 0D);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RequestPage_StartDateAboveEndDate_ErrorOccurs()
    begin
        RunRequestPageTest(StartDateAboveEndDateErr, WorkDate() + 1, WorkDate());
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_RunReportOutsidePostingDateForSingleApplication_ReportContainsNoData()
    var
        Amount: Decimal;
    begin
        GenerateReportWithSingleApplication(Amount, false, CalcDate('<2M>', WorkDate()), CalcDate('<2M>', WorkDate()) + 1);

        Assert.IsFalse(Exists(LibraryReportDataset.GetFileName()), ValueExistsErr);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_SingleApplicationToInvoice_ReportContainsApplicationData()
    begin
        RunSingleApplicationTest(false);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_SingleApplicationToPayment_ReportContainsApplicationData()
    begin
        RunSingleApplicationTest(true);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_MultipleApplicationToInvoice_ReportContainsApplicationData()
    begin
        RunMultipleApplicationTest(ValueNotExistsForMultipleApplicationToInvoiceErr, false);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_MultipleApplicationToPayment_ReportContainsApplicationData()
    begin
        RunMultipleApplicationTest(ValueNotExistsForMultipleApplicationToPaymentErr, true);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_PartApplToInv_ReportContainsOpenInv()
    var
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        GenerateReportWithPartialAppl(InvAmount, PmtAmount, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ABSAmountElementNameTxt, InvAmount - PmtAmount);
    end;

    local procedure RunRequestPageTest(AssertMessage: Text[250]; StartingDate: Date; EndingDate: Date)
    var
        Customer: Record Customer;
    begin
        Customer.Init();

        asserterror SaveReportToXml(Customer."No.", StartingDate, EndingDate, ShowPayments::All);

        Assert.ExpectedError(AssertMessage);
    end;

    local procedure RunSingleApplicationTest(ApplyToPayment: Boolean)
    var
        Amount: Decimal;
    begin
        GenerateReportWithSingleApplication(
          Amount, ApplyToPayment, CalcDate('<CY-1Y>', WorkDate()), CalcDate('<CY+1Y>', WorkDate()));

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalPaymentWithinDueDateElementNameTxt, Amount);
    end;

    local procedure RunMultipleApplicationTest(AssertMessage: Text[250]; ApplyToPayment: Boolean)
    var
        ReportValues: array[250] of Text[250];
        GeneratedAmounts: array[10] of Decimal;
        GeneratedAmountsCount: Integer;
    begin
        GenerateReportWithMultipleApplication(ReportValues, GeneratedAmounts, GeneratedAmountsCount, ApplyToPayment);
        Assert.IsTrue(MatchValues(ReportValues, GeneratedAmounts, GeneratedAmountsCount), AssertMessage);
    end;

    local procedure GenerateReportWithSingleApplication(var Amount: Decimal; ApplyToPayment: Boolean; ReportStartingDate: Date; ReportEndingDate: Date)
    var
        Customer: Record Customer;
    begin
        Amount := GetAmount();
        MakeSimpleInvoicePaymentAndApplication(Amount, Amount, Customer, ApplyToPayment);
        SaveReportToXml(
          Customer."No.", ReportStartingDate, ReportEndingDate, ShowPayments::All);
    end;

    local procedure GenerateReportWithMultipleApplication(var ReportValues: array[250] of Text[250]; var GeneratedAmounts: array[10] of Decimal; var GeneratedAmountsCount: Integer; ApplyToPayment: Boolean)
    var
        Customer: Record Customer;
        ReportValueVariant: Variant;
        InvoiceAmounts: array[10] of Decimal;
        PaymentAmounts: array[10] of Decimal;
        InvoicesCount: Integer;
        PaymentsCount: Integer;
        I: Integer;
    begin
        GenerateAmountsForMultipleApplication(InvoicesCount, InvoiceAmounts, PaymentsCount, PaymentAmounts);
        MakeInvoicePaymentAndApplication(InvoicesCount, InvoiceAmounts, PaymentsCount, PaymentAmounts, Customer, ApplyToPayment);
        SaveReportToXml(
          Customer."No.", CalcDate('<CY-1Y>', WorkDate()), CalcDate('<CY+1Y>', WorkDate()), ShowPayments::All);
        LibraryReportDataset.LoadDataSetFile();

        if not ApplyToPayment then
            CopyArrayAndSize(InvoiceAmounts, InvoicesCount, GeneratedAmounts, GeneratedAmountsCount)
        else
            CopyArrayAndSize(PaymentAmounts, PaymentsCount, GeneratedAmounts, GeneratedAmountsCount);

        I := 1;

        while LibraryReportDataset.GetNextRow() do
            if LibraryReportDataset.CurrentRowHasElement(ABSAmountElementNameTxt) then begin
                LibraryReportDataset.FindCurrentRowValue(ABSAmountElementNameTxt, ReportValueVariant);
                ReportValues[I] := Format(ReportValueVariant);
                I += 1;
            end;
    end;

    local procedure CopyArrayAndSize(SourceArray: array[10] of Decimal; Size: Integer; var NewArray: array[10] of Decimal; var NewSize: Integer)
    var
        I: Integer;
    begin
        for I := 1 to Size do
            NewArray[I] := SourceArray[I];
        NewSize := Size;
    end;

    local procedure MatchValues(Values: array[250] of Text[250]; Amounts: array[10] of Decimal; SizeOfArray: Integer): Boolean
    var
        I: Integer;
        DecimalValue: Decimal;
    begin
        for I := 1 to SizeOfArray do begin
            Evaluate(DecimalValue, Values[I]);
            if DecimalValue <> Amounts[I] then
                exit(false);
        end;
        exit(true);
    end;

    local procedure CreateGenJournalLineForCustomer(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; Amount: Decimal; LineType: Enum "Gen. Journal Document Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalLine.Init();
        ClearGenenalJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          LineType,
          GenJournalLine."Account Type"::Customer,
          CustomerNo,
          Amount);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
    end;

    local procedure ClearGenenalJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure PostApplication(var CustLedgerEntry1: array[10] of Record "Cust. Ledger Entry"; var CustLedgerEntry2: array[10] of Record "Cust. Ledger Entry"; ArraySize1: Integer; ArraySize2: Integer)
    var
        i: Integer;
    begin
        SetupApplyingEntry(CustLedgerEntry1[1], CustLedgerEntry1[1].Amount);

        for i := 1 to ArraySize2 do
            SetupApplyEntry(CustLedgerEntry2[i]);

        for i := 2 to ArraySize1 do
            SetupApplyEntry(CustLedgerEntry1[i]);

        CODEUNIT.Run(CODEUNIT::"CustEntry-Apply Posted Entries", CustLedgerEntry1[1]);
    end;

    local procedure SetupApplyingEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; AmountToApply: Decimal)
    begin
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
    end;

    local procedure SetupApplyEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure MakeInvoicePaymentAndApplication(NumberOfInvoices: Integer; InvoiceAmounts: array[10] of Decimal; NumberOfPayments: Integer; PaymentAmounts: array[10] of Decimal; var Customer: Record Customer; ApplyToPayment: Boolean)
    var
        InvCustLedgerEntry: array[10] of Record "Cust. Ledger Entry";
        PmtCustLedgerEntry: array[10] of Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        I: Integer;
    begin
        if Customer."No." = '' then
            LibrarySales.CreateCustomer(Customer);

        for I := 1 to NumberOfInvoices do
            CreateGenJournalLineForCustomer(
              InvCustLedgerEntry[I], Customer."No.", InvoiceAmounts[I], GenJournalLine."Document Type"::Invoice);
        for I := 1 to NumberOfPayments do
            CreateGenJournalLineForCustomer(
              PmtCustLedgerEntry[I], Customer."No.", -PaymentAmounts[I], GenJournalLine."Document Type"::Payment);

        if ApplyToPayment then
            PostApplication(InvCustLedgerEntry, PmtCustLedgerEntry, NumberOfInvoices, NumberOfPayments)
        else
            PostApplication(PmtCustLedgerEntry, InvCustLedgerEntry, NumberOfPayments, NumberOfInvoices);

        Customer.SetRange("No.", Customer."No.");
    end;

    local procedure MakeSimpleInvoicePaymentAndApplication(InvoiceAmount: Decimal; PaymentAmount: Decimal; var Customer: Record Customer; ApplyToPayment: Boolean)
    var
        InvoiceAmounts: array[10] of Decimal;
        PaymentAmounts: array[10] of Decimal;
    begin
        InvoiceAmounts[1] := InvoiceAmount;
        PaymentAmounts[1] := PaymentAmount;
        MakeInvoicePaymentAndApplication(1, InvoiceAmounts, 1, PaymentAmounts, Customer, ApplyToPayment);
    end;

    local procedure SaveReportToXml(CustomerNo: Code[20]; ReportStartDate: Date; ReportEndDate: Date; ShowPayments: Option)
    var
        Customer: Record Customer;
        CustomerOverduePayments: Report "Customer - Overdue Payments";
    begin
        Customer.SetRange("No.", CustomerNo);
        CustomerOverduePayments.SetTableView(Customer);
        CustomerOverduePayments.InitReportParameters(ReportStartDate, ReportEndDate, ShowPayments);
        Commit();
        CustomerOverduePayments.Run();
    end;

    local procedure GetAmount(): Integer
    begin
        exit(LibraryRandom.RandInt(100));
    end;

    local procedure GenerateAmountsForMultipleApplication(var InvoicesCount: Integer; var InvoiceAmounts: array[10] of Decimal; var PaymentsCount: Integer; var PaymentAmounts: array[10] of Decimal)
    var
        ArraySize: Integer;
    begin
        ArraySize := 10; // due to impossibility to get size directly from array;
        GenerateAmountsArrayForTotalAmount(
          ArraySize, LibraryRandom.RandIntInRange(2, 10), PaymentsCount, PaymentAmounts,
          GenerateAmounts(ArraySize, LibraryRandom.RandIntInRange(2, 10), InvoicesCount, InvoiceAmounts));
    end;

    local procedure GenerateAmounts(ArraySize: Integer; MinCount: Integer; var "Count": Integer; var AmountsArray: array[10] of Decimal) TotalAmount: Integer
    var
        I: Integer;
    begin
        Count := LibraryRandom.RandIntInRange(MinCount, ArraySize);
        for I := 1 to Count do begin
            AmountsArray[I] := GetAmount();
            TotalAmount += AmountsArray[I];
        end;
    end;

    local procedure GenerateAmountsArrayForTotalAmount(ArraySize: Integer; MinCount: Integer; var "Count": Integer; var AmountsArray: array[10] of Decimal; TotalAmount: Integer)
    var
        I: Integer;
        CurrentMaxAmount: Integer;
        ArrayTotalAmount: Integer;
    begin
        Count := LibraryRandom.RandIntInRange(MinCount, ArraySize);
        for I := 1 to Count - 1 do begin
            if TotalAmount - ArrayTotalAmount - 1 < 0 then begin
                Count := I;
                exit;
            end;

            CurrentMaxAmount := TotalAmount - ArrayTotalAmount - Count + I;
            // Ensure that payment is not less than 1;
            if CurrentMaxAmount <= 0 then
                CurrentMaxAmount := 1;
            AmountsArray[I] := LibraryRandom.RandIntInRange(1, CurrentMaxAmount);
            ArrayTotalAmount += AmountsArray[I];
        end;

        if TotalAmount - ArrayTotalAmount = 0 then
            Count -= 1
        else
            AmountsArray[Count] := TotalAmount - ArrayTotalAmount;
    end;

    local procedure GenerateReportWithPartialAppl(var InvAmount: Decimal; var PmtAmount: Decimal; ReportStartingDate: Date; ReportEndingDate: Date)
    var
        CustomerNo: Code[20];
    begin
        InvAmount := GetAmount();
        PmtAmount := Round(InvAmount / 2);

        CustomerNo := MakeInvPmtAndAppl(InvAmount, PmtAmount);
        SaveReportToXml(CustomerNo, ReportStartingDate, ReportEndingDate, ShowPayments::All);
    end;

    local procedure MakeInvPmtAndAppl(InvAmount: Decimal; PmtAmount: Decimal): Code[20]
    var
        InvCustLedgerEntry: array[1] of Record "Cust. Ledger Entry";
        PmtCustLedgerEntry: array[1] of Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        ApplDate: Date;
    begin
        if Customer."No." = '' then
            LibrarySales.CreateCustomer(Customer);

        ApplDate := WorkDate();
        CreateGenJnlLineForCustomerWithPostingDate(
          GenJnlLine, Customer."No.", InvAmount, GenJnlLine."Document Type"::Invoice, ApplDate);
        FindCustomerLedgerEntry(InvCustLedgerEntry[1], GenJnlLine."Document Type", GenJnlLine."Document No.");

        ApplDate := CalcDate('<CY>', WorkDate());
        CreateGenJnlLineForCustomerWithPostingDate(
          GenJnlLine, Customer."No.", -PmtAmount, GenJnlLine."Document Type"::Payment, ApplDate);
        FindCustomerLedgerEntry(PmtCustLedgerEntry[1], GenJnlLine."Document Type", GenJnlLine."Document No.");

        PostApplication(InvCustLedgerEntry, PmtCustLedgerEntry, 1, 1);

        exit(Customer."No.");
    end;

    local procedure CreateGenJnlLineForCustomerWithPostingDate(var GenJnlLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal; LineType: Enum "Gen. Journal Document Type"; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJnlLine.Init();
        ClearGenenalJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          LineType, GenJnlLine."Account Type"::Customer, CustomerNo, Amount);

        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, DocNo);
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOverduePaymentsRequestPageHandler(var CustomerOverduePayments: TestRequestPage "Customer - Overdue Payments")
    begin
        CustomerOverduePayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

