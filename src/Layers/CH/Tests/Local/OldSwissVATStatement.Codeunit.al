codeunit 144012 "Old Swiss VAT Statement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCH: Codeunit "Library - CH";

    [Test]
    [HandlerFunctions('SwissOldVATStatementReportRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyTotalsOnOldSwissVATStatementReportBasedOnSalesInvoice()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoiceDocumentNumber: Code[20];
    begin
        // Setup.
        Initialize();

        // Create a new customer
        LibrarySales.CreateCustomer(Customer);

        // Create a new item
        LibraryInventory.CreateItem(Item);

        // Post sales invoice
        SalesInvoiceDocumentNumber := CreateAndPostSalesInvoice(Customer."No.", Item."No.", 1, LibraryRandom.RandInt(100));

        // Run the report
        RunReport(SalesInvoiceDocumentNumber);

        // Verify totals are correct.
        VerifyReport(SalesInvoiceDocumentNumber, true);
    end;

    [Test]
    [HandlerFunctions('SwissOldVATStatementReportRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyTotalsOnOldSwissVATStatementReportBasedOnPurchaseInvoice()
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        VendorNumber: Code[20];
        PurchaseInvoiceDocumentNumber: Code[20];
    begin
        Initialize();

        // Setup PostingSetup and VAT PostingSetup.
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Create a new item.
        LibraryInventory.CreateItem(Item);

        // Create a new vendor
        VendorNumber := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // Create and post purchase invoice.
        PurchaseInvoiceDocumentNumber := CreateAndPostPurchaseInvoice(VendorNumber, Item."No.", 1, LibraryRandom.RandInt(100));

        // Run the report
        RunReport(PurchaseInvoiceDocumentNumber);

        // Verify totals are correct.
        VerifyReport(PurchaseInvoiceDocumentNumber, false);
    end;

    local procedure UpdateSalesReceivablesSetup()
    var
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        SalesAndReceivablesSetup.Get();
        SalesAndReceivablesSetup.Validate("Stockout Warning", false);
        SalesAndReceivablesSetup.Validate("Credit Warnings", SalesAndReceivablesSetup."Credit Warnings"::"No Warning");
        SalesAndReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Validate("Allow VAT Difference", true);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure Initialize()
    begin
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateLocalData();
        UpdateSalesReceivablesSetup();
        UpdatePurchasesPayablesSetup();
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryCH.CreateVendor(Vendor, GenBusPostingGroup, VATBusPostingGroup);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerNumber: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNumber);
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNumber: Code[20]; ItemNumber: Code[20]; Quantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNumber);
        CreateSalesLine(SalesHeader, SalesLine, ItemNumber, Quantity, UnitPrice);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; VendorNumber: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendorNumber);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNumber: Code[20]; ItemNumber: Code[20]; Quantity: Decimal; UnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNumber);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNumber, Quantity, UnitCost);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure VerifyReport(DocumentNumber: Code[20]; IsAmountNegative: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNumber);
        VATEntry.FindFirst();

        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.SetRange('ExternalDocNo_VATEntry', VATEntry."External Document No.");
        LibraryReportDataset.GetNextRow();

        if IsAmountNegative then
            LibraryReportDataset.AssertCurrentRowValueEquals('Amt_VATEntry', -VATEntry.Amount)
        else
            LibraryReportDataset.AssertCurrentRowValueEquals('Amt_VATEntry', VATEntry.Amount)
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SwissOldVATStatementReportRequestPageHandler(var OldSwissVATStatement: TestRequestPage "Old Swiss VAT Statement")
    begin
        OldSwissVATStatement.OpenTillDate.SetValue(WorkDate());
        OldSwissVATStatement.NormalRatePerc.SetValue(LibraryRandom.RandInt(10));
        OldSwissVATStatement.ReducedRatePerc.SetValue(LibraryRandom.RandInt(10));
        OldSwissVATStatement.SpecialRatePerc.SetValue(LibraryRandom.RandInt(10));
        OldSwissVATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure RunReport(DocumentNumber: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNumber);

        // Run the report.
        Commit();
        REPORT.Run(REPORT::"Old Swiss VAT Statement", true, false, GLEntry);
    end;
}

