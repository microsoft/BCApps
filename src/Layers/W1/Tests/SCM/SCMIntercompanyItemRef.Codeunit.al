codeunit 137630 "SCM Intercompany Item Ref."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intercompany]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        TableFieldErr: Label 'Wrong table field value: table "%1", field "%2".';

    [Test]
    [Scope('OnPrem')]
    procedure SendSalesDocWithItemRefAndVariantCode()
    var
        DummyICPartner: Record "IC Partner";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICPartnerCode: Code[10];
        VendorNo: Code[20];
    begin
        // [SCENARIO 111330.1] Verify Item Ref. with Variant Code is correctly transfered from Sales to Purchase Document
        Initialize();

        // [GIVEN] Sales Order with Item Reference and Variant Code
        CreateSalesDocumentWithDeliveryDates(
          SalesHeader, SalesHeader."Document Type"::Order, ICPartnerCode, VendorNo, true, false,
          DummyICPartner."Outbound Sales Item No. Type"::"Cross Reference");

        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddPurchDocsCreate();
        // [WHEN] Send Sales Order to IC Partner
        SendSalesDocumentReceivePurchaseDocument(SalesHeader, PurchaseHeader, ICPartnerCode, VendorNo);

        // [THEN] Received Purchae Document has correct Item Ref. No. and Variant Code
        VerifyPurchDocItemReferenceInfo(PurchaseHeader, SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendPurchDocWithItemReferenceAndVariantCode()
    var
        DummyICPartner: Record "IC Partner";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICPartnerCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 111330.2] Verify Item Ref. with Variant Code is correctly transfered from Purchase to Sales Document
        Initialize();

        // [GIVEN] Purchase Order with Item Reference and Variant Code
        CreatePurchaseDocumentWithReceiptDates(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, ICPartnerCode, CustomerNo,
          CreateItem(), LibraryRandom.RandIntInRange(10, 100), true, false,
          DummyICPartner."Outbound Purch. Item No. Type"::"Cross Reference");

        LibraryLowerPermissions.SetIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddSalesDocsCreate();
        // [WHEN] Send Purchase Order to IC Partner
        SendPurchaseDocumentReceiveSalesDocument(PurchaseHeader, SalesHeader, ICPartnerCode, CustomerNo);

        // [THEN] Received Sales Document has correct Item Ref. No. and Variant Code
        VerifySalesDocItemReferenceInfo(SalesHeader, PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateSalesLineVariantCodeWithItemReference()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemReference: Record "Item Reference";
    begin
        // [SCENARIO 120301.1] Verify IC Partner is updated when validate Sales Line's Variant Code
        Initialize();

        // [GIVEN] Sales Order with Sell-to IC Partner which has "Outbound Sales Item No. Type"="Item Reference"
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order,
          CreateICCustomer(CreateICPartnerWithItemRefOutbndType()));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // [GIVEN] Item Reference with Variant Code for the Item
        ItemReference.SetRange("Reference No.", CreateItemReferenceWithVariant(SalesLine."No.", SalesLine."Sell-to Customer No.", ''));
        ItemReference.FindFirst();

        // [WHEN] Validate Sales Line's "Variant Code"
        SalesLine.Validate("Variant Code", ItemReference."Variant Code");

        // [THEN] Sales Line's IC Partner fields are updated with Item Reference data
        Assert.AreEqual(
          SalesLine."IC Partner Ref. Type"::"Cross Reference",
          SalesLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("IC Partner Ref. Type")));
        Assert.AreEqual(
          ItemReference."Reference No.",
          SalesLine."IC Item Reference No.",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("IC Item Reference No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchLineVariantCodeWithItemReference()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemReference: Record "Item Reference";
    begin
        // [SCENARIO 120301.2] Verify IC Partner is updated when validate Purchase Line's Variant Code
        Initialize();

        // [GIVEN] Purchase Order with Buy-from IC Partner which has "Outbound Purch. Item No. Type"="Item Reference"
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order,
          CreateICVendor(CreateICPartnerWithItemRefOutbndType()));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // [GIVEN] Item Reference with Variant Code for the Item
        ItemReference.SetRange("Reference No.", CreateItemReferenceWithVariant(PurchaseLine."No.", '', PurchaseLine."Buy-from Vendor No."));
        ItemReference.FindFirst();

        // [WHEN] Validate Purchase Line's "Variant Code"
        PurchaseLine.Validate("Variant Code", ItemReference."Variant Code");

        // [THEN] Purchase Line's IC Partner fields are updated with Item Reference data
        Assert.AreEqual(
          PurchaseLine."IC Partner Ref. Type"::"Cross Reference",
          PurchaseLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("IC Partner Ref. Type")));
        Assert.AreEqual(
          ItemReference."Reference No.",
          PurchaseLine."IC Item Reference No.",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("IC Item Reference No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateSalesLineVariantCodeWithoutItemReference()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemReference: Record "Item Reference";
        NewItemVariant: Record "Item Variant";
    begin
        // [SCENARIO 120301.3] Verify IC Partner is updated with Item info when validate Sales Line's Variant Code which is not in ItemRef setup
        Initialize();

        // [GIVEN] Sales Order with Sell-to IC Partner which has "Outbound Sales Item No. Type"="Internal No."
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateICCustomer(CreateICPartner()));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // [GIVEN] Variant Code "VAR1" for the Item "I" with ItemRef setup
        ItemReference.SetRange("Reference No.", CreateItemReferenceWithVariant(SalesLine."No.", SalesLine."Sell-to Customer No.", ''));
        ItemReference.FindFirst();

        // [GIVEN] Another Variant Code "VAR2" for item "I" without ItemRef setup
        LibraryInventory.CreateItemVariant(NewItemVariant, SalesLine."No.");

        // [WHEN] Validate Sales Line's "Variant Code"="VAR2"
        SalesLine.Validate("Variant Code", NewItemVariant.Code);

        // [THEN] SalesLine's fields are: "IC Partner Ref. Type"=Item, "IC Partner Reference"="I"
        Assert.AreEqual(
          SalesLine."IC Partner Ref. Type"::Item,
          SalesLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("IC Partner Ref. Type")));
        Assert.AreEqual(
          SalesLine."No.",
          SalesLine."IC Partner Reference",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("IC Partner Reference")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchLineVariantCodeWithoutItemReference()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemReference: Record "Item Reference";
        NewItemVariant: Record "Item Variant";
    begin
        // [SCENARIO 120301.4] Verify IC Partner is updated with Item info when validate Purchase Line's Variant Code which is not in ItemRef setup
        Initialize();

        // [GIVEN] Purchase Order with Buy-from IC Partner which has "Outbound Purch. Item No. Type"="Internal No."
        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateICVendor(CreateICPartner()));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // [GIVEN] Variant Code "VAR1" for the Item "I" with ItemRef setup
        ItemReference.SetRange(
            "Reference No.", CreateItemReferenceWithVariant(PurchaseLine."No.", '', PurchaseLine."Buy-from Vendor No."));
        ItemReference.FindFirst();

        // [GIVEN] Another Variant Code "VAR2" for item "I" without ItemRef setup
        LibraryInventory.CreateItemVariant(NewItemVariant, PurchaseLine."No.");

        // [WHEN] Validate Purchase Line's "Variant Code"="VAR2"
        PurchaseLine.Validate("Variant Code", NewItemVariant.Code);

        // [THEN] PurchaseLine's fields are: "IC Partner Ref. Type"=Item, "IC Partner Reference"="I"
        Assert.AreEqual(
          PurchaseLine."IC Partner Ref. Type"::Item,
          PurchaseLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("IC Partner Ref. Type")));
        Assert.AreEqual(
          PurchaseLine."No.",
          PurchaseLine."IC Partner Reference",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("IC Partner Reference")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendSalesDocWithCustomerItemReference()
    var
        DummyICPartner: Record "IC Partner";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICPartnerCode: Code[10];
        VendorNo: Code[20];
    begin
        // [SCENARIO 380749] Verify Item with Item Reference is correctly transfered from Sales to Purchase Document
        Initialize();

        // [GIVEN] Sales Order, Item = 'X' with Customer Reference = 'Y'
        CreateSalesDocumentWithDeliveryDates(
          SalesHeader, SalesHeader."Document Type"::Order, ICPartnerCode, VendorNo, false, false,
          DummyICPartner."Outbound Sales Item No. Type"::"Internal No.");
        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        UpdateSalesLineWithItemReference(SalesHeader);

        // [WHEN] Send Sales Order to IC Partner with outbound type "Internal No."
        LibraryLowerPermissions.AddPurchDocsCreate();
        SendSalesDocumentReceivePurchaseDocument(SalesHeader, PurchaseHeader, ICPartnerCode, VendorNo);

        // [THEN] Received Purchase Document has correct Item No. = 'Y'
        VerifyPurchDocItemInfo(PurchaseHeader, SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendPurchDocWithVendorItemReference()
    var
        DummyICPartner: Record "IC Partner";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ICPartnerCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 380749] Verify Item with Item Reference is correctly transfered from Purchase to Sales Document
        Initialize();

        // [GIVEN] Purchase Order, Item = 'X' with Vendor Item Reference = 'Y'
        CreatePurchaseDocumentWithReceiptDates(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, ICPartnerCode, CustomerNo,
          CreateItem(), LibraryRandom.RandIntInRange(10, 100), false, false,
          DummyICPartner."Outbound Purch. Item No. Type"::"Internal No.");
        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddIntercompanyPostingsEdit();
        LibraryLowerPermissions.AddO365Setup();
        UpdatePurchaseLineWithItemReference(PurchaseHeader);

        // [WHEN] Send Purchase Order to IC Partner with outbound type "Internal No."
        LibraryLowerPermissions.AddSalesDocsCreate();
        SendPurchaseDocumentReceiveSalesDocument(PurchaseHeader, SalesHeader, ICPartnerCode, CustomerNo);

        // [THEN] Received Sales Document has correct Item No. = 'Y'.
        VerifySalesDocItemInfo(SalesHeader, PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentWhenValidateItemRefNoAndMultipleItemRefPresent()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DummyVendorNo: Code[20];
        CustNo: Code[20];
        ItemNo1: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Item Reference] [Sales]
        // [SCENARIO 256279] When "Reference No." is validated in Sales Invoice and two similar Item References present, then "No." in Sales Line has "No." = 1st Item Reference "Item No".
        Initialize();

        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] Items "I1", "I2" and Customer "C"
        PrepareCustomerVendorAndTwoItems(CustNo, DummyVendorNo, ItemNo1, ItemNo2);

        // [GIVEN] Item Reference for Customer "C", item "I1" and "Reference No." = 'X'
        CreateItemReference(
          ItemNo1, '', GetBaseUoMFromItem(ItemNo1), "Item Reference Type"::Customer, CustNo, ItemNo1);

        // [GIVEN] Item Reference for Customer "C", item "I2" and "Reference No." = 'X'
        CreateItemReference(
          ItemNo2, '', GetBaseUoMFromItem(ItemNo2), "Item Reference Type"::Customer, CustNo, ItemNo1);

        // [GIVEN] Sales Order for Customer "C" with Sales Line Type = Item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // [WHEN] Validate "Reference No." = 'X' in Sales Line
        LibraryVariableStorage.Enqueue("Item Reference Type"::Customer);
        LibraryVariableStorage.Enqueue(ItemNo1);
        LibraryVariableStorage.Enqueue(ItemNo2);
        SalesLine.Validate("Item Reference No.", ItemNo1);

        // [THEN] Sales Line "No." = "I1"
        SalesLine.TestField("No.", ItemNo1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDocumentWhenValidateItemRefNoAndMultipleItemRefPresent()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        DummyCustNo: Code[20];
        ItemNo1: Code[20];
        ItemNo2: Code[20];
    begin
        // [FEATURE] [Item Reference] [Purchase]
        // [SCENARIO 256279] When "Item Reference No." is validated in Purchase Invoice and two similar Item References present, then "No." in Purchase Line has "No." = 1st Item Reference "Item No".
        Initialize();

        LibraryLowerPermissions.SetIntercompanyPostingsSetup();
        LibraryLowerPermissions.AddO365Setup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        LibraryLowerPermissions.AddeRead();

        // [GIVEN] Items "I1", "I2" and Vendor "V"
        PrepareCustomerVendorAndTwoItems(DummyCustNo, VendorNo, ItemNo1, ItemNo2);

        // [GIVEN] Item Reference for Vendor "V", item "I1" and "Reference No." = 'X'
        CreateItemReference(ItemNo1, '', GetBaseUoMFromItem(ItemNo1), "Item Reference Type"::Vendor, VendorNo, ItemNo1);

        // [GIVEN] Item Reference for Vendor "V", item "I2" and "Reference No." = 'X'
        CreateItemReference(ItemNo2, '', GetBaseUoMFromItem(ItemNo1), "Item Reference Type"::Vendor, VendorNo, ItemNo1);

        // [GIVEN] Purchase Invoice for Vendor "V" with Purchase Line Type = Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);

        // [WHEN] Validate "Item Reference No." = 'X' in Purchase Line
        LibraryVariableStorage.Enqueue("Item Reference Type"::Vendor);
        LibraryVariableStorage.Enqueue(ItemNo1);
        LibraryVariableStorage.Enqueue(ItemNo2);
        PurchaseLine.Validate("Item Reference No.", ItemNo1);

        // [THEN] Purchase Line "No." = "I1"
        PurchaseLine.TestField("No.", ItemNo1);
    end;

    local procedure Initialize()
    var
        ICSetup: Record "IC Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Intercompany Item Ref.");
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Clear(ICInboxOutboxMgt);

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure PrepareCustomerVendorAndTwoItems(var CustNo: Code[20]; var VendorNo: Code[20]; var ItemNo1: Code[20]; var ItemNo2: Code[20])
    var
        ICPartner: Record "IC Partner";
        ICPartnerCode: Code[20];
    begin
        ICPartnerCode := CreateICPartner();
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Outbound Purch. Item No. Type", ICPartner."Outbound Purch. Item No. Type"::"Cross Reference");
        ICPartner.Validate("Outbound Sales Item No. Type", ICPartner."Outbound Sales Item No. Type"::"Cross Reference");
        ICPartner.Modify(true);
        VendorNo := CreateICVendor(ICPartnerCode);
        CustNo := CreateICCustomer(ICPartnerCode);
        ItemNo1 := LibraryInventory.CreateItemNo();
        ItemNo2 := LibraryInventory.CreateItemNo();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        exit(Item."No.");
    end;

    local procedure CreateItemReference(ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[30]; ReferenceNo: Code[20]): Code[20]
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReference.Init();
        ItemReference."Item No." := ItemNo;
        ItemReference."Variant Code" := VariantCode;
        ItemReference."Unit of Measure" := UnitOfMeasureCode;
        ItemReference."Reference Type" := ReferenceType;
        ItemReference."Reference Type No." := ReferenceTypeNo;
        ItemReference."Reference No." := ReferenceNo;
        ItemReference.Insert();
        exit(ReferenceNo);
    end;

    local procedure CreateItemReferenceWithVariant(ItemNo: Code[20]; CustNo: Code[20]; VendNo: Code[20]): Code[20]
    var
        ItemVariant: Record "Item Variant";
        Item: Record Item;
        RefItemNo: Code[20];
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        Item.Get(ItemNo);
        RefItemNo := LibraryInventory.CreateItemNo();
        CreateItemReference(
            ItemNo, ItemVariant.Code, Item."Base Unit of Measure", "Item Reference Type"::Vendor, VendNo, RefItemNo);
        CreateItemReference(
            ItemNo, ItemVariant.Code, Item."Base Unit of Measure", "Item Reference Type"::Customer, CustNo, RefItemNo);
        exit(RefItemNo);
    end;

    local procedure CreateICPartnerWithItemRefOutbndType(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(CreateICPartner());
        ICPartner.Validate("Outbound Sales Item No. Type", ICPartner."Outbound Sales Item No. Type"::"Cross Reference");
        ICPartner.Validate("Outbound Purch. Item No. Type", ICPartner."Outbound Purch. Item No. Type"::"Cross Reference");
        ICPartner.Modify();
        exit(ICPartner.Code);
    end;

    local procedure CreateICPartner(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        CreateICPartnerBase(ICPartner);
        ICPartner.Validate("Inbox Type", ICPartner."Inbox Type"::Database);
        ICPartner.Validate("Inbox Details", CompanyName);
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure CreateICPartnerBase(var ICPartner: Record "IC Partner")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Receivables Account", GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        ICPartner.Validate("Payables Account", GLAccount."No.");
    end;

    local procedure CreateICCustomer(ICPartnerCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateICVendor(ICPartnerCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("IC Partner Code", ICPartnerCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesDocumentWithDeliveryDates(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; var ICPartnerCode: Code[20]; var VendorNo: Code[20]; ItemRef: Boolean; PricesInclVAT: Boolean; OutboundType: Enum "IC Outb. Sales Item No. Type")
    var
        SalesLine: Record "Sales Line";
    begin
        ICPartnerCode := CreateICPartner();
        UpdateICPartnerWithOutboundType(ICPartnerCode, OutboundType);
        VendorNo := CreateICVendor(ICPartnerCode);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateICCustomer(ICPartnerCode));
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandIntInRange(10, 100));

        SalesLine.Validate("Unit Price", SalesLine."Unit Price" + LibraryRandom.RandDec(1000, 2));
        if ItemRef then
            SalesLine.Validate(
              "Item Reference No.", CreateItemReferenceWithVariant(SalesLine."No.", SalesLine."Sell-to Customer No.", VendorNo));
        SalesLine.Modify(true);

        SalesHeader.Validate(
          "Requested Delivery Date",
          CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(5, 10)), WorkDate()));
        SalesHeader.Validate(
          "Promised Delivery Date",
          CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(1, 4)), WorkDate()));
        SalesHeader.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithReceiptDates(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; var ICPartnerCode: Code[20]; var CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; ItemRef: Boolean; PricesInclVAT: Boolean; OutboundType: Enum "IC Outb. Sales Item No. Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        ICPartnerCode := CreateICPartner();
        UpdateICPartnerWithOutboundType(ICPartnerCode, OutboundType);
        CustomerNo := CreateICCustomer(ICPartnerCode);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateICVendor(ICPartnerCode));
        PurchaseHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);

        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(1000, 2));
        if ItemRef then
            PurchaseLine.Validate(
              "Item Reference No.", CreateItemReferenceWithVariant(PurchaseLine."No.", CustomerNo, PurchaseLine."Buy-from Vendor No."));

        PurchaseLine.Modify(true);

        PurchaseHeader.Validate(
          "Requested Receipt Date",
          CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(5, 10)), WorkDate()));
        PurchaseHeader.Validate(
          "Promised Receipt Date",
          CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(1, 4)), WorkDate()));
        PurchaseHeader.Modify(true);
    end;

    local procedure SendSalesDocumentReceivePurchaseDocument(var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"; ICPartnerCode: Code[10]; VendorNo: Code[20])
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
    begin
        SendICSalesDocument(
          SalesHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader);
        ReceiveICPurchaseDocument(
          PurchaseHeader, SalesHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, VendorNo);
    end;

    local procedure SendPurchaseDocumentReceiveSalesDocument(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; ICPartnerCode: Code[20]; CustomerNo: Code[20])
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
    begin
        SendICPurchaseDocument(
          PurchaseHeader, ICPartnerCode, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader);
        ReceiveICSalesDocument(
          SalesHeader, PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxSalesHeader, CustomerNo);
    end;

    local procedure SendICSalesDocument(var SalesHeader: Record "Sales Header"; ICPartnerCode: Code[20]; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header")
    var
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
    begin
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        ICOutboxTransaction."Document Type" := ConvertDocTypeToICOutboxTransaction(SalesHeader."Document Type");
        ICOutboxSalesHeader."Document Type" := SalesHeader."Document Type";
        OutboxICSalesDocument(
          ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, ICOutboxSalesHeader, SalesHeader."No.", ICPartnerCode);
    end;

    local procedure OutboxICSalesDocument(var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; SalesDocumentNo: Code[20]; ICPartnerCode: Code[20])
    begin
        FindICOutboxTransaction(
          ICOutboxTransaction, SalesDocumentNo, ICOutboxTransaction."Document Type",
          ICOutboxTransaction."IC Source Type"::"Sales Document");
        FindICOutboxSalesHeader(
          ICOutboxSalesHeader, ICOutboxTransaction."Transaction No.", SalesDocumentNo, ICOutboxSalesHeader."Document Type");
        ICInboxOutboxMgt.OutboxTransToInbox(ICOutboxTransaction, ICInboxTransaction, ICPartnerCode);
        ICInboxOutboxMgt.OutboxSalesHdrToInbox(ICInboxTransaction, ICOutboxSalesHeader, ICInboxPurchaseHeader);
    end;

    local procedure ReceiveICPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; VendorNo: Code[20])
    var
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        ICInboxOutboxMgt.CreatePurchDocument(ICInboxPurchaseHeader, false, WorkDate());
        ICOutboxSalesLine."Document Type" := ConvertDocTypeToICOutboxSalesLine(SalesHeader."Document Type");
        InboxICPurchaseDocument(
          PurchaseHeader, ICOutboxTransaction, ICInboxTransaction, ICInboxPurchaseHeader, ICOutboxSalesLine, SalesHeader."No.", VendorNo);
    end;

    local procedure InboxICPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; var ICOutboxSalesLine: Record "IC Outbox Sales Line"; SalesDocumentNo: Code[20]; VendorNo: Code[20])
    var
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
    begin
        FindPurchaseDocument(PurchaseHeader, ICInboxPurchaseHeader."Document Type", VendorNo);
        FindICOutboxSalesLine(
          ICOutboxSalesLine, ICOutboxTransaction."Transaction No.",
          SalesDocumentNo, ICOutboxSalesLine."Document Type");

        ICOutboxSalesLine.SetRecFilter();
        ICOutboxSalesLine.SetRange("Line No.");
        ICOutboxSalesLine.FindFirst();
        repeat
            ICInboxOutboxMgt.OutboxSalesLineToInbox(ICInboxTransaction, ICOutboxSalesLine, ICInboxPurchaseLine);
            ICInboxOutboxMgt.CreatePurchLines(PurchaseHeader, ICInboxPurchaseLine);
        until ICOutboxSalesLine.Next() = 0;
    end;

    local procedure SendICPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; ICPartnerCode: Code[20]; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxSalesHeader: Record "IC Inbox Sales Header")
    var
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
    begin
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        FindICOutboxTransaction(
          ICOutboxTransaction, PurchaseHeader."No.", ConvertDocTypeToICOutboxTransaction(PurchaseHeader."Document Type"),
          ICOutboxTransaction."IC Source Type"::"Purchase Document");
        FindICOutboxPurchaseHeader(
          ICOutboxPurchaseHeader, ICOutboxTransaction."Transaction No.",
          PurchaseHeader."No.", ConvertPurchDocTypeToICOutboxPurchHeader(PurchaseHeader."Document Type"));
        ICInboxOutboxMgt.OutboxTransToInbox(ICOutboxTransaction, ICInboxTransaction, ICPartnerCode);
        ICInboxOutboxMgt.OutboxPurchHdrToInbox(ICInboxTransaction, ICOutboxPurchaseHeader, ICInboxSalesHeader);
    end;

    local procedure ReceiveICSalesDocument(var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"; var ICOutboxTransaction: Record "IC Outbox Transaction"; var ICInboxTransaction: Record "IC Inbox Transaction"; var ICInboxSalesHeader: Record "IC Inbox Sales Header"; CustomerNo: Code[20])
    var
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
    begin
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());
        FindSalesDocument(SalesHeader, PurchaseHeader."Document Type", CustomerNo);
        FindICOutboxPurchaseLine(
          ICOutboxPurchaseLine, ICOutboxTransaction."Transaction No.",
          PurchaseHeader."No.", ConvertPurchDocTypeToICOutboxPurchLine(PurchaseHeader."Document Type"));
        ICInboxOutboxMgt.OutboxPurchLineToInbox(ICInboxTransaction, ICOutboxPurchaseLine, ICInboxSalesLine);
        ICInboxOutboxMgt.CreateSalesLines(SalesHeader, ICInboxSalesLine);
    end;

    local procedure FindICOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction"; DocumentNo: Code[20]; DocumentType: Enum "IC Transaction Document Type"; SourceType: enum "IC Transaction Source Type")
    begin
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        ICOutboxTransaction.SetRange("Document Type", DocumentType);
        ICOutboxTransaction.SetRange("IC Source Type", SourceType);
        ICOutboxTransaction.FindFirst();
    end;

    local procedure FindSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("IC Direction", SalesHeader."IC Direction"::Incoming);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
    end;

    local procedure FindPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("IC Direction", PurchaseHeader."IC Direction"::Incoming);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
    end;

    local procedure FindICOutboxSalesHeader(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; TransactionNo: Integer; DocumentNo: Code[20]; DocumentType: Enum "IC Sales Document Type")
    begin
        ICOutboxSalesHeader.SetRange("IC Transaction No.", TransactionNo);
        ICOutboxSalesHeader.SetRange("No.", DocumentNo);
        ICOutboxSalesHeader.SetRange("Document Type", DocumentType);
        ICOutboxSalesHeader.FindFirst();
    end;

    local procedure FindICOutboxSalesLine(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; TransactionNo: Integer; DocumentNo: Code[20]; DocumentType: Enum "IC Outbox Sales Document Type")
    begin
        ICOutboxSalesLine.SetRange("IC Transaction No.", TransactionNo);
        ICOutboxSalesLine.SetRange("Document No.", DocumentNo);
        ICOutboxSalesLine.SetRange("Document Type", DocumentType);
        ICOutboxSalesLine.FindFirst();
    end;

    local procedure FindICOutboxPurchaseHeader(var ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header"; TransactionNo: Integer; DocumentNo: Code[20]; DocumentType: Enum "IC Purchase Document Type")
    begin
        ICOutboxPurchaseHeader.SetRange("IC Transaction No.", TransactionNo);
        ICOutboxPurchaseHeader.SetRange("No.", DocumentNo);
        ICOutboxPurchaseHeader.SetRange("Document Type", DocumentType);
        ICOutboxPurchaseHeader.FindFirst();
    end;

    local procedure FindICOutboxPurchaseLine(var ICOutboxPurchaseLine: Record "IC Outbox Purchase Line"; TransactionNo: Integer; DocumentNo: Code[20]; DocumentType: Enum "IC Outbox Purchase Document Type")
    begin
        ICOutboxPurchaseLine.SetRange("IC Transaction No.", TransactionNo);
        ICOutboxPurchaseLine.SetRange("Document No.", DocumentNo);
        ICOutboxPurchaseLine.SetRange("Document Type", DocumentType);
        ICOutboxPurchaseLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.FindFirst();
    end;

    local procedure GetBaseUoMFromItem(ItemNo: Code[20]): Code[10]
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item."Base Unit of Measure");
    end;

    local procedure UpdateICPartnerWithOutboundType(ICPartnerCode: Code[20]; OutboundType: Enum "IC Outb. Sales Item No. Type")
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Outbound Purch. Item No. Type", OutboundType);
        ICPartner.Validate("Outbound Sales Item No. Type", OutboundType);
        ICPartner.Modify(true);
    end;

    local procedure UpdatePurchaseLineWithItemReference(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchLine(PurchaseLine, PurchaseHeader);
        CreateItemReference(PurchaseLine."No.", '', PurchaseLine."Unit of Measure Code",
          "Item Reference Type"::Vendor, PurchaseLine."Buy-from Vendor No.", LibraryInventory.CreateItemNo());
        PurchaseLine.Validate("No.");
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesLineWithItemReference(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        CreateItemReference(
            SalesLine."No.", '', SalesLine."Unit of Measure Code",
            "Item Reference Type"::Customer, SalesLine."Sell-to Customer No.", LibraryInventory.CreateItemNo());
        SalesLine.Validate("No.");
        SalesLine.Modify(true);
    end;

    local procedure ConvertDocTypeToICOutboxTransaction(SourceDocumentType: Enum "Sales Document Type"): Enum "IC Transaction Document Type"
    var
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        case SourceDocumentType of
            SalesHeader."Document Type"::Invoice:
                exit(ICOutboxTransaction."Document Type"::Invoice);
            SalesHeader."Document Type"::Order:
                exit(ICOutboxTransaction."Document Type"::Order);
            SalesHeader."Document Type"::"Credit Memo":
                exit(ICOutboxTransaction."Document Type"::"Credit Memo");
            SalesHeader."Document Type"::"Return Order":
                exit(ICOutboxTransaction."Document Type"::"Return Order");
        end;
    end;

    local procedure ConvertDocTypeToICOutboxSalesLine(SourceDocumentType: Enum "Sales Document Type"): Enum "IC Outbox Sales Document Type"
    var
        SalesHeader: Record "Sales Header";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        case SourceDocumentType of
            SalesHeader."Document Type"::Invoice:
                exit(ICOutboxSalesLine."Document Type"::Invoice);
            SalesHeader."Document Type"::Order:
                exit(ICOutboxSalesLine."Document Type"::Order);
            SalesHeader."Document Type"::"Credit Memo":
                exit(ICOutboxSalesLine."Document Type"::"Credit Memo");
            SalesHeader."Document Type"::"Return Order":
                exit(ICOutboxSalesLine."Document Type"::"Return Order");
        end;
    end;

    local procedure ConvertPurchDocTypeToICOutboxPurchHeader(SourceDocumentType: Enum "Purchase Document Type"): Enum "IC Purchase Document Type"
    var
        PurchaseHeader: Record "Purchase Header";
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
    begin
        case SourceDocumentType of
            PurchaseHeader."Document Type"::Invoice:
                exit(ICOutboxPurchaseHeader."Document Type"::Invoice);
            PurchaseHeader."Document Type"::Order:
                exit(ICOutboxPurchaseHeader."Document Type"::Order);
            PurchaseHeader."Document Type"::"Credit Memo":
                exit(ICOutboxPurchaseHeader."Document Type"::"Credit Memo");
            PurchaseHeader."Document Type"::"Return Order":
                exit(ICOutboxPurchaseHeader."Document Type"::"Return Order");
        end;
    end;

    local procedure ConvertPurchDocTypeToICOutboxPurchLine(SourceDocumentType: Enum "Purchase Document Type"): Enum "IC Outbox Purchase Document Type"
    var
        PurchaseHeader: Record "Purchase Header";
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
    begin
        case SourceDocumentType of
            PurchaseHeader."Document Type"::Invoice:
                exit(ICOutboxPurchaseLine."Document Type"::Invoice);
            PurchaseHeader."Document Type"::Order:
                exit(ICOutboxPurchaseLine."Document Type"::Order);
            PurchaseHeader."Document Type"::"Credit Memo":
                exit(ICOutboxPurchaseLine."Document Type"::"Credit Memo");
            PurchaseHeader."Document Type"::"Return Order":
                exit(ICOutboxPurchaseLine."Document Type"::"Return Order");
        end;
    end;

    local procedure VerifySalesDocItemReferenceInfo(SalesHeader: Record "Sales Header"; PurchaseHeader: Record "Purchase Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchLine(PurchaseLine, PurchaseHeader);
        FindSalesLine(SalesLine, SalesHeader);
        Assert.AreEqual(
          PurchaseLine."No.",
          SalesLine."No.",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("No.")));
        Assert.AreEqual(
          PurchaseLine."Item Reference No.",
          SalesLine."Item Reference No.",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("Item Reference No.")));
        Assert.AreEqual(
          PurchaseLine."Variant Code",
          SalesLine."Variant Code",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("Variant Code")));
        Assert.AreEqual(
          SalesLine."IC Partner Ref. Type"::"Cross Reference",
          SalesLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("IC Partner Ref. Type")));
        Assert.AreEqual(
          PurchaseLine."Item Reference No.",
          SalesLine."IC Item Reference No.",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("IC Item Reference No.")));
    end;

    local procedure VerifyPurchDocItemReferenceInfo(PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchLine(PurchaseLine, PurchaseHeader);
        Assert.AreEqual(
          SalesLine."No.",
          PurchaseLine."No.",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("No.")));
        Assert.AreEqual(
          SalesLine."Item Reference No.",
          PurchaseLine."Item Reference No.",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("Item Reference No.")));
        Assert.AreEqual(
          SalesLine."Variant Code",
          PurchaseLine."Variant Code",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("Variant Code")));
        Assert.AreEqual(
          PurchaseLine."IC Partner Ref. Type"::"Cross Reference",
          PurchaseLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("IC Partner Ref. Type")));
        Assert.AreEqual(
          SalesLine."Item Reference No.",
          PurchaseLine."IC Item Reference No.",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("IC Item Reference No.")));
    end;

    local procedure VerifyPurchDocItemInfo(PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        FindPurchLine(PurchaseLine, PurchaseHeader);

        Assert.AreEqual(
          PurchaseLine."IC Partner Ref. Type"::Item,
          PurchaseLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("IC Partner Ref. Type")));

        Assert.AreEqual(
          SalesLine."No.",
          PurchaseLine."No.",
          StrSubstNo(TableFieldErr, PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("No.")));
    end;

    local procedure VerifySalesDocItemInfo(SalesHeader: Record "Sales Header"; PurchaseHeader: Record "Purchase Header")
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchLine(PurchaseLine, PurchaseHeader);
        FindSalesLine(SalesLine, SalesHeader);

        Assert.AreEqual(
          SalesLine."IC Partner Ref. Type"::Item,
          SalesLine."IC Partner Ref. Type",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("IC Partner Ref. Type")));

        Assert.AreEqual(
          PurchaseLine."No.",
          SalesLine."No.",
          StrSubstNo(TableFieldErr, SalesLine.TableCaption(), SalesLine.FieldCaption("No.")));
    end;
}
