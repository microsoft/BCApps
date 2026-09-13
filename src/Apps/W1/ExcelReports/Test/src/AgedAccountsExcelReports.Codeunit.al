// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports.Test;

using Microsoft.Finance.ExcelReports;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.ExcelReports;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.ExcelReports;
using Microsoft.Sales.Receivables;
using System.TestLibraries.Utilities;

codeunit 139555 "Aged Accounts Excel Reports"
{
    Subtype = Test;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        DocumentTypeShouldBeInvoiceErr: Label 'Document Type should be Invoice';
        DocumentNoShouldMatchErr: Label 'Document No should match the ledger entry';
        FilteredPostingGroupTok: Label 'EXRTOPLIST1', Locked = true;
        OtherPostingGroupTok: Label 'EXRTOPLIST2', Locked = true;
        ShowSalesTok: Label 'Sales (LCY)', Locked = true;
        ShowPurchasesTok: Label 'Purchases (LCY)', Locked = true;
        ShowBalanceTok: Label 'Balance (LCY)', Locked = true;
        OneRowExpectedErr: Label 'Only the customer or vendor in the filtered posting group should be exported';

    [Test]
    [HandlerFunctions('EXRAgedAccPayableExcelHandler')]
    procedure AgedAccountsPayableExportsDocumentTypeAndNo()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        ReportDocumentType: Text;
        ReportDocumentNo: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 622247] Aged Accounts Payable Excel report exports Document Type and Document No fields correctly for Invoice entries
        InitializeAgingData();

        // [GIVEN] Vendor "V" with an open vendor ledger entry of type Invoice
        // Create vendor directly to avoid VAT posting setup requirements in some localizations
        CreateMinimalVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", "Gen. Journal Document Type"::Invoice);
        Commit();

        // [WHEN] Running the Aged Accounts Payable Excel report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Acc Payable Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Acc Payable Excel", Variant, RequestPageXml);

        // [THEN] The exported data contains the Document Type "Invoice" and the correct Document No
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'One aging entry should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('DocumentType', Variant);
        ReportDocumentType := Variant;
        Assert.AreEqual(Format("Gen. Journal Document Type"::Invoice), ReportDocumentType, DocumentTypeShouldBeInvoiceErr);
        LibraryReportDataset.FindCurrentRowValue('DocumentNo', Variant);
        ReportDocumentNo := Variant;
        Assert.AreEqual(VendorLedgerEntry."Document No.", ReportDocumentNo, DocumentNoShouldMatchErr);
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccountsRecExcelHandler')]
    procedure AgedAccountsRecExportsDocumentTypeAndNo()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        ReportDocumentType: Text;
        ReportDocumentNo: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 622247] Aged Accounts Receivable Excel report exports Document Type and Document No fields correctly for Invoice entries
        InitializeAgingData();

        // [GIVEN] Customer "C" with an open customer ledger entry of type Invoice
        // Create customer directly to avoid VAT posting setup requirements in some localizations
        CreateMinimalCustomer(Customer);
        CreateCustLedgerEntry(CustLedgerEntry, Customer."No.", "Gen. Journal Document Type"::Invoice);
        Commit();

        // [WHEN] Running the Aged Accounts Receivable Excel report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Accounts Rec Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Accounts Rec Excel", Variant, RequestPageXml);

        // [THEN] The exported data contains the Document Type "Invoice" and the correct Document No
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'One aging entry should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('DocumentType', Variant);
        ReportDocumentType := Variant;
        Assert.AreEqual(Format("Gen. Journal Document Type"::Invoice), ReportDocumentType, DocumentTypeShouldBeInvoiceErr);
        LibraryReportDataset.FindCurrentRowValue('DocumentNo', Variant);
        ReportDocumentNo := Variant;
        Assert.AreEqual(CustLedgerEntry."Document No.", ReportDocumentNo, DocumentNoShouldMatchErr);
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccPayablePostingDateHandler')]
    procedure AgedAccountsPayableReportAgesByPostingDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        ReportingDateText: Text;
        ReportingDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Aged Accounts Payable report uses Posting Date as Reporting Date when aging by Posting Date
        InitializeAgingData();

        // [GIVEN] Vendor "V" with an open ledger entry where Posting Date, Document Date, and Due Date are distinct
        CreateMinimalVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", "Gen. Journal Document Type"::Invoice);
        VendorLedgerEntry."Document Date" := WorkDate() - 10;
        VendorLedgerEntry.Modify();
        Commit();

        // [WHEN] Running the Aged Accounts Payable Excel report with Aging By = Posting Date
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Acc Payable Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Acc Payable Excel", Variant, RequestPageXml);

        // [THEN] The Reporting Date matches the Posting Date of the vendor ledger entry
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'One aging entry should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('ReportingDate', Variant);
        ReportingDateText := Variant;
        Evaluate(ReportingDate, ReportingDateText);
        Assert.AreEqual(VendorLedgerEntry."Posting Date", ReportingDate, 'Reporting Date should match the Posting Date when aging by Posting Date');
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccountsRecExcelHandler')]
    procedure AgedAccountsRecRendersCurrencyCodePerEntry()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        UsdEntry, LcyEntry : Record "Cust. Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        LcyCode: Code[10];
        ForeignCurrencyCode: Code[10];
        DocNo, CurrencyCode : Text;
        i: Integer;
        UsdRowSeen, LcyRowSeen : Boolean;
    begin
        // [SCENARIO 637444] Aged Accounts Receivable Excel renders each row's own Currency Code, not a single per-customer value
        InitializeAgingData();

        // [GIVEN] G/L Setup with a distinct LCY Code
        LcyCode := 'LCY';
        ForeignCurrencyCode := 'USD';
        if not GeneralLedgerSetup.Get() then
            GeneralLedgerSetup.Insert();
        GeneralLedgerSetup."LCY Code" := LcyCode;
        GeneralLedgerSetup.Modify();

        // [GIVEN] A customer with one foreign-currency entry and one LCY (empty Currency Code) entry
        CreateMinimalCustomer(Customer);
        CreateCustLedgerEntry(UsdEntry, Customer."No.", "Gen. Journal Document Type"::Invoice, ForeignCurrencyCode);
        CreateCustLedgerEntry(LcyEntry, Customer."No.", "Gen. Journal Document Type"::Invoice, '');
        Commit();

        // [WHEN] Running the Aged Accounts Receivable Excel report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Accounts Rec Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Accounts Rec Excel", Variant, RequestPageXml);

        // [THEN] The foreign-currency row shows the foreign code and the LCY row shows the LCY code
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(2, LibraryReportDataset.RowCount(), 'Two aging entries should be exported');
        for i := 1 to 2 do begin
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.FindCurrentRowValue('DocumentNo', Variant);
            DocNo := Variant;
            LibraryReportDataset.FindCurrentRowValue('CurrencyCode', Variant);
            CurrencyCode := Variant;
            if DocNo = UsdEntry."Document No." then begin
                Assert.AreEqual(ForeignCurrencyCode, CurrencyCode, 'Foreign-currency row should show its own currency code');
                UsdRowSeen := true;
            end else
                if DocNo = LcyEntry."Document No." then begin
                    Assert.AreEqual(LcyCode, CurrencyCode, 'LCY (empty Currency Code) row should fall back to G/L Setup LCY Code');
                    LcyRowSeen := true;
                end;
        end;
        Assert.IsTrue(UsdRowSeen, 'Foreign-currency row should be present');
        Assert.IsTrue(LcyRowSeen, 'LCY row should be present');
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccPayableExcelHandler')]
    procedure AgedAccountsPayableRendersCurrencyCodePerEntry()
    var
        Vendor: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        UsdEntry, LcyEntry : Record "Vendor Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        LcyCode: Code[10];
        ForeignCurrencyCode: Code[10];
        DocNo, CurrencyCode : Text;
        i: Integer;
        UsdRowSeen, LcyRowSeen : Boolean;
    begin
        // [SCENARIO 637444] Aged Accounts Payable Excel renders each row's own Currency Code, not a single per-vendor value
        InitializeAgingData();

        // [GIVEN] G/L Setup with a distinct LCY Code
        LcyCode := 'LCY';
        ForeignCurrencyCode := 'USD';
        if not GeneralLedgerSetup.Get() then
            GeneralLedgerSetup.Insert();
        GeneralLedgerSetup."LCY Code" := LcyCode;
        GeneralLedgerSetup.Modify();

        // [GIVEN] A vendor with one foreign-currency entry and one LCY (empty Currency Code) entry
        CreateMinimalVendor(Vendor);
        CreateVendorLedgerEntry(UsdEntry, Vendor."No.", "Gen. Journal Document Type"::Invoice, ForeignCurrencyCode);
        CreateVendorLedgerEntry(LcyEntry, Vendor."No.", "Gen. Journal Document Type"::Invoice, '');
        Commit();

        // [WHEN] Running the Aged Accounts Payable Excel report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Acc Payable Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Acc Payable Excel", Variant, RequestPageXml);

        // [THEN] The foreign-currency row shows the foreign code and the LCY row shows the LCY code
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(2, LibraryReportDataset.RowCount(), 'Two aging entries should be exported');
        for i := 1 to 2 do begin
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.FindCurrentRowValue('DocumentNo', Variant);
            DocNo := Variant;
            LibraryReportDataset.FindCurrentRowValue('CurrencyCode', Variant);
            CurrencyCode := Variant;
            if DocNo = UsdEntry."Document No." then begin
                Assert.AreEqual(ForeignCurrencyCode, CurrencyCode, 'Foreign-currency row should show its own currency code');
                UsdRowSeen := true;
            end else
                if DocNo = LcyEntry."Document No." then begin
                    Assert.AreEqual(LcyCode, CurrencyCode, 'LCY (empty Currency Code) row should fall back to G/L Setup LCY Code');
                    LcyRowSeen := true;
                end;
        end;
        Assert.IsTrue(UsdRowSeen, 'Foreign-currency row should be present');
        Assert.IsTrue(LcyRowSeen, 'LCY row should be present');
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccountsRecExcelHandlerWorkdate')]
    procedure AgedAccountsRecExcelReportIncludesNotYetDueEntries()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        ReportDocumentNo: Text;
    begin
        // [SCENARIO] Aged Accounts Receivable Excel report includes open entries that are not yet due as of the Aged As Of date.
        InitializeAgingData();

        // [GIVEN] Customer "C" with an open ledger entry posted on WorkDate and due 30 days later
        CreateMinimalCustomer(Customer);
        CreateCustLedgerEntry(CustLedgerEntry, Customer."No.", "Gen. Journal Document Type"::Invoice);
        Commit();

        // [WHEN] Running the report with Aged As Of = WorkDate, Period Count = 1 and Aging by = Due Date
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Accounts Rec Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Accounts Rec Excel", Variant, RequestPageXml);

        // [THEN] The entry is still exported, even though its Due Date is after the Aged As Of date
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'The not yet due entry should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('DocumentNo', Variant);
        ReportDocumentNo := Variant;
        Assert.AreEqual(CustLedgerEntry."Document No.", ReportDocumentNo, DocumentNoShouldMatchErr);
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccPayableExcelHandlerWorkdate')]
    procedure AgedAccountsPayableExcelReportIncludesNotYetDueEntries()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        ReportDocumentNo: Text;
    begin
        // [SCENARIO] Aged Accounts Payable Excel report includes open entries that are not yet due as of the Aged As Of date.
        InitializeAgingData();

        // [GIVEN] Vendor "V" with an open ledger entry posted on WorkDate and due 30 days later
        CreateMinimalVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", "Gen. Journal Document Type"::Invoice);
        Commit();

        // [WHEN] Running the report with Aged As Of = WorkDate, Period Count = 1 and Aging by = Due Date
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Acc Payable Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Acc Payable Excel", Variant, RequestPageXml);

        // [THEN] The entry is still exported, even though its Due Date is after the Aged As Of date
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'The not yet due entry should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('DocumentNo', Variant);
        ReportDocumentNo := Variant;
        Assert.AreEqual(VendorLedgerEntry."Document No.", ReportDocumentNo, DocumentNoShouldMatchErr);
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccountsRecPostingDatePeriodCountHandler')]
    procedure AgedAccountsRecExcelReportPutsOlderEntriesInCatchAllBucket()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        PeriodEndText: Text;
        PeriodEnd: Date;
    begin
        // [SCENARIO] Entries older than the earliest period are exported into the open ended catch all bucket.
        InitializeAgingData();

        // [GIVEN] Customer "C" with an open ledger entry posted two months before the Aged As Of date
        CreateMinimalCustomer(Customer);
        CreateCustLedgerEntry(CustLedgerEntry, Customer."No.", "Gen. Journal Document Type"::Invoice);
        MoveCustLedgerEntryToDate(CustLedgerEntry, CalcDate('<-2M>', WorkDate()));
        Commit();

        // [WHEN] Running the report with Aging By = Posting Date, Aged As Of = WorkDate and Period Count = 1
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Accounts Rec Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Accounts Rec Excel", Variant, RequestPageXml);

        // [THEN] The entry is exported in the catch all bucket, which ends where the oldest requested period starts
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'The entry older than the earliest period should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('PeriodEnd', Variant);
        PeriodEndText := Variant;
        Evaluate(PeriodEnd, PeriodEndText);
        Assert.AreEqual(CalcDate('<-1M>', WorkDate()), PeriodEnd, 'The catch all bucket should end where the oldest requested period starts');
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccPayablePostingDatePeriodCountHandler')]
    procedure AgedAccountsPayableExcelReportPutsOlderEntriesInCatchAllBucket()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        PeriodEndText: Text;
        PeriodEnd: Date;
    begin
        // [SCENARIO] Entries older than the earliest period are exported into the open ended catch all bucket.
        InitializeAgingData();

        // [GIVEN] Vendor "V" with an open ledger entry posted two months before the Aged As Of date
        CreateMinimalVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", "Gen. Journal Document Type"::Invoice);
        MoveVendorLedgerEntryToDate(VendorLedgerEntry, CalcDate('<-2M>', WorkDate()));
        Commit();

        // [WHEN] Running the report with Aging By = Posting Date, Aged As Of = WorkDate and Period Count = 1
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Acc Payable Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Acc Payable Excel", Variant, RequestPageXml);

        // [THEN] The entry is exported in the catch all bucket, which ends where the oldest requested period starts
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'The entry older than the earliest period should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('PeriodEnd', Variant);
        PeriodEndText := Variant;
        Evaluate(PeriodEnd, PeriodEndText);
        Assert.AreEqual(CalcDate('<-1M>', WorkDate()), PeriodEnd, 'The catch all bucket should end where the oldest requested period starts');
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccountsRecPostingDateThreePeriodsHandler')]
    procedure AgedAccountsRecExcelPeriodStartAndEndComeFromSameBucket()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        PeriodStartText: Text;
        PeriodEndText: Text;
        PeriodStart: Date;
        PeriodEnd: Date;
        FirstPeriodStart: Date;
        SecondPeriodStart: Date;
    begin
        // [SCENARIO] Period Start Date and Period End Date are always read from the same bucket.
        InitializeAgingData();

        // [GIVEN] The period boundaries the report builds for Period Length = -1M and Aged As Of = WorkDate
        FirstPeriodStart := CalcDate('<-1M>', WorkDate());
        SecondPeriodStart := CalcDate('<-1M>', FirstPeriodStart);

        // [GIVEN] Customer "C" with an open ledger entry posted one day before the newest period starts
        CreateMinimalCustomer(Customer);
        CreateCustLedgerEntry(CustLedgerEntry, Customer."No.", "Gen. Journal Document Type"::Invoice);
        MoveCustLedgerEntryToDate(CustLedgerEntry, FirstPeriodStart - 1);
        Commit();

        // [WHEN] Running the report with Aging By = Posting Date, Aged As Of = WorkDate and Period Count = 3
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Accounts Rec Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Accounts Rec Excel", Variant, RequestPageXml);

        // [THEN] The entry is bucketed into the second period, and its end is that period's end, not the newest one
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'One aging entry should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('PeriodStart', Variant);
        PeriodStartText := Variant;
        Evaluate(PeriodStart, PeriodStartText);
        Assert.AreEqual(SecondPeriodStart, PeriodStart, 'The entry should start in the second period');
        LibraryReportDataset.FindCurrentRowValue('PeriodEnd', Variant);
        PeriodEndText := Variant;
        Evaluate(PeriodEnd, PeriodEndText);
        Assert.AreEqual(FirstPeriodStart, PeriodEnd, 'The period end should belong to the same bucket as the period start');
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccountsRecSkipZeroBalanceHandler')]
    procedure AgedAccountsRecExcelSkipZeroBalanceKeepsCustomerWithOldOpenEntry()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO] Skip Customers with Zero Balance compares the balance as of the Aged As Of date, not the net change over the reported periods, so a customer whose only open entry predates those periods is still reported.
        InitializeAgingData();

        // [GIVEN] Customer "C" whose only open ledger entry was posted six months before the Aged As Of date
        CreateMinimalCustomer(Customer);
        CreateCustLedgerEntry(CustLedgerEntry, Customer."No.", "Gen. Journal Document Type"::Invoice);
        MoveCustLedgerEntryToDate(CustLedgerEntry, CalcDate('<-6M>', WorkDate()));
        Commit();

        // [WHEN] Running the report with Skip Customers with Zero Balance enabled and Period Count = 1
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Accounts Rec Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Accounts Rec Excel", Variant, RequestPageXml);

        // [THEN] The customer is not skipped, because the balance as of the Aged As Of date is not zero
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'The customer with an outstanding balance should not be skipped');
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccPayableSkipZeroBalanceHandler')]
    procedure AgedAccountsPayableExcelSkipZeroBalanceKeepsVendorWithOldOpenEntry()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO] Skip Vendors with Zero Balance compares the balance as of the Aged As Of date, not the net change over the reported periods.
        InitializeAgingData();

        // [GIVEN] Vendor "V" whose only open ledger entry was posted six months before the Aged As Of date
        CreateMinimalVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", "Gen. Journal Document Type"::Invoice);
        MoveVendorLedgerEntryToDate(VendorLedgerEntry, CalcDate('<-6M>', WorkDate()));
        Commit();

        // [WHEN] Running the report with Skip Vendors with Zero Balance enabled and Period Count = 1
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Acc Payable Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Acc Payable Excel", Variant, RequestPageXml);

        // [THEN] The vendor is not skipped, because the balance as of the Aged As Of date is not zero
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'The vendor with an outstanding balance should not be skipped');
    end;

    [Test]
    [HandlerFunctions('CustomerTopListRequestPageHandler')]
    procedure TopCustomerListRankedByBalanceFiltersOnLedgerEntryPostingGroup()
    var
        FilteredCustomer: Record Customer;
        OtherCustomer: Record Customer;
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 649289] Ranking by balance, the posting group filter is resolved against the customer ledger entry and not against the blank "Posting Group" on the detailed entry
        InitializeAgingData();

        // [GIVEN] Two customers in different posting groups, where the detailed entries have a blank "Posting Group", as on cloud migrated data
        CreateCustomerInPostingGroup(FilteredCustomer, FilteredPostingGroupTok);
        CreateCustomerInPostingGroup(OtherCustomer, OtherPostingGroupTok);
        CreateCustomerLedgerData(FilteredCustomer."No.", FilteredPostingGroupTok, 2500, 1000);
        CreateCustomerLedgerData(OtherCustomer."No.", OtherPostingGroupTok, 5000, 4000);
        Commit();

        // [WHEN] Running the Customer - Top List (Excel) report ranked by balance, filtered on the first posting group
        RunCustomerTopList(ShowBalanceTok, FilteredPostingGroupTok, RequestPageXml, Variant);

        // [THEN] Only the customer in that posting group is exported, with its balance and its sales
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="TopCustomerData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), OneRowExpectedErr);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerNo', FilteredCustomer."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('AmountLCY', 1000);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount2LCY', 2500);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerTopListRequestPageHandler')]
    procedure TopCustomerListRankedBySalesReportsBalanceForTheSamePostingGroup()
    var
        FilteredCustomer: Record Customer;
        OtherCustomer: Record Customer;
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 649289] Ranking by sales, the balance column is filled from the balance query, which has to resolve the same posting group filter
        InitializeAgingData();

        // [GIVEN] Two customers in different posting groups, where the detailed entries have a blank "Posting Group"
        CreateCustomerInPostingGroup(FilteredCustomer, FilteredPostingGroupTok);
        CreateCustomerInPostingGroup(OtherCustomer, OtherPostingGroupTok);
        CreateCustomerLedgerData(FilteredCustomer."No.", FilteredPostingGroupTok, 2500, 1000);
        CreateCustomerLedgerData(OtherCustomer."No.", OtherPostingGroupTok, 5000, 4000);
        Commit();

        // [WHEN] Running the Customer - Top List (Excel) report ranked by sales, filtered on the first posting group
        RunCustomerTopList(ShowSalesTok, FilteredPostingGroupTok, RequestPageXml, Variant);

        // [THEN] Only the customer in that posting group is exported, with its sales and its balance
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="TopCustomerData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), OneRowExpectedErr);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerNo', FilteredCustomer."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('AmountLCY', 2500);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount2LCY', 1000);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorTopListRequestPageHandler')]
    procedure TopVendorListRankedByBalanceFiltersOnLedgerEntryPostingGroup()
    var
        FilteredVendor: Record Vendor;
        OtherVendor: Record Vendor;
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 649289] Ranking by balance, the posting group filter is resolved against the vendor ledger entry and not against the blank "Posting Group" on the detailed entry
        InitializeAgingData();

        // [GIVEN] Two vendors in different posting groups, where the detailed entries have a blank "Posting Group", as on cloud migrated data
        CreateVendorInPostingGroup(FilteredVendor, FilteredPostingGroupTok);
        CreateVendorInPostingGroup(OtherVendor, OtherPostingGroupTok);
        CreateVendorLedgerData(FilteredVendor."No.", FilteredPostingGroupTok, -2500, -1000);
        CreateVendorLedgerData(OtherVendor."No.", OtherPostingGroupTok, -5000, -4000);
        Commit();

        // [WHEN] Running the Vendor - Top List (Excel) report ranked by balance, filtered on the first posting group
        RunVendorTopList(ShowBalanceTok, FilteredPostingGroupTok, RequestPageXml, Variant);

        // [THEN] Only the vendor in that posting group is exported, with its balance and its purchases
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="TopVendorData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), OneRowExpectedErr);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('VendorNo', FilteredVendor."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('AmountLCY', 1000);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount2LCY', 2500);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorTopListRequestPageHandler')]
    procedure TopVendorListRankedByPurchasesReportsBalanceForTheSamePostingGroup()
    var
        FilteredVendor: Record Vendor;
        OtherVendor: Record Vendor;
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 649289] Ranking by purchases, the balance column is filled from the balance query, which has to resolve the same posting group filter
        InitializeAgingData();

        // [GIVEN] Two vendors in different posting groups, where the detailed entries have a blank "Posting Group"
        CreateVendorInPostingGroup(FilteredVendor, FilteredPostingGroupTok);
        CreateVendorInPostingGroup(OtherVendor, OtherPostingGroupTok);
        CreateVendorLedgerData(FilteredVendor."No.", FilteredPostingGroupTok, -2500, -1000);
        CreateVendorLedgerData(OtherVendor."No.", OtherPostingGroupTok, -5000, -4000);
        Commit();

        // [WHEN] Running the Vendor - Top List (Excel) report ranked by purchases, filtered on the first posting group
        RunVendorTopList(ShowPurchasesTok, FilteredPostingGroupTok, RequestPageXml, Variant);

        // [THEN] Only the vendor in that posting group is exported, with its purchases and its balance
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="TopVendorData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), OneRowExpectedErr);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('VendorNo', FilteredVendor."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('AmountLCY', 2500);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount2LCY', 1000);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure InitializeAgingData()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        LibraryVariableStorage.Clear();
        DetailedVendorLedgEntry.DeleteAll();
        DetailedCustLedgEntry.DeleteAll();
        VendorLedgerEntry.DeleteAll();
        CustLedgerEntry.DeleteAll();
        Vendor.DeleteAll();
        Customer.DeleteAll();
    end;

    local procedure CreateMinimalVendor(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Vendor."No."));
        Vendor.Name := Vendor."No.";
        Vendor.Insert();
    end;

    local procedure CreateMinimalCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Customer."No."));
        Customer.Name := Customer."No.";
        Customer.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CreateVendorLedgerEntry(VendorLedgerEntry, VendorNo, DocumentType, '');
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        EntryNo: Integer;
        Amount: Decimal;
    begin
        if VendorLedgerEntry.FindLast() then;
        EntryNo := VendorLedgerEntry."Entry No." + 1;

        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := EntryNo;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Vendor Name" := VendorNo;
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Document No." := 'DOC' + Format(EntryNo);
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document Date" := WorkDate();
        VendorLedgerEntry."Due Date" := WorkDate() + 30;
        VendorLedgerEntry."Currency Code" := CurrencyCode;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();

        // Create detailed vendor ledger entry for remaining amount
        Amount := -LibraryRandom.RandDec(1000, 2);
        if DetailedVendorLedgEntry.FindLast() then;
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Initial Entry";
        DetailedVendorLedgEntry.Amount := Amount;
        DetailedVendorLedgEntry."Amount (LCY)" := Amount;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure CreateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CreateCustLedgerEntry(CustLedgerEntry, CustomerNo, DocumentType, '');
    end;

    local procedure CreateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EntryNo: Integer;
        Amount: Decimal;
    begin
        if CustLedgerEntry.FindLast() then;
        EntryNo := CustLedgerEntry."Entry No." + 1;

        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := EntryNo;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Customer Name" := CustomerNo;
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := 'DOC' + Format(EntryNo);
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Document Date" := WorkDate();
        CustLedgerEntry."Due Date" := WorkDate() + 30;
        CustLedgerEntry."Currency Code" := CurrencyCode;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();

        // Create detailed customer ledger entry for remaining amount
        Amount := LibraryRandom.RandDec(1000, 2);
        if DetailedCustLedgEntry.FindLast() then;
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry."Entry No." + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry.Amount := Amount;
        DetailedCustLedgEntry."Amount (LCY)" := Amount;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure MoveCustLedgerEntryToDate(var CustLedgerEntry: Record "Cust. Ledger Entry"; NewPostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CustLedgerEntry."Posting Date" := NewPostingDate;
        CustLedgerEntry."Document Date" := NewPostingDate;
        CustLedgerEntry."Due Date" := NewPostingDate + 30;
        CustLedgerEntry.Modify();

        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.ModifyAll("Posting Date", NewPostingDate);
    end;

    local procedure MoveVendorLedgerEntryToDate(var VendorLedgerEntry: Record "Vendor Ledger Entry"; NewPostingDate: Date)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VendorLedgerEntry."Posting Date" := NewPostingDate;
        VendorLedgerEntry."Document Date" := NewPostingDate;
        VendorLedgerEntry."Due Date" := NewPostingDate + 30;
        VendorLedgerEntry.Modify();

        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry.ModifyAll("Posting Date", NewPostingDate);
    end;

    local procedure RunCustomerTopList(ShowValue: Text; PostingGroupCode: Code[20]; var RequestPageXml: Text; var Variant: Variant)
    begin
        LibraryVariableStorage.Enqueue(ShowValue);
        LibraryVariableStorage.Enqueue(PostingGroupCode);
        RequestPageXml := Report.RunRequestPage(Report::"EXR Customer Top List", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Customer Top List", Variant, RequestPageXml);
    end;

    local procedure RunVendorTopList(ShowValue: Text; PostingGroupCode: Code[20]; var RequestPageXml: Text; var Variant: Variant)
    begin
        LibraryVariableStorage.Enqueue(ShowValue);
        LibraryVariableStorage.Enqueue(PostingGroupCode);
        RequestPageXml := Report.RunRequestPage(Report::"EXR Vendor Top List", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Vendor Top List", Variant, RequestPageXml);
    end;

    local procedure CreateCustomerPostingGroup(PostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if CustomerPostingGroup.Get(PostingGroupCode) then
            exit;

        CustomerPostingGroup.Init();
        CustomerPostingGroup.Code := PostingGroupCode;
        CustomerPostingGroup.Insert();
    end;

    local procedure CreateVendorPostingGroup(PostingGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if VendorPostingGroup.Get(PostingGroupCode) then
            exit;

        VendorPostingGroup.Init();
        VendorPostingGroup.Code := PostingGroupCode;
        VendorPostingGroup.Insert();
    end;

    local procedure CreateCustomerInPostingGroup(var Customer: Record Customer; PostingGroupCode: Code[20])
    begin
        CreateCustomerPostingGroup(PostingGroupCode);

        Customer.Init();
        Customer."No." := GenerateAccountNo();
        Customer.Name := Customer."No.";
        Customer."Customer Posting Group" := PostingGroupCode;
        Customer.Insert();
    end;

    local procedure CreateVendorInPostingGroup(var Vendor: Record Vendor; PostingGroupCode: Code[20])
    begin
        CreateVendorPostingGroup(PostingGroupCode);

        Vendor.Init();
        Vendor."No." := GenerateAccountNo();
        Vendor.Name := Vendor."No.";
        Vendor."Vendor Posting Group" := PostingGroupCode;
        Vendor.Insert();
    end;

    local procedure CreateCustomerLedgerData(CustomerNo: Code[20]; PostingGroupCode: Code[20]; SalesLCY: Decimal; BalanceLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if CustLedgerEntry.FindLast() then;
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := CustLedgerEntry."Entry No." + 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Customer Name" := CustomerNo;
        CustLedgerEntry."Document Type" := "Gen. Journal Document Type"::Invoice;
        CustLedgerEntry."Document No." := 'DOC' + Format(CustLedgerEntry."Entry No.");
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Document Date" := WorkDate();
        CustLedgerEntry."Due Date" := WorkDate() + 30;
        CustLedgerEntry."Sales (LCY)" := SalesLCY;
        CustLedgerEntry."Customer Posting Group" := PostingGroupCode;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();

        if DetailedCustLedgEntry.FindLast() then;
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry."Entry No." + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry.Amount := BalanceLCY;
        DetailedCustLedgEntry."Amount (LCY)" := BalanceLCY;
        // Left blank on purpose, the column was added in v20 and is not backfilled on upgrade or cloud migration
        DetailedCustLedgEntry."Posting Group" := '';
        DetailedCustLedgEntry.Insert();
    end;

    local procedure CreateVendorLedgerData(VendorNo: Code[20]; PostingGroupCode: Code[20]; PurchaseLCY: Decimal; BalanceLCY: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if VendorLedgerEntry.FindLast() then;
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Vendor Name" := VendorNo;
        VendorLedgerEntry."Document Type" := "Gen. Journal Document Type"::Invoice;
        VendorLedgerEntry."Document No." := 'DOC' + Format(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document Date" := WorkDate();
        VendorLedgerEntry."Due Date" := WorkDate() + 30;
        VendorLedgerEntry."Purchase (LCY)" := PurchaseLCY;
        VendorLedgerEntry."Vendor Posting Group" := PostingGroupCode;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();

        if DetailedVendorLedgEntry.FindLast() then;
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Initial Entry";
        DetailedVendorLedgEntry.Amount := BalanceLCY;
        DetailedVendorLedgEntry."Amount (LCY)" := BalanceLCY;
        // Left blank on purpose, the column was added in v20 and is not backfilled on upgrade or cloud migration
        DetailedVendorLedgEntry."Posting Group" := '';
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure GenerateAccountNo() AccountNo: Code[20]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(AccountNo)));
    end;

    [RequestPageHandler]
    procedure EXRAgedAccPayableExcelHandler(var EXRAgedAccPayableExcel: TestRequestPage "EXR Aged Acc Payable Excel")
    begin
        EXRAgedAccPayableExcel.AgedAsOfOption.SetValue(WorkDate() + 30);
        EXRAgedAccPayableExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccountsRecExcelHandler(var EXRAgedAccountsRecExcel: TestRequestPage "EXR Aged Accounts Rec Excel")
    begin
        EXRAgedAccountsRecExcel.AgedAsOfOption.SetValue(WorkDate() + 30);
        EXRAgedAccountsRecExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccPayablePostingDateHandler(var EXRAgedAccPayableExcel: TestRequestPage "EXR Aged Acc Payable Excel")
    begin
        EXRAgedAccPayableExcel.AgedAsOfOption.SetValue(WorkDate() + 30);
        EXRAgedAccPayableExcel.AgingbyOption.SetValue('Posting Date');
        EXRAgedAccPayableExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccountsRecExcelHandlerWorkdate(var EXRAgedAccountsRecExcel: TestRequestPage "EXR Aged Accounts Rec Excel")
    begin
        EXRAgedAccountsRecExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccountsRecExcel.AgingbyOption.SetValue('Due Date');
        EXRAgedAccountsRecExcel.PeriodCountOption.SetValue(1);
        EXRAgedAccountsRecExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccPayableExcelHandlerWorkdate(var EXRAgedAccPayableExcel: TestRequestPage "EXR Aged Acc Payable Excel")
    begin
        EXRAgedAccPayableExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccPayableExcel.AgingbyOption.SetValue('Due Date');
        EXRAgedAccPayableExcel.PeriodCountOption.SetValue(1);
        EXRAgedAccPayableExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccountsRecPostingDatePeriodCountHandler(var EXRAgedAccountsRecExcel: TestRequestPage "EXR Aged Accounts Rec Excel")
    begin
        EXRAgedAccountsRecExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccountsRecExcel.AgingbyOption.SetValue('Posting Date');
        EXRAgedAccountsRecExcel.PeriodCountOption.SetValue(1);
        EXRAgedAccountsRecExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccPayablePostingDatePeriodCountHandler(var EXRAgedAccPayableExcel: TestRequestPage "EXR Aged Acc Payable Excel")
    begin
        EXRAgedAccPayableExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccPayableExcel.AgingbyOption.SetValue('Posting Date');
        EXRAgedAccPayableExcel.PeriodCountOption.SetValue(1);
        EXRAgedAccPayableExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccountsRecPostingDateThreePeriodsHandler(var EXRAgedAccountsRecExcel: TestRequestPage "EXR Aged Accounts Rec Excel")
    begin
        EXRAgedAccountsRecExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccountsRecExcel.AgingbyOption.SetValue('Posting Date');
        EXRAgedAccountsRecExcel.PeriodCountOption.SetValue(3);
        EXRAgedAccountsRecExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccountsRecSkipZeroBalanceHandler(var EXRAgedAccountsRecExcel: TestRequestPage "EXR Aged Accounts Rec Excel")
    begin
        EXRAgedAccountsRecExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccountsRecExcel.AgingbyOption.SetValue('Due Date');
        EXRAgedAccountsRecExcel.PeriodCountOption.SetValue(1);
        EXRAgedAccountsRecExcel."Skip Zero Balance Customers".SetValue(true);
        EXRAgedAccountsRecExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccPayableSkipZeroBalanceHandler(var EXRAgedAccPayableExcel: TestRequestPage "EXR Aged Acc Payable Excel")
    begin
        EXRAgedAccPayableExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccPayableExcel.AgingbyOption.SetValue('Due Date');
        EXRAgedAccPayableExcel.PeriodCountOption.SetValue(1);
        EXRAgedAccPayableExcel."Skip Zero Balance Vendors".SetValue(true);
        EXRAgedAccPayableExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CustomerTopListRequestPageHandler(var EXRCustomerTopList: TestRequestPage "EXR Customer Top List")
    begin
        EXRCustomerTopList.Show.SetValue(LibraryVariableStorage.DequeueText());
        EXRCustomerTopList.TopCustomerData.SetFilter("Customer Posting Group", LibraryVariableStorage.DequeueText());
        EXRCustomerTopList.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure VendorTopListRequestPageHandler(var EXRVendorTopList: TestRequestPage "EXR Vendor Top List")
    begin
        EXRVendorTopList.Show.SetValue(LibraryVariableStorage.DequeueText());
        EXRVendorTopList.TopVendorData.SetFilter("Vendor Posting Group", LibraryVariableStorage.DequeueText());
        EXRVendorTopList.OK().Invoke();
    end;
}
