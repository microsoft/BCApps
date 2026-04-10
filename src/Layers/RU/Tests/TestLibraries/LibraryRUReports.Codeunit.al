codeunit 143016 "Library RU Reports"
{
    Permissions = tabledata "FA Ledger Entry" = i;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LocalReportMgt: Codeunit "Local Report Management";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;

    [Scope('OnPrem')]
    procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "),
          LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SalesLineQty: Integer)
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        I: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibraryInventory.CreateItem(Item);

        for I := 1 to SalesLineQty do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
            SalesLine.Modify(true);
        end;
        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure GetSalesLinesAmountIncVAT(SalesHeader: Record "Sales Header"): Decimal
    begin
        SalesHeader.CalcFields("Amount Including VAT");
        exit(SalesHeader."Amount Including VAT");
    end;

    [Scope('OnPrem')]
    procedure GetInvoiceLinesAmountIncVAT(DocumentNo: Code[20]): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        exit(SalesInvoiceHeader."Amount Including VAT");
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "),
          LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; LineQty: Integer)
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(Vendor));

        for i := 1 to LineQty do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
              CreateItem(Vendor."VAT Bus. Posting Group"), LibraryRandom.RandDecInRange(5, 10, 2));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 1000, 2));
            PurchaseLine.Modify(true);
        end;

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateReleaseSalesInvoice(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CurrencyCode);
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure CreatePostPurchDocument(DocumentType: Enum "Purchase Document Type"; LineQty: Integer): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchDocument(PurchaseHeader, DocumentType, LineQty);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostSalesInvoice(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CurrencyCode);
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostSalesInvoiceAddSheet(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CurrencyCode);
        UpdateSalesHeaderWithAddSheetInfo(SalesHeader, '<1M>');
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostSalesInvoiceMultiLines(var CustomerNo: Code[20]; CurrencyCode: Code[10]; NormalVATRate: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATRate: array[3] of Decimal;
        i: Integer;
    begin
        VATRate[1] := NormalVATRate;
        VATRate[2] := 10;
        VATRate[3] := 0;

        LibraryERM.CreateVATPostingSetupWithAccounts(
          TempVATPostingSetup, TempVATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        for i := 1 to ArrayLen(VATRate) do begin
            LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
            VATPostingSetup[i] := TempVATPostingSetup;
            VATPostingSetup[i]."VAT Prod. Posting Group" := VATProdPostingGroup.Code;
            VATPostingSetup[i]."VAT %" := VATRate[i];
            VATPostingSetup[i]."VAT Identifier" := VATProdPostingGroup.Code;
            VATPostingSetup[i].Insert();
        end;

        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group");
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CurrencyCode);

        for i := 1 to ArrayLen(VATRate) do
            CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup[i]);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CurrencyCode);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostPurchaseInvoiceAddSheet(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CurrencyCode);
        UpdatePurchaseHeaderWithAddSheetInfo(PurchaseHeader, '<1M>');
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostPurchaseInvoiceMultiLines(var VendorNo: Code[20]; CurrencyCode: Code[10]; NormalVATRate: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATRate: array[3] of Decimal;
        i: Integer;
    begin
        VATRate[1] := NormalVATRate;
        VATRate[2] := 10;
        VATRate[3] := 0;

        LibraryERM.CreateVATPostingSetupWithAccounts(
          TempVATPostingSetup, TempVATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        for i := 1 to ArrayLen(VATRate) do begin
            LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
            VATPostingSetup[i] := TempVATPostingSetup;
            VATPostingSetup[i]."VAT Prod. Posting Group" := VATProdPostingGroup.Code;
            VATPostingSetup[i]."VAT %" := VATRate[i];
            VATPostingSetup[i]."VAT Identifier" := VATProdPostingGroup.Code;
            VATPostingSetup[i].Insert();
        end;

        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group");
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, CurrencyCode);

        for i := 1 to ArrayLen(VATRate) do
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup[i]);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateItem(VATBusPostGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryInventory.CreateItem(Item);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostGroup);
        VATPostingSetup.FindFirst();

        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(var Vendor: Record Vendor): Code[20]
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        CompanyInformation.Get();
        CreatePostCode(PostCode);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Vendor.Name), 0));
        Vendor.Validate("Name 2", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Vendor."Name 2"), 0));
        Vendor.Validate("Full Name", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Vendor."Full Name"), 0));
        Vendor."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        Vendor.Validate("KPP Code", LibraryUtility.GenerateGUID());
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Validate(Address, LibraryUtility.GenerateGUID());
        Vendor.Validate("Address 2", LibraryUtility.GenerateGUID());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(var Customer: Record Customer): Code[20]
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        CompanyInformation.Get();
        CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer.Name), 0));
        Customer.Validate("Name 2", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer."Name 2"), 0));
        Customer.Validate("Full Name", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer."Full Name"), 0));
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        Customer.Validate("KPP Code", LibraryUtility.GenerateGUID());
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Validate(Address, LibraryUtility.GenerateGUID());
        Customer.Validate("Address 2", LibraryUtility.GenerateGUID());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreatePostCode(var PostCode: Record "Post Code")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryERM.CreatePostCode(PostCode);
        PostCode.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        PostCode.Validate(County, LibraryUtility.GenerateGUID());
        PostCode.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATSettlementTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Init();
        GenJournalTemplate.Name := LibraryUtility.GenerateRandomCode(GenJournalTemplate.FieldNo(Name), DATABASE::"Gen. Journal Template");
        GenJournalTemplate.Type := GenJournalTemplate.Type::"VAT Settlement";
        GenJournalTemplate.Insert();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    [Scope('OnPrem')]
    procedure SuggestPostManualVATSettlement(VendorNo: Code[20])
    var
        TempVATDocEntryBuffer: Record "VAT Document Entry Buffer" temporary;
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        VATSettlementType: Option ,Purchase,Sale,"Fixed Asset","Future Expense";
    begin
        TempVATDocEntryBuffer.SetRange("CV No.", VendorNo);
        TempVATDocEntryBuffer.SetRange("Date Filter", 0D, WorkDate());
        VATSettlementMgt.Generate(TempVATDocEntryBuffer, VATSettlementType::Purchase);
        VATSettlementMgt.CopyToJnl(TempVATDocEntryBuffer, VATEntry);

        GetVATAgentPostingSetup(VATPostingSetup, VendorNo);
        PostVATSettlement(VATPostingSetup."VAT Settlement Template", VATPostingSetup."VAT Settlement Batch");
    end;

    [Scope('OnPrem')]
    procedure PostVATSettlement(VATSettlementTemplate: Code[10]; VATSettlementBatch: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
    begin
        GenJournalLine."Journal Template Name" := VATSettlementTemplate;
        GenJournalLine."Journal Batch Name" := VATSettlementBatch;
        Clear(GenJnlPostBatch);
        GenJnlPostBatch.VATSettlement(GenJournalLine);
    end;

    [Scope('OnPrem')]
    procedure MockDepreciationCode(): Code[10]
    var
        DepreciationCode: Record "Depreciation Code";
    begin
        DepreciationCode.Init();
        DepreciationCode.Code := LibraryUtility.GenerateGUID();
        DepreciationCode.Insert();
        exit(DepreciationCode.Code);
    end;

    [Scope('OnPrem')]
    procedure MockDepreciationGroup(): Code[10]
    var
        DepreciationGroup: Record "Depreciation Group";
    begin
        DepreciationGroup.Init();
        DepreciationGroup.Code := LibraryUtility.GenerateGUID();
        DepreciationGroup.Insert();
        exit(DepreciationGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure MockFADepreciationBook(var FADeprBook: Record "FA Depreciation Book")
    begin
        FADeprBook."Depreciation Starting Date" := GetRandomDate();
        FADeprBook."Disposal Date" := GetRandomDate();
        FADeprBook."Acquisition Date" := GetRandomDate();
        FADeprBook."G/L Acquisition Date" := GetRandomDate();
        FADeprBook."No. of Depreciation Months" := LibraryRandom.RandIntInRange(5, 7);
        FADeprBook."No. of Depreciation Years" := LibraryRandom.RandIntInRange(3, 5);
        FADeprBook."FA Posting Group" := MockFAPostingGroup();
        FADeprBook."Depreciation Method" := FADeprBook."Depreciation Method"::"Straight-Line";
        FADeprBook.Validate("Book Value", LibraryRandom.RandDec(100, 2));
        FADeprBook.Validate("Acquisition Cost", LibraryRandom.RandDec(100, 2));
        FADeprBook.Validate("Initial Acquisition Cost", LibraryRandom.RandDec(100, 2));
        FADeprBook.Validate("Acquisition Cost", LibraryRandom.RandDec(100, 2));
        FADeprBook.Validate(Depreciation, LibraryRandom.RandDec(100, 2));
        FADeprBook.Modify();
    end;

    [Scope('OnPrem')]
    procedure MockFALocation(): Code[10]
    var
        FALocation: Record "FA Location";
    begin
        FALocation.Init();
        FALocation.Code := LibraryUtility.GenerateGUID();
        FALocation.Insert();
        exit(FALocation.Code);
    end;

    [Scope('OnPrem')]
    procedure MockFAPostingGroup(): Code[20]
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        FAPostingGroup.Init();
        FAPostingGroup.Code := LibraryUtility.GenerateGUID();
        FAPostingGroup."Acquisition Cost Account" := MockGLAccount();
        FAPostingGroup.Insert();
        exit(FAPostingGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure MockGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := LibraryUtility.GenerateGUID();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure MockMainAssetComponent(FANo: Code[20])
    var
        MainAssetComponent: Record "Main Asset Component";
    begin
        MainAssetComponent.Init();
        MainAssetComponent."Main Asset No." := FANo;
        MainAssetComponent."FA No." := LibraryUtility.GenerateGUID();
        MainAssetComponent.Description := MainAssetComponent."FA No.";
        MainAssetComponent.Quantity := LibraryRandom.RandInt(100);
        MainAssetComponent.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockItemFAPreciousMetal(FANo: Code[20])
    var
        ItemFAPreciousMetal: Record "Item/FA Precious Metal";
    begin
        ItemFAPreciousMetal.Init();
        ItemFAPreciousMetal."Item Type" := ItemFAPreciousMetal."Item Type"::FA;
        ItemFAPreciousMetal."No." := FANo;
        ItemFAPreciousMetal."Precious Metals Code" := MockPreciousMetal();
        ItemFAPreciousMetal.Quantity := LibraryRandom.RandInt(100);
        ItemFAPreciousMetal.Mass := LibraryRandom.RandDec(100, 2);
        ItemFAPreciousMetal.Insert();
    end;

    local procedure MockPreciousMetal(): Code[10]
    var
        PreciousMetal: Record "Precious Metal";
    begin
        PreciousMetal.Init();
        PreciousMetal.Code := LibraryUtility.GenerateGUID();
        PreciousMetal.Name := PreciousMetal.Code;
        PreciousMetal.Insert();
        exit(PreciousMetal.Code);
    end;

    [Scope('OnPrem')]
    procedure GetPurchaseTotalAmount(DocumentType: Enum "Purchase Document Type"; OrderNo: Code[20]): Text
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, OrderNo);
        PurchaseHeader.CalcFields(Amount);
        exit(FormatAmount(PurchaseHeader.Amount));
    end;

    [Scope('OnPrem')]
    procedure GetPurchaseTotalAmountIncVAT(DocumentType: Enum "Purchase Document Type"; OrderNo: Code[20]): Text
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, OrderNo);
        PurchaseHeader.CalcFields("Amount Including VAT");
        exit(FormatAmount(PurchaseHeader."Amount Including VAT"));
    end;

    [Scope('OnPrem')]
    procedure GetPostedPurchaseTotalAmount(DocumentNo: Code[20]): Text
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields(Amount);
        exit(FormatAmount(PurchInvHeader.Amount));
    end;

    [Scope('OnPrem')]
    procedure GetPostedPurchaseTotalAmountIncVAT(DocumentNo: Code[20]): Text
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        exit(FormatAmount(PurchInvHeader."Amount Including VAT"));
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            exit;

        GLSetup.Get();
        if GLSetup."LCY Code" = CurrencyCode then
            exit;

        if LocalReportMgt.IsConventionalCurrency(CurrencyCode) then
            exit;

        if Currency.Get(CurrencyCode) then begin
            if Currency."RU Bank Digital Code" <> '' then
                exit(Currency."RU Bank Digital Code");
            exit(Currency.Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCustomerFullAddress(CustomerNo: Code[20]): Text
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        exit(LocalReportMgt.GetFullAddr(Customer."Post Code", Customer.City, Customer.Address, Customer."Address 2", '', Customer.County));
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    var
        StdRepMgt: Codeunit "Local Report Management";
    begin
        exit(StdRepMgt.FormatReportValue(Amount, 2));
    end;

    [Scope('OnPrem')]
    procedure FormatAmountXML(DecValue: Decimal): Text
    begin
        exit(Format(DecValue, 0, '<Precision,2:2><Sign><Integer><Decimals><comma,.>'));
    end;

    local procedure GetRandomDate(): Date
    begin
        exit(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
    end;

    [Scope('OnPrem')]
    procedure GetFirstFADeprBook(FANo: Code[20]): Code[10]
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.FindFirst();
        exit(FADepreciationBook."Depreciation Book Code");
    end;

    [Scope('OnPrem')]
    procedure GetVATAgentPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", Vendor."VAT Agent Prod. Posting Group");
    end;

    [Scope('OnPrem')]
    procedure GetRandomVATRegNoForCVType(CVType: Option Person,Company): Text[12]
    begin
        case CVType of
            CVType::Person:
                exit(CopyStr(LibraryUtility.GenerateRandomXMLText(12), 1, 12));  // individual\person
            CVType::Company:
                exit(CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, 10));  // company\organization
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithCost(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateLocation(UseAsTransit: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Use As In-Transit", UseAsTransit);
        Location.Modify(true);
        exit(Location.Code);
    end;

    [Scope('OnPrem')]
    procedure InitItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; Type: Enum "Item Journal Template Type"; ClearJnl: Boolean)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, Type, ItemJournalTemplate.Name);
        if ClearJnl then
            LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        ItemJnlLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
        ItemJnlLine."Journal Batch Name" := ItemJournalBatch.Name;
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostItemJournalLine(LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; ClearJnl: Boolean)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        InitItemJournalLine(ItemJnlLine, ItemJournalTemplate.Type::Item, ClearJnl);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemNo, 0);
        ItemJnlLine.Validate("Location Code", LocationCode);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    [Scope('OnPrem')]
    procedure CreateStatutoryReport(var StatutoryReport: Record "Statutory Report")
    begin
        StatutoryReport.Init();
        StatutoryReport.Code :=
          LibraryUtility.GenerateRandomCode(StatutoryReport.FieldNo(Code), DATABASE::"Statutory Report");
        StatutoryReport.Insert();
    end;

    [Scope('OnPrem')]
    procedure UpdateCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CompanyInformation.Name), 0));
        CompanyInformation.Validate("Name 2", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CompanyInformation."Name 2"), 0));
        CompanyInformation.Validate("Full Name", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CompanyInformation."Full Name"), 0));
        CompanyInformation."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        CompanyInformation.Validate("KPP Code", LibraryUtility.GenerateGUID());
        CompanyInformation.Modify();
    end;

    [Scope('OnPrem')]
    procedure UpdateCompanyTypeInfo(Type: Option)
    var
        CompanyInfo: Record "Company Information";
        CompanyType: Option Person,Organization;
    begin
        CompanyInfo.Get();
        case Type of
            CompanyType::Organization:
                CompanyInfo.Validate("KPP Code", CopyStr(LibraryUtility.GenerateRandomXMLText(9), 1, 9));
            CompanyType::Person:
                CompanyInfo.Validate("KPP Code", '');
        end;
        CompanyInfo."VAT Registration No." := GetRandomVATRegNoForCVType(Type);
        CompanyInfo.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateVATPostingSetupWithManualVATSettlement(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateVATSettlementTemplateAndBatch(GenJournalBatch);
        VATPostingSetup.Validate("Manual VAT Settlement", true);
        VATPostingSetup.Validate("VAT Settlement Template", GenJournalBatch."Journal Template Name");
        VATPostingSetup.Validate("VAT Settlement Batch", GenJournalBatch.Name);
        VATPostingSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure UpdateCompanyAddress()
    var
        CompanyAddress: Record "Company Address";
        PostCode: Record "Post Code";
    begin
        CreatePostCode(PostCode);
        CompanyAddress.FindFirst();
        CompanyAddress.Validate("Post Code", PostCode.Code);
        CompanyAddress.Validate("Region Name", LibraryUtility.GenerateGUID());
        CompanyAddress.Validate(Address, LibraryUtility.GenerateGUID());
        CompanyAddress.Validate("Address 2", LibraryUtility.GenerateGUID());
        CompanyAddress.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateCustomerPrepmtAccountVATRate(CustomerNo: Code[20]; VATRate: Decimal)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // Copy paste existing setup and insert a new one with given VAT Rate
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GLAccount.Get(CustomerPostingGroup."Prepayment Account");
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");

        VATPostingSetup.Validate("VAT %", VATRate);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Insert(true);

        GLAccount.Validate("No.", LibraryUtility.GenerateGUID());
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Insert(true);

        CustomerPostingGroup.Validate(Code, LibraryUtility.GenerateGUID());
        CustomerPostingGroup.Validate("Prepayment Account", GLAccount."No.");
        CustomerPostingGroup.Insert(true);

        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateSalesHeaderWithAddSheetInfo(var SalesHeader: Record "Sales Header"; PostingDateCalcFormula: Code[10])
    var
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, PostingDateCalcFormula);
        SalesHeader.Validate("Posting Date", CalcDate(DateFormula, WorkDate()));
        SalesHeader.Validate("Additional VAT Ledger Sheet", true);
        SalesHeader.Validate("Corrected Document Date", WorkDate());
        SalesHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchaseHeaderWithAddSheetInfo(var PurchaseHeader: Record "Purchase Header"; PostingDateCalcFormula: Code[10])
    var
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, PostingDateCalcFormula);
        PurchaseHeader.Validate("Posting Date", CalcDate(DateFormula, WorkDate()));
        PurchaseHeader.Validate("Additional VAT Ledger Sheet", true);
        PurchaseHeader.Validate("Corrected Document Date", WorkDate());
        PurchaseHeader.Modify(true);
        UpdatePurchaseHeaderWithVendorVATInvoiceInfo(PurchaseHeader, '', WorkDate());
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchaseHeaderWithVendorVATInvoiceInfo(var PurchaseHeader: Record "Purchase Header"; VendVATInvNo: Code[30]; VendorVATInvDate: Date)
    begin
        PurchaseHeader.Validate("Vendor VAT Invoice No.", VendVATInvNo);
        PurchaseHeader.Validate("Vendor VAT Invoice Date", VendorVATInvDate);
        PurchaseHeader.Validate("Vendor VAT Invoice Rcvd Date", VendorVATInvDate);
        PurchaseHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateCustomerType(CustomerNo: Code[20]; CustomerType: Option Person,Company)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("KPP Code", CopyStr(LibraryUtility.GenerateRandomXMLText(9), 1, 9));
        Customer."VAT Registration No." := GetRandomVATRegNoForCVType(CustomerType);
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateVendorType(VendorNo: Code[20]; VendorType: Option Person,Company)
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("KPP Code", CopyStr(LibraryUtility.GenerateRandomXMLText(9), 1, 9));
        Vendor."VAT Registration No." := GetRandomVATRegNoForCVType(VendorType);
        Vendor.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure FindVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; LedgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20])
    begin
        VATLedgerLine.SetRange(Type, LedgerType);
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("C/V No.", CVNo);
        VATLedgerLine.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure VerifyVATLedgerLineCustomerDetails(VATLedgerType: Option; VATLedgerCode: Code[20]; CustomerNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        FindVATLedgerLine(VATLedgerLine, VATLedgerType, VATLedgerCode, CustomerNo);
        Assert.AreEqual(LocalReportMgt.GetCustName(CustomerNo), VATLedgerLine."C/V Name", VATLedgerLine.FieldCaption("C/V Name"));
        Assert.AreEqual(Customer."VAT Registration No.", VATLedgerLine."C/V VAT Reg. No.", VATLedgerLine.FieldCaption("C/V VAT Reg. No."));
        Assert.AreEqual(Customer."KPP Code", VATLedgerLine."Reg. Reason Code", VATLedgerLine.FieldCaption("Reg. Reason Code"));
    end;

    [Scope('OnPrem')]
    procedure VerifyVATLedgerLineVendorDetails(VATLedgerType: Option; VATLedgerCode: Code[20]; VendorNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        FindVATLedgerLine(VATLedgerLine, VATLedgerType, VATLedgerCode, VendorNo);
        Assert.AreEqual(LocalReportMgt.GetVendorName(VendorNo), VATLedgerLine."C/V Name", VATLedgerLine.FieldCaption("C/V Name"));
        Assert.AreEqual(Vendor."VAT Registration No.", VATLedgerLine."C/V VAT Reg. No.", VATLedgerLine.FieldCaption("C/V VAT Reg. No."));
        Assert.AreEqual(Vendor."KPP Code", VATLedgerLine."Reg. Reason Code", VATLedgerLine.FieldCaption("Reg. Reason Code"));
    end;

    [Scope('OnPrem')]
    procedure VerifyVATLedgerLineCompanyDetails(VATLedgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        FindVATLedgerLine(VATLedgerLine, VATLedgerType, VATLedgerCode, CVNo);
        Assert.AreEqual(LocalReportMgt.GetCompanyName(), VATLedgerLine."C/V Name", VATLedgerLine.FieldCaption("C/V Name"));
        Assert.AreEqual(CompanyInformation."VAT Registration No.", VATLedgerLine."C/V VAT Reg. No.", VATLedgerLine.FieldCaption("C/V VAT Reg. No."));
        Assert.AreEqual(CompanyInformation."KPP Code", VATLedgerLine."Reg. Reason Code", VATLedgerLine.FieldCaption("Reg. Reason Code"));
    end;

    [Scope('OnPrem')]
    procedure VerifyVATLedgerLineCount(VATLedgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20]; ExpectedVATLedgerLineCount: Integer)
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
    begin
        DummyVATLedgerLine.SetRange(Type, VATLedgerType);
        DummyVATLedgerLine.SetRange(Code, VATLedgerCode);
        DummyVATLedgerLine.SetRange("C/V No.", CVNo);
        Assert.RecordCount(DummyVATLedgerLine, ExpectedVATLedgerLineCount);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_DocNo(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'BN', 2, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_SellerName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'N', 7, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_SellerAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'J', 8, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_SellerINN(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'Y', 9, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_ConsigneeAndAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AH', 11, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_BuyerName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'O', 14, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_BuyerAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'J', 15, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_BuyerINN(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AA', 16, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_LineNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'A', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_ItemNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'E', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_TariffNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AA', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_Unit(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AH', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_UnitName(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AN', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_Qty(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AY', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_Price(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'BH', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_Amount(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'BT', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_VATPct(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'CT', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_VATAmount(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'DB', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_AmountInclVAT(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'DN', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_CountryCode(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'ED', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_CountryName(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'EK', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_GTD(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'EY', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CorrDocNo(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AA', 6, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_DocNo(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'Y', 8, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CorrDocDate(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AL', 6, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_DocDate(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AL', 8, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CompanyName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'M', 10, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CompanyAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'I', 11, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CompanyINN(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'X', 12, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_BuyerName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'O', 13, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_BuyerAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'I', 14, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_BuyerINN(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'Y', 15, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CurrencyName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'Z', 16, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CurrencyCode(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'BS', 16, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_LineNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'A', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_ItemNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'E', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_TariffNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AA', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_UOMCode(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AC', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_UOMName(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AJ', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_Qty(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AV', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_Price(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'BF', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_Amount(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'BR', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_VATPct(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'CT', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_VATAmount(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'DD', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_AmountInclVAT(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'DO', 23 + RowOffset, ExpectedValue);
    end;

    local procedure VerifyExcelReportValue(FileName: Text; ColumnName: Text; RowNo: Integer; ExpectedValue: Text)
    begin
        if LibraryReportValidation.GetFileName() <> FileName then
            LibraryReportValidation.SetFullFileName(FileName);
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo, 1, ExpectedValue);
    end;
}

