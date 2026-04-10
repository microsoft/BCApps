codeunit 134476 "ERM Dimension Purchase"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Purchase]
        IsInitialized := false;
    end;

    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        DimensionHeaderErr: Label 'The dimensions used in %1 %2 are invalid', Locked = true;
        DimensionLineErr: Label 'The dimensions used in %1 %2, line no. %3 are invalid', Locked = true;
        DimensionValueCodeErr: Label '%1 must be %2.', Comment = '%1 = dimension value field, %2 = dimension value code';
        QuantityReceivedErr: Label '%1 must be %2 in %3.', Comment = '%1 = quantity field, %2 = quantity value, %3 = purchase line';
        VendorLedgerEntryErr: Label 'Field Open in Vendor Ledger Entries should be %1 for Document No. = %2', Comment = '%1 = open field, %2 = document no. value';
        UpdateFromHeaderLinesQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        UpdateLineDimQst: Label 'You have changed one or more dimensions on the';
        DimensionSetIDErr: Label 'Invalid Dimension Set ID';
        NotEqualDimensionsErr: Label 'Dimensions are equal.';
        LocationChangesMsg: Label 'You have changed Location Code on the purchase header, but it has not been changed on the existing purchase lines.\You must update the existing purchase lines manually.';
        LocationChangeErr: Label 'Location Change message expected';
        MissingDimensionErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for G/L Account %2.', Comment = '%1 - Dimension Code, %2 - G/L Account No.';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DimensionUpdateOnLine()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValueCode: Code[20];
        ShortcutDimensionCode: Code[20];
        DimensionSetID: Integer;
    begin
        // [SCENARIO] Test Dimension on Purchase Line updated successfully after updation of Dimension on Purchase Header.

        // [GIVEN] Create Vendor, Item, Purchase Header with Dimension and Purchase Line, Change Dimension Value for Purchase Header Dimension
        // and Select Yes on Confirmation message occurs for updating Dimension on Purchase Line.
        Initialize();
        CreateOrderWithDimension(TempDimensionSetEntry, DimensionValueCode, ShortcutDimensionCode, DimensionSetID);

        // [THEN] Verify Dimension Set Entry and Dimension on Purchase Line successfully updated.
        VerifyDimensionSetEntry(TempDimensionSetEntry, DimensionSetID);

        FindDimensionSetEntry(DimensionSetEntry, ShortcutDimensionCode, DimensionSetID);
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DimensionNotUpdateOnLine()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValueCode: Code[20];
        ShortcutDimensionCode: Code[20];
        DimensionSetID: Integer;
    begin
        // [SCENARIO] Test Dimension on Purchase Line not updated after updation of Dimension on Purchase Header.

        // [GIVEN] Create Vendor, Item, Purchase Header with Dimension and Purchase Line, Change Dimension Value for Purchase Header Dimension
        // and Select No on Confirmation message occurs for updating Dimension on Purchase Line.
        Initialize();
        CreateOrderWithDimension(TempDimensionSetEntry, DimensionValueCode, ShortcutDimensionCode, DimensionSetID);

        // [THEN] Verify Dimension Set Entry and Dimension on Purchase Line not updated.
        VerifyDimensionSetEntry(TempDimensionSetEntry, DimensionSetID);

        FindDimensionSetEntry(DimensionSetEntry, ShortcutDimensionCode, DimensionSetID);
        Assert.AreNotEqual(
          DimensionValueCode,
          DimensionSetEntry."Dimension Value Code",
          StrSubstNo(
            DimensionValueCodeErr, DimensionSetEntry.FieldCaption("Dimension Value Code"), DimensionSetEntry."Dimension Value Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuePostingRuleOnHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test error occurs on Posting Purchase Invoice with Invalid Dimension On Purchase Header.

        // [GIVEN] Create Vendor with Default Dimension, Item, Purchase Header and Update value of Dimension on Purchase Header.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(PurchaseHeader,
          PurchaseLine, Dimension.Code, '', DefaultDimension."Value Posting"::"Same Code",
          PurchaseHeader."Document Type"::Invoice);
        UpdateDimensionPurchaseHeader(PurchaseHeader);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Vendor, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Post Purchase Invoice.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [THEN] Verify error occurs "Invalid Dimension" on Posting Purchase Invoice.
        Assert.ExpectedError(
          StrSubstNo(DimensionHeaderErr, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuePostingRuleOnLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test error occurs on Posting Purchase Invoice with Invalid Dimension On Purchase Line.

        // [GIVEN] Create Vendor, Item with Default Dimension, Purchase Header and Update value of Dimension on Purchase Line.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Dimension.Code, DefaultDimension."Value Posting"::"Same Code",
          PurchaseHeader."Document Type"::Invoice);
        UpdateDimensionPurchaseLine(PurchaseLine);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Item, PurchaseLine."No.");

        // [WHEN] Post Purchase Invoice.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [THEN] Verify error occurs "Invalid Dimension" on Posting Purchase Invoice.
        Assert.ExpectedError(
          StrSubstNo(DimensionLineErr, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderFromQuoteWithDimension()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DimensionSetIdHeader: Integer;
        DimensionSetIdLine: Integer;
    begin
        // [SCENARIO] Test Dimension on Purchase Order Created from Purchase Quote.

        // [GIVEN] Create Vendor and Item with Default Dimension, Purchase Quote.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Dimension.Code, FindDifferentDimension(Dimension.Code), DefaultDimension."Value Posting"::" ",
          PurchaseHeader."Document Type"::Quote);
        DimensionSetIdHeader := PurchaseHeader."Dimension Set ID";
        DimensionSetIdLine := PurchaseLine."Dimension Set ID";

        // [WHEN] Convert Purchase Quote to Order.
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);

        // [THEN] Verify Dimension on created Purchase Header and Purchase Line.
        FindPurchaseOrder(PurchaseHeader, PurchaseHeader."No.");
        PurchaseHeader.TestField("Dimension Set ID", DimensionSetIdHeader);

        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.TestField("Dimension Set ID", DimensionSetIdLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryDimension()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test Dimension on G/L Entry after Posting Purchase Invoice.

        // [GIVEN] Create Vendor, Items and Purchase Invoice for different Items.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Dimension.Code, DefaultDimension."Value Posting"::" ", PurchaseHeader."Document Type"::Invoice);

        // Use Random because value is not important.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item,
          CreateItemWithDimension(FindDifferentDimension(Dimension.Code), DefaultDimension."Value Posting"::" "),
          LibraryRandom.RandDec(10, 2));
        UpdateVendorInvoiceNo(PurchaseHeader);

        // [WHEN] Post the Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [THEN] Verify Dimension on G/L Entry.
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        VerifyGLEntryDimension(PurchaseLine, PurchInvHeader."No.");
        VerifyGLEntryDimension(PurchaseLine2, PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDimensionAfterPartial()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO] Test Dimension on G/L Entry after Posting Purchase Order in Multiple Steps with Change Dimension Value on Purchase Line.

        // [GIVEN] Create Vendor, Item, Create and Post Purchase Order Partially.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Dimension.Code, DefaultDimension."Value Posting"::" ", PurchaseHeader."Document Type"::Order);
        UpdatePartialQuantityToReceive(PurchaseLine);
        UpdateVendorInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Update Dimension Value on Purchase Line Dimension and Post Purchase Order.
        UpdateDimensionPurchaseLine(PurchaseLine);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        UpdateVendorInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Dimension on G/L Entry.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindLast();
        VerifyGLEntryDimension(PurchaseLine, PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeShortcutDimensionInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [SCENARIO] Test Purchase Header Dimension after change Shortcut Dimension 2 Code on Purchase Invoice Header.

        // [GIVEN] Create Vendor.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Create Purchase Header and Update Shortcut Dimension 2 Code on Purchase Header.
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 2 Code");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        PurchaseHeader.Modify(true);

        // [THEN] Verify Purchase Header Dimension.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PurchaseHeader."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 2 Code");
        DimensionSetEntry.TestField("Dimension Value Code", PurchaseHeader."Shortcut Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentWithDimension()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [SCENARIO] Test Dimension on Purchase Invoice Created from Copy Document.

        // [GIVEN] Create Vendor with Default Dimension, Item, Create and Post Purchase Order.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Dimension.Code, FindDifferentDimension(Dimension.Code), DefaultDimension."Value Posting"::" ",
          PurchaseHeader."Document Type"::Order);
        UpdatePartialQuantityToReceive(PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();

        // [WHEN] Create Purchase Invoice through Copy Document.
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.");
        RunCopyPurchaseDocument(PurchaseHeader, PurchRcptHeader."No.");

        // [THEN] Verify Dimension on Purchase Header and Purchase Line.
        PurchaseHeader.TestField("Dimension Set ID", PurchRcptHeader."Dimension Set ID");
        PurchaseLine.SetFilter(Type, '<>''''');
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindFirst();
        PurchaseLine.TestField("Dimension Set ID", PurchRcptLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnRequisitionLine()
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        DimensionSetID: Integer;
    begin
        // [SCENARIO] Test Dimension on Requisition Line created from Get Sales Order.

        Initialize();
        // [GIVEN] Create Customer, Sales Order having Purchasing Code with Drop Shipment True, Create Dimension Set Entry for Sales Line
        // [WHEN] Run Get Sales Order from Requisition Worksheet.
        CreateRequisitionLine(RequisitionWkshName, DimensionSetID);

        // [THEN] Verify Dimension on Requisition Line.
        FindRequisitionLine(RequisitionLine, RequisitionWkshName);
        RequisitionLine.TestField("Dimension Set ID", DimensionSetID);

        // 3. Teardown: Delete created Requisition Line.
        RequisitionLine.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DropShipment()
    var
        SalesHeader: Record "Sales Header";
        DefaultDimension: Record "Default Dimension";
        RequisitionLine: Record "Requisition Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        DimensionSetID: Integer;
        DimensionCode: Code[20];
        OrderNo: Code[20];
    begin
        // [SCENARIO] Test Dimension on Purchase Receipt created from Drop Shipment functionality.

        Initialize();
        // [GIVEN] Create Customer, Sales Order having Purchasing Code with Drop Shipment True, Create Dimension Set Entry for Sales Line
        // [GIVEN] Run Get Sales Order from Requisition Worksheet.
        DimensionCode := CreateRequisitionLine(RequisitionWkshName, DimensionSetID);
        UpdateVendorOnRequisitionLine(
          RequisitionLine, RequisitionWkshName,
          CreateVendorWithDimension(DefaultDimension, DefaultDimension."Value Posting"::" ", FindDifferentDimension(DimensionCode)));

        // [WHEN] Create Purchase Order from Requisition Worksheet, Post Sales Order and Purchase Order.
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
        SalesHeader.Get(SalesHeader."Document Type"::Order, RequisitionLine."Sales Order No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        OrderNo := PostPurchaseOrder(RequisitionLine."Vendor No.");

        // [THEN] Verify Dimension on Purchase Receipt.
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
        PurchRcptHeader.TestField("Dimension Set ID", RequisitionLine."Dimension Set ID");
        VerifyDimensionOnReceiptLine(PurchRcptHeader."No.", RequisitionLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnInvoiceRounding()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test Dimension on G/L Entry of Invoice Rounding.

        Initialize();
        // [GIVEN] Update Inv. Rounding Precision (LCY) on General Ledger Setup, Create Vendor with Default Dimension, Item,
        LibraryPurchase.SetInvoiceRounding(true);
        LibraryDimension.FindDimension(Dimension);

        LibraryERM.SetInvRoundingPrecisionLCY(0.1);
        LibraryERM.SetAmountRoundingPrecision(0.01);

        // [GIVEN] Create Purchase Invoice and Update Line Amount on Purchase Line.
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Dimension.Code, '', DefaultDimension."Value Posting"::" ", PurchaseHeader."Document Type"::Invoice);
        UpdateInvoiceAmountForRounding(PurchaseLine);

        // [WHEN] Post Purchase Invoice.
        UpdateVendorInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [THEN] Verify Dimension on G/L Entry of Invoice Rounding.
        VerifyDimensionOnRoundingEntry(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [SCENARIO] Test Dimension on Archive Purchase Order.

        // [GIVEN] Create Vendor with Default Dimension, Item, Purchase Order.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Dimension.Code, '', DefaultDimension."Value Posting"::" ", PurchaseHeader."Document Type"::Order);

        // [WHEN] Create Archive Purchase Order.
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // [THEN] Verify Dimension on Archive Purchase Order.
        VerifyDimensionOnArchiveHeader(PurchaseHeader);
        VerifyDimensionOnArchiveLine(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('PurchaseCodePageHandler')]
    [Scope('OnPrem')]
    procedure DimensionStandardPurchaseCode()
    var
        Item: Record Item;
        Dimension: Record Dimension;
        StandardPurchaseLine: Record "Standard Purchase Line";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        DifferentDimensionCode: Code[20];
    begin
        // [SCENARIO] Test Dimension on Standard Purchase Code.

        // [GIVEN] Create Item and find Dimension.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateItemWithExtendedText(Item, Dimension.Code);

        // [WHEN] Create Vendor, GL Account, Standard Purchase Code, Standard Purchase Line and Standard Vendor Purchase Code.
        DifferentDimensionCode :=
          CreateStandardPurchaseDocument(
            StandardPurchaseLine, Dimension.Code, Item."No.", CreateGLAccountWithDimension(Dimension.Code, Item."VAT Prod. Posting Group"));
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseLine."Standard Purchase Code");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        StandardVendorPurchaseCode.InsertPurchLines(PurchaseHeader);

        // [THEN] Verify that Line Dimensions copied from Standard Purchase Line.
        VerifyDimensionCode(StandardPurchaseLine."Dimension Set ID", DifferentDimensionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDimension()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
        PurchaseLine: Record "Purchase Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [SCENARIO] Check Purchase Line Dimension.

        // [GIVEN]
        Initialize();

        // [WHEN] Create Purchase Credit Memo.
        GeneralLedgerSetup.Get();
        CreatePurchaseDocument(PurchaseLine, SetGLAccountDefaultDimension(DefaultDimension, GeneralLedgerSetup."Global Dimension 1 Code"),
          CreateVendorWithDimension(DefaultDimension2, DefaultDimension."Value Posting", GeneralLedgerSetup."Global Dimension 1 Code"));

        // [THEN] Verify Dimension Value on Purchase Line.
        DimensionSetEntry.Get(PurchaseLine."Dimension Set ID", GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSetEntry.TestField("Dimension Value Code", PurchaseLine."Shortcut Dimension 1 Code");

        // Tear Down: Remove Default Dimension from G/L Account.
        DeleteDefaultDimension(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryDimensionsForPurchase()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Test Dimension on G/L Entry after posting Purchase document with IC Partner.

        // [GIVEN] Set Default Dimension for G/L Account and Create Purchase Credit Memo.
        Initialize();
        GeneralLedgerSetup.Get();
        Vendor.Get(
          CreateVendorWithDimension(
            DefaultDimension2, DefaultDimension."Value Posting", GeneralLedgerSetup."Global Dimension 1 Code"));
        GLAccount.Get(SetGLAccountDefaultDimension(DefaultDimension, GeneralLedgerSetup."Global Dimension 1 Code"));
        GLAccount."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        GLAccount.Modify();
        CreatePurchaseDocument(PurchaseLine, GLAccount."No.", Vendor."No.");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo());
        PurchaseLine.Validate("IC Partner Reference", FindICGLAccount());
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Credit Memo.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Dimension Value and IC Partner Code on GL Entry.
        VerifyGLEntryICPartner(PostedDocumentNo, PurchaseLine."IC Partner Code", DefaultDimension."Dimension Value Code");

        // Tear Down: Remove Default Dimension from G/L Account.
        DeleteDefaultDimension(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionAfterApplyForVendor()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] Test Dimension on G/L Entry after Apply from Vendor Ledger Entry.

        // [GIVEN] Find Dimension, Create and Post General Journal Line. Using Random value for Amount.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor,
          CreateVendorWithDimension(DefaultDimension, DefaultDimension."Value Posting"::" ", Dimension.Code),
          -LibraryRandom.RandDec(100, 2));

        // [WHEN] Apply Payment from Vendor Ledger Entry.
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", GenJournalLine.Amount, GenJournalLine."Document Type");

        // [THEN] Verify Dimension on G/L Entry.
        VerifyGLEntry(GenJournalLine."Document No.", Dimension.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnPurchaseOrderLine()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Test Dimension on Purchase Order Line.

        // [GIVEN] Find Dimension.
        Initialize();
        LibraryDimension.FindDimension(Dimension);

        // [WHEN] Create Purchase Order.
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Dimension.Code, DefaultDimension."Value Posting"::"Code Mandatory",
          PurchaseHeader."Document Type"::Order);

        // [THEN] Verify Dimension on Purchase Line.
        VerifyDimensionOnPurchaseOrderLine(PurchaseHeader."Document Type", PurchaseHeader."No.", Dimension.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityReceivedOnPurchaseLine()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtytoReceive: Decimal;
    begin
        // [SCENARIO] Test "Quantity Received" on posting the Purchase Order as Receipt.

        // [GIVEN] Find Dimension And Create Purchase Order.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Dimension.Code, DefaultDimension."Value Posting"::"Code Mandatory",
          PurchaseHeader."Document Type"::Order);
        QtytoReceive := PurchaseLine."Qty. to Receive";

        // [WHEN]
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Transfer "Quantity Received" on Purchase Line.
        VerifyQuantityReceivedOnPurchaseLine(PurchaseHeader."Document Type", PurchaseHeader."No.", QtytoReceive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiptLineOnPostedPurchaseReceipt()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Test Receipt Line on Posted Purchase Receipt.

        // [GIVEN] Find Dimension And Create Purchase Order.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Dimension.Code, DefaultDimension."Value Posting"::"Code Mandatory",
          PurchaseHeader."Document Type"::Order);

        // [WHEN]
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify Receipt Line on Posted Purchase Receipt.
        VerifyReceiptLineOnPostedPurchaseReceipt(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnPurchaseReceipt()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Test Dimension on Posted Purchase Receipt.

        // [GIVEN] Find Dimension And Create Purchase Order.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Dimension.Code, DefaultDimension."Value Posting"::"Code Mandatory",
          PurchaseHeader."Document Type"::Order);

        // [WHEN]
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify Dimension on Posted Purchase Receipt.
        VerifyDimensionOnPurchaseReceipt(PurchaseLine."Document No.", Dimension.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoPostedPurchaseReceipt()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [SCENARIO] Test Quantity after Undo Receipt on Posted Purchase Receipt.

        // [GIVEN] Find Dimension, Create And Post Purchase Order, Find Purchase Receipt Line.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Dimension.Code, DefaultDimension."Value Posting"::"Code Mandatory",
          PurchaseHeader."Document Type"::Order);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.FindFirst();

        // [WHEN] Undo Purchase Receipt Line.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] Verify Quantity after Undo Receipt on Posted Purchase Receipt And Quantity to Receive on Purchase Line.
        VerifyUndoReceiptLineOnPostedReceipt(PurchaseLine."Document No.", PurchaseLine.Quantity);
        VerifyQuantitytoReceiveOnPurchaseLine(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Quantity Received");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyVendorLedgerEntryWithDifferentDimensionSetID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        NewDimSetID: Integer;
        NewDimSetID2: Integer;
    begin
        // [SCENARIO] Test Unapply Vendor Ledger Entries successfully when entries have different dimension set ID

        // [GIVEN] Create Dimension with 2 Dimension Values, Create and Post General Journal Line with different Dimension Set ID.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateDimensionWithTwoDimensionValue(NewDimSetID, NewDimSetID2);
        CreateAndPostGenJournalLinesWithDimSetID(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          -LibraryRandom.RandDec(100, 2), NewDimSetID, NewDimSetID2);

        // [WHEN] Apply Payment from Vendor Ledger Entry.
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", GenJournalLine.Amount, GenJournalLine."Document Type");

        // [WHEN] Unapply the entries
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // [THEN] Verify Unapply successfully. Vendor Ledger Entries are open again.
        VerifyVendorLedgerEntryOpen(GenJournalLine."Document No.", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForPurchHeaderDimUpdate')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderGlobalDimConfirmYes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Purchase Header Shortcut Dimension 1 Code change causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Purchase Order with partly shipped Item line
        CreatePartlyReceiptPurchOrder(PurchaseHeader, PurchaseLine);
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Purchase Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        PurchaseHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForPurchaseHeaderDimUpdate

        // [THEN] Purchase Line dimension set contains "NewDimValue"
        PurchaseLine.Find();
        VerifyDimensionOnDimSet(PurchaseLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForPurchHeaderDimUpdate')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderGlobalDimConfirmNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Purchase Header Shortcut Dimension 1 Code change causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Purchase Order with partly shipped Item line with some initial value "InitialDimSetID"
        CreatePartlyReceiptPurchOrder(PurchaseHeader, PurchaseLine);
        SavedDimSetID := PurchaseLine."Dimension Set ID";
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Purchase Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        asserterror PurchaseHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer No on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForPurchaseHeaderDimUpdate

        // [THEN] Purchase Line dimension set left "InitialDimSetID"
        PurchaseLine.Find();
        PurchaseLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForPurchHeaderDimUpdate,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderDimSetPageConfirmYes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Purchase Header dimension change from Edit Dimension Set Entries page causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Purchase Order with partly shipped Item line
        CreatePartlyReceiptPurchOrder(PurchaseHeader, PurchaseLine);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Purchase Header dimension set is being updated in Edit Dimension Set Entries page
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.Dimensions.Invoke();

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForPurchaseHeaderDimUpdate

        // [THEN] Purchase Line dimension set contains "NewDimValue"
        PurchaseLine.Find();
        VerifyDimensionOnDimSet(PurchaseLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForPurchHeaderDimUpdate,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderDimSetPageConfirmNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
        PurchaseOrder: TestPage "Purchase Order";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Purchase Header dimension change from Edit Dimension Set Entries page causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Purchase Order with partly shipped Item line with some initial value "InitialDimSetID"
        CreatePartlyReceiptPurchOrder(PurchaseHeader, PurchaseLine);
        SavedDimSetID := PurchaseLine."Dimension Set ID";
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Purchase Header dimension set is being updated in Edit Dimension Set Entries page
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        asserterror PurchaseOrder.Dimensions.Invoke();

        // [WHEN] Answer No on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForPurchaseHeaderDimUpdate

        // [THEN] Purchase Line dimension set left "InitialDimSetID"
        PurchaseLine.Find();
        PurchaseLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineGlobalDimConfirmYes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Purchase Line Shortcut Dimension 1 Code change causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Purchase Order with partly shipped Item line
        CreatePartlyReceiptPurchOrder(PurchaseHeader, PurchaseLine);
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Purchase Line Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        PurchaseLine.Find();
        PurchaseLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Purchase Line dimension set contains "NewDimValue"
        VerifyDimensionOnDimSet(PurchaseLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineGlobalDimConfirmNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Purchase Line Shortcut Dimension 1 Code change causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Purchase Order with partly shipped Item line with some initial value "InitialDimSetID"
        CreatePartlyReceiptPurchOrder(PurchaseHeader, PurchaseLine);
        SavedDimSetID := PurchaseLine."Dimension Set ID";
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Purchase Line Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        PurchaseLine.Find();
        asserterror PurchaseLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer No on shipped line update confirmation

        // [THEN] Purchase Line dimension set left "InitialDimSetID"
        PurchaseLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineDimSetPageConfirmYes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Purchase Line dimension change from Edit Dimension Set Entries page causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Purchase Order with partly shipped Item line
        CreatePartlyReceiptPurchOrder(PurchaseHeader, PurchaseLine);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Purchase Line dimension set is being updated in Edit Dimension Set Entries page
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines.Dimensions.Invoke();

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Purchase Line dimension set contains "NewDimValue"
        PurchaseLine.Find();
        VerifyDimensionOnDimSet(PurchaseLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineDimSetPageConfirmNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
        PurchaseOrder: TestPage "Purchase Order";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Purchase Line dimension change from Edit Dimension Set Entries page causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Purchase Order with partly shipped Item line with some initial value "InitialDimSetID"
        CreatePartlyReceiptPurchOrder(PurchaseHeader, PurchaseLine);
        SavedDimSetID := PurchaseLine."Dimension Set ID";
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Purchase Line dimension set is being updated in Edit Dimension Set Entries page
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.First();
        asserterror PurchaseOrder.PurchLines.Dimensions.Invoke();

        // [WHEN] Answer No on shipped line update confirmation

        // [THEN] Purchase Line dimension set left "InitialDimSetID"
        PurchaseLine.Find();
        PurchaseLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchGetDropShptTransfersDimensions()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        DimensionManagement: Codeunit DimensionManagement;
        GlobalDimension: array[2] of Code[20];
        CombinedDimensionSetID: Integer;
        DimensionSetID: array[10] of Integer;
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 346249] Codeunit "Purch.-Get Drop Shpt" combines Default dimensions of Vendor with Dimensions of Sales Line.
        Initialize();

        // [GIVEN] Sales Order with Drop Shipment True and Sales Line with Dimension "D1".
        CreateSalesOrderPurchasingCode(SalesLine);
        CreateDimensionForSalesLine(SalesLine);

        // [GIVEN] Purchase Header for Vendor with Dimension "D2".
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        Vendor.Get(CreateVendorWithDimension(DefaultDimension, DefaultDimension."Value Posting"::" ", DimensionValue."Dimension Code"));
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        PurchaseHeader.Modify(true);

        // [WHEN] Codeunit "Purch.-Get Drop Shpt." is run to create Puchase Line from Sales Line for Drop Shipment.
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Drop Shpt.", PurchaseHeader);

        // [THEN] Dimension set of Purchase Line is equal to combination of Default Dimensions of Vendor and Dimension Set of Sales Line.
        DimensionSetID[1] := PurchaseHeader."Dimension Set ID";
        DimensionSetID[2] := SalesLine."Dimension Set ID";
        CombinedDimensionSetID := DimensionManagement.GetCombinedDimensionSetID(DimensionSetID, GlobalDimension[1], GlobalDimension[2]);

        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        Assert.AreEqual(CombinedDimensionSetID, PurchaseLine."Dimension Set ID", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure PurchaseInvoiceMultipleLinesAndDimensionsWithReverseChargeVAT()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: array[5] of Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[5] of Record "Purchase Line";
        Index: Integer;
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
        ExpectedVATAmountACY: array[5] of Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT] [Dimension] [Rounding]
        // [SCENARIO 377909] System does not loss cent remainder when it posts multiple VAT entries with "VAT Calculation Type" = Reverse Charge VAT

        Initialize();

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        for Index := 2 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[Index], DimensionValue[1]."Dimension Code");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for Index := 1 to ArrayLen(DimensionValue) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine[Index], PurchaseHeader, PurchaseLine[Index].Type::"G/L Account", GLAccount."No.", 1);
            PurchaseLine[Index].Validate("Shortcut Dimension 1 Code", DimensionValue[Index].Code);
            PurchaseLine[Index].Validate("Direct Unit Cost", 25.8);
            PurchaseLine[Index].Modify(true);
        end;

        PurchaseLine[Index].Validate("Direct Unit Cost", 35.0);
        PurchaseLine[Index].Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        InitializeExpectedVATAmounts(ExpectedVATAmount, 8.05, 5.94, 5.93, 5.94, 5.93);
        InitializeExpectedVATAmounts(ExpectedVATAmountACY, 0, 0, 0, 0, 0);

        VerifyVATEntriesAmountAndAmountACY(
            VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount, ExpectedVATAmountACY);
    end;

    [Test]
    procedure PurchaseInvoiceMultipleLinesAndDimensionsWithNormalVAT()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: array[5] of Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[5] of Record "Purchase Line";
        Index: Integer;
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
        ExpectedVATAmountACY: array[5] of Decimal;
    begin
        // [FEATURE] [Normal VAT] [VAT] [Dimension] [Rounding]
        // [SCENARIO 377909] System does not loss cent remainder when it posts multiple VAT entries with "VAT Calculation Type" = Normal VAT

        Initialize();

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        for Index := 2 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[Index], DimensionValue[1]."Dimension Code");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for Index := 1 to ArrayLen(DimensionValue) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine[Index], PurchaseHeader, PurchaseLine[Index].Type::"G/L Account", GLAccount."No.", 1);
            PurchaseLine[Index].Validate("Shortcut Dimension 1 Code", DimensionValue[Index].Code);
            PurchaseLine[Index].Validate("Direct Unit Cost", 25.8);
            PurchaseLine[Index].Modify(true);
        end;

        PurchaseLine[Index].Validate("Direct Unit Cost", 35.0);
        PurchaseLine[Index].Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        InitializeExpectedVATAmounts(ExpectedVATAmount, 8.05, 5.94, 5.93, 5.94, 5.93);
        InitializeExpectedVATAmounts(ExpectedVATAmountACY, 0, 0, 0, 0, 0);

        VerifyVATEntriesAmountAndAmountACY(
            VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount, ExpectedVATAmountACY);
    end;

    [Test]
    procedure PurchaseInvoiceMultipleLinesAndDimensionsWithReverseChargeVATACY()
    var
        Vendor: Record Vendor;
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: array[5] of Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[5] of Record "Purchase Line";
        ExchangeRate: Decimal;
        Index: Integer;
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
        ExpectedVATAmountACY: array[5] of Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT] [Dimension] [Rounding] [Additional-Currency] [ACY]
        // [SCENARIO 377909] System does not loss cent remainder when it posts multiple VAT entries with "VAT Calculation Type" = Reverse Charge VAT and get's "Amount Rounding Precision" from currency for rounding in "Additional-Currency Amount" field

        Initialize();

        ExchangeRate := 19;

        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), ExchangeRate, ExchangeRate);
        Currency."Amount Rounding Precision" := 0.1;
        Currency.Modify(true);
        LibraryERM.SetAddReportingCurrency(Currency.Code);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        for Index := 2 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[Index], DimensionValue[1]."Dimension Code");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for Index := 1 to ArrayLen(DimensionValue) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine[Index], PurchaseHeader, PurchaseLine[Index].Type::"G/L Account", GLAccount."No.", 1);
            PurchaseLine[Index].Validate("Shortcut Dimension 1 Code", DimensionValue[Index].Code);
            PurchaseLine[Index].Validate("Direct Unit Cost", 25.8);
            PurchaseLine[Index].Modify(true);
        end;

        PurchaseLine[Index].Validate("Direct Unit Cost", 35.0);
        PurchaseLine[Index].Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        InitializeExpectedVATAmounts(ExpectedVATAmount, 8.05, 5.94, 5.93, 5.94, 5.93);
        InitializeExpectedVATAmounts(ExpectedVATAmountACY, 153, 112.9, 112.7, 112.9, 112.7);

        VerifyVATEntriesAmountAndAmountACY(
            VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount, ExpectedVATAmountACY);
    end;

    [Test]
    procedure PurchaseInvoiceFCYMultipleLinesAndDimensionsWithReverseChargeVATACYIsFCY()
    var
        Vendor: Record Vendor;
        CurrencyFCY: Record Currency;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: array[5] of Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[5] of Record "Purchase Line";
        ExchangeRateFCY: Decimal;
        Index: Integer;
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
        ExpectedVATAmountACY: array[5] of Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT] [Dimension] [Rounding]
        // [SCENARIO 377909] System does not loss cent remainder when it posts multiple VAT entries with "VAT Calculation Type" = Reverse Charge VAT and get's "Amount Rounding Precision" from currency for rounding in "Additional-Currency Amount" field

        Initialize();

        ExchangeRateFCY := 1 / 19;

        CurrencyFCY.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateExchangeRate(CurrencyFCY.Code, WorkDate(), ExchangeRateFCY, ExchangeRateFCY);
        CurrencyFCY."Amount Rounding Precision" := 0.1;
        CurrencyFCY.Modify(true);

        LibraryERM.SetAddReportingCurrency(CurrencyFCY.Code);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyFCY.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        for Index := 2 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[Index], DimensionValue[1]."Dimension Code");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for Index := 1 to ArrayLen(DimensionValue) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine[Index], PurchaseHeader, PurchaseLine[Index].Type::"G/L Account", GLAccount."No.", 1);
            PurchaseLine[Index].Validate("Shortcut Dimension 1 Code", DimensionValue[Index].Code);
            PurchaseLine[Index].Validate("Direct Unit Cost", 25.8);
            PurchaseLine[Index].Modify(true);
        end;

        PurchaseLine[Index].Validate("Direct Unit Cost", 35.0);
        PurchaseLine[Index].Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        InitializeExpectedVATAmounts(ExpectedVATAmount, 153.9, 112.1, 112.1, 114, 112.1);
        InitializeExpectedVATAmounts(ExpectedVATAmountACY, 8.1, 5.9, 5.9, 6, 5.9);

        VerifyVATEntriesAmountAndAmountACY(
            VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount, ExpectedVATAmountACY);
    end;

    [Test]
    procedure PurchaseInvoiceFCYMultipleLinesAndDimensionsWithReverseChargeVATACYIsNotFCY()
    var
        Vendor: Record Vendor;
        CurrencyFCY: Record Currency;
        CurrencyACY: Record Currency;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: array[5] of Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[5] of Record "Purchase Line";
        ExchangeRateFCY: Decimal;
        ExchangeRateACY: Decimal;
        Index: Integer;
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
        ExpectedVATAmountACY: array[5] of Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT] [Dimension] [Rounding] [FCY] [ACY]
        // [SCENARIO 377909] System does not loss cent remainder when it posts multiple VAT entries with "VAT Calculation Type" = Reverse Charge VAT and get's "Amount Rounding Precision" from currency for rounding in "Additional-Currency Amount" field

        Initialize();

        ExchangeRateFCY := 1 / 19;
        ExchangeRateACY := 13;

        CurrencyFCY.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateExchangeRate(CurrencyFCY.Code, WorkDate(), ExchangeRateFCY, ExchangeRateFCY);
        CurrencyFCY."Amount Rounding Precision" := 0.1;
        CurrencyFCY.Modify(true);

        CurrencyACY.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateExchangeRate(CurrencyACY.Code, WorkDate(), ExchangeRateACY, ExchangeRateACY);
        CurrencyACY."Amount Rounding Precision" := 0.1;
        CurrencyACY.Modify(true);

        LibraryERM.SetAddReportingCurrency(CurrencyACY.Code);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyFCY.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        for Index := 2 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[Index], DimensionValue[1]."Dimension Code");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for Index := 1 to ArrayLen(DimensionValue) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine[Index], PurchaseHeader, PurchaseLine[Index].Type::"G/L Account", GLAccount."No.", 1);
            PurchaseLine[Index].Validate("Shortcut Dimension 1 Code", DimensionValue[Index].Code);
            PurchaseLine[Index].Validate("Direct Unit Cost", 25.8);
            PurchaseLine[Index].Modify(true);
        end;

        PurchaseLine[Index].Validate("Direct Unit Cost", 35.0);
        PurchaseLine[Index].Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        InitializeExpectedVATAmounts(ExpectedVATAmount, 153.9, 112.1, 112.1, 114, 112.1);
        InitializeExpectedVATAmounts(ExpectedVATAmountACY, 2000.7, 1457.3, 1457.3, 1482, 1457.3);

        VerifyVATEntriesAmountAndAmountACY(
            VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount, ExpectedVATAmountACY);
    end;

    [Test]
    procedure PurchaseInvoiceFCYMultipleLinesAndDimensionsWithNormalVATACYIsFCY()
    var
        Vendor: Record Vendor;
        CurrencyFCY: Record Currency;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: array[5] of Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[5] of Record "Purchase Line";
        ExchangeRateFCY: Decimal;
        Index: Integer;
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
        ExpectedVATAmountACY: array[5] of Decimal;
    begin
        // [FEATURE] [Normal VAT] [VAT] [Dimension] [Rounding] [FCY] [ACY]
        // [SCENARIO 377909] System does not loss cent remainder when it posts multiple VAT entries with "VAT Calculation Type" = Reverse Charge VAT and get's "Amount Rounding Precision" from currency for rounding in "Additional-Currency Amount" field

        Initialize();

        ExchangeRateFCY := 1 / 19;

        CurrencyFCY.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateExchangeRate(CurrencyFCY.Code, WorkDate(), ExchangeRateFCY, ExchangeRateFCY);
        CurrencyFCY."Amount Rounding Precision" := 0.1;
        CurrencyFCY.Modify(true);

        LibraryERM.SetAddReportingCurrency(CurrencyFCY.Code);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyFCY.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        for Index := 2 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[Index], DimensionValue[1]."Dimension Code");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for Index := 1 to ArrayLen(DimensionValue) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine[Index], PurchaseHeader, PurchaseLine[Index].Type::"G/L Account", GLAccount."No.", 1);
            PurchaseLine[Index].Validate("Shortcut Dimension 1 Code", DimensionValue[Index].Code);
            PurchaseLine[Index].Validate("Direct Unit Cost", 25.8);
            PurchaseLine[Index].Modify(true);
        end;

        PurchaseLine[Index].Validate("Direct Unit Cost", 35.0);
        PurchaseLine[Index].Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        InitializeExpectedVATAmounts(ExpectedVATAmount, 153.9, 112.1, 112.1, 114, 112.1);
        InitializeExpectedVATAmounts(ExpectedVATAmountACY, 8.1, 5.9, 5.9, 6, 5.9);

        VerifyVATEntriesAmountAndAmountACY(
            VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount, ExpectedVATAmountACY);
    end;

    [Test]
    procedure PurchaseInvoiceFCYMultipleLinesAndDimensionsWithNormalVATACYIsNotFCY()
    var
        Vendor: Record Vendor;
        CurrencyFCY: Record Currency;
        CurrencyACY: Record Currency;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: array[5] of Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[5] of Record "Purchase Line";
        ExchangeRateFCY: Decimal;
        ExchangeRateACY: Decimal;
        Index: Integer;
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
        ExpectedVATAmountACY: array[5] of Decimal;
    begin
        // [FEATURE] [Normal VAT] [VAT] [Dimension] [Rounding] [FCY] [ACY]
        // [SCENARIO 377909] System does not loss cent remainder when it posts multiple VAT entries with "VAT Calculation Type" = Reverse Charge VAT and get's "Amount Rounding Precision" from currency for rounding in "Additional-Currency Amount" field

        Initialize();

        ExchangeRateFCY := 1 / 19;
        ExchangeRateACY := 13;

        CurrencyFCY.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateExchangeRate(CurrencyFCY.Code, WorkDate(), ExchangeRateFCY, ExchangeRateFCY);
        CurrencyFCY."Amount Rounding Precision" := 0.1;
        CurrencyFCY.Modify(true);

        CurrencyACY.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateExchangeRate(CurrencyACY.Code, WorkDate(), ExchangeRateACY, ExchangeRateACY);
        CurrencyACY."Amount Rounding Precision" := 0.1;
        CurrencyACY.Modify(true);

        LibraryERM.SetAddReportingCurrency(CurrencyACY.Code);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyFCY.Code);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        for Index := 2 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[Index], DimensionValue[1]."Dimension Code");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for Index := 1 to ArrayLen(DimensionValue) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine[Index], PurchaseHeader, PurchaseLine[Index].Type::"G/L Account", GLAccount."No.", 1);
            PurchaseLine[Index].Validate("Shortcut Dimension 1 Code", DimensionValue[Index].Code);
            PurchaseLine[Index].Validate("Direct Unit Cost", 25.8);
            PurchaseLine[Index].Modify(true);
        end;

        PurchaseLine[Index].Validate("Direct Unit Cost", 35.0);
        PurchaseLine[Index].Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        InitializeExpectedVATAmounts(ExpectedVATAmount, 153.9, 112.1, 112.1, 114, 112.1);
        InitializeExpectedVATAmounts(ExpectedVATAmountACY, 2000.7, 1457.3, 1457.3, 1482, 1457.3);

        VerifyVATEntriesAmountAndAmountACY(
            VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount, ExpectedVATAmountACY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceMultipleLinesAndDimensionsWithReverseChargeVATFCY()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
        ExpectedVATAmountACY: array[5] of Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT] [Dimension] [Rounding] [FCY]
        // [SCENARIO 401316] System calculates VAT Amount in currency's values and then converts to LCY amounts for Normal VAT

        Initialize();

        CurrencyCode := CreateCurrencyWithRelationalExchangeRate(4.3976);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        CreateDocument258and350(PurchaseHeader, Vendor, GLAccount);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        InitializeExpectedVATAmounts(ExpectedVATAmount, 35.4, 26.12, 26.08, 26.12, 26.08);
        InitializeExpectedVATAmounts(ExpectedVATAmountACY, 0, 0, 0, 0, 0);

        VerifyVATEntriesAmountAndAmountACY(
          VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount, ExpectedVATAmountACY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceMultipleLinesAndDimensionsWithNormalVATFCY()
    var
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
        ExpectedVATAmountACY: array[5] of Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Normal VAT] [VAT] [Dimension] [Rounding] [FCY]
        // [SCENARIO 401316] System calculates VAT Amount in currency's values and then converts to LCY amounts for Reverse Charge VAT

        Initialize();

        CurrencyCode := CreateCurrencyWithRelationalExchangeRate(4.3976);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));

        CreateDocument258and350(PurchaseHeader, Vendor, GLAccount);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        InitializeExpectedVATAmounts(ExpectedVATAmount, 35.4, 26.12, 26.08, 26.12, 26.08);
        InitializeExpectedVATAmounts(ExpectedVATAmountACY, 0, 0, 0, 0, 0);
        VerifyVATEntriesAmountAndAmountACY(
            VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount, ExpectedVATAmountACY);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure QuoteWithDimension()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        PurchaseQuotePage: TestPage "Purchase Quote";
        ShipToOptions: Option "Default (Company Address)",Location,"Custom Address";
    begin
        // [SCENARIO 446055] Header Dimensions will be deleted in a purchase document without a confirm message when you select ship to custom address

        // [GIVEN] Create Vendor and Item with Default Dimension, Purchase Quote.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Dimension.Code, FindDifferentDimension(Dimension.Code), DefaultDimension."Value Posting"::" ",
          PurchaseHeader."Document Type"::Quote);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation

        // [WHEN] Open the page, click on Dimensions and assign the dimension
        PurchaseQuotePage.OpenEdit();
        PurchaseQuotePage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseQuotePage.Dimensions.Invoke();

        // [THEN] Verify the confirmation triggered when custom address is selected 
        PurchaseQuotePage.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,EditDimensionSetEntriesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimensionsInPurchaseOrderWhenShipToIsLocation()
    var
        PurchaseHeader: Record "Purchase Header";
        DimensionValue: Record "Dimension Value";
        Location: Record Location;
        DimensionSetEntry: Record "Dimension Set Entry";
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseOrder: TestPage "Purchase Order";
        ShipToOptions: Option "Default (Company Address)",Location,"Customer Address","Custom Address";
    begin
        // [SCENARIO 450839] Header Dimensions will be deleted in a purchase order when you select ship to location.
        Initialize();

        // [GIVEN] Create Purchase Quote and Dimension with Values
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(true);

        // [GIVEN] Open the page, click on Dimensions and assign the dimension
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseQuote.Dimensions.Invoke();
        PurchaseQuote.Close();
        PurchaseHeader.Find();

        // [GIVEN] Create Purchase Order form Purchase Quote
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);

        // [GIVEN] Create Location
        FindPurchaseOrder(PurchaseHeader, PurchaseHeader."No.");
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] Open Purchase Order page and set "Ship to" as location
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        PurchaseOrder."Location Code".SetValue(Location.Code);
        PurchaseOrder.Close();

        // [THEN] Verify Header Dimensions are available.
        DimensionSetEntry.SetRange("Dimension Set ID", PurchaseHeader."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(PurchaseHeader."Dimension Set ID", DimensionSetEntry."Dimension Set ID", DimensionSetIDErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,EditDimensionSetEntriesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPurchaseOrderDimensionsWhenShipToIsChanged()
    var
        PurchaseHeader: Record "Purchase Header";
        DimensionValue: Record "Dimension Value";
        Location: Record Location;
        DimensionSetEntry: Record "Dimension Set Entry";
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseOrder: TestPage "Purchase Order";
        ShipToOptions: Option "Default (Company Address)",Location,"Customer Address","Custom Address";
    begin
        // [SCENARIO 454238] Header Dimensions will be deleted in a purchase order when you select ship to location.
        Initialize();

        // [GIVEN] Create Purchase Quote and Dimension with Values
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(true);

        // [GIVEN] Open the page, click on Dimensions and assign the dimension
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseQuote.Dimensions.Invoke();
        PurchaseQuote.Close();
        PurchaseHeader.Find();

        // [GIVEN] Create Purchase Order form Purchase Quote
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);

        // [GIVEN] Create Location
        FindPurchaseOrder(PurchaseHeader, PurchaseHeader."No.");
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] Open Purchase Order page and set "Ship to" as location
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        PurchaseOrder."Location Code".SetValue(Location.Code);
        PurchaseOrder.Close();

        // [THEN] Verify Header Dimensions are available.
        DimensionSetEntry.SetRange("Dimension Set ID", PurchaseHeader."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(PurchaseHeader."Dimension Set ID", DimensionSetEntry."Dimension Set ID", DimensionSetIDErr);
    end;

    [Test]
    [HandlerFunctions('LocationMessageHandler,EditDimensionSetEntriesHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifyLocationChangeMessagePurchaseQuoteWhenShipToIsChanged()
    var
        PurchaseHeader: Record "Purchase Header";
        DimensionValue: Record "Dimension Value";
        Location: Record Location;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 454238] Header Dimensions will be deleted in a purchase order when you select ship to location.
        Initialize();

        // [GIVEN] Create Purchase Quote and Dimension with Values
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryWarehouse.CreateLocation(Location);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(true);

        // [GIVEN] Open the page, click on Dimensions and assign the dimension
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseQuote.Dimensions.Invoke();
        PurchaseQuote.ShippingOptionWithLocation.SetValue(1);
        PurchaseQuote."Location Code".SetValue(Location.Code);

        // [VERIFY] Verify Location Change message on handler page.
    end;

    [Test]
    procedure VerifyDimensionsAreNotReInitializedIfDefaultDimensionDoesntExist()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        // [SCENARIO 455039] Verify dimensions are not re-initialized on validate field if default dimensions does not exist
        Initialize();

        // [GIVEN] Create Vendor with default global dimension value
        CreateVendorWithDefaultGlobalDimValue(Vendor, DimensionValue);

        // [GIVEN] Create Item without Default Dimension
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Location without Default Dimension
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Purchase Order
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", Item."No.");

        // [GIVEN] Update global dimension 1 on Purchase Line
        UpdateGlobalDimensionOnPurchaseLine(PurchaseLine, DimensionValue2);

        // [WHEN] Change Location on Purchase Line
        UpdateLocationOnPurchaseLine(PurchaseLine, Location.Code);

        // [VERIFY] Verify Dimensions are not re initialized on Purchase Line
        VerifyDimensionOnPurchaseOrderLine(PurchaseHeader."Document Type", PurchaseHeader."No.", DimensionValue2."Dimension Code");
    end;

    [Test]
    procedure VerifyAccountTypeDefaultDimensionsIsPulledOnPurchaseLine()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 465518] Verify Dimension Code is pulled from Account Type Def. Dimension to Purchase Line, if Vendor and Item doesn't have def. dimensions
        Initialize();

        // [GIVEN] Create Vendor without default dimension
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Item without Default Dimension
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Account Type Default Dimension for Item table
        CreateAccountTypeDefaultDimension(DimensionValue, Vendor."No.", Database::Item);

        // [WHEN] Create Purchase Order
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", Item."No.");

        // [VERIFY] Verify Dimension are puled from Account Type to Purchase Line
        Assert.AreEqual(PurchaseLine."Shortcut Dimension 1 Code", DimensionValue.Code,
            StrSubstNo(DimensionValueCodeErr, PurchaseLine.FieldCaption("Shortcut Dimension 1 Code"), DimensionValue.Code));
    end;

    [Test]
    procedure VerifyWarningMessageAboutChangeDimensionsIsNotShownWhenPurchInvoiceIsCreatedFromVendor()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        DimensionValue: Record "Dimension Value";
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 467051] Verify warning message about dimension change is not shown when Purchase Invoice is created from Vendor 
        Initialize();

        // [GIVEN] Create Dimension Value for Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create Location with default dimension
        CreateLocationWithDefaultDimension(Location, DimensionValue);

        // [GIVEN] Create Vendor 
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Update Location on Vendor
        Vendor.Validate("Location Code", Location.Code);
        Vendor.Modify(true);

        // [GIVEN] Open Vendor Card
        OpenVendorCard(VendorCard, Vendor."No.");

        // [WHEN] Create Purchase Invoice from Vendor Card
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // [THEN] Verify Confirmation message is not shown
        PurchaseInvoice."Vendor Invoice No.".Activate();
    end;

    [Test]
    procedure VerifyWarningMessageAboutChangeDimensionsIsNotShownWhenPurchOrderIsCreatedFromListWithLocationAssignToVendor()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        DimensionValue: array[2] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 467051] Verify warning message about dimension change is not shown when Purchase Order is created from List with Location assigned to Vendor
        Initialize();

        // [GIVEN] Create Dimension Value for Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create Location with default dimension
        CreateLocationWithDefaultDimension(Location, DimensionValue[1]);

        // [GIVEN] Create Dimension with Dimension Value
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);

        // [GIVEN] Create Vendor with Dimension
        Vendor.Get(CreateVendorWithDimension(DefaultDimension, DefaultDimension."Value Posting"::" ", DimensionValue[2]."Dimension Code"));

        // [GIVEN] Update Location on Vendor
        Vendor.Validate("Location Code", Location.Code);
        Vendor.Modify(true);

        // [WHEN] Create new Purchase Order for Vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [THEN] Verify results
        VerifyDimensionsInDimensionSet(PurchaseHeader, DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ApplyVendorEntriesModalPageHandler,PostApplicationModalPageHandler')]
    procedure VerifyErrorMsgForRequiredDimensionOnGainLossAccountsOnApplyEntriesFotExchangeRateDifference()
    var
        Currency: Record Currency;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        FirstStartingDate, SecondStartingDate : Date;
        VendorNo, PurchaseInvoiceDocumentNo, PaymentDocNo : Code[20];
    begin
        // [SCENARIO 485652] Verify error message for required dimension on Gain/Loss Accounts on Apply Entries for Exchange Rate Difference 
        Initialize();

        // [GIVEN] Create Currency with Gain/Loss Accounts
        CreateCurrencyWithMultipleExchangeRate(Currency, FirstStartingDate, SecondStartingDate);

        // [GIVEN] Created Dimension with Value
        CreateDimensionWithValue(DimensionValue);

        // [GIVEN] New mandatory Default Dimension for the Gain/Loss Accounts
        CreateDefaultDimensionCodeMandatory(DefaultDimension, Database::"G/L Account", Currency."Realized Gains Acc.", DimensionValue."Dimension Code");

        // [GIVEN] Create Vendor with Currency
        VendorNo := CreateVendorWithCurrency(Currency.Code);

        // [GIVEN] Create and Post Purchase Invoice
        PurchaseInvoiceDocumentNo := CreateAndPostPurchaseInvoiceWithCurrencyCode(PurchaseLine, VendorNo, FirstStartingDate);

        // [GIVEN] Create and Post Payment
        PaymentDocNo := CreateAndPostPaymentLine(GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Document Type"::Payment,
          PurchaseLine."Amount Including VAT", SecondStartingDate);
        LibraryVariableStorage.Enqueue(PaymentDocNo);

        // [WHEN] Call Apply Entries action on Vendor Ledger Entries from Posted Invoice
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.Filter.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntries.Filter.SetFilter("Document No.", PurchaseInvoiceDocumentNo);
        VendorLedgerEntries.ActionApplyEntries.Invoke();
        VendorLedgerEntries.Close();

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(MissingDimensionErr, DimensionValue."Dimension Code", Currency."Realized Gains Acc."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,MessageHandler')]
    procedure VerifyPurchaseOrderDimensionNotDeletedWhenShippingOptionChange()
    var
        PurchaseHeader: Record "Purchase Header";
        ModifiedPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Dimension: array[3] of Record Dimension;
        DimensionValue: array[3] of Record "Dimension Value";
        PurchaseOrder: TestPage "Purchase Order";
        ShipToOptions: Option "Default (Company Address)",Location,"Customer Address","Custom Address";
        VendNo: Code[20];
        ExpectedDimID: Integer;
    begin
        // [SCENARIO 490897] Dimensions are being deleted from Purchase Order headers when changing the "Ship-to" field.
        Initialize();

        // [GIVEN] Create Multiple Dimensions, it's Dimension Values, and Vendor
        CreateDimensionValues(Dimension, DimensionValue);
        VendNo := CreateVendorWithPurchaserAndDefDim(Dimension, DimensionValue);

        // [THEN] Create a Purchase Order.
        LibraryPurchase.CreatePurchaseOrderForVendorNo(PurchaseHeader, VendNo);
        ExpectedDimID := PurchaseHeader."Dimension Set ID";

        // [GIVEN] Add New Dimension on Purchase Header and Purchase Line.
        CreateDimensionSetEntryHeader(PurchaseHeader, Dimension[3].Code);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        CreateDimensionSetEntryLine(PurchaseLine, Dimension[3].Code);

        // [GIVEN] Open Purchase Order.
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        // [VERIFY] Verify: Dimensions On Purchase Order When Ship to Option "Location".
        LibraryWarehouse.CreateLocationWithAddress(Location);
        UpdateShipToOption(PurchaseOrder, ShipToOptions::Location, Location.Code);
        ModifiedPurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseOrder."No.".Value);
        Assert.AreEqual(PurchaseHeader."Dimension Set ID", ModifiedPurchaseHeader."Dimension Set ID", DimensionSetIDErr);

        // [VERIFY] Verify: Dimensions On Purchase Order When Ship to Option "Default (Company Address)".
        UpdateShipToOption(PurchaseOrder, ShipToOptions::"Default (Company Address)", '');
        ModifiedPurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseOrder."No.".Value);
        Assert.AreEqual(ExpectedDimID, ModifiedPurchaseHeader."Dimension Set ID", DimensionSetIDErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceChangeDimension()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        PostedInvoiceNo: Code[20];
        InvDate: Date;
    begin
        // [SCENARIO 496433] When changing global dimension value code and posting a purchase invoice with the new value it gets posted with the old value
        Initialize();

        // [GIVEN] Create Dimension, Dimension Value and Change Global Dimension 1 Code with newly created dimension
        CreateDimensionAndRunChangeGlobalDimension(Dimension, DimensionValue);
        InvDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());

        // [GIVEN] Create Vendor and Item
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [THEN] Create and post Purchase Invoice when Dimension Value Code set to Purchase Line with Initial Value
        PostedInvoiceNo := CreateAndPostPurchaseInvoice(InvDate, Vendor."No.", Item."No.", DimensionValue.Code);

        // [WHEN] Copy and Post Purchase Invoice, after changing Dimension Value Code to New Value.
        PostedInvoiceNo := CreateCopyAndPostPurchaseInvoiceWithDimensionValueRename(InvDate, Vendor."No.", Item."No.", Dimension.Code, DimensionValue, PostedInvoiceNo);

        // [VERIFY] Verify: Correct Dimension Flowed on newly Posted Purchase Invoice
        VerifyPostedPurchaseInvoiceLineContainsNewDimensionValue(PostedInvoiceNo, Item."No.", DimensionValue.Code);
        VerifyPostedGLEntryContainsNewDimensionValue(PostedInvoiceNo, DimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    procedure PurchaseOrderDimensionNotDeletedWhenShippingOptionChangeFromLocationToOther()
    var
        PurchaseHeader: Record "Purchase Header";
        ModifiedPurchaseHeader: Record "Purchase Header";
        Dimension: array[3] of Record Dimension;
        DimensionValues: array[3] of Record "Dimension Value";
        DimensionValue: Record "Dimension Value";
        Location: Record Location;
        PurchaseOrder: TestPage "Purchase Order";
        ShipToOptions: Option "Default (Company Address)",Location,"Customer Address","Custom Address";
        VendNo: Code[20];
        ExpectedDimID: Integer;
    begin
        // [SCENARIO 498578] Dimensions are being deleted from Purchase Order headers when changing the "Ship-to" field
        Initialize();

        // [GIVEN] Create Multiple Dimensions, it's Dimension Values, and Vendor
        CreateDimensionValues(Dimension, DimensionValues);
        VendNo := CreateVendorWithPurchaserAndDefDim(Dimension, DimensionValues);

        // [GIVEN] Create Dimension Value for Global Dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create Location with default dimension
        CreateLocationWithDefaultDimension(Location, DimensionValue);

        // [THEN] Create a Purchase Order.
        LibraryPurchase.CreatePurchaseOrderForVendorNo(PurchaseHeader, VendNo);
        ExpectedDimID := PurchaseHeader."Dimension Set ID";

        // [GIVEN] Add New Dimension on Purchase Header and Purchase Line.
        CreateDimensionSetEntryHeader(PurchaseHeader, Dimension[3].Code);

        // [GIVEN] Open Purchase Order.
        OpenPurchaseOrder(PurchaseHeader, PurchaseOrder);

        // [VERIFY] Verify: Dimensions On Purchase Order When Ship to Option "Location".
        UpdateShipToOption(PurchaseOrder, ShipToOptions::Location, Location.Code);
        ModifiedPurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseOrder."No.".Value);
        Assert.AreNotEqual(PurchaseHeader."Dimension Set ID", ModifiedPurchaseHeader."Dimension Set ID", DimensionSetIDErr);

        // [VERIFY] Verify: Dimensions On Purchase Order When Ship to Option "Default (Company Address)".
        UpdateShipToOption(PurchaseOrder, ShipToOptions::"Default (Company Address)", '');
        ModifiedPurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseOrder."No.".Value);
        Assert.AreEqual(ExpectedDimID, ModifiedPurchaseHeader."Dimension Set ID", DimensionSetIDErr);

        // [VERIFY] Verify: Dimensions On Purchase Order When Ship to Option "Default (Company Address)".
        UpdateShipToOption(PurchaseOrder, ShipToOptions::"Custom Address", '');
        ModifiedPurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseOrder."No.".Value);
        Assert.AreEqual(ExpectedDimID, ModifiedPurchaseHeader."Dimension Set ID", DimensionSetIDErr);
    end;

    [Test]
    [HandlerFunctions('ChangeDimensionConfirmHandler,ChangeLocationMessageHandler')]
    procedure VerifyDimensionsAreNotReInitializedIfLocationIsNotChanged()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Location: array[2] of Record Location;
        DimensionValue: array[2] of Record "Dimension Value";
        ShiptoAddress: array[2] of Record "Ship-to Address";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        // [SCENARIO 504598] Verify dimensions are not re-initialized from location on validatation of ship-to code if location is not changed
        Initialize();

        // [GIVEN] Create vendor with global dimension 1 value
        CreateVendorWithDefaultGlobalDimValue(Vendor, DimensionValue[1]);

        // [GIVEN] Create customer that will be used for ship-to address
        LibrarySales.CreateCustomer(Customer);

        //[GIVEN] Create one more dimension value for global dimension 1 code
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create two locations with different global dimension 1 values
        // [GIVEN] Create two shipping addresses with the locations for the customer
        for i := 1 to 2 do begin
            CreateLocationWithDefaultDimension(Location[i], DimensionValue[i]);
            CreateShipToAddressWithLocation(ShiptoAddress[i], Customer."No.", Location[i].Code);
        end;

        // [GIVEN] Create purchase order, global dimnesion 1 value is coppied from vendor
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", '');

        // [GIVEN] Change global dimension 1 value on purchase header
        ChangeDimensionOnDocument(PurchaseHeader, DimensionValue[2].Code); // ChangeDimensionConfirmHandler

        // [GIVEN] Change ship-to code on purchase header and location code is coppied from ship-to address
        PurchaseHeader.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader.Validate("Ship-to Code", ShiptoAddress[1].Code);

        // [GIVEN] Change location code on purchase header
        PurchaseHeader.Validate("Location Code", Location[2].Code);

        // [WHEN] Change ship-to code with the same location code on purchase header
        PurchaseHeader.Validate("Ship-to Code", ShiptoAddress[2].Code);

        // [THEN] Verify dimensions are not re-initialized on purchase header and purchase lines
        VerifyDimensionOnPurchaseOrder(PurchaseHeader, DimensionValue[2]."Dimension Code");
    end;

    local procedure Initialize()
    var
        ICSetup: Record "IC Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Purchase");
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Purchase");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Purchase");
    end;

    local procedure InitializeExpectedVATAmounts(var ExpectedVATAmount: array[5] of decimal; Amount1: Decimal; Amount2: Decimal; Amount3: Decimal; Amount4: Decimal; Amount5: Decimal)
    begin
        ExpectedVATAmount[1] := Amount1;
        ExpectedVATAmount[2] := Amount2;
        ExpectedVATAmount[3] := Amount3;
        ExpectedVATAmount[4] := Amount4;
        ExpectedVATAmount[5] := Amount5;
    end;

    local procedure ApplyAndPostVendorEntry(DocumentNo: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, VendorLedgerEntry2."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry2.FindSet();
        repeat
            VendorLedgerEntry2.CalcFields("Remaining Amount");
            VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
            VendorLedgerEntry2.Modify(true);
        until VendorLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure ChangeDimensionPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Update Dimension value on Purchase Header.
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PurchaseHeader."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        DimensionSetEntry.FindFirst();
        PurchaseHeader.Validate(
          "Shortcut Dimension 1 Code",
          FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        PurchaseHeader.Modify(true);
    end;

    local procedure CopyDimensionSetEntry(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; var DimensionSetEntry: Record "Dimension Set Entry")
    begin
        repeat
            TempDimensionSetEntry := DimensionSetEntry;
            TempDimensionSetEntry.Insert();
        until DimensionSetEntry.Next() = 0;
    end;

    local procedure CreateCurrencyWithRelationalExchangeRate(RelationalExchangeRate: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchangeRate);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalExchangeRate);
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure CreateDocument258and350(var PurchaseHeader: Record "Purchase Header"; var Vendor: Record Vendor; var GLAccount: Record "G/L Account")
    var
        DimensionValue: array[5] of Record "Dimension Value";
        PurchaseLine: array[5] of Record "Purchase Line";
        Index: Integer;
    begin
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        for Index := 2 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[Index], DimensionValue[1]."Dimension Code");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for Index := 1 to ArrayLen(DimensionValue) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine[Index], PurchaseHeader, PurchaseLine[Index].Type::"G/L Account", GLAccount."No.", 1);
            PurchaseLine[Index].Validate("Shortcut Dimension 1 Code", DimensionValue[Index].Code);
            PurchaseLine[Index].Validate("Direct Unit Cost", 25.8);
            PurchaseLine[Index].Modify(true);
        end;

        PurchaseLine[Index].Validate("Direct Unit Cost", 35.0);
        PurchaseLine[Index].Modify(true);
    end;

    local procedure CreateDimensionForSalesLine(var SalesLine: Record "Sales Line"): Code[20]
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        DimensionSetID := LibraryDimension.CreateDimSet(SalesLine."Dimension Set ID", Dimension.Code, DimensionValue.Code);
        SalesLine.Validate("Dimension Set ID", DimensionSetID);
        SalesLine.Modify(true);
        exit(Dimension.Code);
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetID: Integer; ShortcutDimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, FindDifferentDimension(ShortcutDimensionCode));
        DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        LibraryDimension.FindDimensionValue(DimensionValue, ShortcutDimensionCode);
        DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, ShortcutDimensionCode, DimensionValue.Code);
    end;

    local procedure CreateDimensionSetEntryHeader(var PurchaseHeader: Record "Purchase Header"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetID: Integer;
    begin
        DimensionSetID := PurchaseHeader."Dimension Set ID";
        CreateDimensionSetEntry(DimensionSetID, ShortcutDimensionCode);
        PurchaseHeader.Validate("Dimension Set ID", DimensionSetID);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateDimensionSetEntryLine(var PurchaseLine: Record "Purchase Line"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetID: Integer;
    begin
        DimensionSetID := PurchaseLine."Dimension Set ID";
        CreateDimensionSetEntry(DimensionSetID, ShortcutDimensionCode);
        PurchaseLine.Validate("Dimension Set ID", DimensionSetID);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateDimensionWithTwoDimensionValue(var NewDimSetID: Integer; var NewDimSetID2: Integer)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);
        NewDimSetID := LibraryDimension.CreateDimSet(NewDimSetID, Dimension.Code, DimensionValue.Code);
        NewDimSetID2 := LibraryDimension.CreateDimSet(NewDimSetID2, Dimension.Code, DimensionValue2.Code);
    end;

    local procedure CreateItemWithDimension(DimensionCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type") ItemNo: Code[20]
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryInventory.CreateItem(Item);
        // Use Random because value is not important.
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        ItemNo := Item."No.";
        if DimensionCode = '' then
            exit;
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateOrderWithDimension(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; var DimensionValueCode: Code[20]; var ShortcutDimensionCode: Code[20]; var DimensionSetID: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [GIVEN] Create Vendor, Item, Purchase Header and Purchase Line with Dimension.
        GeneralLedgerSetup.Get();
        ShortcutDimensionCode := GeneralLedgerSetup."Shortcut Dimension 1 Code";
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', '', DefaultDimension."Value Posting"::" ", PurchaseHeader."Document Type"::Order);
        CreateDimensionSetEntryHeader(PurchaseHeader, ShortcutDimensionCode);
        CreateDimensionSetEntryLine(PurchaseLine, ShortcutDimensionCode);

        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PurchaseLine."Dimension Set ID");
        CopyDimensionSetEntry(TempDimensionSetEntry, DimensionSetEntry);
        TempDimensionSetEntry.SetFilter("Dimension Code", '<>%1', ShortcutDimensionCode);
        TempDimensionSetEntry.FindSet();

        // [WHEN] Change Dimension Value for Purchase Header Shortcut Dimension.
        ChangeDimensionPurchaseHeader(PurchaseHeader, ShortcutDimensionCode);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        DimensionValueCode := PurchaseHeader."Shortcut Dimension 1 Code";
        DimensionSetID := PurchaseLine."Dimension Set ID";
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorDimensionCode: Code[20]; ItemDimensionCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type"; DocumentType: Enum "Purchase Document Type")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType, CreateVendorWithDimension(DefaultDimension, ValuePosting, VendorDimensionCode));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithDimension(ItemDimensionCode, ValuePosting),
          LibraryRandom.RandDec(10, 2));  // Take Random Value for Quantity.
    end;

    local procedure CreateRequisitionLine(var RequisitionWkshName: Record "Requisition Wksh. Name"; var DimensionSetID: Integer) DimensionCode: Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        // Create Customer, Sales Order having Purchasing Code with Drop Shipment True, Create Dimension Set Entry for Sales Line.
        CreateSalesOrderPurchasingCode(SalesLine);
        DimensionCode := CreateDimensionForSalesLine(SalesLine);
        DimensionSetID := SalesLine."Dimension Set ID";

        // Run get Sales Order from Requisition Worksheet.
        GetSalesOrder(RequisitionWkshName, SalesLine);
    end;

    local procedure CreateSalesLinePurchasingCode(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        // Use Random because value is not important.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader,
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Purchasing Code", FindPurchasingCode());
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderPurchasingCode(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLinePurchasingCode(SalesLine, SalesHeader);
    end;

    local procedure CreateVendorWithDimension(var DefaultDimension: Record "Default Dimension"; ValuePosting: Enum "Default Dimension Value Posting Type"; DimensionCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if DimensionCode = '' then
            exit(Vendor."No.");
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
        // another default dimension causing no error
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, Vendor."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithExtendedText(var Item: Record Item; DimensionCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        Item.Get(CreateItemWithDimension(DimensionCode, DefaultDimension."Value Posting"::" "));
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
    end;

    local procedure CreateGLAccountWithDimension(DimensionCode: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        if DimensionCode = '' then
            exit;
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::" ");
        DefaultDimension.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateStandardPurchaseDocument(var StandardPurchaseLine: Record "Standard Purchase Line"; DimensionCode: Code[20]; ItemNo: Code[20]; GLAccountNo: Code[20]) DifferentDimensionCode: Code[20]
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code, StandardPurchaseLine.Type::Item, ItemNo);
        DifferentDimensionCode := FindDifferentDimension(DimensionCode);
        UpdateDimensionSetID(StandardPurchaseLine, DifferentDimensionCode);
        CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code, StandardPurchaseLine.Type::"G/L Account", GLAccountNo);

        // Use Random because value is not important.
        StandardPurchaseLine.Validate("Amount Excl. VAT", StandardPurchaseLine.Quantity * LibraryRandom.RandDec(10, 2));
        StandardPurchaseLine.Modify(true);
        UpdateDimensionSetID(StandardPurchaseLine, DifferentDimensionCode);
    end;

    local procedure CreateStandardPurchaseLine(var StandardPurchaseLine: Record "Standard Purchase Line"; StandardPurchaseCode: Code[10]; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode);
        StandardPurchaseLine.Validate(Type, Type);
        StandardPurchaseLine.Validate("No.", No);
        // Use Random because value is not important.
        StandardPurchaseLine.Validate(Quantity, LibraryRandom.RandInt(10));
        StandardPurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJournalLineWithDimSetID(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; NewDimSetID: Integer)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Dimension Set ID", NewDimSetID);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLinesWithDimSetID(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; DimSetID: Integer; DimSetID2: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        CreateGenJournalLineWithDimSetID(
          GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, Amount, DimSetID);
        CreateGenJournalLineWithDimSetID(
          GenJournalBatch, GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, -GenJournalLine.Amount, DimSetID2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePartlyReceiptPurchOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInDecimalRange(10, 20, 2));
        UpdatePartialQuantityToReceive(PurchaseLine);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateGlobal1DimensionValue(var DimensionValue: Record "Dimension Value"): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        exit(DimensionValue.Code);
    end;

    local procedure FindDifferentDimension("Code": Code[20]): Code[20]
    var
        Dimension: Record Dimension;
    begin
        Dimension.SetFilter(Code, '<>%1', Code);
        LibraryDimension.FindDimension(Dimension);
        exit(Dimension.Code);
    end;

    local procedure FindDifferentDimensionValue(DimensionCode: Code[20]; "Code": Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetFilter(Code, '<>%1', Code);
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        exit(DimensionValue.Code);
    end;

    local procedure FindDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; ShortcutDimensionCode: Code[20]; DimensionSetID: Integer)
    begin
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; QuoteNo: Code[20])
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Quote No.", QuoteNo);
        PurchaseHeader.FindFirst();
    end;

    local procedure FindPurchasingCode(): Code[10]
    var
        Purchasing: Record Purchasing;
        RecordRef: RecordRef;
    begin
        Purchasing.Init();
        Purchasing.SetRange("Drop Shipment", true);
        RecordRef.GetTable(Purchasing);
        LibraryUtility.FindRecord(RecordRef);
        RecordRef.SetTable(Purchasing);
        exit(Purchasing.Code);
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.FindFirst();
    end;

    local procedure GetSalesOrder(var RequisitionWkshName: Record "Requisition Wksh. Name"; SalesLine: Record "Sales Line")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
    begin
        ReqWkshTemplate.SetRange(Type, RequisitionWkshName."Template Type"::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        Commit();
        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);

        RunGetSalesOrders(SalesLine, RequisitionLine);
    end;

    local procedure PostPurchaseOrder(BuyFromVendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.FindFirst();
        UpdateVendorInvoiceNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseHeader."No.");
    end;

    local procedure RunCopyPurchaseDocument(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20])
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        Commit();
        Clear(CopyPurchaseDocument);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Sales Document Type From"::"Posted Shipment", DocumentNo, true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure RunGetSalesOrders(SalesLine: Record "Sales Line"; RequisitionLine: Record "Requisition Line")
    var
        GetSalesOrders: Report "Get Sales Orders";
        RetrieveDimensions: Option Item,"Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        Clear(GetSalesOrders);
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.InitializeRequest(RetrieveDimensions::"Sales Line");
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 0);
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.RunModal();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and delete General Journal Lines before creating new General Journal Lines in the General Journal
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateDimensionPurchaseHeader(PurchaseHeader: Record "Purchase Header") DimensionSetID: Integer
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Update Dimension value on Purchase Header Dimension.
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PurchaseHeader."Dimension Set ID");
        DimensionSetID :=
          LibraryDimension.EditDimSet(
            DimensionSetEntry."Dimension Set ID", DimensionSetEntry."Dimension Code",
            FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        PurchaseHeader.Validate("Dimension Set ID", DimensionSetID);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateDimensionPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetID: Integer;
    begin
        // Update Dimension value on Purchase Line Dimension.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PurchaseLine."Dimension Set ID");
        DimensionSetID :=
          LibraryDimension.EditDimSet(
            DimensionSetEntry."Dimension Set ID", DimensionSetEntry."Dimension Code",
            FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        PurchaseLine.Validate("Dimension Set ID", DimensionSetID);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePartialQuantityToReceive(PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity * LibraryUtility.GenerateRandomFraction());
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateVendorOnRequisitionLine(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; VendorNo: Code[20])
    begin
        FindRequisitionLine(RequisitionLine, RequisitionWkshName);
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateDimensionSetID(var StandardPurchaseLine: Record "Standard Purchase Line"; DifferentDimension: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, DifferentDimension);
        DimensionSetID := LibraryDimension.CreateDimSet(StandardPurchaseLine."Dimension Set ID", DifferentDimension, DimensionValue.Code);
        StandardPurchaseLine.Validate("Dimension Set ID", DimensionSetID);
        StandardPurchaseLine.Modify(true);
    end;

    local procedure UpdateInvoiceAmountForRounding(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Line Amount", LibraryRandom.RandDecInRange(10, 20, 3));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; GLAccountCode: Code[20]; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Create Purchase Credit Memo and modify Purchase Line with Random values.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountCode, LibraryRandom.RandDec(5, 2));
    end;

    local procedure SetGLAccountDefaultDimension(var DefaultDimension: Record "Default Dimension"; DimensionCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure FindICGLAccount(): Code[20]
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        ICGLAccount.SetRange("Account Type", ICGLAccount."Account Type"::Posting);
        ICGLAccount.SetRange(Blocked, false);
        ICGLAccount.FindFirst();
        exit(ICGLAccount."No.");
    end;

    local procedure DeleteDefaultDimension(DefaultDimension: Record "Default Dimension")
    begin
        DefaultDimension.Get(DefaultDimension."Table ID", DefaultDimension."No.", DefaultDimension."Dimension Code");
        DefaultDimension.Delete(true);
    end;

    local procedure VerifyDimensionOnArchiveHeader(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindFirst();
        PurchaseHeaderArchive.TestField("Dimension Set ID", PurchaseHeader."Dimension Set ID");
    end;

    local procedure VerifyDimensionOnArchiveLine(PurchaseLine: Record "Purchase Line")
    var
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        PurchaseLineArchive.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLineArchive.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLineArchive.FindFirst();
        PurchaseLineArchive.TestField("Dimension Set ID", PurchaseLine."Dimension Set ID");
    end;

    local procedure VerifyDimensionOnReceiptLine(DocumentNo: Code[20]; DimensionSetID: Integer)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchRcptLine.FindFirst();
        PurchRcptLine.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyDimensionOnRoundingEntry(PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");

        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();

        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Invoice Rounding Account");
        FindGLEntry(GLEntry, PurchInvHeader."No.");
        GLEntry.TestField("Dimension Set ID", PurchaseHeader."Dimension Set ID");
    end;

    local procedure VerifyDimensionSetEntry(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        repeat
            DimensionSetEntry.SetRange("Dimension Code", TempDimensionSetEntry."Dimension Code");
            DimensionSetEntry.FindFirst();
            DimensionSetEntry.TestField("Dimension Value Code", TempDimensionSetEntry."Dimension Value Code");
        until TempDimensionSetEntry.Next() = 0;
    end;

    local procedure VerifyGLEntryDimension(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange("No.", PurchaseLine."No.");
        PurchInvLine.FindFirst();

        GLEntry.SetRange(Amount, PurchInvLine.Amount);
        FindGLEntry(GLEntry, DocumentNo);
        GLEntry.TestField("Dimension Set ID", PurchaseLine."Dimension Set ID");
    end;

    local procedure VerifyDimensionCode(DimensionSetID: Integer; DimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.TestField("Dimension Code", DimensionCode)
    end;

    local procedure VerifyGLEntryICPartner(DocumentNo: Code[20]; ICPartnerCode: Code[20]; GlobalDimensionCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"IC Partner");
        GLEntry.FindFirst();
        GLEntry.TestField("Global Dimension 1 Code", GlobalDimensionCode);
        GLEntry.TestField("IC Partner Code", ICPartnerCode);
    end;

    local procedure VerifyGLEntry(DocumentnNo: Code[20]; DimensionCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentnNo);
        GLEntry.FindSet();
        repeat
            Assert.IsTrue(DimensionSetEntry.Get(GLEntry."Dimension Set ID", DimensionCode), 'Dimension Set Entry must found');
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyDimensionOnPurchaseOrderLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; DimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, DocumentType, DocumentNo);
        DimensionSetEntry.SetRange("Dimension Set ID", PurchaseLine."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(
          DimensionCode, DimensionSetEntry."Dimension Code",
          StrSubstNo(DimensionValueCodeErr, DimensionSetEntry.FieldCaption("Dimension Code"), DimensionCode));
    end;

    local procedure VerifyQuantityReceivedOnPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, DocumentType, DocumentNo);
        Assert.AreEqual(
          Quantity, PurchaseLine."Quantity Received",
          StrSubstNo(QuantityReceivedErr, PurchaseLine.FieldCaption("Quantity Received"), Quantity, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyReceiptLineOnPostedPurchaseReceipt(PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.FindFirst();
        PurchRcptLine.TestField(Type, PurchaseLine.Type);
        PurchRcptLine.TestField("No.", PurchaseLine."No.");
        PurchRcptLine.TestField("Location Code", PurchRcptLine."Location Code");
        PurchRcptLine.TestField(Quantity, PurchRcptLine.Quantity);
    end;

    local procedure VerifyDimensionOnPurchaseReceipt(DocumentNo: Code[20]; DimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", DocumentNo);
        PurchRcptLine.FindFirst();
        DimensionSetEntry.SetRange("Dimension Set ID", PurchRcptLine."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(
          DimensionCode, DimensionSetEntry."Dimension Code",
          StrSubstNo(DimensionValueCodeErr, DimensionSetEntry.FieldCaption("Dimension Code"), DimensionCode));
    end;

    local procedure VerifyUndoReceiptLineOnPostedReceipt(DocumentNo: Code[20]; Quantity: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", DocumentNo);
        PurchRcptLine.FindLast();
        Assert.AreEqual(
          Quantity, -PurchRcptLine.Quantity,
          StrSubstNo(QuantityReceivedErr, PurchRcptLine.FieldCaption(Quantity), Quantity, PurchRcptLine.TableCaption()));
    end;

    local procedure VerifyQuantitytoReceiveOnPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, DocumentType, DocumentNo);
        Assert.AreEqual(
          Quantity, PurchaseLine."Qty. to Receive",
          StrSubstNo(QuantityReceivedErr, PurchaseLine.FieldCaption("Qty. to Receive"), Quantity, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyVendorLedgerEntryOpen(DocumentNo: Code[20]; Open: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(Open, VendorLedgerEntry.Open, StrSubstNo(VendorLedgerEntryErr, Open, DocumentNo));
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDimensionOnDimSet(DimSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.GetDimensionSet(TempDimensionSetEntry, DimSetID);
        TempDimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        TempDimensionSetEntry.FindFirst();
        TempDimensionSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure VerifyVATEntriesAmountAndAmountACY(VATProdPostingGroup: Code[20]; DocumentNo: Code[20]; ExpectedVATAmount: array[5] of Decimal; ExpectedVATAmountACY: array[5] of Decimal)
    var
        VATEntry: Record "VAT Entry";
        VATEntryAmount: array[5] of Decimal;
        VATEntryAmountACY: array[5] of Decimal;
        Index: Integer;
        IncorrectAmountErr: Label 'Incorrect Amount in "VAT Entry"[%1]', Locked = true;
        IncorrectAdditionalCurrAmountErr: Label 'Incorrect Additional-Currency Amount in "VAT Entry"[%1]', Locked = true;
    begin

        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(VATEntry, ArrayLen(ExpectedVATAmount));

        Index := 0;
        VATEntry.FindSet();
        repeat
            Index += 1;
            VATEntryAmount[Index] := VATEntry.Amount;
            VATEntryAmountACY[Index] := VATEntry."Additional-Currency Amount";
        until VATEntry.Next() = 0;

        for Index := 1 to ArrayLen(ExpectedVATAmount) do begin
            Assert.AreEqual(ExpectedVATAmount[Index], VATEntryAmount[Index], StrSubstNo(IncorrectAmountErr, Index));
            Assert.AreEqual(ExpectedVATAmountACY[Index], VATEntryAmountACY[Index], StrSubstNo(IncorrectAdditionalCurrAmountErr, Index));
        end;
    end;

    local procedure UpdateLocationOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    begin
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateGlobalDimensionOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        PurchaseLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20])
    begin
        // Purchase Order with one Purchase line. Take random value for Quantity and Direct Unit Cost.        
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreateAndModifyPurchaseLine(
          PurchaseLine, PurchaseHeader, ItemNo, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateAndModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVendorWithDefaultGlobalDimValue(var Vendor: Record Vendor; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, Vendor."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateAccountTypeDefaultDimension(var DimensionValue: Record "Dimension Value"; VendorNo: Code[20]; TableId: Integer)
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.CreateAccTypeDefaultDimension(DefaultDimension, TableId, DimensionValue."Dimension Code",
            DimensionValue.Code, DefaultDimension."Value Posting"::" ");
    end;

    local procedure OpenVendorCard(var VendorCard: TestPage "Vendor Card"; VendorNo: Code[20])
    begin
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", VendorNo);
    end;

    local procedure CreateLocationWithDefaultDimension(var Location: Record Location; DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure VerifyDimensionsInDimensionSet(var PurchaseHeader: Record "Purchase Header"; var DimensionValue: array[2] of Record "Dimension Value")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", PurchaseHeader."Dimension Set ID");
        DimensionSetEntry.FindSet();
        repeat
            if DimensionSetEntry."Dimension Code" = DimensionValue[1].Code then
                Assert.AreEqual(DimensionSetEntry."Dimension Value Code", DimensionValue[1]."Dimension Code", NotEqualDimensionsErr);
            if DimensionSetEntry."Dimension Code" = DimensionValue[2].Code then
                Assert.AreEqual(DimensionSetEntry."Dimension Value Code", DimensionValue[2]."Dimension Code", NotEqualDimensionsErr);
        until DimensionSetEntry.Next() = 0;
    end;

    local procedure CreateAndPostPaymentLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date) PaymentDocNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo, DocumentType, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        PaymentDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateVendorWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostPurchaseInvoiceWithCurrencyCode(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; PostingDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, VendorNo, PostingDate);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", PostingDate);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateDefaultDimensionCodeMandatory(var DefaultDimension: Record "Default Dimension"; TableId: Integer; No: Code[20]; DimensionCode: Code[20])
    begin
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableId, No, DimensionCode, '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify();
    end;

    local procedure CreateCurrencyWithMultipleExchangeRate(var Currency: Record Currency; var FirstStartingDate: Date; var SecondStartingDate: Date)
    begin
        // Create Currency with different starting date and Exchange Rate. Taken Random value to calculate Date.
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        SecondStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', FirstStartingDate);
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        CreateExchangeRate(Currency.Code, WorkDate());
        CreateExchangeRate(Currency.Code, FirstStartingDate);
        CreateExchangeRate(Currency.Code, SecondStartingDate);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; StartingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Take Random Value for Exchange Rate Fields.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" + LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate(
          "Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount" + LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateDimensionValues(
        var Dimension: array[3] of Record Dimension;
        var DimensionValue: array[3] of Record "Dimension Value")
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Dimension) do begin
            LibraryDimension.CreateDimension(Dimension[i]);
            LibraryDimension.CreateDimensionValue(DimensionValue[i], Dimension[i].Code);
        end;
    end;

    local procedure CreateVendorWithPurchaserAndDefDim(
        Dimension: array[3] of Record Dimension;
        DimensionValue: array[3] of Record "Dimension Value"): Code[20]
    var
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension, Database::"Salesperson/Purchaser", SalespersonPurchaser.Code, Dimension[1].Code, DimensionValue[1].Code);

        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension, Database::Vendor, Vendor."No.", Dimension[2].Code, DimensionValue[2].Code);

        exit(Vendor."No.");
    end;

    local procedure OpenPurchaseOrder(PurchaseHeader: Record "Purchase Header"; var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
    end;

    local procedure UpdateShipToOption(
        PurchaseOrder: TestPage "Purchase Order";
        ShipToOptions: Option "Default (Company Address)",Location,"Customer Address","Custom Address";
        LocationCode: Code[10])
    begin
        PurchaseOrder.ShippingOptionWithLocation.SetValue(ShipToOptions);
        if ShipToOptions = ShipToOptions::Location then
            PurchaseOrder."Location Code".SetValue(LocationCode)
        else
            PurchaseOrder."Location Code".SetValue('');
    end;

    local procedure CreateDimensionAndRunChangeGlobalDimension(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.RunChangeGlobalDimensions(Dimension.Code, GeneralLedgerSetup."Global Dimension 2 Code");
    end;

    local procedure CreateAndPostPurchaseInvoice(InvDate: Date; VendorNo: Code[20]; ItemNo: Code[20]; DimensionValueCode: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", InvDate);
        PurchaseHeader.Validate("Document Date", InvDate);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Shortcut Dimension 1 Code", DimensionValueCode);
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCopyAndPostPurchaseInvoiceWithDimensionValueRename(InvDate: Date; VendorNo: Code[20]; ItemNo: Code[20]; DimensionCode: Code[20]; var DimensionValue: Record "Dimension Value"; DocumentNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", InvDate);
        PurchaseHeader.Validate("Document Date", InvDate);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        RunCopyPurchaseDoc(DocumentNo, PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", false, true);

        DimensionValue.Get(DimensionCode, DimensionValue.Code);
        DimensionValue.Rename(DimensionCode, UpperCase(LibraryRandom.RandText(10)));

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure RunCopyPurchaseDoc(
        DocumentNo: Code[20];
        NewPurchaseHeader: Record "Purchase Header";
        DocType: Enum "Purchase Document Type From";
        IncludeHeader: Boolean;
        RecalculateLines: Boolean)
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        Clear(CopyPurchaseDocument);
        CopyPurchaseDocument.SetParameters(DocType, DocumentNo, IncludeHeader, RecalculateLines);
        CopyPurchaseDocument.SetPurchHeader(NewPurchaseHeader);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.RunModal();
    end;

    local procedure VerifyPostedPurchaseInvoiceLineContainsNewDimensionValue(PostedInvoiceNo: Code[20]; ItemNo: Code[20]; DimensionValueCode: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.SetRange("No.", ItemNo);
        PurchInvLine.FindFirst();
        Assert.AreEqual(
            DimensionValueCode,
            PurchInvLine."Shortcut Dimension 1 Code",
            StrSubstNo(DimensionValueCodeErr, DimensionValueCode, PurchInvLine.FieldCaption("Shortcut Dimension 1 Code")));
    end;

    local procedure VerifyPostedGLEntryContainsNewDimensionValue(PostedInvoiceNo: Code[20]; DimensionValueCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", PostedInvoiceNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetFilter("Global Dimension 1 Code", '<>%1', '');
        GLEntry.FindFirst();
        Assert.AreEqual(
            DimensionValueCode,
            GLEntry."Global Dimension 1 Code",
            StrSubstNo(DimensionValueCodeErr, DimensionValueCode, GLEntry.FieldCaption("Global Dimension 1 Code")));
    end;

    local procedure ChangeDimensionOnDocument(var PurchaseHeader: Record "Purchase Header"; DimensionValueCode: Code[20])
    begin
        PurchaseHeader.ValidateShortcutDimCode(1, DimensionValueCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyDimensionOnPurchaseOrder(PurchaseHeader: Record "Purchase Header"; DimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify the dimension on purchase header
        DimensionSetEntry.Get(PurchaseHeader."Dimension Set ID", DimensionCode);
        Assert.AreEqual(
          DimensionCode, DimensionSetEntry."Dimension Code",
          StrSubstNo(DimensionValueCodeErr, DimensionSetEntry.FieldCaption("Dimension Code"), DimensionCode));

        // Verify the dimension on purchase line
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        DimensionSetEntry.Get(PurchaseLine."Dimension Set ID", DimensionCode);
        Assert.AreEqual(
          DimensionCode, DimensionSetEntry."Dimension Code",
          StrSubstNo(DimensionValueCodeErr, DimensionSetEntry.FieldCaption("Dimension Code"), DimensionCode));
    end;

    local procedure CreateShipToAddressWithLocation(var ShiptoAddress: Record "Ship-to Address"; VendorNo: Code[20]; LocationCode: Code[10])
    begin
        LibrarySales.CreateShipToAddress(ShiptoAddress, VendorNo);
        ShiptoAddress.Validate("Location Code", LocationCode);
        ShiptoAddress.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerForPurchHeaderDimUpdate(Question: Text[1024]; var Reply: Boolean)
    begin
        case true of
            Question = UpdateFromHeaderLinesQst:
                Reply := true;
            StrPos(Question, UpdateLineDimQst) <> 0:
                Reply := LibraryVariableStorage.DequeueBoolean();
        end;
    end;

    [ConfirmHandler]
    procedure ChangeDimensionConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ChangeDimensionsQst: Label 'You may have changed a dimension', Locked = true;
    begin
        Reply := Question.Contains(ChangeDimensionsQst);
    end;

    [MessageHandler]
    procedure ChangeLocationMessageHandler(Message: Text[1024])
    begin
        // Just for handle the message.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Just for Handle the Message.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure LocationMessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(LocationChangesMsg, Message, LocationChangeErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCodePageHandler(var StandardVendorPurchaseCodes: Page "Standard Vendor Purchase Codes"; var Response: Action)
    begin
        // Modal Page Handler.
        StandardVendorPurchaseCodes.SetRecord(StandardVendorPurchaseCode);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries.New();
        EditDimensionSetEntries."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        EditDimensionSetEntries.DimensionValueCode.SetValue(LibraryVariableStorage.DequeueText());
        EditDimensionSetEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListModalPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.FILTER.SetFilter("Sell-to Customer No.", LibraryVariableStorage.DequeueText());
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.Filter.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        asserterror ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [ModalPageHandler]
    procedure PostApplicationModalPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;
}

