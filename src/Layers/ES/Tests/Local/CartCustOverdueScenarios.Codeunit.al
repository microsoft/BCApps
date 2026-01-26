codeunit 147535 "Cart. Cust. Overdue Scenarios"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        NotChangedDueDateTxt: Label 'Due Date is not changed.';
        InconsistentDataErr: Label 'Sales Invoice no.';
        InconsistentDateChangeErr: Label 'Due Date';
        CustomerLedgerEntryDescriptionElementNameTxt: Label 'Cust__Ledger_Entry__Description';
        CustomerLedgerEntryDocumentNoElementNameTxt: Label 'Detailed_Cust__Ledg__Entry__Document_No__';

    [Test]
    [Scope('OnPrem')]
    procedure InconsistentDataInPaymentTerms_ErrorOccurs()
    var
        Customer: Record Customer;
        DueDateCalculationFormula: Integer;
        MaxNoOfDays: Integer;
        NumberOfInstallments: Integer;
    begin
        // Test verifies that the error occurs when data in Payment Terms (Due Date Calculation and Max. No. of Days till Due Date)
        // for the line is inconsistent.

        // Setup: create Customer with Payment Terms with inconsistent data
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        DueDateCalculationFormula := DueDateCalculationFormula + LibraryRandom.RandInt(10);

        CreateCustomer(Customer, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);

        // Exercise: try to create and post Sales Invoice
        asserterror CreateAndPostSalesInvoice(Customer, WorkDate(), WorkDate());

        // Verification: get an error message for Sales Invoice
        Assert.ExpectedError(InconsistentDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedDueDateForBillsIsOutOfRange_ErrorOccurs()
    var
        Customer: Record Customer;
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
        // Setup: create Customer with Payment Terms, create and post Sales Invoice, create Bill Group
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateCustomer(Customer, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);
        InvoiceNo := CreateAndPostSalesInvoice(Customer, WorkDate(), WorkDate());

        CreateEmptyBillGroup(BillGroup);
        AddDocToBillGroup(BillGroup."No.", InvoiceNo);

        // Exercise: change Due Date in the line with falling out of the permitted range
        CarteraDoc.SetRange("Document No.", InvoiceNo);
        CarteraDoc.FindFirst();
        asserterror CarteraDoc.Validate("Due Date", CalcDate('<+' + Format(MaxNoOfDays + LibraryRandom.RandInt(10)) + 'D>',
              CarteraDoc."Due Date"));

        // Verification: get an error message
        Assert.ExpectedError(InconsistentDateChangeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangedDueDateForBillsIsInRange()
    var
        Customer: Record Customer;
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
        // Setup: create Customer with Payment Terms, create and post Sales Invoice, create Bill Group
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateCustomer(Customer, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);
        InvoiceNo := CreateAndPostSalesInvoice(Customer, WorkDate(), WorkDate());

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
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_ApplyInvoiceToPayment_Overdue()
    var
        Customer: Record Customer;
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
        // Setup: create Customer with Payment Terms, create and apply invoice to payment
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateCustomer(Customer, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);

        NumberOfInvoices := NumberOfInstallments;
        DocumentDate := CalcDate('<-' + Format(DueDateCalculationFormula) + 'D>', WorkDate());
        PostingDate := CalcDate('<-' + Format(DueDateCalculationFormula / 2) + 'D>', WorkDate());
        PostingDelta := '<+' + Format(DueDateCalculationFormula) + 'D>';
        Evaluate(PostingDeltaDateFormula, PostingDelta);

        CreateAndApplyInvoiceToPayment(Customer, PostingDate, DocumentDate, PostingDeltaDateFormula, NumberOfInvoices, 1);

        StartingDate := CalcDate('<CY-1Y>', WorkDate());
        EndingDate := CalcDate('<CY+1Y>', WorkDate());

        Customer.SetRange("No.", Customer."No.");
        SaveReportAsXML(
          Customer, StartingDate, EndingDate, ShowPayments::Overdue);

        LibraryReportDataset.LoadDataSetFile();

        // Verification: verify report data
        ReportVerification(Customer, PostingDate, PostingDelta);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_ApplyInvoiceToPayment_LegallyOverdue()
    var
        Customer: Record Customer;
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
        // Setup: create Customer with Payment Terms, create and apply invoice to payment
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateCustomer(Customer, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);

        NumberOfInvoices := NumberOfInstallments;
        DocumentDate := CalcDate('<-' + Format(DueDateCalculationFormula) + 'D>', WorkDate());
        PostingDate := CalcDate('<-' + Format(DueDateCalculationFormula / 2) + 'D>', WorkDate());
        PostingDelta := '<+' + Format(MaxNoOfDays) + 'D>';
        Evaluate(PostingDeltaDateFormula, PostingDelta);

        CreateAndApplyInvoiceToPayment(Customer, PostingDate, DocumentDate, PostingDeltaDateFormula, NumberOfInvoices, 1);

        StartingDate := CalcDate('<CY-1Y>', WorkDate());
        EndingDate := CalcDate('<CY+1Y>', WorkDate());

        Customer.SetRange("No.", Customer."No.");
        SaveReportAsXML(
          Customer, StartingDate, EndingDate, ShowPayments::"Legally Overdue");

        LibraryReportDataset.LoadDataSetFile();

        // Verification: verify report data
        ReportVerification(Customer, PostingDate, PostingDelta);
    end;

    [Test]
    [HandlerFunctions('CustomerOverduePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportData_ApplyUnapplyInvoiceToPayment_Overdue()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
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
    begin
        // Test verifies that report consists of also un-applied entries as per CDCR Integration: ES NAV 7 (Task ID 315353)
        // Setup: create Customer with Payment Terms, create and apply invoice to payment
        SetupPaymentOptions(DueDateCalculationFormula, MaxNoOfDays, NumberOfInstallments);

        CreateCustomer(Customer, '<' + Format(DueDateCalculationFormula) + 'D>', MaxNoOfDays, NumberOfInstallments);

        DocumentDate := CalcDate('<-' + Format(DueDateCalculationFormula) + 'D>', WorkDate());
        PostingDate := CalcDate('<-' + Format(DueDateCalculationFormula / 2) + 'D>', WorkDate());
        Evaluate(PostingDeltaDateFormula, '<+' + Format(DueDateCalculationFormula) + 'D>');

        CreateAndApplyInvoiceToPayment(Customer, PostingDate, DocumentDate, PostingDeltaDateFormula, 2, 1);

        // Verification: report exists successfully
        StartingDate := CalcDate('<CY-1Y>', WorkDate());
        EndingDate := CalcDate('<CY+1Y>', WorkDate());

        Customer.SetRange("No.", Customer."No.");
        SaveReportAsXML(
          Customer, StartingDate, EndingDate, ShowPayments::Overdue);

        LibraryReportDataset.LoadDataSetFile();

        // Exercise: unapply payment then try to open the report
        SelectCustomerLedgerEntry(
          CustLedgerEntry, Customer."No.", CalcDate(PostingDeltaDateFormula, WorkDate()), CustLedgerEntry."Document Type"::Payment);
        LibraryERMUnapply.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        Customer.SetRange("No.", Customer."No.");
        SaveReportAsXML(
          Customer, StartingDate, EndingDate, ShowPayments::Overdue);

        LibraryReportDataset.LoadDataSetFile();

        // Verification: verify report data
        VerifyReportInvoiceDescriptionColumn(Customer, PostingDate);
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

    local procedure GetInstallmentTotalPercent(PaymentTermsCode: Code[10]): Decimal
    var
        Installment: Record Installment;
    begin
        Installment.SetRange("Payment Terms Code", PaymentTermsCode);
        Installment.CalcSums("% of Total");
        exit(Installment."% of Total");
    end;

    local procedure CreateAndPostSalesInvoice(Customer: Record Customer; PostingDate: Date; DocumentDate: Date) InvoiceNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        SalesHeader."Posting Date" := PostingDate;
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Modify();

        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000) * 10);
        SalesLine.Modify();
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; DueDateCalculation: Text[256]; MaxNoOfDays: Integer; NumberOfInstallments: Integer)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreatePaymentTerms(PaymentTerms, DueDateCalculation, MaxNoOfDays);
        CreateInstallments(PaymentTerms, NumberOfInstallments);
        FindPaymentMethod(PaymentMethod);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);
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

    local procedure CreateAndApplyInvoiceToPayment(Customer: Record Customer; PostingDate: Date; DocumentDate: Date; PostingDeltaDateFormula: DateFormula; NumberOfInvoices: Integer; NumberOfPayments: Integer)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PmtCustLedgerEntry: Record "Cust. Ledger Entry";
        InvCustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
    begin
        InvoiceNo := CreateAndPostSalesInvoice(Customer, PostingDate, DocumentDate);

        SalesInvoiceHeader.Get(InvoiceNo);

        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        CreateCustomerPayment(
          PmtCustLedgerEntry,
          Customer."No.", -SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Currency Code", PostingDeltaDateFormula);

        FindInvCustomerLedgerEntries(
          InvCustLedgerEntry, InvCustLedgerEntry."Document Type"::Bill, InvoiceNo, SalesInvoiceHeader."Posting Date");
        PostApplicationCustomer(InvCustLedgerEntry, PmtCustLedgerEntry, NumberOfInvoices, NumberOfPayments);
    end;

    local procedure ClearGenenalJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateCustomerPayment(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; Amount: Decimal; Currency: Code[10]; PostingDeltaDateFormula: DateFormula)
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
          PmtGenJnlLine."Account Type"::Customer,
          CustomerNo,
          Amount);

        // Set posting date and currency.
        PostingDate := CalcDate(PostingDeltaDateFormula, WorkDate());
        PmtGenJnlLine.Validate("Posting Date", PostingDate);
        PmtGenJnlLine.Validate("Currency Code", Currency);
        PmtGenJnlLine.Modify(true);

        // Post it.
        LibraryERM.PostGeneralJnlLine(PmtGenJnlLine);

        // Find the newly posted customer ledger entry and update flowfields.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, PmtGenJnlLine."Document Type", PmtGenJnlLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount");
    end;

    local procedure PostApplicationCustomer(var InvCustLedgerEntry: Record "Cust. Ledger Entry"; var PmtCustLedgerEntry: Record "Cust. Ledger Entry"; NumberOfInvoices: Integer; NumberOfPayments: Integer)
    var
        i: Integer;
    begin
        // The first payment is the applying entry, otherwise the discount does not apply.
        SetupApplyingEntryCustomer(PmtCustLedgerEntry, PmtCustLedgerEntry.Amount);

        // Include all invoices.
        for i := 1 to NumberOfInvoices do begin
            SetupApplyEntryCustomer(InvCustLedgerEntry);
            InvCustLedgerEntry.Next();
        end;

        // Include remaining payments.
        PmtCustLedgerEntry.Next();
        for i := 2 to NumberOfPayments do begin
            SetupApplyEntryCustomer(PmtCustLedgerEntry);
            PmtCustLedgerEntry.Next();
        end;

        // Call Apply codeunit.
        CODEUNIT.Run(CODEUNIT::"CustEntry-Apply Posted Entries", PmtCustLedgerEntry);
    end;

    local procedure SetupApplyingEntryCustomer(var CustLedgerEntry: Record "Cust. Ledger Entry"; AmountToApply: Decimal)
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
    end;

    local procedure SetupApplyEntryCustomer(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure FindInvCustomerLedgerEntries(var InvCustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; PostingDate: Date)
    begin
        InvCustLedgerEntry.SetRange("Posting Date", PostingDate);
        InvCustLedgerEntry.SetRange("Document Type", DocumentType);
        InvCustLedgerEntry.SetRange("Document No.", DocumentNo);
        InvCustLedgerEntry.FindSet();
    end;

    local procedure FindPaymentMethod(var PaymentMethod: Record "Payment Method")
    begin
        PaymentMethod.SetRange("Create Bills", true);
        PaymentMethod.SetRange("Bill Type", PaymentMethod."Bill Type"::"Bill of Exchange");
        PaymentMethod.SetRange("Invoices to Cartera", false);
        PaymentMethod.SetRange("Bal. Account No.", '');
        PaymentMethod.FindFirst();
    end;

    local procedure SelectCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Posting Date", PostingDate);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindFirst();
    end;

    local procedure SaveReportAsXML(var Customer: Record Customer; ReportStartDate: Date; ReportEndDate: Date; ShowPayments: Option)
    var
        CustomerOverduePayments: Report "Customer - Overdue Payments";
    begin
        CustomerOverduePayments.SetTableView(Customer);
        CustomerOverduePayments.InitReportParameters(ReportStartDate, ReportEndDate, ShowPayments);
        Commit();
        CustomerOverduePayments.Run();
    end;

    local procedure ReportVerification(Customer: Record Customer; PostingDate: Date; PostingDelta: Text[30])
    begin
        VerifyReportInvoiceDescriptionColumn(Customer, PostingDate);
        VerifyReportDocumentNoColumn(Customer, PostingDelta);
    end;

    local procedure VerifyReportInvoiceDescriptionColumn(Customer: Record Customer; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SelectCustomerLedgerEntry(CustLedgerEntry, Customer."No.", PostingDate, CustLedgerEntry."Document Type"::Bill);
        LibraryReportDataset.Reset();

        LibraryReportDataset.AssertElementWithValueExists(
          CustomerLedgerEntryDescriptionElementNameTxt, CustLedgerEntry.Description);
    end;

    local procedure VerifyReportDocumentNoColumn(Customer: Record Customer; PostingDelta: Text[30])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostingDeltaDateFormula: DateFormula;
    begin
        Evaluate(PostingDeltaDateFormula, PostingDelta);
        SelectCustomerLedgerEntry(
          CustLedgerEntry, Customer."No.", CalcDate(PostingDeltaDateFormula, WorkDate()), CustLedgerEntry."Document Type"::Payment);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          CustomerLedgerEntryDocumentNoElementNameTxt, CustLedgerEntry."Document No.");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOverduePaymentsRequestPageHandler(var CustomerOverduePayments: TestRequestPage "Customer - Overdue Payments")
    begin
        CustomerOverduePayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

