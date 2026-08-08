// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reports;
using System.TestLibraries.Utilities;

codeunit 144050 "ERM Payment Tolerance"
{
    // // [FEATURE] [Payment Tolerance]

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ConfirmMessageForPaymentQst: Label 'Do you want to change all open entries for every customer and vendor that are not blocked';

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningPageHandler,VendorBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorDetaiTriallBalanceOnPmtTolerance()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntryInv: Record "Vendor Ledger Entry";
        VendorLedgerEntryPmt: Record "Vendor Ledger Entry";
        ApplicationDate: Date;
        PostedInvoiceNo: Code[20];
        PostedPmtNo: Code[20];
        InvoiceAmount: Decimal;
        AmountToApply: Decimal;
        MaxPaymentToleranceAmt: Decimal;
    begin
        // [FEATURE] [Application] [Purchases]
        // [SCENARIO 379007] Print Vendor Detail Trial Balance Report in case of Payment Tolerance
        Initialize();

        // [GIVEN] Setup Max Payment Tolerance Amount
        InvoiceAmount := LibraryRandom.RandDecInRange(10, 500, 2);
        MaxPaymentToleranceAmt := GetMaxPaymentTolerance(InvoiceAmount);

        // [GIVEN] Posted Purchase Invoice
        LibraryPurchase.CreateVendor(Vendor);
        ApplicationDate := LibraryRandom.RandDate(10);
        PostedInvoiceNo := PostPurchaseInvoiceWithTolerance(Vendor."No.", InvoiceAmount, ApplicationDate);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryInv, VendorLedgerEntryInv."Document Type"::Invoice, PostedInvoiceNo);

        // [GIVEN] Posted Payment
        AmountToApply := Round(InvoiceAmount - MaxPaymentToleranceAmt / 2);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        PostedPmtNo := CreateAndPostPayment(GenJournalLine, Vendor."No.", ApplicationDate, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryPmt, VendorLedgerEntryPmt."Document Type"::Payment, PostedPmtNo);

        // [GIVEN] Apply Vendor Payment to Vendor Invoice using Payment Tolerance
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntryInv);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntryPmt);
        VendorLedgerEntryPmt.Validate("Accepted Payment Tolerance", MaxPaymentToleranceAmt);
        VendorLedgerEntryPmt.Modify(true);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntryPmt);

        // [WHEN] Vendor Detail Trial Balance Report Run on Next Period
        RunVendorDetailedBalance(Vendor."No.", ApplicationDate);

        // [THEN] Report shows the zero balance - Nothing to Output
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'Balance is Not Zero');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentToleranceWarningPageHandler,CustomerBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetaiTriallBalanceOnPmtTolerance()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryInv: Record "Cust. Ledger Entry";
        CustLedgerEntryPmt: Record "Cust. Ledger Entry";
        ApplicationDate: Date;
        PostedInvoiceNo: Code[20];
        PostedPmtNo: Code[20];
        InvoiceAmount: Decimal;
        AmountToApply: Decimal;
        MaxPaymentToleranceAmt: Decimal;
    begin
        // [FEATURE] [Application] [Sales]
        // [SCENARIO 379007] Print Customer Detail Trial Balance Report in case of Payment Tolerance
        Initialize();

        // [GIVEN] Setup Max Payment Tolerance Amount
        InvoiceAmount := LibraryRandom.RandDecInRange(10, 500, 2);
        MaxPaymentToleranceAmt := GetMaxPaymentTolerance(InvoiceAmount);

        // [GIVEN] Posted Sales Invoice
        LibrarySales.CreateCustomer(Customer);
        ApplicationDate := LibraryRandom.RandDate(10);
        PostedInvoiceNo := PostSalesInvoiceWithTolerance(Customer."No.", InvoiceAmount, ApplicationDate);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryInv, CustLedgerEntryInv."Document Type"::Invoice, PostedInvoiceNo);

        // [GIVEN] Posted Payment
        AmountToApply := Round(InvoiceAmount - MaxPaymentToleranceAmt / 2);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        PostedPmtNo := CreateAndPostPayment(GenJournalLine, Customer."No.", ApplicationDate, -AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryPmt, CustLedgerEntryPmt."Document Type"::Payment, PostedPmtNo);

        // [GIVEN] Apply Customer Payment to Sales Invoice using Payment Tolerance
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryInv);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryPmt);
        CustLedgerEntryPmt.Validate("Accepted Payment Tolerance", MaxPaymentToleranceAmt);
        CustLedgerEntryPmt.Modify(true);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntryPmt);

        // [WHEN] Customer Detail Trial Balance Report Run on Next Period
        RunCustomerDetailedBalance(Customer."No.", ApplicationDate);

        // [THEN] Report shows the zero balance - Nothing to Output
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'Balance is Not Zero');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Tolerance");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance");

        IsInitialized := true;
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance");
    end;

    local procedure CreateAndPostPayment(var GenJournalLine: Record "Gen. Journal Line"; DocNo: Code[20]; ApplicationDate: Date; Amount: Decimal): Code[20]
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type", DocNo,
          Amount);
        GenJournalLine.Validate("Posting Date", ApplicationDate);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure EnqueueValuesForRequestPageHandler(No: Variant; DateFilter: Variant)
    begin
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(DateFilter);
    end;

    local procedure GetMaxPaymentTolerance(InvoiceAmount: Decimal) MaxPaymentToleranceAmount: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        UpdateGeneralLedgerSetup();
        RunChangePaymentTolerance('', LibraryRandom.RandDecInRange(2, 10, 2), LibraryRandom.RandDecInRange(2, 10, 2));
        GeneralLedgerSetup.Get();
        MaxPaymentToleranceAmount := Round(InvoiceAmount * GeneralLedgerSetup."Payment Tolerance %" / 100);
        GeneralLedgerSetup."Max. Payment Tolerance Amount" := MaxPaymentToleranceAmount;
        GeneralLedgerSetup.Modify();
        exit(MaxPaymentToleranceAmount);
    end;

    local procedure PostPurchaseInvoiceWithTolerance(VendorNo: Code[20]; var InvoiceAmount: Decimal; ApplicationDate: Date): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandIntInRange(2, 10));
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", ApplicationDate);
        PurchaseLine.Validate("Direct Unit Cost", InvoiceAmount);
        PurchaseLine.Modify(true);
        PurchaseHeader.CalcFields("Amount Including VAT");
        InvoiceAmount := PurchaseHeader."Amount Including VAT";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure PostSalesInvoiceWithTolerance(CustomerNo: Code[20]; var InvoiceAmount: Decimal; ApplicationDate: Date): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.",
          LibraryRandom.RandIntInRange(2, 10));
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", ApplicationDate);
        SalesLine.Validate("Unit Price", InvoiceAmount);
        SalesLine.Modify(true);
        SalesHeader.CalcFields("Amount Including VAT");
        InvoiceAmount := SalesHeader."Amount Including VAT";
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure RunChangePaymentTolerance(CurrencyCode: Code[10]; PaymentTolerance: Decimal; MaxPmtToleranceAmount: Decimal)
    var
        ChangePaymentTolerance: Report "Change Payment Tolerance";
    begin
        Clear(ChangePaymentTolerance);
        ChangePaymentTolerance.InitializeRequest(false, CurrencyCode, PaymentTolerance, MaxPmtToleranceAmount);
        ChangePaymentTolerance.UseRequestPage(false);
        ChangePaymentTolerance.Run();
    end;

    local procedure RunVendorDetailedBalance(VendorNo: Code[20]; ApplicationDate: Date)
    var
        DateFilter: Code[30];
    begin
        DateFilter := StrSubstNo('%1..%2', CalcDate('<CY+1Y>', ApplicationDate), CalcDate('<CY+2Y-1D>', ApplicationDate));
        EnqueueValuesForRequestPageHandler(VendorNo, DateFilter);
        REPORT.Run(REPORT::"Vendor Detail Trial Balance");
    end;

    local procedure RunCustomerDetailedBalance(CustomerNo: Code[20]; ApplicationDate: Date)
    var
        DateFilter: Code[30];
    begin
        DateFilter := StrSubstNo('%1..%2', CalcDate('<CY+1Y>', ApplicationDate), CalcDate('<CY+2Y-1D>', ApplicationDate));
        EnqueueValuesForRequestPageHandler(CustomerNo, DateFilter);
        REPORT.Run(REPORT::"Cust. Detail Trial Balance");
    end;

    local procedure UpdateGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate(
          "Payment Tolerance Posting", GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts");
        GeneralLedgerSetup.Validate(
          "Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts");
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", true);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", true);
        GeneralLedgerSetup.Modify(true);

        // Using Random Number for Payment Tolerance Percentage and Maximum Payment Tolerance Amount.
        RunChangePaymentTolerance('', LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = ConfirmMessageForPaymentQst);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarningPageHandler(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        // Modal Page Handler for Payment Tolerance Warning.
        PaymentToleranceWarning.InitializeOption(1);
        Response := ACTION::Yes
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBalanceRequestPageHandler(var CustomerDetailTrialBalance: TestRequestPage "Cust. Detail Trial Balance")
    begin
        CustomerDetailTrialBalance.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerDetailTrialBalance.Customer.SetFilter("Date Filter", LibraryVariableStorage.DequeueText());
        CustomerDetailTrialBalance.ExcludeCustomersBalanceOnly.SetValue(false);
        CustomerDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorBalanceRequestPageHandler(var VendorDetailTrialBalance: TestRequestPage "Vendor Detail Trial Balance")
    begin
        VendorDetailTrialBalance.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        VendorDetailTrialBalance.Vendor.SetFilter("Date Filter", LibraryVariableStorage.DequeueText());
        VendorDetailTrialBalance.ExcludeVendorsBalanceOnly.SetValue(false);
        VendorDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

