// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50187 "Filename Test Data"
{
    // The business data the tests name, created by the tests themselves: customers, items and
    // vendors, posted sales and purchase invoices, sales documents, payment terms, reminders,
    // financial reports, and the test app's own proof documents. A test names a document of its own, built only from data it created and the
    // company's setup - posting groups, number series, report selections, the chart of accounts -
    // rather than whatever documents the company happens to hold, so its result does not depend on
    // which demo data, or how much of it, the database carries.

    Access = Internal;

    /// <summary>
    /// Posts a new sales invoice, for a new customer and a new item, and returns it.
    /// </summary>
    internal procedure PostNewInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        PostNewInvoice(CreateCustomer(), SalesInvoiceHeader);
    end;

    /// <summary>
    /// Posts a new sales invoice of a new item for the customer given, and returns it.
    /// </summary>
    internal procedure PostNewInvoice(CustomerNo: Code[20]; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        PostNewInvoice(CustomerNo, '', '', SalesInvoiceHeader);
    end;

    /// <summary>
    /// Posts a new sales invoice of a new item for the customer given, in the language and on the
    /// payment terms given (blank keeps the customer's), and returns it.
    /// </summary>
    /// <param name="CustomerNo">The customer.</param>
    /// <param name="LanguageCode">The invoice's language; blank for the customer's.</param>
    /// <param name="PaymentTermsCode">The invoice's payment terms; blank for the customer's.</param>
    /// <param name="SalesInvoiceHeader">Receives the posted invoice, filtered to itself.</param>
    internal procedure PostNewInvoice(CustomerNo: Code[20]; LanguageCode: Code[10]; PaymentTermsCode: Code[10]; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        PostNewInvoice(CustomerNo, LanguageCode, PaymentTermsCode, DefaultUnitPrice(), SalesInvoiceHeader);
    end;

    /// <summary>
    /// The same, with its one line sold at the unit price given - for a test whose invoices have to
    /// differ in amount, or need an amount large enough to carry a thousands separator.
    /// </summary>
    /// <param name="CustomerNo">The customer.</param>
    /// <param name="LanguageCode">The invoice's language; blank for the customer's.</param>
    /// <param name="PaymentTermsCode">The invoice's payment terms; blank for the customer's.</param>
    /// <param name="UnitPrice">The unit price of its one line, of quantity 1.</param>
    /// <param name="SalesInvoiceHeader">Receives the posted invoice, filtered to itself.</param>
    internal procedure PostNewInvoice(CustomerNo: Code[20]; LanguageCode: Code[10]; PaymentTermsCode: Code[10]; UnitPrice: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DraftNo: Code[20];
    begin
        CreateSalesDocument(SalesHeader."Document Type"::Invoice, CustomerNo, LanguageCode, SalesHeader);
        if PaymentTermsCode <> '' then
            SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
        DraftNo := SalesHeader."No.";

        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", LineNo());
        if SalesLine."Unit Price" <> UnitPrice then begin
            SalesLine.Validate("Unit Price", UnitPrice);
            SalesLine.Modify(true);
        end;

        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        // The invoice this posting produced, by the number it was drafted under - not the last one posted.
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", DraftNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.SetRecFilter();
    end;

    /// <summary>
    /// Posts new sales invoices, as many as given, all for one new customer, and returns their
    /// numbers in the order they were posted - which is their order by number, as the company's
    /// number series hands numbers out in ascending order.
    /// </summary>
    /// <param name="NumberOfInvoices">How many.</param>
    /// <param name="InvoiceNos">Receives the numbers of the posted invoices.</param>
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
    /// A new, unposted sales document of the type given - a quote, an order, an invoice - for the
    /// customer given, with one line of a new item.
    /// </summary>
    /// <param name="DocumentType">The type of document.</param>
    /// <param name="CustomerNo">The customer.</param>
    /// <param name="SalesHeader">Receives the document.</param>
    internal procedure CreateSalesDocument(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; var SalesHeader: Record "Sales Header")
    begin
        CreateSalesDocument(DocumentType, CustomerNo, '', SalesHeader);
    end;

    /// <summary>
    /// The same, in the language given. The language is set before the line is added: set on a
    /// document that has lines, Business Central says the lines were not updated, in a message no
    /// test expects.
    /// </summary>
    /// <param name="DocumentType">The type of document.</param>
    /// <param name="CustomerNo">The customer.</param>
    /// <param name="LanguageCode">The document's language; blank for the customer's.</param>
    /// <param name="SalesHeader">Receives the document.</param>
    internal procedure CreateSalesDocument(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LanguageCode: Code[10]; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        Clear(SalesHeader);
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        if LanguageCode <> '' then
            SalesHeader.Validate("Language Code", LanguageCode);
        SalesHeader.Modify(true);

        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine."Line No." := LineNo();
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", CreateItem());
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Unit Price", DefaultUnitPrice());
        SalesLine.Modify(true);
    end;

    /// <summary>
    /// The line number of a sales document's one line.
    /// </summary>
    local procedure LineNo(): Integer
    begin
        exit(10000);
    end;

    /// <summary>
    /// The unit price a sales document's one line is sold at unless a test says otherwise.
    /// </summary>
    local procedure DefaultUnitPrice(): Decimal
    begin
        exit(100);
    end;

    /// <summary>
    /// Posted sales invoice headers, written directly and without lines, for a test that needs many
    /// invoices in one selection and reads only their headers. Posting each would take minutes and
    /// prove nothing more. Numbered from the prefix given, which must not be a number series' own.
    /// </summary>
    /// <param name="NoPrefix">The prefix of their numbers.</param>
    /// <param name="CustomerNo">Their customer.</param>
    /// <param name="LanguageCode">Their language.</param>
    /// <param name="NumberOfInvoices">How many.</param>
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
    /// A sales header of the type given under the number given, written directly and without lines,
    /// for a test that needs documents of different types to share a number: Sales Header is keyed on
    /// Document Type and No., so Business Central allows it, but number series never produce it.
    ///
    /// When the company already has a document of that type under that number - a number series of
    /// that type overlapping the other's - the two numbers already collide, which is all a caller
    /// needs, so that document is left exactly as it is rather than the insert failing. Callers find
    /// their own documents by their own keys, never by this number alone.
    /// </summary>
    /// <param name="DocumentType">The type of document.</param>
    /// <param name="DocumentNo">Its number, which a document of another type already has.</param>
    /// <param name="CustomerNo">Its customer.</param>
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

    /// <summary>
    /// A new customer, numbered by the company's own number series, with posting groups the company has
    /// set up for sales: a customer posting group with a receivables account, and a general and a VAT
    /// business posting group that a sales posting setup exists for (FindSalesPostingSetup).
    /// </summary>
    /// <returns>The customer's number.</returns>
    internal procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindSalesPostingSetup(GeneralPostingSetup, VATPostingSetup);
        // The first with a receivables account; past the last, TestField says which is missing.
        CustomerPostingGroup.FindSet();
        while CustomerPostingGroup."Receivables Account" = '' do
            if CustomerPostingGroup.Next() = 0 then
                CustomerPostingGroup.TestField("Receivables Account");

        Customer.Init();
        Customer.Insert(true);
        Customer.Validate(Name, CustomerNameTok);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    /// <summary>
    /// A new item of type Service - so posting its sale needs no inventory posting setup and no stock -
    /// with a unit of measure the company has, and the product posting groups of the sales posting
    /// setup FindSalesPostingSetup chooses. Numbered by FreeCode rather than by the company's item
    /// number series: every document a test makes has an item of its own, the data a codeunit's tests
    /// make is rolled back only when the codeunit ends, and the demonstration company's series holds
    /// a hundred numbers - one codeunit used them up, and the series' warning then failed the tests.
    /// </summary>
    /// <returns>The item's number.</returns>
    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindSalesPostingSetup(GeneralPostingSetup, VATPostingSetup);
        UnitOfMeasure.FindFirst();

        Item.Init();
        Item."No." := FreeCode(Database::Item);
        Item.Insert(true);
        Item.Validate(Description, ItemDescriptionTok);
        Item.Validate(Type, Item.Type::Service);
        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Unit Price", 100);
        Item.Modify(true);
        exit(Item."No.");
    end;

    /// <summary>
    /// The first general posting setup that can post a sale - both groups set, a sales account, not
    /// blocked - and the first VAT posting setup that can: both groups set, normal VAT, a sales VAT
    /// account, not blocked. The two are independent, as they are in Business Central.
    /// </summary>
    local procedure FindSalesPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Sales Account", '<>%1', '');
        GeneralPostingSetup.SetRange(Blocked, false);
        GeneralPostingSetup.FindFirst();

        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        VATPostingSetup.SetRange(Blocked, false);
        VATPostingSetup.FindFirst();
    end;

    /// <summary>
    /// Posts a new purchase invoice, for a new vendor and a new item, and returns it.
    /// </summary>
    /// <param name="PurchInvHeader">Receives the posted invoice, filtered to itself.</param>
    internal procedure PostNewPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DraftNo: Code[20];
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        DraftNo := PurchaseHeader."No.";

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Insert(true);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", CreatePurchaseItem());
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Modify(true);

        PurchaseHeader.Receive := true;
        PurchaseHeader.Invoice := true;
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);

        PurchInvHeader.Reset();
        PurchInvHeader.SetRange("Pre-Assigned No.", DraftNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.SetRecFilter();
    end;

    /// <summary>
    /// A new vendor, numbered by the company's own number series, with posting groups the company has
    /// set up for purchases: a vendor posting group with a payables account, and a general and a VAT
    /// business posting group that a purchase posting setup exists for.
    /// </summary>
    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindPurchasePostingSetup(GeneralPostingSetup, VATPostingSetup);
        VendorPostingGroup.FindSet();
        while VendorPostingGroup."Payables Account" = '' do
            if VendorPostingGroup.Next() = 0 then
                VendorPostingGroup.TestField("Payables Account");

        Vendor.Init();
        Vendor.Insert(true);
        Vendor.Validate(Name, VendorNameTok);
        Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    /// <summary>
    /// A new item of type Service with the product posting groups of the purchase posting setup
    /// FindPurchasePostingSetup chooses, numbered by FreeCode as CreateItem's are.
    /// </summary>
    local procedure CreatePurchaseItem(): Code[20]
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindPurchasePostingSetup(GeneralPostingSetup, VATPostingSetup);
        UnitOfMeasure.FindFirst();

        Item.Init();
        Item."No." := FreeCode(Database::Item);
        Item.Insert(true);
        Item.Validate(Description, ItemDescriptionTok);
        Item.Validate(Type, Item.Type::Service);
        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    /// <summary>
    /// The first general posting setup that can post a purchase - both groups set, a purchase account,
    /// not blocked - and the first VAT posting setup that can: both groups set, normal VAT, a purchase
    /// VAT account, not blocked.
    /// </summary>
    local procedure FindPurchasePostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        GeneralPostingSetup.SetRange(Blocked, false);
        GeneralPostingSetup.FindFirst();

        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("Purchase VAT Account", '<>%1', '');
        VATPostingSetup.SetRange(Blocked, false);
        VATPostingSetup.FindFirst();
    end;

    /// <summary>
    /// New payment terms with the description given, under a code no other payment terms have.
    /// </summary>
    /// <param name="Description">The description, which is what a pattern names.</param>
    /// <returns>The code.</returns>
    internal procedure CreatePaymentTerms(Description: Text[100]): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Init();
        PaymentTerms.Code := CopyStr(FreeCode(Database::"Payment Terms"), 1, MaxStrLen(PaymentTerms.Code));
        PaymentTerms.Description := Description;
        Evaluate(PaymentTerms."Due Date Calculation", DueDateCalculationTok);
        PaymentTerms.Insert(true);
        exit(PaymentTerms.Code);
    end;

    /// <summary>
    /// New reminder terms with levels 1 to the number given and no attachment texts - so nothing in
    /// Base Application names a reminder's attachment from them, and a pattern decides.
    /// </summary>
    /// <param name="NumberOfLevels">How many levels.</param>
    /// <returns>The terms' code.</returns>
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
    /// An issued reminder at the level given, under the terms given, for the customer given and in the
    /// language given, written directly: issuing one for real needs overdue entries and posting setup
    /// that are not what the tests are about. It carries what the reminder report reads.
    /// </summary>
    /// <param name="CustomerNo">The customer.</param>
    /// <param name="ReminderTermsCode">The reminder terms.</param>
    /// <param name="Level">The reminder level.</param>
    /// <param name="LanguageCode">The reminder's language; blank for the customer's.</param>
    /// <param name="IssuedReminderHeader">Receives the reminder, filtered to itself.</param>
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
    /// A new financial report with a row definition and a column definition of its own. With a period
    /// column, one column is Net Change, so report 25 keeps its Starting Date; without, every column is
    /// Balance at Date, so report 25 can switch Starting Date off.
    /// </summary>
    /// <param name="Description">The report's description.</param>
    /// <param name="WithPeriodColumn">Whether one column is a period column.</param>
    /// <returns>The financial report's name.</returns>
    internal procedure CreateFinancialReport(Description: Text[80]; WithPeriodColumn: Boolean): Code[10]
    var
        FinancialReport: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
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

    /// <summary>
    /// Every posting account of the company's chart of accounts, as a totaling range: from the first
    /// account to the last.
    /// </summary>
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

    /// <summary>
    /// A new Filename Proof Document - the test app's own stand-in document - under a number no other
    /// has, carrying the customer name given.
    /// </summary>
    /// <param name="CustomerName">The name it carries.</param>
    /// <returns>Its number.</returns>
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
    /// Makes sure the Language table has the language given, so a document can carry it. A test can
    /// create the row; it cannot create Base Application's translations into that language.
    /// </summary>
    /// <param name="LanguageCode">The language code.</param>
    /// <param name="WindowsLanguageId">Its Windows language ID.</param>
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
    /// A code no record of the table has as the first field of its primary key: RFT followed by a
    /// number, the first that is free. Ten characters at most, so it fits every Code[10] key.
    /// </summary>
    /// <param name="TableNo">The table.</param>
    /// <returns>The code.</returns>
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
        CustomerNameTok: Label 'Report Filename Test Customer', Locked = true;
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
