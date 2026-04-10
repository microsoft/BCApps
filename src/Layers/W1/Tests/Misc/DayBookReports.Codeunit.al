codeunit 139351 "Day Book Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [PSREPORTING]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('DayBookCustLedgerEntryExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DayBookCustLedgerEntryExcel()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        ExpectedValueDiscount: Text;
        ExpectedValueAmount: Text;
    begin
        // [FEATURE] [Report] [Sales] [Day Book]
        // [SCENARIO 254499] "Day Book Cust. Ledger Entry" report shows payment discount amounts on "Discount Given" and "Actual Amount" columns

        Initialize();

        // [GIVEN] Customer ledger entry with "Pmt. Disc. Given (LCY)" = 50 and "Amount (LCY)" = 1000 for customer "C"
        MockCustomerLedgerEntry(CustLedgerEntry);
        MockVATEntry(VATEntry, CustLedgerEntry."Transaction No.");
        MockDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.", CustLedgerEntry."Transaction No.");

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");
        LibraryVariableStorage.Enqueue(true); // Print details
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());

        // [WHEN] Run "Day Book Cust. Ledger Entry" report for customer "C"
        REPORT.Run(REPORT::"Day Book Cust. Ledger Entry");

        CustLedgerEntry.CalcFields("Amount (LCY)");
        ExpectedValueDiscount := LibraryReportValidation.FormatDecimalValue(-CustLedgerEntry."Pmt. Disc. Given (LCY)");
        CustLedgerEntry.TestField("Pmt. Disc. Given (LCY)");
        ExpectedValueAmount :=
          LibraryReportValidation.FormatDecimalValue(CustLedgerEntry."Amount (LCY)" + CustLedgerEntry."Pmt. Disc. Given (LCY)");

        LibraryReportValidation.OpenFile();

        // [THEN] "Discount Given" = 50 and "Actual Amount" = 950 in totals by document type
        LibraryReportValidation.VerifyCellValueOnWorksheet(18, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(18, 9, ExpectedValueAmount, '1');

        // [THEN] "Discount Given" = 50 and "Actual Amount" = 950 in totals by date
        LibraryReportValidation.VerifyCellValueOnWorksheet(20, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(20, 9, ExpectedValueAmount, '1');

        // [THEN] "Discount Given" = 50 and "Actual Amount" = 950 in totals by customer
        LibraryReportValidation.VerifyCellValueOnWorksheet(21, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(21, 9, ExpectedValueAmount, '1');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DayBookVendorLedgerEntryExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DayBookVendorLedgerEntryExcel()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        ExpectedValueDiscount: Text;
        ExpectedValueAmount: Text;
    begin
        // [FEATURE] [Report] [Purchases] [Day Book]
        // [SCENARIO 254499] "Day Book Venfor Ledger Entry" report shows payment discount amounts on "Discount Rcd." and "Actual Amount" columns

        Initialize();

        // [GIVEN] Vendor ledger entry with "Pmt. Disc. Rcd.(LCY)" = 50 and "Amount (LCY)" = 1000 for vendor "V"
        MockVendorLedgerEntry(VendorLedgerEntry);
        MockVATEntry(VATEntry, VendorLedgerEntry."Transaction No.");
        MockDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", VendorLedgerEntry."Transaction No.");

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Vendor No.");
        LibraryVariableStorage.Enqueue(true); // Print details
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());

        // [WHEN] Run "Day Book Vendor Ledger Entry" report for vendor "V"
        REPORT.Run(REPORT::"Day Book Vendor Ledger Entry");

        VendorLedgerEntry.CalcFields("Amount (LCY)");
        ExpectedValueDiscount := LibraryReportValidation.FormatDecimalValue(-VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)");
        VendorLedgerEntry.TestField("Pmt. Disc. Rcd.(LCY)");
        ExpectedValueAmount :=
          LibraryReportValidation.FormatDecimalValue(VendorLedgerEntry."Amount (LCY)" + VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)");

        LibraryReportValidation.OpenFile();

        // [THEN] "Discount Rcd." = 50 and "Actual Amount" = 950 in totals by document type
        LibraryReportValidation.VerifyCellValueOnWorksheet(20, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(20, 9, ExpectedValueAmount, '1');

        // [THEN] "Discount Rcd." = 50 and "Actual Amount" = 950 in totals by date
        LibraryReportValidation.VerifyCellValueOnWorksheet(23, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(23, 9, ExpectedValueAmount, '1');

        // [THEN] "Discount Rcd." = 50 and "Actual Amount" = 950 in totals by vendor
        LibraryReportValidation.VerifyCellValueOnWorksheet(24, 8, ExpectedValueDiscount, '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(24, 9, ExpectedValueAmount, '1');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure MockCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        MockGLEntry(GLEntry);

        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry.Insert();

        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Customer No." := MockCustomer();
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Positive := true;
        CustLedgerEntry."Pmt. Disc. Given (LCY)" := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry."Due Date" := WorkDate();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Transaction No." := GLEntry."Transaction No.";
        CustLedgerEntry."Closed by Entry No." := CustLedgerEntry."Entry No.";
        CustLedgerEntry.Modify();
    end;

    local procedure MockDetailedCustomerLedgerEntry(CustLedgerEntryNo: Integer; TransactionNo: Integer): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry.Insert();

        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Realized Loss";
        DetailedCustLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry."Transaction No." := TransactionNo;
        DetailedCustLedgEntry.Modify();

        exit(DetailedCustLedgEntry."Entry No.");
    end;

    local procedure MockCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure MockVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        MockGLEntry(GLEntry);

        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry.Insert();

        VendorLedgerEntry."Vendor No." := MockVendor();
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Remaining Pmt. Disc. Possible" := LibraryRandom.RandDecInRange(10, 20, 2);
        VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)" := LibraryRandom.RandDecInRange(10, 20, 2);
        VendorLedgerEntry."Pmt. Discount Date" := WorkDate();

        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Transaction No." := GLEntry."Transaction No.";
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Closed by Entry No." := VendorLedgerEntry."Entry No.";
        VendorLedgerEntry.Modify();
    end;

    local procedure MockDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; TransactionNo: Integer): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry.Insert();

        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Realized Loss";
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDecInDecimalRange(10, 20, 2);
        DetailedVendorLedgEntry."Amount (LCY)" := DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Transaction No." := TransactionNo;
        DetailedVendorLedgEntry.Modify();

        exit(DetailedVendorLedgEntry."Entry No.");
    end;

    local procedure MockVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateGUID();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure MockGLEntry(var GLEntry: Record "G/L Entry")
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := LibraryUTUtility.GetNewCode();
        GLEntry."Document No." := LibraryUTUtility.GetNewCode();
        GLEntry."Transaction No." := LibraryUtility.GetLastTransactionNo() + 1;
        GLEntry.Insert();
    end;

    local procedure MockVATEntry(var VATEntry: Record "VAT Entry"; TransactionNo: Integer)
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Transaction No." := TransactionNo;
        VATEntry.Amount := LibraryRandom.RandDec(10, 2);
        VATEntry.Base := LibraryRandom.RandDec(10, 2);
        VATEntry.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DayBookCustLedgerEntryExcelRequestPageHandler(var DayBookCustLedgerEntry: TestRequestPage "Day Book Cust. Ledger Entry")
    var
        CustomerNo: Variant;
        PrintCustLedgerDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        LibraryVariableStorage.Dequeue(PrintCustLedgerDetails);
        DayBookCustLedgerEntry.PrintCustLedgerDetails.SetValue(PrintCustLedgerDetails);
        DayBookCustLedgerEntry.PrintGLEntryDetails.SetValue(PrintCustLedgerDetails);
        DayBookCustLedgerEntry.ReqCustLedgEntry.SetFilter("Customer No.", CustomerNo);
        DayBookCustLedgerEntry.ReqCustLedgEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookCustLedgerEntry.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DayBookVendorLedgerEntryExcelRequestPageHandler(var DayBookVendorLedgerEntry: TestRequestPage "Day Book Vendor Ledger Entry")
    var
        VendorNo: Variant;
        PrintVendLedgerDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(PrintVendLedgerDetails);
        DayBookVendorLedgerEntry.PrintVendLedgerDetails.SetValue(PrintVendLedgerDetails);
        DayBookVendorLedgerEntry.PrintGLEntryDetails.SetValue(PrintVendLedgerDetails);
        DayBookVendorLedgerEntry.ReqVendLedgEntry.SetFilter("Vendor No.", VendorNo);
        DayBookVendorLedgerEntry.ReqVendLedgEntry.SetFilter("Posting Date", Format(WorkDate()));
        DayBookVendorLedgerEntry.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;
}

