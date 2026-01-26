codeunit 144032 "Test Cust Balance to Date"
{
    // // [FEATURE] [Report] [Sales]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ReportRowsErr: Label 'Expected row to be found with %1 value = %2', Comment = '%1=XML Tag Name %2 = XML Tag value';
        ReportNoRowsErr: Label 'No rows expected with %1 element name!', Comment = '%1=ConsNo_DtldCustLedgEntry';
        ReportEndDatasetErr: Label 'Only %1 rows expected to be found.', Comment = '%1 = Count of output rows';
        CountOfSheetsErr: Label '3 excel sheets expected to be found.';
        ConsNoDtldCustLedgEntryTagTxt: Label 'ConsNo_DtldCustLedgEntry';
        CustomerNoTagTxt: Label 'No_Cust';
        OutputNoTagTxt: Label 'OutputNo';
        TotalTagTxt: Label 'TotalCaption';
        CountOfPagesWithTotalsErr: Label 'Report Totals are situated on the wrong page.';

    [Test]
    [HandlerFunctions('CustBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestCustBalanceToDate()
    var
        Customer: Record Customer;
        AppliesToGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup - Create an Invoice and a payment
        LibrarySales.CreateCustomer(Customer);
        PostSalesDocument(AppliesToGenJournalLine, Customer, AppliesToGenJournalLine."Document Type"::Invoice,
          LibraryRandom.RandDec(1000, 2), '', WorkDate());
        PostAppliedSalesDocument(GenJournalLine, AppliesToGenJournalLine, GenJournalLine."Document Type"::Payment,
          -LibraryRandom.RandDecInDecimalRange(1, AppliesToGenJournalLine."Amount (LCY)", 2));

        Commit();

        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"SR Cust. - Balance to Date", true, false, Customer);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Cust', Customer."No.");

        // Expect 2 rows for the customer - one detailed line for the sales invoice, and one aggregation
        Assert.AreEqual(2, LibraryReportDataset.RowCount(), 'Expected 2 rows to be found in the report');
    end;

    [Test]
    [HandlerFunctions('CustBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestFCYCustomerTotaling()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        TotalCustLCYBalance: Decimal;
        i: Integer;
    begin
        Initialize();

        // Setup - Create random Invoices with random Currencies
        LibrarySales.CreateCustomer(Customer);
        for i := 0 to LibraryRandom.RandInt(10) do begin
            CurrencyCode :=
              LibraryERM.CreateCurrencyWithExchangeRate(
                WorkDate(), LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));
            PostSalesDocument(GenJournalLine, Customer, GenJournalLine."Document Type"::Invoice,
              LibraryRandom.RandDec(1000, 2), CurrencyCode, WorkDate());
            TotalCustLCYBalance += GenJournalLine."Amount (LCY)";
        end;

        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"SR Cust. - Balance to Date", true, false, Customer);

        LibraryReportDataset.LoadDataSetFile();

        // Expect totaling value in LCY for all Currencies is equal to total 'Amount (LCY)' of posted Invoices
        LibraryReportDataset.AssertElementWithValueExists('CustomerTotalLCY', TotalCustLCYBalance);
    end;

    [Test]
    [HandlerFunctions('CustBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestUnappliedEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        AppliesToGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup - Create an Invoice and a payment
        LibrarySales.CreateCustomer(Customer);
        PostSalesDocument(AppliesToGenJournalLine, Customer, AppliesToGenJournalLine."Document Type"::Invoice,
          LibraryRandom.RandDec(1000, 2), '', WorkDate());
        PostAppliedSalesDocument(GenJournalLine, AppliesToGenJournalLine, GenJournalLine."Document Type"::Payment,
          -LibraryRandom.RandDecInDecimalRange(1, AppliesToGenJournalLine."Amount (LCY)", 2));

        // Unapply.
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindFirst();
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        Commit();
        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"SR Cust. - Balance to Date", true, false, Customer);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Cust', Customer."No.");
        LibraryReportDataset.SetRange('DocNo_CustLedgEntry', CustLedgerEntry."Document No.");

        Assert.AreEqual(2, LibraryReportDataset.RowCount(), 'Expected 2 rows to be found in the report');
    end;

    [Test]
    [HandlerFunctions('CustBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckConsequentNoDtldCustLedgEntryTag()
    var
        Customer: Record Customer;
        Amount: array[3] of Decimal;
    begin
        // [FEATURE] [Application]

        // [SCENARIO 380055] Customer with Sales Invoice and two applied payments in "SR Cust. - Balance to Date" Report
        Initialize();

        // [GIVEN] Sales Invoice "SI" with amount 1000 for customer "C1"
        // [GIVEN] Payment "P1" with amount 300 and "P2" with amount 200 for customer "C1" have applied to invoice "SI"
        CreateSalesInvoiceWithAppliedPayments(Customer, Amount);
        Commit();

        // [WHEN] "SR Cust. - Balance to Date" run filtered on "C1" Customer
        Customer.SetRecFilter();
        REPORT.Run(REPORT::"SR Cust. - Balance to Date", true, false, Customer);

        // [THEN] 3 rows generated
        // [THEN] Row[1]."ConsNo_DtldCustLedgEntry" = 1
        // [THEN] Row[2]."ConsNo_DtldCustLedgEntry" = 2
        // [THEN] Row[3] - TAG "ConsNo_DtldCustLedgEntry" does not exist
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(CustomerNoTagTxt, Customer."No.");
        VerifyTagOnRows(ConsNoDtldCustLedgEntryTagTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithAppliedPayments()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        AppliedDocNo: Code[20];
        Amount: array[3] of Decimal;
    begin
        // [FEATURE] [Excel] [Application]

        // [SCENARIO 380055] Customer with sales invoice and two applied payments to invoice when "SR Cust. - Balance to Date" Report is run
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Sales Invoice "I1" with Amount 1000
        Amount[1] := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);

        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] "P1" applied to "I1" with amount 300
        Amount[2] := -LibraryRandom.RandDec(Round(Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[2]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        // [GIVEN] Payment "P2" applied to "I1" with amount 200
        Amount[3] := -LibraryRandom.RandDec(Round(Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[3]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        Commit();

        // [WHEN] Report "SR Cust. - Balance to Date" run filtered on "C1" customer and saved as excel
        Customer.SetRecFilter();
        LibraryReportValidation.SetFileName(Customer."No.");
        REPORT.SaveAsExcel(REPORT::"SR Cust. - Balance to Date", LibraryReportValidation.GetFileName(), Customer);

        // [THEN] 1st line: "I1".Amount = 900,00
        // [THEN] 2nd line: "P1".Amount = -300,00
        // [THEN] 3rd line: "P2".Amount = -200,00
        // [THEN] 4th line: "I1".Remaining Amount = 500,00
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(14, 17, Format(Amount[1]));
        LibraryReportValidation.VerifyCellValue(15, 17, Format(Amount[2]));
        LibraryReportValidation.VerifyCellValue(16, 17, Format(Amount[3]));
        LibraryReportValidation.VerifyCellValue(17, 17, Format(Amount[1] + Amount[2] + Amount[3]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoSalesInvoicesEachWithAppliedPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        AppliedDocNo: Code[20];
        Amount: array[4] of Decimal;
    begin
        // [FEATURE] [Excel] [Application]

        // [SCENARIO 380055] Customer with two sales invoices applied to different payments when "SR Cust. - Balance to Date" Report is run
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Sales Invoice "I1" with Amount 1000
        Amount[1] := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);

        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment "P1" applied to "I1" with amount 300
        Amount[2] := -LibraryRandom.RandDec(Round(Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[2]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        // [GIVEN] Sales Invoice "I2" with amount 2000
        Amount[3] := LibraryRandom.RandDec(1000, 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Amount[3]);
        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment "P2" applied to "I2" with amount 200
        Amount[4] := -LibraryRandom.RandDec(Round(Amount[3] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[4]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        Commit();

        // [WHEN] Report "SR Cust. - Balance to Date" run filtered on "C1" customer and saved as excel
        Customer.SetRecFilter();
        LibraryReportValidation.SetFileName(Customer."No.");
        REPORT.SaveAsExcel(REPORT::"SR Cust. - Balance to Date", LibraryReportValidation.GetFileName(), Customer);

        // [THEN] 1st line: "I1".Amount = 1000
        // [THEN] 2nd line: "P1".Amount =  = -300
        // [THEN] 3rd line: "I1".Remaining Amount = 700
        // [THEN] 4th line: "I2".Amount = 2000
        // [THEN] 5th line: "P2".Amount = -200
        // [THEN] 6rd line: "I1".Remaining Amount= 1800
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(14, 17, Format(Amount[1]));
        LibraryReportValidation.VerifyCellValue(15, 17, Format(Amount[2]));
        LibraryReportValidation.VerifyCellValue(16, 17, Format(Amount[1] + Amount[2]));
        LibraryReportValidation.VerifyCellValue(17, 17, Format(Amount[3]));
        LibraryReportValidation.VerifyCellValue(18, 17, Format(Amount[4]));
        LibraryReportValidation.VerifyCellValue(19, 17, Format(Amount[3] + Amount[4]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicesAndAppliedPayments()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AppliedDocNo: Code[20];
        Amount: array[6] of Decimal;
    begin
        // [FEATURE] [Excel] [Application]

        // [SCENARIO 380055] Customer with sales invoices and applied payments when "SR Cust. - Balance to Date" Report is run
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Sales Invoice "I1" with amount 1000
        Amount[1] := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);

        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Payment "P1" with amount 300 applied to Invoice "I1"
        Amount[2] := -LibraryRandom.RandDec(Round(Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[2]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        // [GIVEN] Payment "P2" with amount 200 applied to Invoice "I1"
        Amount[3] := -LibraryRandom.RandDec(Round(Amount[1] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[3]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliedDocNo);

        // [GIVEN] Payment "P3" with amount 800
        Amount[4] := -LibraryRandom.RandDec(1000, 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[4]);
        AppliedDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Sales Invoice "I2" with amount 300 applied to Payment "P3"
        Amount[5] := LibraryRandom.RandDec(Round(-Amount[4] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Amount[5]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Payment, AppliedDocNo);

        // [GIVEN] Sales Invoice "I3" with amount 400 applied to Payment "P3"
        Amount[6] := LibraryRandom.RandDec(Round(-Amount[4] / 3, 1), 2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Amount[6]);
        ApplyAndPostGenJournalLine(GenJournalLine, GenJournalLine."Applies-to Doc. Type"::Payment, AppliedDocNo);

        // [WHEN] Report "SR Cust. - Balance to Date" run filtered on "C1" customer and saved as excel
        Customer.SetRecFilter();
        LibraryReportValidation.SetFileName(Customer."No.");
        REPORT.SaveAsExcel(REPORT::"SR Cust. - Balance to Date", LibraryReportValidation.GetFileName(), Customer);

        // [THEN] 1st line: "I1".Amount = 900
        // [THEN] 2nd line: "P1".Amount = -200
        // [THEN] 3rd line: "P2".Amount = -300
        // [THEN] 4th line: "I1".Remaining Amount = 400
        // [THEN] 5th line: "P3".Amount = -800
        // [THEN] 6st line: "I2".Amount = 300
        // [THEN] 7th line: "I3".Amount = 400
        // [THEN] 8th line: "P3".Remaining Amount = -100
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(14, 17, Format(Amount[1]));
        LibraryReportValidation.VerifyCellValue(15, 17, Format(Amount[2]));
        LibraryReportValidation.VerifyCellValue(16, 17, Format(Amount[3]));
        LibraryReportValidation.VerifyCellValue(17, 17, Format(Amount[1] + Amount[2] + Amount[3]));
        LibraryReportValidation.VerifyCellValue(18, 17, Format(Amount[4]));
        LibraryReportValidation.VerifyCellValue(19, 17, Format(Amount[5]));
        LibraryReportValidation.VerifyCellValue(20, 17, Format(Amount[6]));
        LibraryReportValidation.VerifyCellValue(21, 17, Format(Amount[4] + Amount[5] + Amount[6]));
    end;

    [Test]
    [HandlerFunctions('CustBalanceToDateRequestPageHandlerSaveAsExcel')]
    [Scope('OnPrem')]
    procedure SalesInvoicesAndAppliedPaymentsOneTransaction()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: array[6] of Decimal;
        InvoiceNo: array[2] of Code[20];
    begin
        // [FEATURE] [Excel] [Application]
        // [SCENARIO 380055] Customer with sales invoices and applied payments when "SR Cust. - Balance to Date" Report is run
        Initialize();

        // [GIVEN] Customer with application Method "Apply to Oldest"
        LibrarySales.CreateCustomer(Customer);
        Customer."Application Method" := Customer."Application Method"::"Apply to Oldest";
        Customer.Modify();

        // [GIVEN] Sales Invoice "I1" with amount 200
        // [GIVEN] Sales Invoice "I2" with amount 300
        // [GIVEN] Payment "P1" with amount -150
        // [GIVEN] Payment "P2" with amount -250
        Amount[1] := LibraryRandom.RandDecInRange(100, 200, 2); // Invoice 1
        Amount[2] := LibraryRandom.RandDecInRange(200, 300, 2); // Invoice 2
        Amount[3] := -Round(Amount[1] / 3, 2); // Payment 1
        Amount[4] := -Round(Amount[2] / 3, 2); // Payment 2

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", Amount[1]);
        InvoiceNo[1] := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[3]);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo[1]);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Amount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        InvoiceNo[2] := GenJournalLine."Document No.";

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, Amount[4]);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo[2]);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Report "SR Cust. - Balance to Date" run filtered on "C1" customer and saved as excel
        Customer.SetRecFilter();
        LibraryReportValidation.SetFileName(Customer."No.");
        LibraryVariableStorage.Enqueue(true);
        REPORT.RunModal(REPORT::"SR Cust. - Balance to Date", true, false, Customer);

        // [THEN] "I1" fully applied. No Output for "I1"
        // [THEN] 1st line: "I1".Amount = 200
        // [THEN] 2nd line: "P1". Amount applied to "I1" = -150
        // [THEN] 3rd line: "I1".Remaining Amont = 50
        // [THEN] 4th line: "I2".Amount = 300
        // [THEN] 5th line: "P2". Amount applied to "I2" = -250
        // [THEN] 6th line: "I2".Remaining Amont = 50
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(14, 17, Format(Amount[1]));
        LibraryReportValidation.VerifyCellValue(15, 17, Format(Amount[3]));
        LibraryReportValidation.VerifyCellValue(16, 17, Format(Amount[1] + Amount[3]));
        LibraryReportValidation.VerifyCellValue(17, 17, Format(Amount[2]));
        LibraryReportValidation.VerifyCellValue(18, 17, Format(Amount[4]));
        LibraryReportValidation.VerifyCellValue(19, 17, Format(Amount[2] + Amount[4]));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustBalanceToDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerGroupFilterNewPagePerCustomer()
    var
        Customer: Record Customer;
        RowValue: Variant;
        CustomerPostingGroupCode: Code[20];
    begin
        // [SCENARIO 380482] Two Customers filtered on "Customer Posting Group" when "SR Cust. - Balance to Date" Report is run
        Initialize();

        // [GIVEN] Customer posting group "CPG"
        // [GIVEN] Customer "C1", "C1"."Customer Posting Group" = "CPG"
        // [GIVEN] Sales Invoice "SI1" for customer "C1"
        // [GIVEN] Customer "C2", "C2"."Customer Posting Group" = "CPG"
        // [GIVEN] Sales Invoice "SI2" for customer "C2"
        CustomerPostingGroupCode := TwoSalesInvoicesWithCustomerPostingGroup();

        Commit();

        // [WHEN] "SR Cust. - Balance to Date" run filtered on "Customer Posting Group" = "CPG", print one per page = TRUE
        Customer.SetFilter("Customer Posting Group", CustomerPostingGroupCode);
        REPORT.Run(REPORT::"SR Cust. - Balance to Date", true, false, Customer);

        // [THEN] 5 rows are generated
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(5, LibraryReportDataset.RowCount(), StrSubstNo(ReportEndDatasetErr, 5));

        // [THEN] Row[1]."OutputNo" = 1
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.FindCurrentRowValue(OutputNoTagTxt, RowValue);
        Assert.AreEqual(1, RowValue, StrSubstNo(ReportRowsErr, OutputNoTagTxt, 1));

        // [THEN] Row[3]."OutputNo" = 2
        LibraryReportDataset.MoveToRow(3);
        LibraryReportDataset.FindCurrentRowValue(OutputNoTagTxt, RowValue);
        Assert.AreEqual(2, RowValue, StrSubstNo(ReportRowsErr, OutputNoTagTxt, 2));

        // [THEN] Row[5] is the total row
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(TotalTagTxt, 'Total');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerGroupFilterNewPagePerCustomerExcel()
    var
        Customer: Record Customer;
        CustomerPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Excel]

        // [SCENARIO 380482] Two Customers filtered on "Customer Posting Group" when "SR Cust. - Balance to Date" Report is saved as excel
        Initialize();

        // [GIVEN] Customer posting group "CPG"
        // [GIVEN] Customer "C1", "C1"."Customer Posting Group" = "CPG"
        // [GIVEN] Sales Invoice "SI1" for customer "C1"
        // [GIVEN] Customer "C2", "C2"."Customer Posting Group" = "CPG"
        // [GIVEN] Sales Invoice "SI2" for customer "C2"
        CustomerPostingGroupCode := TwoSalesInvoicesWithCustomerPostingGroup();

        Commit();

        // [WHEN] "SR Cust. - Balance to Date" run filtered on "Customer Posting Group" = "CPG" and saved as excel file
        Customer.Init();
        Customer.SetFilter("Customer Posting Group", CustomerPostingGroupCode);
        LibraryReportValidation.SetFileName(CustomerPostingGroupCode);
        REPORT.SaveAsExcel(REPORT::"SR Cust. - Balance to Date", LibraryReportValidation.GetFileName(), Customer);

        // [THEN] 3 excel worksheets are generated
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(3, LibraryReportValidation.CountWorksheets(), CountOfSheetsErr);
    end;

    [Test]
    [HandlerFunctions('CustBalanceToDateRequestPageHandlerSaveAsExcel')]
    [Scope('OnPrem')]
    procedure VerifyReportTotalsPositionWithoutNewPagePerCustomer()
    var
        Customer: Record Customer;
        Amount: array[3] of Decimal;
    begin
        // [SCENARIO 251982] Report Totals are not moved to the new page if NewPagePerCustomer = FALSE.
        Initialize();

        // [GIVEN] One Sales Invoice with Payments for Customer. One Invoice will occupy one line in the Report and will not exceed one page.
        CreateSalesInvoiceWithAppliedPayments(Customer, Amount);
        Commit();

        // [WHEN] "SR Cust. - Balance to Date" run for Customer with NewPagePerCustomer = FALSE.
        LibraryReportValidation.SetFileName(Customer."No.");
        Customer.SetFilter("No.", Customer."No.");
        LibraryVariableStorage.Enqueue(false);

        REPORT.Run(REPORT::"SR Cust. - Balance to Date", true, false, Customer);

        // [THEN] Report contains 1 page, because Totals part is situated on the same page with Customer.
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(1, LibraryReportValidation.CountWorksheets(), CountOfPagesWithTotalsErr);

        // Tear Down.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustBalanceToDateRequestPageHandlerSaveAsExcel')]
    [Scope('OnPrem')]
    procedure VerifyReportTotalsPositionWithNewPagePerCustomer()
    var
        Customer: Record Customer;
        Amount: array[3] of Decimal;
    begin
        // [SCENARIO 251982] Report Totals are moved to the new page if NewPagePerCustomer = TRUE.
        Initialize();

        // [GIVEN] One Sales Invoice with Payments for Customer. One Invoice will occupy one line in the Report and will not exceed one page.
        CreateSalesInvoiceWithAppliedPayments(Customer, Amount);
        Commit();

        // [WHEN] "SR Cust. - Balance to Date" run for Customer with NewPagePerCustomer = TRUE.
        LibraryReportValidation.SetFileName(Customer."No.");
        Customer.SetFilter("No.", Customer."No.");
        LibraryVariableStorage.Enqueue(true);

        REPORT.Run(REPORT::"SR Cust. - Balance to Date", true, false, Customer);

        // [THEN] Report contains 2 pages, one for Customer and one for Totals.
        LibraryReportValidation.OpenExcelFile();
        Assert.AreEqual(2, LibraryReportValidation.CountWorksheets(), CountOfPagesWithTotalsErr);

        // Tear Down.
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);
        LibraryReportDataset.Reset();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
    end;

    local procedure CreateSalesInvoiceWithAppliedPayments(var Customer: Record Customer; var Amount: array[3] of Decimal)
    var
        AppliesToGenJournalLine: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        PostSalesDocument(
          AppliesToGenJournalLine, Customer, AppliesToGenJournalLine."Document Type"::Invoice,
          LibraryRandom.RandDec(1000, 2), '', WorkDate());
        Amount[1] := AppliesToGenJournalLine.Amount;
        PostAppliedSalesDocument(
          GenJournalLine, AppliesToGenJournalLine, GenJournalLine."Document Type"::Payment,
          -LibraryRandom.RandDecInDecimalRange(1, AppliesToGenJournalLine."Amount (LCY)" / 3, 2));
        Amount[2] := GenJournalLine.Amount;
        PostAppliedSalesDocument(
          GenJournalLine, AppliesToGenJournalLine, GenJournalLine."Document Type"::Payment,
          -LibraryRandom.RandDecInDecimalRange(1, AppliesToGenJournalLine."Amount (LCY)" / 3, 2));
        Amount[3] := GenJournalLine.Amount;
    end;

    local procedure TwoSalesInvoicesWithCustomerPostingGroup() CustomerPostingGroupCode: Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroupCode := CustomerPostingGroup.Code;
        PostSalesInvoiceWithCustomerPostingGroup(CustomerPostingGroupCode);
        PostSalesInvoiceWithCustomerPostingGroup(CustomerPostingGroupCode);
    end;

    local procedure PostSalesInvoiceWithCustomerPostingGroup(CustomerPostingGroupCode: Code[20])
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroupCode);
        Customer.Modify();
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", DocumentType,
          GenJournalLine."Account Type", GenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", Amount);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Modify(true);
    end;

    local procedure ApplyAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Type: Enum "Gen. Journal Document Type"; AppliedDocNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", Type);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostSalesDocument(var GenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostAppliedSalesDocument(var GenJournalLine: Record "Gen. Journal Line"; AppliedToGenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::Customer, AppliedToGenJournalLine."Account No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliedToGenJournalLine."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedToGenJournalLine."Document No.");
        GenJournalLine.Validate("Currency Code", AppliedToGenJournalLine."Currency Code");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyTagOnRows(XMLTag: Text)
    var
        RowValue: Variant;
    begin
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.FindCurrentRowValue(XMLTag, RowValue);
        Assert.AreEqual(RowValue, 1, StrSubstNo(ReportRowsErr, XMLTag, 1));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue(XMLTag, RowValue);
        Assert.AreEqual(RowValue, 2, StrSubstNo(ReportRowsErr, XMLTag, 2));
        LibraryReportDataset.GetNextRow();
        Assert.IsFalse(LibraryReportDataset.CurrentRowHasElement(XMLTag), ReportNoRowsErr);
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), StrSubstNo(ReportEndDatasetErr, 3));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustBalanceToDateRequestPageHandler(var SRCustBalanceToDateRequestPage: TestRequestPage "SR Cust. - Balance to Date")
    begin
        SRCustBalanceToDateRequestPage.FixedDay.SetValue(WorkDate());
        SRCustBalanceToDateRequestPage.PrintOnePerPage.SetValue(true);
        SRCustBalanceToDateRequestPage.CheckGLReceivables.SetValue(true);
        SRCustBalanceToDateRequestPage.PrintUnappliedEntries.SetValue(true);
        SRCustBalanceToDateRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustBalanceToDateRequestPageHandlerSaveAsExcel(var SRCustBalanceToDateRequestPage: TestRequestPage "SR Cust. - Balance to Date")
    begin
        SRCustBalanceToDateRequestPage.FixedDay.SetValue(WorkDate());
        SRCustBalanceToDateRequestPage.PrintOnePerPage.SetValue(LibraryVariableStorage.DequeueBoolean());
        SRCustBalanceToDateRequestPage.CheckGLReceivables.SetValue(true);
        SRCustBalanceToDateRequestPage.PrintUnappliedEntries.SetValue(true);
        SRCustBalanceToDateRequestPage.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

