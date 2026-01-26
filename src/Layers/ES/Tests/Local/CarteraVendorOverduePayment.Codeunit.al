codeunit 147504 "Cartera Vendor Overdue Payment"
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
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
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
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportRun_GenerateEmptyReport_NoErrors()
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        SaveReportToXml(Vendor."No.", WorkDate(), WorkDate() + 1, ShowPayments::All);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RequestPage_NoStartDate_ErrorOccurs()
    begin
        RunRequestPageTest(NoStartDateErr, 0D, WorkDate());
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RequestPage_NoEndDate_ErrorOccurs()
    begin
        RunRequestPageTest(NoEndDateErr, WorkDate(), 0D);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RequestPage_StartDateAboveEndDate_ErrorOccurs()
    begin
        RunRequestPageTest(StartDateAboveEndDateErr, WorkDate() + 1, WorkDate());
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_RunReportOutsidePostingDateForSingleApplication_ReportContainsNoData()
    var
        Amount: Decimal;
    begin
        GenerateReportWithSingleApplication(Amount, false, CalcDate('<2M>', WorkDate()), CalcDate('<2M>', WorkDate()) + 1);

        Assert.IsTrue(not Exists(LibraryReportDataset.GetFileName()), ValueExistsErr);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_SingleApplicationToInvoice_ReportContainsApplicationData()
    begin
        RunSingleApplicationTest(false);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_SingleApplicationToPayment_ReportContainsApplicationData()
    begin
        RunSingleApplicationTest(true);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_MultipleApplicationToInvoice_ReportContainsApplicationData()
    begin
        RunMultipleApplicationTest(ValueNotExistsForMultipleApplicationToInvoiceErr, false);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_MultipleApplicationToPayment_ReportContainsApplicationData()
    begin
        RunMultipleApplicationTest(ValueNotExistsForMultipleApplicationToPaymentErr, true);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
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

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NoAndPctOfInvPaidHasValueInVendOverduePaymentReportOnlyWhenPaymentIsDone()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 540768] No. of invoices paid within the legal limit and % of invoices paid within the legal limit 
        // In Vendor - Overdue Payments Report will have values only when Payment of Invoices are done else it will be zero.

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Payment Method and Validate Create Bills.
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Create Bills", true);
        PaymentMethod.Modify(true);

        // [GIVEN] Create a Payment terms and Validate Due Date Calculation 
        // And Max. No. of Days till Due Date.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<10D>');
        PaymentTerms.Validate("Max. No. of Days till Due Date", LibraryRandom.RandIntInRange(10, 10));
        PaymentTerms.Modify(true);

        // [GIVEN] Create a Vendor and Validate Payment Method code and Payment Terms Code.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);

        // [GIVEN] Create a Purchase Header and Validate Posting Date.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", CalcDate('<CY-3Y>', WorkDate()));
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a Purchase Line and Validate Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 10));
        PurchaseLine.Modify(true);

        // [GIVEN] Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Run Vendor - Overdue Payments Report.
        SaveReportToXml(
            Vendor."No.",
            CalcDate('<CY-7Y>', WorkDate()),
            CalcDate('<CY-3Y>', WorkDate()),
            ShowPayments::All);

        // [THEN] No. and % of invoices paid within the legal limit must be 0.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('InvPaidWithinLegalDueDateCountPerVendorVal', 0);
        LibraryReportDataset.AssertElementWithValueExists('InvPaidToTotalCountPctPerVendorVal', 0);

        // [GIVEN] Find Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Bill);
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();

        // [GIVEN] Create and Post Gen. Journal Line.
        CreateAndPostGenJournalLine(Vendor, PurchaseLine, VendorLedgerEntry);

        // [WHEN] Run Vendor - Overdue Payments Report.
        SaveReportToXml(
            Vendor."No.",
            CalcDate('<CY-7Y>', WorkDate()),
            CalcDate('<CY-3Y>', WorkDate()),
            ShowPayments::All);

        // [THEN] No. of invoices paid within the legal limit must be 1
        // And % of invoices paid within the legal limit must be 100.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('InvPaidWithinLegalDueDateCountPerVendorVal', LibraryRandom.RandInt(0));
        LibraryReportDataset.AssertElementWithValueExists('InvPaidToTotalCountPctPerVendorVal', LibraryRandom.RandIntInRange(100, 100));
    end;

    local procedure RunRequestPageTest(AssertMessage: Text[250]; StartingDate: Date; EndingDate: Date)
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();

        asserterror SaveReportToXml(Vendor."No.", StartingDate, EndingDate, ShowPayments::All);

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
        Vendor: Record Vendor;
    begin
        Amount := GetAmount();
        MakeSimpleInvoicePaymentAndApplication(Amount, Amount, Vendor, ApplyToPayment);
        SaveReportToXml(
          Vendor."No.", ReportStartingDate, ReportEndingDate, ShowPayments::All);
    end;

    local procedure GenerateReportWithMultipleApplication(var ReportValues: array[250] of Text[250]; var GeneratedAmounts: array[10] of Decimal; var GeneratedAmountsCount: Integer; ApplyToPayment: Boolean)
    var
        Vendor: Record Vendor;
        ReportValueVariant: Variant;
        InvoiceAmounts: array[10] of Decimal;
        PaymentAmounts: array[10] of Decimal;
        InvoicesCount: Integer;
        PaymentsCount: Integer;
        I: Integer;
    begin
        GenerateAmountsForMultipleApplication(InvoicesCount, InvoiceAmounts, PaymentsCount, PaymentAmounts);
        MakeInvoicePaymentAndApplication(InvoicesCount, InvoiceAmounts, PaymentsCount, PaymentAmounts, Vendor, ApplyToPayment);
        SaveReportToXml(
          Vendor."No.", CalcDate('<CY-1Y>', WorkDate()), CalcDate('<CY+1Y>', WorkDate()), ShowPayments::All);
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

    local procedure CreateGenJournalLineForVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; Amount: Decimal; LineType: Enum "Gen. Journal Document Type")
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
          GenJournalLine."Account Type"::Vendor,
          VendorNo,
          Amount);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
    end;

    local procedure ClearGenenalJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure PostApplication(var VendorLedgerEntry1: array[10] of Record "Vendor Ledger Entry"; var VendorLedgerEntry2: array[10] of Record "Vendor Ledger Entry"; ArraySize1: Integer; ArraySize2: Integer)
    var
        i: Integer;
    begin
        SetupApplyingEntry(VendorLedgerEntry1[1], VendorLedgerEntry1[1].Amount);

        for i := 1 to ArraySize2 do
            SetupApplyEntry(VendorLedgerEntry2[i]);

        for i := 2 to ArraySize1 do
            SetupApplyEntry(VendorLedgerEntry1[i]);

        CODEUNIT.Run(CODEUNIT::"VendEntry-Apply Posted Entries", VendorLedgerEntry1[1]);
    end;

    local procedure SetupApplyingEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AmountToApply: Decimal)
    begin
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
    end;

    local procedure SetupApplyEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure MakeInvoicePaymentAndApplication(NumberOfInvoices: Integer; InvoiceAmounts: array[10] of Decimal; NumberOfPayments: Integer; PaymentAmounts: array[10] of Decimal; var Vendor: Record Vendor; ApplyToPayment: Boolean)
    var
        InvVendorLedgerEntry: array[10] of Record "Vendor Ledger Entry";
        PmtVendorLedgerEntry: array[10] of Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        I: Integer;
    begin
        if Vendor."No." = '' then
            LibraryPurchase.CreateVendor(Vendor);

        for I := 1 to NumberOfInvoices do
            CreateGenJournalLineForVendor(InvVendorLedgerEntry[I], Vendor."No.", -InvoiceAmounts[I], GenJournalLine."Document Type"::Invoice);
        for I := 1 to NumberOfPayments do
            CreateGenJournalLineForVendor(PmtVendorLedgerEntry[I], Vendor."No.", PaymentAmounts[I], GenJournalLine."Document Type"::Payment);

        if ApplyToPayment then
            PostApplication(InvVendorLedgerEntry, PmtVendorLedgerEntry, NumberOfInvoices, NumberOfPayments)
        else
            PostApplication(PmtVendorLedgerEntry, InvVendorLedgerEntry, NumberOfPayments, NumberOfInvoices);

        Vendor.SetRange("No.", Vendor."No.");
    end;

    local procedure MakeSimpleInvoicePaymentAndApplication(InvoiceAmount: Decimal; PaymentAmount: Decimal; var Vendor: Record Vendor; ApplyToPayment: Boolean)
    var
        InvoiceAmounts: array[10] of Decimal;
        PaymentAmounts: array[10] of Decimal;
    begin
        InvoiceAmounts[1] := InvoiceAmount;
        PaymentAmounts[1] := PaymentAmount;
        MakeInvoicePaymentAndApplication(1, InvoiceAmounts, 1, PaymentAmounts, Vendor, ApplyToPayment);
    end;

    local procedure SaveReportToXml(VendorNo: Code[20]; ReportStartDate: Date; ReportEndDate: Date; ShowPayments: Option)
    var
        Vendor: Record Vendor;
        VendorOverduePayments: Report "Vendor - Overdue Payments";
    begin
        Vendor.SetRange("No.", VendorNo);
        VendorOverduePayments.SetTableView(Vendor);
        VendorOverduePayments.InitReportParameters(ReportStartDate, ReportEndDate, ShowPayments);
        Commit();
        VendorOverduePayments.Run();
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
        VendorNo: Code[20];
    begin
        InvAmount := GetAmount();
        PmtAmount := Round(InvAmount / 2);

        VendorNo := MakeInvPmtAndAppl(InvAmount, PmtAmount);
        SaveReportToXml(VendorNo, ReportStartingDate, ReportEndingDate, ShowPayments::All);
    end;

    local procedure MakeInvPmtAndAppl(InvAmount: Decimal; PmtAmount: Decimal): Code[20]
    var
        InvVendorLedgerEntry: array[1] of Record "Vendor Ledger Entry";
        PmtVendorLedgerEntry: array[1] of Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        ApplDate: Date;
    begin
        if Vendor."No." = '' then
            LibraryPurchase.CreateVendor(Vendor);

        ApplDate := WorkDate();
        CreateGenJnlLineForVendorWithPostingDate(
          GenJnlLine, Vendor."No.", -InvAmount, GenJnlLine."Document Type"::Invoice, ApplDate);
        FindVendorLedgerEntry(InvVendorLedgerEntry[1], GenJnlLine."Document Type", GenJnlLine."Document No.");

        ApplDate := CalcDate('<CY>', WorkDate());
        CreateGenJnlLineForVendorWithPostingDate(
          GenJnlLine, Vendor."No.", PmtAmount, GenJnlLine."Document Type"::Payment, ApplDate);
        FindVendorLedgerEntry(PmtVendorLedgerEntry[1], GenJnlLine."Document Type", GenJnlLine."Document No.");

        PostApplication(InvVendorLedgerEntry, PmtVendorLedgerEntry, 1, 1);

        exit(Vendor."No.");
    end;

    local procedure CreateGenJnlLineForVendorWithPostingDate(var GenJnlLine: Record "Gen. Journal Line"; VendorNo: Code[20]; Amount: Decimal; LineType: Enum "Gen. Journal Document Type"; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJnlLine.Init();
        ClearGenenalJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          LineType, GenJnlLine."Account Type"::Vendor, VendorNo, Amount);

        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocType, DocNo);
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
    end;

    local procedure CreateAndPostGenJournalLine(Vendor: Record Vendor; PurchaseLine: Record "Purchase Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", PurchaseLine."Amount Including VAT");
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Bill);
        GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJournalLine.Validate("Applies-to Bill No.", VendorLedgerEntry."Bill No.");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorOverduePaymentsRequestPageHandler(var VendorOverduePayments: TestRequestPage "Vendor - Overdue Payments")
    begin
        VendorOverduePayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

