// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using System.Globalization;

codeunit 149537 "Filename Test Data"
{
    Access = Internal;

    internal procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        GLAccount: Record "G/L Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxGroup: Record "Tax Group";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchaseSetup: Record "Purchases & Payables Setup";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        if not CompanyInformation.Get() then begin
            CompanyInformation.Init();
            CompanyInformation.Insert();
        end;
        if CompanyInformation.Name = '' then begin
            CompanyInformation.Validate(Name, CompanyNameTok);
            CompanyInformation.Modify(true);
        end;
        if CompanyInformation."Bank Name" = '' then begin
            CompanyInformation.Validate("Bank Name", BankNameTok);
            CompanyInformation.Modify(true);
        end;

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then
            LibraryERM.SetLCYCode(LCYCodeTok);
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Inv. Rounding Precision (LCY)" = 0 then begin
            GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", 0.01);
            GeneralLedgerSetup.Modify(true);
        end;
        // These fixtures exercise report delivery, not VAT reporting periods or local VAT dates.
        if GeneralLedgerSetup."VAT Reporting Date Usage" <> GeneralLedgerSetup."VAT Reporting Date Usage"::Disabled then begin
            // Set the test precondition directly; CZ validation prompts for a production data migration.
            GeneralLedgerSetup."VAT Reporting Date Usage" := GeneralLedgerSetup."VAT Reporting Date Usage"::Disabled;
            GeneralLedgerSetup."VAT Reporting Date" := GeneralLedgerSetup."VAT Reporting Date"::"Posting Date";
            GeneralLedgerSetup.Modify(true);
        end;
        if TaxGroup.IsEmpty() then
            LibraryERM.CreateTaxGroup(TaxGroup);

        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        CompleteGeneralPostingSetup(GeneralPostingSetup);
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        if VATPostingSetup.IsEmpty() then
            LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        // The filter and unfiltered-run proofs need at least three accounts, even in an empty company.
        while GLAccount.Count() < 3 do
            LibraryERM.CreateGLAccount(GLAccount);

        if not SalesSetup.Get() then begin
            SalesSetup.Init();
            SalesSetup.Insert(true);
        end;
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesSetup.FieldNo("Customer Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesSetup.FieldNo("Order Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesSetup.FieldNo("Quote Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesSetup.FieldNo("Credit Memo Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesSetup.FieldNo("Posted Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesSetup.FieldNo("Posted Shipment Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesSetup.FieldNo("Posted Credit Memo Nos."));

        if not PurchaseSetup.Get() then begin
            PurchaseSetup.Init();
            PurchaseSetup.Insert(true);
        end;
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Purchases & Payables Setup", PurchaseSetup.FieldNo("Vendor Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Purchases & Payables Setup", PurchaseSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Purchases & Payables Setup", PurchaseSetup.FieldNo("Posted Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Purchases & Payables Setup", PurchaseSetup.FieldNo("Posted Receipt Nos."));
        SetupDocumentJournalTemplates();
        UpdateCountrySetup();
    end;

    local procedure UpdateCountrySetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PreviousSalesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        PreviousSalesSetup.Get();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        // BE replaces these on every call. Keep the fixture's numbering and templates across documents.
        SalesSetup.Get();
        SalesSetup.Validate("Customer Nos.", PreviousSalesSetup."Customer Nos.");
        SalesSetup.Validate("Invoice Nos.", PreviousSalesSetup."Invoice Nos.");
        SalesSetup.Validate("S. Invoice Template Name", PreviousSalesSetup."S. Invoice Template Name");
        SalesSetup.Validate("S. Cr. Memo Template Name", PreviousSalesSetup."S. Cr. Memo Template Name");
        SalesSetup.Modify(true);
    end;

    local procedure SetupDocumentJournalTemplates()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchaseSetup: Record "Purchases & Payables Setup";
    begin
        SalesSetup.Get();
        if SalesSetup."S. Invoice Template Name" = '' then begin
            SalesSetup.Validate(
                "S. Invoice Template Name",
                CreatePostingJournalTemplate(Enum::"Gen. Journal Template Type"::Sales, SalesSetup."Posted Invoice Nos."));
            SalesSetup.Modify(true);
        end;
        if SalesSetup."S. Cr. Memo Template Name" = '' then begin
            SalesSetup.Validate(
                "S. Cr. Memo Template Name",
                CreatePostingJournalTemplate(Enum::"Gen. Journal Template Type"::Sales, SalesSetup."Posted Credit Memo Nos."));
            SalesSetup.Modify(true);
        end;
        PurchaseSetup.Get();
        if PurchaseSetup."P. Invoice Template Name" = '' then begin
            PurchaseSetup.Validate(
                "P. Invoice Template Name",
                CreatePostingJournalTemplate(Enum::"Gen. Journal Template Type"::Purchases, PurchaseSetup."Posted Invoice Nos."));
            PurchaseSetup.Modify(true);
        end;
    end;

    local procedure CreatePostingJournalTemplate(TemplateType: Enum "Gen. Journal Template Type"; PostingNoSeries: Code[20]): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, TemplateType);
        GenJournalTemplate.Validate("Posting No. Series", PostingNoSeries);
        GenJournalTemplate.Modify(true);
        exit(GenJournalTemplate.Name);
    end;

    internal procedure SetupInvoiceReport()
    begin
        SetupReportSelection(Enum::"Report Selection Usage"::"S.Invoice", Report::"Standard Sales - Invoice");
    end;

    internal procedure SetupPurchaseInvoiceReport()
    begin
        SetupReportSelection(Enum::"Report Selection Usage"::"P.Invoice", Report::"Purchase - Invoice");
    end;

    internal procedure SetupDocumentReports()
    begin
        SetupInvoiceReport();
        SetupPurchaseInvoiceReport();
        SetupReportSelection(Enum::"Report Selection Usage"::"S.Invoice Draft", Report::"Standard Sales - Draft Invoice");
        SetupReportSelection(Enum::"Report Selection Usage"::"S.Quote", Report::"Standard Sales - Quote");
    end;

    local procedure SetupReportSelection(Usage: Enum "Report Selection Usage"; ReportId: Integer)
    var
        ReportSelections: Record "Report Selections";
        LibraryERM: Codeunit "Library - ERM";
    begin
        ReportSelections.SetRange(Usage, Usage);
        ReportSelections.DeleteAll();
        LibraryERM.SetupReportSelection(Usage, ReportId);
    end;

    internal procedure PostNewInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        PostNewInvoice(CreateCustomer(), SalesInvoiceHeader);
    end;

    internal procedure PostNewInvoice(CustomerNo: Code[20]; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        PostNewInvoice(CustomerNo, '', '', SalesInvoiceHeader);
    end;

    /// <summary>
    /// Blank LanguageCode or PaymentTermsCode keeps the customer's. Returns the invoice filtered to itself.
    /// </summary>
    internal procedure PostNewInvoice(CustomerNo: Code[20]; LanguageCode: Code[10]; PaymentTermsCode: Code[10]; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        PostNewInvoice(CustomerNo, LanguageCode, PaymentTermsCode, DefaultUnitPrice(), SalesInvoiceHeader);
    end;

    internal procedure PostNewInvoice(CustomerNo: Code[20]; LanguageCode: Code[10]; PaymentTermsCode: Code[10]; UnitPrice: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
        PostedInvoiceNo: Code[20];
    begin
        CreateSalesDocument(SalesHeader."Document Type"::Invoice, CustomerNo, LanguageCode, SalesHeader);
        if PaymentTermsCode <> '' then
            SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);

        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", LineNo());
        if SalesLine."Unit Price" <> UnitPrice then begin
            SalesLine.Validate("Unit Price", UnitPrice);
            SalesLine.Modify(true);
        end;

        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        SalesInvoiceHeader.SetRecFilter();
    end;

    /// <summary>
    /// Returns the numbers in posting order, which is also ascending number order.
    /// </summary>
    internal procedure PostInvoicesOfOneCustomer(NumberOfInvoices: Integer; var InvoiceNos: List of [Code[20]])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
        Counter: Integer;
    begin
        Clear(InvoiceNos);
        CustomerNo := CreateCustomer();
        for Counter := 1 to NumberOfInvoices do begin
            PostNewInvoice(CustomerNo, SalesInvoiceHeader);
            InvoiceNos.Add(SalesInvoiceHeader."No.");
        end;
    end;

    /// <summary>
    /// A new, unposted sales document with one line of a new item.
    /// </summary>
    internal procedure CreateSalesDocument(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; var SalesHeader: Record "Sales Header")
    begin
        CreateSalesDocument(DocumentType, CustomerNo, '', SalesHeader);
    end;

    /// <summary>
    /// The language is set before the line is added: changing it on a document with lines raises a
    /// message no test expects.
    /// </summary>
    internal procedure CreateSalesDocument(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LanguageCode: Code[10]; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
    begin
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        if LanguageCode <> '' then
            SalesHeader.Validate("Language Code", LanguageCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item,
            CreateItem(SalesHeader."Gen. Bus. Posting Group", SalesHeader."VAT Bus. Posting Group"), 1);
        SalesLine.Validate("Unit Price", DefaultUnitPrice());
        SalesLine.Modify(true);
    end;

    local procedure LineNo(): Integer
    begin
        exit(10000);
    end;

    local procedure DefaultUnitPrice(): Decimal
    begin
        exit(100);
    end;

    /// <summary>
    /// Headers only, written directly: for tests that need many invoices and read only headers, where
    /// posting each would be too slow. NoPrefix must not be a number series' own.
    /// </summary>
    internal procedure InsertInvoiceHeaders(NoPrefix: Code[10]; CustomerNo: Code[20]; LanguageCode: Code[10]; NumberOfInvoices: Integer)
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Counter: Integer;
    begin
        Customer.Get(CustomerNo);
        for Counter := 1 to NumberOfInvoices do begin
            SalesInvoiceHeader.Init();
            SalesInvoiceHeader."No." := CopyStr(NoPrefix + Format(Counter, 0, '<Integer,4><Filler Character,0>'), 1, MaxStrLen(SalesInvoiceHeader."No."));
            SalesInvoiceHeader."Sell-to Customer No." := Customer."No.";
            SalesInvoiceHeader."Bill-to Customer No." := Customer."No.";
            SalesInvoiceHeader."Sell-to Customer Name" := Customer.Name;
            SalesInvoiceHeader."Bill-to Name" := Customer.Name;
            SalesInvoiceHeader."Customer Posting Group" := Customer."Customer Posting Group";
            SalesInvoiceHeader."Language Code" := LanguageCode;
            SalesInvoiceHeader."Posting Date" := WorkDate();
            SalesInvoiceHeader."Document Date" := WorkDate();
            SalesInvoiceHeader."Due Date" := WorkDate();
            SalesInvoiceHeader.Insert(false);
        end;
    end;

    /// <summary>
    /// Written directly, for tests that need documents of different types to share a number, which
    /// cannot be relied on from number series. An existing document under that type and number
    /// already gives the collision, so it is left as it is.
    /// </summary>
    internal procedure InsertSalesHeaderUnderNo(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        if SalesHeader.Get(DocumentType, DocumentNo) then
            exit;
        Customer.Get(CustomerNo);
        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := DocumentNo;
        SalesHeader."Sell-to Customer No." := Customer."No.";
        SalesHeader."Bill-to Customer No." := Customer."No.";
        SalesHeader."Sell-to Customer Name" := Customer.Name;
        SalesHeader."Bill-to Name" := Customer.Name;
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader."Document Date" := WorkDate();
        SalesHeader.Insert(false);
    end;

    internal procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, CustomerNameTok);
        Customer.Validate("Payment Terms Code", CreatePaymentTerms(PaymentTermsTok));
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    /// <summary>
    /// Type Service, so posting needs no stock.
    /// </summary>
    local procedure CreateItem(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        // Use the document's business groups, not an unrelated pair found by the item helper.
        if not GeneralPostingSetup.Get(GenBusPostingGroup, Item."Gen. Prod. Posting Group") then
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, Item."Gen. Prod. Posting Group");
        CompleteGeneralPostingSetup(GeneralPostingSetup);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.FindFirst();
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate(Description, ItemDescriptionTok);
        Item.Validate(Type, Item.Type::Service);
        Item.Validate("Unit Price", 100);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CompleteGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupInvtAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    internal procedure PostNewPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        PostedInvoiceNo: Code[20];
    begin
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            CreateItem(PurchaseHeader."Gen. Bus. Posting Group", PurchaseHeader."VAT Bus. Posting Group"), 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Modify(true);

        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Reset();
        PurchInvHeader.Get(PostedInvoiceNo);
        PurchInvHeader.SetRecFilter();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, VendorNameTok);
        Vendor.Validate("Payment Terms Code", CreatePaymentTerms(PaymentTermsTok));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    internal procedure CreatePaymentTerms(Description: Text[100]): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // The localized library also creates IT payment lines; inserting only the header is insufficient.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate(Description, Description);
        if PaymentTerms.FieldActive("Due Date Calculation") then begin
            Evaluate(PaymentTerms."Due Date Calculation", DueDateCalculationTok);
            PaymentTerms.Validate("Due Date Calculation");
        end;
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    /// <summary>
    /// No attachment texts, so Base Application does not name the reminder's attachment and a pattern decides.
    /// </summary>
    internal procedure CreateReminderTerms(NumberOfLevels: Integer): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        Level: Integer;
    begin
        ReminderTerms.Init();
        ReminderTerms.Code := CopyStr(FreeCode(Database::"Reminder Terms"), 1, MaxStrLen(ReminderTerms.Code));
        ReminderTerms.Description := ReminderTermsTok;
        ReminderTerms.Insert(false);
        for Level := 1 to NumberOfLevels do begin
            ReminderLevel.Init();
            ReminderLevel."Reminder Terms Code" := ReminderTerms.Code;
            ReminderLevel."No." := Level;
            ReminderLevel.Insert(false);
        end;
        exit(ReminderTerms.Code);
    end;

    /// <summary>
    /// Written directly: issuing one for real needs overdue entries and posting setup the tests are
    /// not about. Blank LanguageCode keeps the customer's.
    /// </summary>
    internal procedure CreateIssuedReminder(CustomerNo: Code[20]; ReminderTermsCode: Code[10]; Level: Integer; LanguageCode: Code[10]; var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Clear(IssuedReminderHeader);
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." := CopyStr(FreeCode(Database::"Issued Reminder Header"), 1, MaxStrLen(IssuedReminderHeader."No."));
        IssuedReminderHeader."Customer No." := Customer."No.";
        IssuedReminderHeader.Name := Customer.Name;
        IssuedReminderHeader."Reminder Level" := Level;
        IssuedReminderHeader."Reminder Terms Code" := ReminderTermsCode;
        IssuedReminderHeader."Posting Date" := WorkDate();
        IssuedReminderHeader."Document Date" := WorkDate();
        IssuedReminderHeader."Due Date" := WorkDate();
        IssuedReminderHeader."Language Code" := Customer."Language Code";
        if LanguageCode <> '' then
            IssuedReminderHeader."Language Code" := LanguageCode;
        IssuedReminderHeader."Currency Code" := Customer."Currency Code";
        IssuedReminderHeader."Customer Posting Group" := Customer."Customer Posting Group";
        IssuedReminderHeader."Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
        IssuedReminderHeader."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
        IssuedReminderHeader.Address := Customer.Address;
        IssuedReminderHeader.City := Customer.City;
        IssuedReminderHeader."Post Code" := Customer."Post Code";
        IssuedReminderHeader."Country/Region Code" := Customer."Country/Region Code";
        IssuedReminderHeader.Insert(false);
        IssuedReminderHeader.SetRecFilter();
    end;

    /// <summary>
    /// With a period (Net Change) column report 25 keeps its Starting Date; with only Balance at Date
    /// columns its SetBudgetFilterEnable can switch Starting Date off.
    /// </summary>
    internal procedure CreateFinancialReport(Description: Text[80]; WithPeriodColumn: Boolean): Code[10]
    var
        FinancialReport: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        Initialize();
        AccScheduleName.Init();
        AccScheduleName.Name := CopyStr(FreeCode(Database::"Acc. Schedule Name"), 1, MaxStrLen(AccScheduleName.Name));
        AccScheduleName.Description := Description;
        AccScheduleName.Insert(true);
        AccScheduleLine.Init();
        AccScheduleLine."Schedule Name" := AccScheduleName.Name;
        AccScheduleLine."Line No." := 10000;
        AccScheduleLine."Row No." := RowNoTok;
        AccScheduleLine.Description := RowDescriptionTok;
        AccScheduleLine."Totaling Type" := AccScheduleLine."Totaling Type"::"Posting Accounts";
        AccScheduleLine.Totaling := AllPostingAccounts();
        AccScheduleLine.Insert(true);

        ColumnLayoutName.Init();
        ColumnLayoutName.Name := CopyStr(FreeCode(Database::"Column Layout Name"), 1, MaxStrLen(ColumnLayoutName.Name));
        ColumnLayoutName.Description := Description;
        ColumnLayoutName.Insert(true);
        ColumnLayout.Init();
        ColumnLayout."Column Layout Name" := ColumnLayoutName.Name;
        ColumnLayout."Line No." := 10000;
        ColumnLayout."Column No." := BalanceColumnNoTok;
        ColumnLayout."Column Header" := BalanceColumnHeaderTok;
        ColumnLayout."Column Type" := ColumnLayout."Column Type"::"Balance at Date";
        ColumnLayout.Insert(true);
        if WithPeriodColumn then begin
            ColumnLayout.Init();
            ColumnLayout."Column Layout Name" := ColumnLayoutName.Name;
            ColumnLayout."Line No." := 20000;
            ColumnLayout."Column No." := PeriodColumnNoTok;
            ColumnLayout."Column Header" := PeriodColumnHeaderTok;
            ColumnLayout."Column Type" := ColumnLayout."Column Type"::"Net Change";
            ColumnLayout.Insert(true);
        end;

        FinancialReport.Init();
        FinancialReport.Name := CopyStr(FreeCode(Database::"Financial Report"), 1, MaxStrLen(FinancialReport.Name));
        FinancialReport.Description := Description;
        FinancialReport."Financial Report Row Group" := AccScheduleName.Name;
        FinancialReport."Financial Report Column Group" := ColumnLayoutName.Name;
        FinancialReport.Insert(true);
        exit(FinancialReport.Name);
    end;

    local procedure AllPostingAccounts(): Text[250]
    var
        GLAccount: Record "G/L Account";
        FirstNo: Code[20];
    begin
        GLAccount.FindFirst();
        FirstNo := GLAccount."No.";
        GLAccount.FindLast();
        exit(CopyStr(FirstNo + '..' + GLAccount."No.", 1, 250));
    end;

    internal procedure CreateProofDocument(CustomerName: Text[100]): Code[20]
    var
        ProofDocument: Record "Filename Proof Document";
    begin
        ProofDocument.Init();
        ProofDocument."No." := FreeCode(Database::"Filename Proof Document");
        ProofDocument."Customer Name" := CustomerName;
        ProofDocument.Insert(false);
        exit(ProofDocument."No.");
    end;

    /// <summary>
    /// Creates the Language row only; Base Application's translations into it cannot be created.
    /// </summary>
    internal procedure EnsureLanguage(LanguageCode: Code[10]; WindowsLanguageId: Integer)
    var
        Language: Record Language;
    begin
        if Language.Get(LanguageCode) then
            exit;
        Language.Init();
        Language.Code := LanguageCode;
        Language.Name := LanguageCode;
        Language."Windows Language ID" := WindowsLanguageId;
        Language.Insert(true);
    end;

    /// <summary>
    /// The first free code of RFT and five digits for the table's first key field, so it fits every
    /// Code[10] key.
    /// </summary>
    local procedure FreeCode(TableNo: Integer): Code[20]
    var
        RecRef: RecordRef;
        KeyField: FieldRef;
        Candidate: Code[20];
        Counter: Integer;
    begin
        RecRef.Open(TableNo);
        KeyField := RecRef.KeyIndex(1).FieldIndex(1);
        repeat
            Counter += 1;
            Candidate := CopyStr(CodePrefixTok + Format(Counter, 0, '<Integer,5><Filler Character,0>'), 1, MaxStrLen(Candidate));
            KeyField.SetRange(Candidate);
        until RecRef.IsEmpty();
        RecRef.Close();
        exit(Candidate);
    end;

    var
        CompanyNameTok: Label 'Report Filename Test Company', Locked = true;
        BankNameTok: Label 'Report Filename Test Bank', Locked = true;
        LCYCodeTok: Label 'LCY', Locked = true;
        CustomerNameTok: Label 'Report Filename Test Customer', Locked = true;
        PaymentTermsTok: Label 'Report Filename Test Terms', Locked = true;
        VendorNameTok: Label 'Report Filename Test Vendor', Locked = true;
        ItemDescriptionTok: Label 'Report Filename Test Item', Locked = true;
        ReminderTermsTok: Label 'Report Filename Test Terms', Locked = true;
        DueDateCalculationTok: Label '<14D>', Locked = true;
        CodePrefixTok: Label 'RFT', Locked = true;
        RowNoTok: Label 'R1', Locked = true;
        RowDescriptionTok: Label 'All accounts', Locked = true;
        BalanceColumnNoTok: Label 'C1', Locked = true;
        BalanceColumnHeaderTok: Label 'Balance', Locked = true;
        PeriodColumnNoTok: Label 'C2', Locked = true;
        PeriodColumnHeaderTok: Label 'Net Change', Locked = true;
}
