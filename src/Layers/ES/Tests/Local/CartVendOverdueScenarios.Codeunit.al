codeunit 147505 "Cart. Vend. Overdue Scenarios"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        NotChangedDueDateTxt: Label 'Due Date is not changed.';
        InconsistentDataErr: Label 'Purchase Invoice no.';
        WrongErrorMsg: Label 'Error message "%1" is incorrect.';
        InconsistentDateChangeErr: Label 'Due Date';
        TotalGreater100Err: Label 'The total of "% of Total" cannot be greater than 100.';
        VendorLedgerEntryDescriptionElementNameTxt: Label 'Vend__Ledger_Entry__Description';
        VendorLedgerEntryDocumentNoElementNameTxt: Label 'Detailed_Vend__Ledg__Entry__Document_No__';

    [Test]
    [Scope('OnPrem')]
    procedure InstallmentsValidation_ValidPercent_NoErrorsOnValidate()
    var
        Installment: Record Installment;
    begin
        // 2 installments group to get total amount for all installments > 100
        CreateTwoInstallmentGroupsAndReturnFirstInstalmentFromSecondGroup(Installment);

        // Validation: no errors occurs
        Installment.Validate("% of Total");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InstallmentsValidation_PercentAbove100_ErrorOnValidate()
    var
        Installment: Record Installment;
    begin
        CreateTwoInstallmentGroupsAndReturnFirstInstalmentFromSecondGroup(Installment);
        Installment."% of Total" += LibraryRandom.RandInt(100);

        asserterror Installment.Validate("% of Total");
        Assert.ExpectedError(TotalGreater100Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InstallmentsInserting_ValidPercent_NoErrorsOnInsert()
    var
        Installment: Record Installment;
        InstallmentToInsert: Record Installment;
    begin
        CreateTwoInstallmentGroupsAndReturnFirstInstalmentFromSecondGroup(Installment);
        CreateAdditionalInstallmentToExistingGroup(Installment, InstallmentToInsert);
        // Validation: no errors occurs
        InstallmentToInsert.Insert(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InstallmentsInserting_PercentAbove100_ErrorOnInsert()
    var
        Installment: Record Installment;
        InstallmentToInsert: Record Installment;
    begin
        CreateTwoInstallmentGroupsAndReturnFirstInstalmentFromSecondGroup(Installment);
        CreateAdditionalInstallmentToExistingGroup(Installment, InstallmentToInsert);
        InstallmentToInsert."% of Total" += LibraryRandom.RandInt(100);

        asserterror InstallmentToInsert.Insert(true);
        Assert.ExpectedError(TotalGreater100Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InconsistentDataInPaymentTerms_ErrorOccurs()
    var
        Vendor: Record Vendor;
        DueDateCalculationFormula: Integer;
        MaxNoOfDays: Integer;
        NumberOfInstallments: Integer;
    begin
        // Test verifies that the error occurs when data in Payment Terms (Due Date Calculation and Max. No. of Days till Due Date)
        // for the line is inconsistent.

        // Setup: create Vendor with Payment Terms with inconsistent data
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        DueDateCalculationFormula := DueDateCalculationFormula + LibraryRandom.RandInt(10);

        CreateVendor(Vendor, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);

        // Exercise: try to create and post Purchase Invoice
        asserterror CreateAndPostPurchaseInvoice(Vendor, WorkDate(), WorkDate());

        // Verification: get an error message for Purchase Invoice
        Assert.IsTrue(StrPos(GetLastErrorText, InconsistentDataErr) > 0, StrSubstNo(WrongErrorMsg, GetLastErrorText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedDueDateForBillsIsOutOfRange_ErrorOccurs()
    var
        Vendor: Record Vendor;
        CarteraDoc: Record "Cartera Doc.";
        BillGroup: Record "Bill Group";
        InvoiceNo: Code[20];
        DueDateCalculationFormula: Integer;
        MaxNoOfDays: Integer;
        NumberOfInstallments: Integer;
    begin
        // Test verifies that if user changes Due Date in the line so it will fall out of the permitted range
        // (Initial Invoice."Document Date" + Payment Terms."Max. No of Days till Due Date").
        // The system doesn't allow to change the date to outstanding.
        // Setup: create Vendor with Payment Terms, create and post Purchase Invoice, create Bill Group
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateVendor(Vendor, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);
        InvoiceNo := CreateAndPostPurchaseInvoice(Vendor, WorkDate(), WorkDate());

        CreateEmptyBillGroup(BillGroup);
        AddDocToBillGroup(BillGroup."No.", InvoiceNo);

        // Exercise: change Due Date in the line with falling out of the permitted range
        CarteraDoc.SetRange("Document No.", InvoiceNo);
        CarteraDoc.FindFirst();
        asserterror CarteraDoc.Validate("Due Date", CalcDate('<+' + Format(MaxNoOfDays + LibraryRandom.RandInt(10)) + 'D>',
              CarteraDoc."Due Date"));

        // Verification: get an error message
        Assert.IsTrue(StrPos(GetLastErrorText, InconsistentDateChangeErr) > 0, StrSubstNo(WrongErrorMsg, GetLastErrorText));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedDueDateForBillsIsInRange()
    var
        Vendor: Record Vendor;
        CarteraDoc: Record "Cartera Doc.";
        BillGroup: Record "Bill Group";
        InvoiceNo: Code[20];
        DueDate: Date;
        DueDateCalculationFormula: Integer;
        MaxNoOfDays: Integer;
        NumberOfInstallments: Integer;
    begin
        // Test verifies that if user changes Due Date in Bill Group line that in will be in the permitted range.
        // The Due Date is successfully changed.
        // Setup: create Vendor with Payment Terms, create and post Purchase Invoice, create Bill Group
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateVendor(Vendor, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);
        InvoiceNo := CreateAndPostPurchaseInvoice(Vendor, WorkDate(), WorkDate());

        CreateEmptyBillGroup(BillGroup);
        AddDocToBillGroup(BillGroup."No.", InvoiceNo);

        // Exercise: change Due Date in the line in the permitted range
        CarteraDoc.SetRange("Document No.", InvoiceNo);
        CarteraDoc.FindFirst();
        DueDate := CarteraDoc."Due Date";
        CarteraDoc."Due Date" := CalcDate('<+' + Format(DueDateCalculationFormula) + 'D>', CarteraDoc."Due Date");
        CarteraDoc.Modify();

        // Verification: Due Date is successfully changed
        Assert.AreEqual(CalcDate('<+' + Format(DueDateCalculationFormula) + 'D>', DueDate), CarteraDoc."Due Date", NotChangedDueDateTxt);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_ApplyInvoiceToPayment_Overdue()
    var
        Vendor: Record Vendor;
        ShowPayments: Option Overdue,"Legally Overdue",All;
        PostingDate: Date;
        DocumentDate: Date;
        PostingDelta: Text[30];
        StartingDate: Date;
        EndingDate: Date;
        DueDateCalculationFormula: Integer;
        MaxNoOfDays: Integer;
        NumberOfInstallments: Integer;
        NumberOfInvoices: Integer;
        PostingDeltaDateFormula: DateFormula;
    begin
        // Test verifies report results if overdue exists
        // Setup: create Vendor with Payment Terms, create and apply invoice to payment
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateVendor(Vendor, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);

        NumberOfInvoices := NumberOfInstallments;

        DocumentDate := CalcDate('<-' + Format(DueDateCalculationFormula) + 'D>', WorkDate());
        PostingDate := CalcDate('<-' + Format(DueDateCalculationFormula / 2) + 'D>', WorkDate());
        PostingDelta := '<+' + Format(DueDateCalculationFormula) + 'D>';
        Evaluate(PostingDeltaDateFormula, PostingDelta);

        CreateAndApplyInvoiceToPayment(Vendor, PostingDate, DocumentDate, PostingDeltaDateFormula, NumberOfInvoices, 1);

        StartingDate := CalcDate('<CY-1Y>', WorkDate());
        EndingDate := CalcDate('<CY+1Y>', WorkDate());

        Vendor.SetRange("No.", Vendor."No.");
        SaveReportAsXML(
          Vendor, StartingDate, EndingDate, ShowPayments::Overdue);

        LibraryReportDataset.LoadDataSetFile();

        // Verification: verify report data
        ReportVerification(Vendor, PostingDate, PostingDelta);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_ApplyInvoiceToPayment_LegallyOverdue()
    var
        Vendor: Record Vendor;
        ShowPayments: Option Overdue,"Legally Overdue",All;
        PostingDate: Date;
        DocumentDate: Date;
        PostingDelta: Text[30];
        StartingDate: Date;
        EndingDate: Date;
        DueDateCalculationFormula: Integer;
        MaxNoOfDays: Integer;
        NumberOfInstallments: Integer;
        NumberOfInvoices: Integer;
        PostingDeltaDateFormula: DateFormula;
    begin
        // Test verifies report results if legally overdue exists
        // Setup: create Vendor with Payment Terms, create and apply invoice to payment
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateVendor(Vendor, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);

        NumberOfInvoices := NumberOfInstallments;
        DocumentDate := CalcDate('<-' + Format(DueDateCalculationFormula) + 'D>', WorkDate());
        PostingDate := CalcDate('<-' + Format(DueDateCalculationFormula / 2) + 'D>', WorkDate());
        PostingDelta := '<+' + Format(MaxNoOfDays) + 'D>';
        Evaluate(PostingDeltaDateFormula, PostingDelta);

        CreateAndApplyInvoiceToPayment(Vendor, PostingDate, DocumentDate, PostingDeltaDateFormula, NumberOfInvoices, 1);

        StartingDate := CalcDate('<CY-1Y>', WorkDate());
        EndingDate := CalcDate('<CY+1Y>', WorkDate());

        Vendor.SetRange("No.", Vendor."No.");
        SaveReportAsXML(
          Vendor, StartingDate, EndingDate, ShowPayments::"Legally Overdue");

        LibraryReportDataset.LoadDataSetFile();

        // Verification: verify report data
        ReportVerification(Vendor, PostingDate, PostingDelta);
    end;

    [Test]
    [HandlerFunctions('VendorOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_ApplyUnapplyInvoiceToPayment_Overdue()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LibraryERMUnapply: Codeunit "Library - ERM Unapply";
        ShowPayments: Option Overdue,"Legally Overdue",All;
        PostingDate: Date;
        DocumentDate: Date;
        PostingDeltaDateFormula: DateFormula;
        StartingDate: Date;
        EndingDate: Date;
        DueDateCalculationFormula: Integer;
        MaxNoOfDays: Integer;
        NumberOfInstallments: Integer;
        NumberOfInvoices: Integer;
    begin
        // Test verifies that report consists also of un-applied entries as per CDCR Integration: ES NAV 7 (Task ID 315353)
        // Setup: create Vendor with Payment Terms, create and apply invoice to payment
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateVendor(Vendor, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);

        NumberOfInvoices := NumberOfInstallments;
        DocumentDate := CalcDate('<-' + Format(DueDateCalculationFormula) + 'D>', WorkDate());
        PostingDate := CalcDate('<-' + Format(DueDateCalculationFormula / 2) + 'D>', WorkDate());
        Evaluate(PostingDeltaDateFormula, '<+' + Format(DueDateCalculationFormula) + 'D>');

        CreateAndApplyInvoiceToPayment(Vendor, PostingDate, DocumentDate, PostingDeltaDateFormula, NumberOfInvoices, 1);

        // Verification: report exists successfully
        StartingDate := CalcDate('<CY-1Y>', WorkDate());
        EndingDate := CalcDate('<CY+1Y>', WorkDate());

        Vendor.SetRange("No.", Vendor."No.");
        SaveReportAsXML(
          Vendor, StartingDate, EndingDate, ShowPayments::Overdue);

        LibraryReportDataset.LoadDataSetFile();

        // Exercise: unapply payment then try to open the report
        SelectVendorLedgerEntry(
          VendorLedgerEntry, Vendor."No.", CalcDate(PostingDeltaDateFormula, WorkDate()), VendorLedgerEntry."Document Type"::Payment);
        LibraryERMUnapply.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        Vendor.SetRange("No.", Vendor."No.");
        SaveReportAsXML(
          Vendor, StartingDate, EndingDate, ShowPayments::Overdue);

        LibraryReportDataset.LoadDataSetFile();

        // Verification: verify report data
        VerifyReportInvoiceDescriptionColumn(Vendor, PostingDate);
    end;

    local procedure SetupPaymentOptions(var DueDateCalculationFormula: Integer; var MaxNoOfDays: Integer; var NumberOfInstallments: Integer)
    begin
        DueDateCalculationFormula := LibraryRandom.RandIntInRange(3, 6) * 2;
        NumberOfInstallments := LibraryRandom.RandIntInRange(2, 4);
        MaxNoOfDays := DueDateCalculationFormula * NumberOfInstallments;
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms"; DueDateCalculation: Text[256]; MaxNoOfDays: Integer)
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", DueDateCalculation);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Validate("Max. No. of Days till Due Date", MaxNoOfDays);
        PaymentTerms.Validate("VAT distribution", PaymentTerms."VAT distribution"::Proportional);
        PaymentTerms.Modify(true);
    end;

    local procedure CreateInstallments(PaymentTerms: Record "Payment Terms"; QtyOfIterations: Integer)
    var
        Installment: Record Installment;
        Counter: Integer;
    begin
        for Counter := 1 to QtyOfIterations do begin
            Installment.Init();
            Installment."Payment Terms Code" := PaymentTerms.Code;
            Installment."Line No." := Counter;
            Installment.Insert();
            if Counter <> QtyOfIterations then begin
                Installment."Gap between Installments" := '<' + Format(PaymentTerms."Due Date Calculation") + '>';
                Installment.Validate("% of Total", 100 / QtyOfIterations);
            end else
                Installment.Validate("% of Total", 100 - GetInstallmentTotalPercent(PaymentTerms.Code));
            Installment.Modify();
        end;
    end;

    local procedure CreateAndPostPurchaseInvoice(Vendor: Record Vendor; PostingDate: Date; DocumentDate: Date) InvoiceNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        PurchaseHeader."Posting Date" := PostingDate;
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Modify();

        LibrarySales.FindItem(Item);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000) * 10);
        PurchaseLine.Modify();
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; DueDateCalculation: Text[256]; MaxNoOfDays: Integer; NumberOfInstallments: Integer)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePaymentTerms(PaymentTerms, DueDateCalculation, MaxNoOfDays);
        CreateInstallments(PaymentTerms, NumberOfInstallments);
        FindPaymentMethod(PaymentMethod);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateEmptyBillGroup(var BillGroup: Record "Bill Group")
    begin
        BillGroup.Init();
        BillGroup.Insert(true);
    end;

    local procedure AddDocToBillGroup(BillGroupNo: Code[20]; InvoiceNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", InvoiceNo);
        if CarteraDoc.FindSet() then
            repeat
                CarteraDoc."Bill Gr./Pmt. Order No." := BillGroupNo;
                CarteraDoc.Modify();
            until CarteraDoc.Next() = 0;
    end;

    local procedure CreateAndApplyInvoiceToPayment(Vendor: Record Vendor; PostingDate: Date; DocumentDate: Date; PostingDelta: DateFormula; NumberOfInvoices: Integer; NumberOfPayments: Integer)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PmtVendorLedgerEntry: Record "Vendor Ledger Entry";
        InvVendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
    begin
        InvoiceNo := CreateAndPostPurchaseInvoice(Vendor, PostingDate, DocumentDate);

        PurchInvHeader.Get(InvoiceNo);

        PurchInvHeader.CalcFields("Amount Including VAT");
        CreateVendorPayment(
          PmtVendorLedgerEntry, Vendor."No.", PurchInvHeader."Amount Including VAT", PurchInvHeader."Currency Code", PostingDelta);
        FindInvVendorLedgerEntries(
          InvVendorLedgerEntry, InvVendorLedgerEntry."Document Type"::Bill, InvoiceNo, PurchInvHeader."Posting Date");
        PostApplicationVendor(InvVendorLedgerEntry, PmtVendorLedgerEntry, NumberOfInvoices, NumberOfPayments);
    end;

    local procedure ClearGenenalJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateVendorPayment(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; Amount: Decimal; Currency: Code[10]; PostingDeltaDateFormula: DateFormula)
    var
        PmtGenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
        PostingDate: Date;
    begin
        // Create a Payment in the General Journal.
        PmtGenJnlLine.Init();
        ClearGenenalJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          PmtGenJnlLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          PmtGenJnlLine."Document Type"::Payment,
          PmtGenJnlLine."Account Type"::Vendor,
          VendorNo,
          Amount);

        // Set posting date and currency.
        PostingDate := CalcDate(PostingDeltaDateFormula, WorkDate());
        PmtGenJnlLine.Validate("Posting Date", PostingDate);
        PmtGenJnlLine.Validate("Currency Code", Currency);
        PmtGenJnlLine.Modify(true);

        // Post it.
        LibraryERM.PostGeneralJnlLine(PmtGenJnlLine);

        // Find the newly posted vendor ledger entry and update flowfields.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, PmtGenJnlLine."Document Type", PmtGenJnlLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
    end;

    local procedure PostApplicationVendor(var InvVendorLedgerEntry: Record "Vendor Ledger Entry"; var PmtVendorLedgerEntry: Record "Vendor Ledger Entry"; NumberOfInvoices: Integer; NumberOfPayments: Integer)
    var
        i: Integer;
    begin
        // The first payment is the applying entry, otherwise the discount does not apply.
        SetupApplyingEntryVendor(PmtVendorLedgerEntry, PmtVendorLedgerEntry.Amount);

        // Include all invoices.
        for i := 1 to NumberOfInvoices do begin
            SetupApplyEntryVendor(InvVendorLedgerEntry);
            InvVendorLedgerEntry.Next();
        end;

        // Include remaining payments.
        PmtVendorLedgerEntry.Next();
        for i := 2 to NumberOfPayments do begin
            SetupApplyEntryVendor(PmtVendorLedgerEntry);
            PmtVendorLedgerEntry.Next();
        end;

        // Call Apply codeunit.
        CODEUNIT.Run(CODEUNIT::"VendEntry-Apply Posted Entries", PmtVendorLedgerEntry);
    end;

    local procedure SetupApplyingEntryVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AmountToApply: Decimal)
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
    end;

    local procedure SetupApplyEntryVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure FindInvVendorLedgerEntries(var InvVendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; PostingDate: Date)
    begin
        InvVendorLedgerEntry.SetRange("Posting Date", PostingDate);
        InvVendorLedgerEntry.SetRange("Document Type", DocumentType);
        InvVendorLedgerEntry.SetRange("Document No.", DocumentNo);
        InvVendorLedgerEntry.FindSet();
    end;

    local procedure FindPaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        PaymentMethod.SetRange("Create Bills", true);
        PaymentMethod.SetRange("Bill Type", PaymentMethod."Bill Type"::"Bill of Exchange");
        PaymentMethod.SetRange("Invoices to Cartera", false);
        PaymentMethod.SetRange("Bal. Account No.", '');
        PaymentMethod.FindFirst();
    end;

    local procedure SelectVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Posting Date", PostingDate);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure SaveReportAsXML(var Vendor: Record Vendor; ReportStartDate: Date; ReportEndDate: Date; ShowPayments: Option)
    var
        VendorOverduePayments: Report "Vendor - Overdue Payments";
    begin
        VendorOverduePayments.SetTableView(Vendor);
        VendorOverduePayments.InitReportParameters(ReportStartDate, ReportEndDate, ShowPayments);
        Commit();
        VendorOverduePayments.Run();
    end;

    local procedure ReportVerification(Vendor: Record Vendor; PostingDate: Date; PostingDelta: Text[30])
    begin
        VerifyReportInvoiceDescriptionColumn(Vendor, PostingDate);
        VerifyReportDocumentNoColumn(Vendor, PostingDelta);
    end;

    local procedure VerifyReportInvoiceDescriptionColumn(Vendor: Record Vendor; PostingDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        SelectVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", PostingDate, VendorLedgerEntry."Document Type"::Bill);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(VendorLedgerEntryDescriptionElementNameTxt, VendorLedgerEntry.Description);
    end;

    local procedure VerifyReportDocumentNoColumn(Vendor: Record Vendor; PostingDelta: Text[30])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostingDeltaDateFormula: DateFormula;
    begin
        Evaluate(PostingDeltaDateFormula, PostingDelta);
        SelectVendorLedgerEntry(
          VendorLedgerEntry, Vendor."No.", CalcDate(PostingDeltaDateFormula, WorkDate()), VendorLedgerEntry."Document Type"::Payment);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(VendorLedgerEntryDocumentNoElementNameTxt, VendorLedgerEntry."Document No.");
    end;

    local procedure GetInstallmentTotalPercent(PaymentTermsCode: Code[10]): Decimal
    var
        Installment: Record Installment;
    begin
        Installment.SetRange("Payment Terms Code", PaymentTermsCode);
        Installment.CalcSums("% of Total");
        exit(Installment."% of Total");
    end;

    local procedure CreateInstallmentGroup(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        DueDateCalculationFormula: Integer;
        MaxNoOfDays: Integer;
        NumberOfInstallments: Integer;
    begin
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);
        DueDateCalculationFormula := DueDateCalculationFormula + LibraryRandom.RandInt(10);
        CreatePaymentTerms(PaymentTerms, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays);
        CreateInstallments(PaymentTerms, NumberOfInstallments);

        exit(PaymentTerms.Code);
    end;

    local procedure CreateTwoInstallmentGroupsAndReturnFirstInstalmentFromSecondGroup(var Installment: Record Installment)
    var
        PaymentTermsCode: Code[10];
    begin
        CreateInstallmentGroup();
        PaymentTermsCode := CreateInstallmentGroup();

        Installment.SetRange("Payment Terms Code", PaymentTermsCode);
        Installment.FindFirst();
    end;

    local procedure CreateAdditionalInstallmentToExistingGroup(var Installment: Record Installment; var InstallmentToInsert: Record Installment)
    var
        TotalPercent: Decimal;
    begin
        Installment.SetRange("Payment Terms Code", Installment."Payment Terms Code");
        Installment.FindLast();
        TotalPercent := Installment."% of Total";
        Installment."% of Total" := Installment."% of Total" / 2;
        Installment.Modify();

        InstallmentToInsert.Init();
        InstallmentToInsert."Payment Terms Code" := Installment."Payment Terms Code";
        InstallmentToInsert."Line No." := Installment."Line No." + 1;
        InstallmentToInsert."% of Total" := TotalPercent - Installment."% of Total";
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorOverduePaymentsRequestPageHandler(var VendorOverduePayments: TestRequestPage "Vendor - Overdue Payments")
    begin
        VendorOverduePayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

