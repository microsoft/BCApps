// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50187 "Filename Test Data"
{
    // Creates the documents the tests name, from the company's setup only, so results do not depend
    // on which demo data the database carries.

    Access = Internal;

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

        // By the draft number, not the last one posted.
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", DraftNo);
        SalesInvoiceHeader.FindFirst();
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
    /// Type Service, so posting needs no inventory posting group or stock. Numbered by FreeCode, not
    /// the item number series, so creating items does not depend on that series.
    /// </summary>
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

    // Type Service and numbered by FreeCode, for the same reasons as CreateItem.
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
