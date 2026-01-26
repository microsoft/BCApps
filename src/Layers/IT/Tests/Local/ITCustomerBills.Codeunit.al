codeunit 144191 "IT - Customer Bills"
{
    // 1.  Test Customer Bill List Report for Balance, Total Amount and No of Lines with "Only Open Entries" as TRUE.
    // 2.  Test Customer Bill List Report for Balance, Total Amount and No of Lines with "Only Open Entries" as FALSE.
    // 3.  Test to validate Amount in Customer Bill List Report after run Issue Bank Receipt Report and post Journal Line after applying.
    // 
    //   Covers Test Cases For Bug:
    //   --------------------------------------------------------------------------------------
    //   Test Function Name                                                           TFS ID
    //   --------------------------------------------------------------------------------------
    //   CustomerBillsListOpenLines,CustomerBillsListAllLines                         278550
    // 
    //   Covers Test Cases For Bug: 278550
    //   --------------------------------------------------------------------------------------
    //   Test Function Name                                                           TFS ID
    //   --------------------------------------------------------------------------------------
    //   CustomerBillsAfterPostCashReceiptJournal                                     278526

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        AppliedAmountLbl: Label 'Applied Amount (LCY)';
        AmountDueLCYLbl: Label 'Amount Due (LCY)';
        CustomerBalanceLbl: Label 'Total';
        ReportOpenEntriesOnly: Boolean;
        NoOfLinesErr: Label 'No of Lines must be %1.', Comment = '.';
        AmountErr: Label 'Amount must be %1.', Comment = '.';

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler,MessageHandler,CustomerBillListPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListOpenLines()
    begin
        // Test Customer Bills List Report for Balance, Total Amount and No of Lines With "Only Open Entries" as TRUE.
        ReportOpenEntriesOnly := true;
        BillsListReportOnAppliedBillAndDishonoredPmt(ReportOpenEntriesOnly);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler,MessageHandler,CustomerBillListPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListAllLines()
    begin
        // Test Customer Bills List Report for Balance, Total Amount and No of Lines With "Only Open Entries" as FALSE.
        ReportOpenEntriesOnly := false;
        BillsListReportOnAppliedBillAndDishonoredPmt(ReportOpenEntriesOnly);
    end;

    [Test]
    [HandlerFunctions('CustomerBillListPageHandler,ApplyCustEntryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsAfterPostCashReceiptJournal()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerBillHeader: Record "Customer Bill Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Test to validate Amount in Customer Bill List Report after run Issue Bank Receipt Report and post Journal Line after applying.

        // Setup: Create Customer, Create and Post Sales Invoice, Run Issue Bank Receipt Report, Create and Post Customer Bill, Post Journal Line for Dishonor and Payment after applying.
        ReportOpenEntriesOnly := false;
        Amount := LibraryRandom.RandDec(10, 2);
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        RunIssueBankReceipt(SalesLine."Sell-to Customer No.");
        CreateCustomerBill(CustomerBillHeader, SalesLine."Sell-to Customer No.");
        PostCustomerBill(CustomerBillHeader);
        ApplyCustBillToPayment(SalesLine."Sell-to Customer No.", Amount, false, GenJournalLine."Document Type"::Dishonored);
        ApplyCustBillToPayment(SalesLine."Sell-to Customer No.", -1 * Amount, false, GenJournalLine."Document Type"::Payment);

        // Exercise: Save Customer Bill List Report.
        SaveCustomerBillListReport(SalesLine."Sell-to Customer No.");

        // Verify: Verify Amount in Customer Bill List Report.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyAmountInCustomerBillListReport(SalesInvoiceHeader."Amount Including VAT", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BillsListReportOnCustomerPartnerType()
    var
        SalesHeader: Record "Sales Header";
        CustomerBillHeader: Record "Customer Bill Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
        Amount: Decimal;
        CustomerBillcard: TestPage "Customer Bill Card";
    begin
        // [SCENARIO 461752] The Partner Type filter is used when suggesting Customer Bills in the Italian version shows entries on Customer bill line
        // [GIVEN] Create Customer and update Customer Partner Type.
        CustomerNo := CreateCustomer();
        UpdateCustomerPartnerType(CustomerNo);

        // [GIVEN] Create sales invoice and post that invoice.
        CreateSalesDocument(SalesHeader, CustomerNo);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Save the "Amount Including VAT" in variable. 
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        Amount := SalesInvoiceHeader."Amount Including VAT";

        // [WHEN] Run Issue Bank Receipt report 
        RunIssueBankReceipt(CustomerNo);

        // [THEN] Create Customer Bill and suggest bill to get the line for Customer "Partner Type"
        CreateCustomerBillWithBillSubject(CustomerBillHeader, CustomerNo);

        // [VERIFY] Open Customer Bill card and verify the amount on Customer Bill Line.
        CustomerBillcard.OpenEdit();
        CustomerBillcard.GoToRecord(CustomerBillHeader);
        CustomerBillcard.CustomerBillLine.Amount.AssertEquals(Amount);
    end;

    local procedure BillsListReportOnAppliedBillAndDishonoredPmt(OpenEntriesOnly: Boolean)
    var
        SalesHeader: Record "Sales Header";
        CustomerBillHeader: Record "Customer Bill Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
        ExpectedLines: Integer;
        Amount: Decimal;
    begin
        // Setup: Create Customer, Create and Post Sales Invoice, Run Issue Bank Receipt Report, Create and Post Customer Bill, Post Journal Line for Dishonor after applying.
        CustomerNo := CreateCustomer();
        CreateSalesDocument(SalesHeader, CustomerNo);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        Amount := SalesInvoiceHeader."Amount Including VAT";
        RunIssueBankReceipt(CustomerNo);
        CreateCustomerBill(CustomerBillHeader, CustomerNo);
        PostCustomerBill(CustomerBillHeader);
        ExpectedLines := ApplyCustBillToDishonoredPayment(CustomerNo, Amount, OpenEntriesOnly);

        // Exercise: Save Customer Bill List Report.
        SaveCustomerBillListReport(CustomerNo);

        // Verify: Verify Total Amount and No. of Lines in Report.
        VerifyCustomerBillListReport(ExpectedLines, Amount);
    end;

    local procedure ApplyCustBillToPayment(CustomerNo: Code[20]; Amount: Decimal; OpenEntriesOnly: Boolean; DocumentType: Enum "Gen. Journal Document Type"): Integer
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        ApplyGenJournalLine(GenJournalBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        if not OpenEntriesOnly then
            exit(3);
        exit(1);
    end;

    local procedure ApplyGenJournalLine(GenJournalBatchName: Code[10])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        Commit();  // COMMIT is required for Write Transaction Error.
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CashReceiptJournal."Applies-to Doc. No.".Lookup();
        CashReceiptJournal.OK().Invoke();
    end;

    local procedure ApplyCustBillToDishonoredPayment(CustomerNo: Code[20]; Amount: Decimal; OpenEntriesOnly: Boolean): Integer
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Dishonored,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        ApplyGenJournalLine(GenJournalBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        if not OpenEntriesOnly then
            exit(3);
        exit(1);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(100, 2));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", FindPaymentMethod());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBill(var CustomerBillHeader: Record "Customer Bill Header"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        BillPostingGroup: Record "Bill Posting Group";
    begin
        // Find Bank Account No for the Payment Method and Create Customer Bill.
        Customer.Get(CustomerNo);
        BillPostingGroup.SetRange("Payment Method", Customer."Payment Method Code");
        BillPostingGroup.FindFirst();
        LibrarySales.CreateCustomerBillHeader(
          CustomerBillHeader, BillPostingGroup."No.", BillPostingGroup."Payment Method", CustomerBillHeader.Type::"Bills For Collection");
        RunSuggestCustomerBill(CustomerBillHeader, CustomerNo);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        exit(SalesLine.Amount);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        BankAccount.FindFirst();
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure FindPaymentMethod(): Code[10]
    var
        Bill: Record Bill;
        PaymentMethod: Record "Payment Method";
    begin
        Bill.SetRange("Allow Issue", true);
        Bill.SetRange("Bank Receipt", true);
        Bill.FindFirst();
        PaymentMethod.SetRange("Bill Code", Bill.Code);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure RunIssueBankReceipt(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuingCustomerBill: Report "Issuing Customer Bill";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        IssuingCustomerBill.SetTableView(CustLedgerEntry);
        IssuingCustomerBill.SetPostingDescription(CustomerNo);
        IssuingCustomerBill.UseRequestPage(false);
        IssuingCustomerBill.Run();
    end;

    local procedure RunSuggestCustomerBill(CustomerBillHeader: Record "Customer Bill Header"; CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SuggestCustomerBills: Report "Suggest Customer Bills";
    begin
        Clear(SuggestCustomerBills);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        SuggestCustomerBills.InitValues(CustomerBillHeader, true);
        SuggestCustomerBills.SetTableView(CustLedgerEntry);
        SuggestCustomerBills.UseRequestPage(false);
        SuggestCustomerBills.Run();
    end;

    local procedure PostCustomerBill(var CustomerBillHeader: Record "Customer Bill Header")
    var
        CustomerBillPostPrint: Codeunit "Customer Bill - Post + Print";
    begin
        CustomerBillPostPrint.SetHidePrintDialog(true);
        CustomerBillPostPrint.Code(CustomerBillHeader);
    end;

    local procedure SaveCustomerBillListReport(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        REPORT.Run(REPORT::"Customer Bills List", true, false, CustLedgerEntry);
    end;

    local procedure VerifyCustomerBillListReport(ExpectedLines: Integer; ExpectedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TotalAmount: Decimal;
    begin
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(CustLedgerEntry.FieldCaption("Posting Date"), Format(WorkDate()));
        LibraryReportValidation.SetColumn(CustLedgerEntry.FieldCaption("Posting Date"));
        Assert.AreEqual(ExpectedLines, LibraryReportValidation.CountRows(), StrSubstNo(NoOfLinesErr, ExpectedLines));
        LibraryReportValidation.SetRange(CustomerBalanceLbl, CustomerBalanceLbl);
        LibraryReportValidation.SetColumn(AmountDueLCYLbl);
        Evaluate(TotalAmount, LibraryReportValidation.GetValue());
        Assert.AreEqual(ExpectedAmount, TotalAmount, StrSubstNo(AmountErr, ExpectedAmount));
    end;

    local procedure VerifyAmountInCustomerBillListReport(Amount: Decimal; DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        ExpectedAmount: Decimal;
    begin
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(VATEntry.FieldCaption("Document No."), DocumentNo);
        LibraryReportValidation.SetColumn(AppliedAmountLbl);
        Evaluate(ExpectedAmount, LibraryReportValidation.GetValue());
        Assert.AreEqual(Amount, ExpectedAmount, StrSubstNo(AmountErr, ExpectedAmount));
    end;

    local procedure CreateCustomerBillWithBillSubject(var CustomerBillHeader: Record "Customer Bill Header"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        BillPostingGroup: Record "Bill Posting Group";
    begin
        // Find Bank Account No for the Payment Method and Create Customer Bill.
        Customer.Get(CustomerNo);
        BillPostingGroup.SetRange("Payment Method", Customer."Payment Method Code");
        BillPostingGroup.FindFirst();
        LibrarySales.CreateCustomerBillHeader(
          CustomerBillHeader, BillPostingGroup."No.", BillPostingGroup."Payment Method", CustomerBillHeader.Type::"Bills Subject To Collection");
        RunSuggestCustomerBill(CustomerBillHeader, CustomerNo);
    end;

    local procedure UpdateCustomerPartnerType(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Partner Type", Customer."Partner Type"::" ");
        Customer.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBillListPageHandler(var CustomerBillsListReport: TestRequestPage "Customer Bills List")
    begin
        CustomerBillsListReport."Ending Date".SetValue(WorkDate());
        CustomerBillsListReport."Only Opened Entries".SetValue(ReportOpenEntriesOnly);
        LibraryReportValidation.SetFileName(LibraryUtility.GetGlobalNoSeriesCode());
        CustomerBillsListReport.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

