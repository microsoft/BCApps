codeunit 144017 "ERM Corrective Documents"
{
    // // [FEATURE] [Corrective Documents]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        IsInitialized: Boolean;
        CorrectiveSalesLineErr: Label 'You must change the quantity or the price on line %3 before you can post corrective sales %1 %2.', Comment = '%1 - Document Type %2 - Document No. %3 - Line No.';

    [Test]
    [Scope('OnPrem')]
    procedure VendVATInvoiceDateLessThenPostingDate()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 362383] "Vend. VAT Invoice Date" should not depend on "Posting Date"

        Initialize();
        // [GIVEN] "Posting Date" = "X"
        PurchHeader."Posting Date" := WorkDate();
        // [WHEN] "Vend. VAT Invoice Date" = "X" - 1
        PurchHeader.Validate("Vendor VAT Invoice Date", PurchHeader."Posting Date" - 1);
        // [THEN] "Vend. VAT Invoice Date" = "X" - 1
        Assert.AreEqual(
          PurchHeader."Posting Date" - 1, PurchHeader."Vendor VAT Invoice Date", PurchHeader.FieldCaption("Vendor VAT Invoice Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendVATInvoiceRcvdDateLessThenPostingDate()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 362383] "Vend. VAT Invoice Rcvd Date" should not depend on "Posting Date"

        Initialize();
        // [GIVEN] "Posting Date" = "X"
        PurchHeader."Posting Date" := WorkDate();
        // [WHEN] "Vend. VAT Invoice Rcvd Date" = "X" - 1
        PurchHeader.Validate("Vendor VAT Invoice Rcvd Date", PurchHeader."Posting Date" - 1);
        // [THEN] "Vend. VAT Invoice Rcvd Date" = "X" - 1
        Assert.AreEqual(
          PurchHeader."Posting Date" - 1, PurchHeader."Vendor VAT Invoice Rcvd Date", PurchHeader.FieldCaption("Vendor VAT Invoice Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCorrCreditMemoForInvoiceWithNoQtyChangesAtLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378870] Block posting process of Sales Corr. Credit Memo for Sales Invoice when a correction not change Quantity
        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        InvoiceNo := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] Sales Corrective Credit Memo for Posted Invoice with equal quantities and prices at lines
        CreateSalesCorrectiveCreditMemoForInvoice(SalesHeader, SalesHeader."Sell-to Customer No.", InvoiceNo, 0, WorkDate());

        // [GIVEN] "Quantity (After)" changed on first line
        DecreaseQtyAfterAtFirstLine(SalesHeader, SalesLine);

        // [WHEN] Post Sales Corrective Credit Memo
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error "You must change the quantity or the price on line 20000 before you can post corrective sales Credit Memo .."
        Assert.ExpectedError(StrSubstNo(CorrectiveSalesLineErr, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCorrInvoiceForInvoiceWithNoQtyChangesAtLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378870] Block posting process of Sales Corr. Invoice dor Sales Invoice when a correction not change Quantity
        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        InvoiceNo := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] Sales Corrective Invoice for Posted Invoice with equal quantities and prices at lines
        CreateSalesCorrectiveInvoiceForInvoice(SalesHeader, SalesHeader."Sell-to Customer No.", InvoiceNo, 0, WorkDate());

        // [GIVEN] "Quantity (After)" changed on first line
        IncreaseQtyAfterAtFirstLine(SalesHeader, SalesLine);

        // [WHEN] Post Sales Corrective Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error "You must change the quantity or the price on line 20000 before you can post corrective sales Invoice .."
        Assert.ExpectedError(StrSubstNo(CorrectiveSalesLineErr, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCorrCreditMemoForCrMemoWithNoQtyChangesAtLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CreditMemoNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378870] Block posting process of Sales Corr. Credit Memo For Posted Cr. Memo when a correction not change Quantity
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with two lines
        CreditMemoNo := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [GIVEN] Sales Corrective Credit Memo for Posted Credit Memo with equal quantities and prices at lines
        CreateSalesCorrectiveCreditMemoForCreditMemo(SalesHeader, SalesHeader."Sell-to Customer No.", CreditMemoNo, 0, WorkDate());

        // [GIVEN] "Quantity (After)" changed on first line
        DecreaseQtyAfterAtFirstLine(SalesHeader, SalesLine);

        // [WHEN] Post Sales Corrective Credit Memo
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error "You must change the quantity or the price on line 20000 before you can post corrective sales Credit Memo .."
        Assert.ExpectedError(StrSubstNo(CorrectiveSalesLineErr, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCorrInvoiceForCrMemoWithNoQtyChangesAtLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CreditMemoNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378870] Block posting process of Sales Corr. Invoice For Posted Cr. Memo when a correction not change Quantity
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with two lines
        CreditMemoNo := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [GIVEN] Sales Corrective Invoice for Posted Credit Memo with equal quantities and prices at lines
        CreateSalesCorrectiveInvoiceForCreditMemo(SalesHeader, SalesHeader."Sell-to Customer No.", CreditMemoNo, 0, WorkDate());

        // [GIVEN] "Quantity (After)" changed on first line
        IncreaseQtyAfterAtFirstLine(SalesHeader, SalesLine);

        // [WHEN] Post Sales Corrective Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error "You must change the quantity or the price on line 20000 before you can post corrective sales Invoice .."
        Assert.ExpectedError(StrSubstNo(CorrectiveSalesLineErr, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCorrCreditMemoForInvoiceWithNoPriceChangesAtLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378870] Block posting process of Sales Corr. Credit Memo for Sales Invoice when a correction not change Unit Price
        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        InvoiceNo := PostSalesDocumentWithItemCharge(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] Sales Corrective Credit Memo for Posted Invoice with equal quantities and prices at lines
        CreateSalesCorrectiveCreditMemoForInvoice(SalesHeader, SalesHeader."Sell-to Customer No.", InvoiceNo, 1, WorkDate());

        // [GIVEN] "Unit Price (After)" changed on first line
        DecreasePriceAfterAtFirstLine(SalesHeader, SalesLine);

        // [WHEN] Post Sales Corrective Credit Memo
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error "You must change the quantity or the price on line 20000 before you can post corrective sales Credit Memo .."
        Assert.ExpectedError(StrSubstNo(CorrectiveSalesLineErr, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCorrInvoiceForInvoiceWithNoPriceChangesAtLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378870] Block posting process of Sales Corr. Invoice dor Sales Invoice when a correction not change Unit Price
        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        InvoiceNo := PostSalesDocumentWithItemCharge(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] Sales Corrective Invoice for Posted Invoice with equal quantities and prices at lines
        CreateSalesCorrectiveInvoiceForInvoice(SalesHeader, SalesHeader."Sell-to Customer No.", InvoiceNo, 1, WorkDate());

        // [GIVEN] "Unit Price (After)" changed on first line
        IncreasePriceAfterAtFirstLine(SalesHeader, SalesLine);

        // [WHEN] Post Sales Corrective Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error "You must change the quantity or the price on line 20000 before you can post corrective sales Invoice .."
        Assert.ExpectedError(StrSubstNo(CorrectiveSalesLineErr, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCorrCreditMemoForCrMemoWithNoPriceChangesAtLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CreditMemoNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378870] Block posting process of Sales Corr. Credit Memo For Posted Cr. Memo when a correction not change Unit Price
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with two lines
        CreditMemoNo := PostSalesDocumentWithItemCharge(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [GIVEN] Sales Corrective Credit Memo for Posted Credit Memo with equal quantities and prices at lines
        CreateSalesCorrectiveCreditMemoForCreditMemo(SalesHeader, SalesHeader."Sell-to Customer No.", CreditMemoNo, 1, WorkDate());

        // [GIVEN] "Unit Price (After)" changed on first line
        DecreasePriceAfterAtFirstLine(SalesHeader, SalesLine);

        // [WHEN] Post Sales Corrective Credit Memo
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error "You must change the quantity or the price on line 20000 before you can post corrective sales Credit Memo .."
        Assert.ExpectedError(StrSubstNo(CorrectiveSalesLineErr, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCorrInvoiceForCrMemoWithNoPriceChangesAtLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CreditMemoNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378870] Block posting process of Sales Corr. Invoice For Posted Cr. Memo when a correction not change Unit Price
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with two lines
        CreditMemoNo := PostSalesDocumentWithItemCharge(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [GIVEN] Sales Corrective Invoice for Posted Credit Memo with equal quantities and prices at lines
        CreateSalesCorrectiveInvoiceForCreditMemo(SalesHeader, SalesHeader."Sell-to Customer No.", CreditMemoNo, 1, WorkDate());

        // [GIVEN] "Unit Price (After)" changed on first line
        IncreasePriceAfterAtFirstLine(SalesHeader, SalesLine);

        // [WHEN] Post Sales Corrective Invoice
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Error "You must change the quantity or the price on line 20000 before you can post corrective sales Invoice .."
        Assert.ExpectedError(StrSubstNo(CorrectiveSalesLineErr, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrInvoiceGetCorrDocLinesWhenNotBaseUoM()
    var
        SalesHeader: Record "Sales Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PostedDocNo: Code[20];
        QtyUoM: Decimal;
        QtyBase: Decimal;
    begin
        // [SCENARIO 292487] When Corrective Invoice Line is created for Posted Sales Invoice Line via codeunit Corrective Document Mgt.,
        // [SCENARIO 292487] then UoM is taken from Posted Sales Invoice Line
        Initialize();
        QtyUoM := LibraryRandom.RandInt(10);

        // [GIVEN] Item had Unit of Measure (Base) = PCS, Sales Unit of Measure = BOX, BOX = 2 PCS
        LibraryInventory.CreateItemUnitOfMeasureCode(
          ItemUnitOfMeasure, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Posted Sales Invoice with Qty = 3, Unit of Measure = BOX
        CreateSalesInvoiceWithQtyAndUoM(SalesHeader, QtyBase, ItemUnitOfMeasure."Item No.", ItemUnitOfMeasure.Code, QtyUoM);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Corrective Sales Invoice for Posted Sales Invoice
        CreateSalesCorrectiveInvoiceForInvoice(SalesHeader, SalesHeader."Sell-to Customer No.", PostedDocNo, 0, SalesHeader."Posting Date");

        // [WHEN] Run CreateSalesLinesFromPstdInv in codeunit Corrective Document Mgt.
        // done in CreateSalesCorrectiveLinesFromInvoice

        // [THEN] Sales Line has Unit of Measure Code = BOX, Qty. per Unit of Measure = 2, Quantity (Base) = 6, Quantity (Before) = Quantity (After) = 3
        VerifySalesLineQtyAndUoM(
          SalesHeader."Document Type", SalesHeader."No.", ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure", QtyBase,
          QtyUoM, QtyUoM);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrCrMemoGetCorrDocLinesWhenNotBaseUoM()
    var
        SalesHeader: Record "Sales Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PostedDocNo: Code[20];
        QtyUoM: Decimal;
        QtyBase: Decimal;
    begin
        // [SCENARIO 292487] When Corrective Credit Memo Line is created for Posted Sales Invoice Line via codeunit Corrective Document Mgt.,
        // [SCENARIO 292487] then UoM is taken from Posted Sales Invoice Line
        Initialize();
        QtyUoM := LibraryRandom.RandInt(10);

        // [GIVEN] Item had Unit of Measure (Base) = PCS, Sales Unit of Measure = BOX, BOX = 2 PCS
        LibraryInventory.CreateItemUnitOfMeasureCode(
          ItemUnitOfMeasure, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Posted Sales Invoice with Qty = 3, Unit of Measure = BOX
        CreateSalesInvoiceWithQtyAndUoM(SalesHeader, QtyBase, ItemUnitOfMeasure."Item No.", ItemUnitOfMeasure.Code, QtyUoM);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Corrective Credit Memo for Posted Sales Invoice
        CreateSalesCorrectiveCreditMemoForInvoice(
          SalesHeader, SalesHeader."Sell-to Customer No.", PostedDocNo, 0, SalesHeader."Posting Date");

        // [WHEN] Run CreateSalesLinesFromPstdInv in codeunit Corrective Document Mgt.
        // done in CreateSalesCorrectiveLinesFromInvoice

        // [THEN] Sales Line has Unit of Measure Code = BOX, Qty. per Unit of Measure = 2, Quantity (Base) = 6, Quantity (Before) = Quantity (After) = 3
        VerifySalesLineQtyAndUoM(
          SalesHeader."Document Type", SalesHeader."No.", ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure", QtyBase,
          QtyUoM, QtyUoM);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrCrMemoGetCorrDocLinesFromCorrInvoiceWhenRedStornoIsDisabled()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PostedDocNo: Code[20];
        CorrectedQtyUoM: Decimal;
        QtyBase: Decimal;
    begin
        // [SCENARIO 292487] When Corrective Credit Memo Line is created for Posted Corrective Sales Invoice Line via codeunit Corrective Document Mgt.
        // [SCENARIO 292487] with Red Storno disabled then Sales Line has Quantity (After) = Quantity (Before) = Posted Corrective Sales Invoice Line Quantity (After)
        Initialize();

        // [GIVEN] Red Storno was enabled in Inventory Setup
        UpdateInventorySetupRedStorno(false);

        // [GIVEN] Item had Unit of Measure (Base) = PCS, Sales Unit of Measure = BOX, BOX = 2 PCS
        LibraryInventory.CreateItemUnitOfMeasureCode(
          ItemUnitOfMeasure, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Posted Sales Invoice with Qty = 3, Unit of Measure = BOX
        CreateSalesInvoiceWithQtyAndUoM(
          SalesHeader, QtyBase, ItemUnitOfMeasure."Item No.", ItemUnitOfMeasure.Code, LibraryRandom.RandInt(10));
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Corrective Sales Invoice with Qty = 5
        CreateSalesCorrectiveInvoiceForInvoice(SalesHeader, SalesHeader."Sell-to Customer No.", PostedDocNo, 0, SalesHeader."Posting Date");
        IncreaseQtyAfterAtFirstLine(SalesHeader, SalesLine);
        CorrectedQtyUoM := SalesLine."Quantity (After)";
        QtyBase += SalesLine."Quantity (Base)";
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Corrective Sales Credit Memo for Posted Corrective Sales Invoice
        CreateSalesCorrectiveCreditMemoForInvoice(
          SalesHeader, SalesHeader."Sell-to Customer No.", PostedDocNo, 0, SalesHeader."Posting Date");

        // [WHEN] Run CreateSalesLinesFromPstdInv in codeunit Corrective Document Mgt.
        // done in CreateSalesCorrectiveLinesFromInvoice

        // [THEN] Sales Line has Quantity (Before) = Quantity (After) = 5, Unit of Measure = BOX
        // [THEN] Sales Line Quantity (Base) = 10 = 5 * 2
        VerifySalesLineQtyAndUoM(
          SalesHeader."Document Type", SalesHeader."No.", ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure", QtyBase,
          CorrectedQtyUoM, CorrectedQtyUoM);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrCrMemoGetCorrDocLinesFromCorrInvoiceWhenRedStornoIsEnabled()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PostedDocNo: Code[20];
        InitialQtyUoM: Decimal;
        CorrectedQtyUoM: Decimal;
        QtyBase: Decimal;
    begin
        // [SCENARIO 292487] When Corrective Credit Memo Line is created for Posted Corrective Sales Invoice Line via codeunit Corrective Document Mgt.
        // [SCENARIO 292487] with Red Storno disabled then Sales Line has Quantity (After) = Quantity (Before) - Posted Corrective Sales Invoice Line Quantity (After)
        Initialize();
        InitialQtyUoM := LibraryRandom.RandInt(10);

        // [GIVEN] Red Storno was enabled in Inventory Setup
        UpdateInventorySetupRedStorno(true);

        // [GIVEN] Item had Unit of Measure (Base) = PCS, Sales Unit of Measure = BOX, BOX = 2 PCS
        LibraryInventory.CreateItemUnitOfMeasureCode(
          ItemUnitOfMeasure, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 10));

        // [GIVEN] Posted Sales Invoice with Qty = 3, Unit of Measure = BOX
        CreateSalesInvoiceWithQtyAndUoM(SalesHeader, QtyBase, ItemUnitOfMeasure."Item No.", ItemUnitOfMeasure.Code, InitialQtyUoM);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Corrective Sales Invoice with Qty = 5, Quantity (Base) = 4 = (5 - 3) * 2
        CreateSalesCorrectiveInvoiceForInvoice(SalesHeader, SalesHeader."Sell-to Customer No.", PostedDocNo, 0, SalesHeader."Posting Date");
        IncreaseQtyAfterAtFirstLine(SalesHeader, SalesLine);
        CorrectedQtyUoM := SalesLine."Quantity (After)";
        QtyBase := SalesLine."Quantity (Base)";
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Corrective Sales Credit Memo for Posted Corrective Sales Invoice
        CreateSalesCorrectiveCreditMemoForInvoice(
          SalesHeader, SalesHeader."Sell-to Customer No.", PostedDocNo, 0, SalesHeader."Posting Date");

        // [WHEN] Run CreateSalesLinesFromPstdInv in codeunit Corrective Document Mgt.
        // done in CreateSalesCorrectiveLinesFromInvoice

        // [THEN] Sales Line has Quantity (Before) = 5, Quantity (After) = 3, Unit of Measure = BOX
        // [THEN] Sales Line Quantity (Base) = 4 = (5 - 3) * 2
        VerifySalesLineQtyAndUoM(
          SalesHeader."Document Type", SalesHeader."No.", ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure", QtyBase,
          CorrectedQtyUoM, InitialQtyUoM);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure UpdateInventorySetupRedStorno(EnableRedStorno: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Enable Red Storno" := EnableRedStorno;
        InventorySetup.Modify();
    end;

    local procedure CreateSalesInvoiceWithQtyAndUoM(var SalesHeader: Record "Sales Header"; var QtyBase: Decimal; ItemNo: Code[20]; UoMCode: Code[10]; QtyUoM: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, QtyUoM);
        SalesLine.Validate("Unit of Measure Code", UoMCode);
        SalesLine.Modify(true);
        QtyBase := SalesLine."Quantity (Base)";
    end;

    local procedure CreateSalesCorrectiveCreditMemoForInvoice(var CorrSalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CorrectedDocNo: Code[20]; CorrectionType: Option Quantity,"Unit Price"; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(CorrSalesHeader, CorrSalesHeader."Document Type"::"Credit Memo", CustomerNo);
        UpdateCorrSalesHeader(CorrSalesHeader, CorrSalesHeader."Corrected Doc. Type"::Invoice, CorrectedDocNo, PostingDate);

        CreateSalesCorrectiveLinesFromInvoice(CorrSalesHeader, CorrectedDocNo, CorrectionType);
    end;

    local procedure CreateSalesCorrectiveInvoiceForInvoice(var CorrSalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CorrectedDocNo: Code[20]; CorrectionType: Option Quantity,"Unit Price"; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(CorrSalesHeader, CorrSalesHeader."Document Type"::Invoice, CustomerNo);
        UpdateCorrSalesHeader(CorrSalesHeader, CorrSalesHeader."Corrected Doc. Type"::Invoice, CorrectedDocNo, PostingDate);

        CreateSalesCorrectiveLinesFromInvoice(CorrSalesHeader, CorrectedDocNo, CorrectionType);
    end;

    local procedure CreateSalesCorrectiveCreditMemoForCreditMemo(var CorrSalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CorrectedDocNo: Code[20]; CorrectionType: Option Quantity,"Unit Price"; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(CorrSalesHeader, CorrSalesHeader."Document Type"::"Credit Memo", CustomerNo);
        UpdateCorrSalesHeader(CorrSalesHeader, CorrSalesHeader."Corrected Doc. Type"::"Credit Memo", CorrectedDocNo, PostingDate);

        CreateSalesCorrectiveLinesFromCreditMemo(CorrSalesHeader, CorrectedDocNo, CorrectionType);
    end;

    local procedure CreateSalesCorrectiveInvoiceForCreditMemo(var CorrSalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CorrectedDocNo: Code[20]; CorrectionType: Option Quantity,"Unit Price"; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(CorrSalesHeader, CorrSalesHeader."Document Type"::Invoice, CustomerNo);
        UpdateCorrSalesHeader(CorrSalesHeader, CorrSalesHeader."Corrected Doc. Type"::"Credit Memo", CorrectedDocNo, PostingDate);

        CreateSalesCorrectiveLinesFromCreditMemo(CorrSalesHeader, CorrectedDocNo, CorrectionType);
    end;

    local procedure UpdateSalesCorrDocChargeForItem(ItemNo: Code[20])
    var
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        ItemCharge: Record "Item Charge";
    begin
        Item.Get(ItemNo);
        InventoryPostingGroup.Get(Item."Inventory Posting Group");
        LibraryInventory.CreateItemCharge(ItemCharge);
        InventoryPostingGroup.Validate("Sales Corr. Doc. Charge (Item)", ItemCharge."No.");
        InventoryPostingGroup.Modify(true);
    end;

    local procedure IncreasePriceAfterAtFirstLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit Price (After)", SalesLine."Unit Price (Before)" * 2);
        SalesLine.Modify(true);
        SalesLine.Next();
    end;

    local procedure DecreasePriceAfterAtFirstLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit Price (After)", SalesLine."Unit Price (Before)" / 2);
        SalesLine.Modify(true);
        SalesLine.Next();
    end;

    local procedure IncreaseQtyAfterAtFirstLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Quantity (After)", SalesLine."Quantity (Before)" + 1);
        SalesLine.Modify(true);
        SalesLine.Next();
    end;

    local procedure DecreaseQtyAfterAtFirstLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Quantity (After)", SalesLine."Quantity (Before)" - 1);
        SalesLine.Modify(true);
        SalesLine.Next();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType,
          LibrarySales.CreateCustomerNo(), '', LibraryRandom.RandInt(10), '', WorkDate());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandInt(10));
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostSalesDocumentWithItemCharge(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType,
          LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        UpdateSalesCorrDocChargeForItem(SalesLine."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandInt(10));
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure UpdateCorrSalesHeader(var SalesHeader: Record "Sales Header"; CorrectedDocType: Option; CorrectedDocNo: Code[20]; PostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Corrective Document", true);
        SalesHeader.Validate("Corrective Doc. Type", SalesHeader."Corrective Doc. Type"::Correction);
        SalesHeader.Validate("Corrected Doc. Type", CorrectedDocType);
        SalesHeader.Validate("Corrected Doc. No.", CorrectedDocNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesCorrectiveLinesFromInvoice(SalesHeader: Record "Sales Header"; CorrectedDocNo: Code[20]; CorrectionType: Option Quantity,"Unit Price")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        CorrectiveDocumentMgt: Codeunit "Corrective Document Mgt.";
    begin
        CorrectiveDocumentMgt.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        CorrectiveDocumentMgt.SetCorrectionType(CorrectionType);
        SalesInvoiceLine.SetRange("Document No.", CorrectedDocNo);
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        CorrectiveDocumentMgt.CreateSalesLinesFromPstdInv(SalesInvoiceLine);
    end;

    local procedure CreateSalesCorrectiveLinesFromCreditMemo(SalesHeader: Record "Sales Header"; CorrectedDocNo: Code[20]; CorrectionType: Option Quantity,"Unit Price")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CorrectiveDocumentMgt: Codeunit "Corrective Document Mgt.";
    begin
        CorrectiveDocumentMgt.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        CorrectiveDocumentMgt.SetCorrectionType(CorrectionType);
        SalesCrMemoLine.SetRange("Document No.", CorrectedDocNo);
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        CorrectiveDocumentMgt.CreateSalesLinesFromPstdCrMemo(SalesCrMemoLine);
    end;

    local procedure VerifySalesLineQtyAndUoM(DocType: Enum "Sales Document Type"; DocNo: Code[20]; UoMCode: Code[10]; QtyPerUoM: Decimal; QtyBase: Decimal; QtyBefore: Decimal; QtyAfter: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.FindFirst();
        SalesLine.TestField("Unit of Measure Code", UoMCode);
        SalesLine.TestField("Qty. per Unit of Measure", QtyPerUoM);
        SalesLine.TestField("Quantity (Base)", QtyBase);
        SalesLine.TestField("Quantity (Before)", QtyBefore);
        SalesLine.TestField("Quantity (After)", QtyAfter);
    end;
}

