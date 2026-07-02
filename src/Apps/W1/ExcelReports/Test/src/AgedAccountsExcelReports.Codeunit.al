// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports.Test;

using Microsoft.Finance.ExcelReports;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 139555 "Aged Accounts Excel Reports"
{
    Subtype = Test;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        DocumentTypeShouldBeInvoiceErr: Label 'Document Type should be Invoice';
        DocumentNoShouldMatchErr: Label 'Document No should match the ledger entry';

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
    procedure AgedAccountsReceivableExcelReportExportsAsPerPeriodCount()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 640052] Aged Accounts Receivable Excel report exports as per Period count.
        InitializeAgingData();

        // [GIVEN] Customer "C" with an open customer ledger entry of type Invoice
        // Create customer directly to avoid VAT posting setup requirements in some localizations
        CreateMinimalCustomer(Customer);
        CreateCustLedgerEntry(CustLedgerEntry, Customer."No.", "Gen. Journal Document Type"::Invoice);
        Commit();

        // [WHEN] Running the Aged Accounts Receivable Excel report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Accounts Rec Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Accounts Rec Excel", Variant, RequestPageXml);

        // [THEN] The exported data does not exist.
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'No aging entry should be exported');
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
        EXRAgedAccountsRecExcel.OK().Invoke();
    end;
}