codeunit 144006 "ERM Item Storno"
{
    // // [FEATURE] [Red Storno]
    // PS 24221

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        isInitialized: Boolean;
        ValuesAreNotEqualErr: Label 'Values are not equal in table %1, field %2';
        ApplyEntryNoShortExpectedErr: Label '%1 must have a value in Item Journal Line:';
        IncorrectExpectedMessageErr: Label 'Incorrect Expected message.';

    [Test]
    [Scope('OnPrem')]
    procedure ItemJnlNegativeAdjRedStorno()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Correction for Negative adjustment as Red Storno
        CorrectionForItemJournal(
          ItemJnlLine."Entry Type"::"Negative Adjmt.", ItemJnlLine."Entry Type"::"Negative Adjmt.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJnlNegativeAdjReverse()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Correction for Negative adjustment as Reverse
        CorrectionForItemJournal(
          ItemJnlLine."Entry Type"::"Negative Adjmt.", ItemJnlLine."Entry Type"::"Positive Adjmt.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJnlPositiveAdjRedStorno()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Correction for Positive adjustment as Red Storno
        CorrectionForItemJournal(
          ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemJnlLine."Entry Type"::"Positive Adjmt.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJnlPositiveAdjReverse()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Correction for Positive adjustment as Reverse
        CorrectionForItemJournal(
          ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemJnlLine."Entry Type"::"Negative Adjmt.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyErrorOnItemJnl()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Error on posting Red Storno with "Applies-from Entry" = 0 in Item Journal Line
        Initialize();

        LibraryInventory.CreateItem(Item);
        asserterror CreateAndPostItemJournalLine(
            ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", WorkDate(),
            LibraryRandom.RandDec(10, 2), 0, 0, true);

        Assert.IsTrue(
          StrPos(GetLastErrorText, StrSubstNo(ApplyEntryNoShortExpectedErr, ItemJournalLine.FieldCaption("Applies-from Entry"))) > 0,
          IncorrectExpectedMessageErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CorrShipmentWithShipmentRedStorno()
    var
        InvtDocHeader: Record "Invt. Document Header";
    begin
        // Correction for Item Shipment as Red Storno
        CorrectionForInvtDocuments(InvtDocHeader."Document Type"::Shipment, InvtDocHeader."Document Type"::Shipment, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CorrShipmentWithReceiptReverse()
    var
        InvtDocHeader: Record "Invt. Document Header";
    begin
        // Correction for Item Shipment as Reverse
        CorrectionForInvtDocuments(InvtDocHeader."Document Type"::Shipment, InvtDocHeader."Document Type"::Receipt, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CorrReceiptWithReceiptRedStorno()
    var
        InvtDocHeader: Record "Invt. Document Header";
    begin
        // Correction for Item Receipt as Red Storno
        CorrectionForInvtDocuments(InvtDocHeader."Document Type"::Receipt, InvtDocHeader."Document Type"::Receipt, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CorrReceiptWithShipmentReverse()
    var
        InvtDocHeader: Record "Invt. Document Header";
    begin
        // Correction for Item Receipt as Reverse
        CorrectionForInvtDocuments(InvtDocHeader."Document Type"::Receipt, InvtDocHeader."Document Type"::Shipment, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyErrorForItemDocument()
    var
        Item: Record Item;
        InvtDocHeader: Record "Invt. Document Header";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Error on posting Red Storno with "Applies-from Entry" = 0 in Item Documents
        Initialize();
        LibraryInventory.CreateItem(Item);

        asserterror CreateAndPostInvtDocument(
            InvtDocHeader."Document Type"::Shipment, InvtDocHeader."Document Type"::Shipment, Item."No.", WorkDate(),
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2), 0, true);

        Assert.ExpectedTestFieldError(ItemJournalLine.FieldCaption("Applies-from Entry"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrSalesWithCrMemoRedStorno()
    begin
        // Correction for Sales Order as Red Storno
        CorrectionForSalesDocument(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrSalesWithCrMemoReverse()
    begin
        // Correction for Sales Order as Reverse
        CorrectionForSalesDocument(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyErrorForSalesDocument()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        InvoiceNo: Code[20];
    begin
        // Error on posting Red Storno with "Applies-from Entry" = 0 in Sales Documents
        Initialize();

        LibraryInventory.CreateItem(Item);
        InvoiceNo :=
          CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, Item."No.", WorkDate(), LibraryRandom.RandDec(10, 2));

        asserterror CreateAndPostCorrSalesCrMemo(InvoiceNo, WorkDate(), 0, true);

        Assert.ExpectedTestFieldError(ItemJournalLine.FieldCaption("Applies-from Entry"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrPurchaseWithCrMemoRedStorno()
    begin
        // Correction for Purchase Order as Red Storno
        CorrectionForPurchDocument(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrPurchaseWithCrMemoReverse()
    begin
        // Correction for Purchase Order as Reverse
        CorrectionForPurchDocument(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyErrorForPurchDocument()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemJournalLine: Record "Item Journal Line";
        InvoiceNo: Code[20];
    begin
        // Error on posting Red Storno with "Applies-from Entry" = 0 in Purchase Documents
        Initialize();

        LibraryInventory.CreateItem(Item);
        InvoiceNo :=
          CreateAndPostPurchDocument(PurchaseHeader."Document Type"::Invoice, Item."No.", WorkDate(), LibraryRandom.RandDec(10, 2));

        asserterror CreateAndPostCorrPurchCrMemo(InvoiceNo, WorkDate(), 0, true);

        Assert.ExpectedTestFieldError(ItemJournalLine.FieldCaption("Applies-to Entry"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeRevaluationRedStorno()
    begin
        // Post Revaluation as Red Storno
        CorrectionForRevaluation(-1, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeRevaluationReverse()
    begin
        // Post Revaluation as Reverse
        CorrectionForRevaluation(-1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyErrorForPositiveRevaluation()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify error for Red Storno when Unit Cost (Revalued) > Unit Cost (Calculated).
        asserterror CorrectionForRevaluation(1, true);

        Assert.ExpectedTestFieldError(ItemJournalLine.FieldCaption("Red Storno"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReclassificationRedStorno()
    begin
        CorrectionForReclassification(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReclassificationReverse()
    begin
        CorrectionForReclassification(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FAAcquisitionRedStorno()
    var
        AsStorno: Boolean;
    begin
        // Correction for FA acquisiton as Red Storno
        AsStorno := true;
        CorrectionForFA(AsStorno);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FAAcquisitionReverse()
    var
        AsStorno: Boolean;
    begin
        // Correction for FA acquisiton as Reverse
        AsStorno := false;
        CorrectionForFA(AsStorno);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRevisionCrMemoAfterInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
        ItemNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Correction]
        // [SCENARIO 377833] Corrective (Revision) Sales Credit Memo posting after Invoice in case of "Enable Red Storno" = TRUE
        Initialize();

        // [GIVEN] Inventory Setup "Enable Red Storno" = TRUE.
        // [GIVEN] Posted Sales Invoice "I".
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), WorkDate(), false);
        for i := 1 to ArrayLen(ItemNo) do begin
            ItemNo[i] := CreateItemNo();
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo[i], LibraryRandom.RandIntInRange(100, 200));
        end;
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [GIVEN] Create Corrective Sales Credit Memo with "Corrective Doc. Type" = Revision. Use "Get Corr. Doc. Lines" from posted invoice "I".
        CreateRevSalesCrMemoAfterInvoice(SalesHeader, InvoiceNo);

        // [WHEN] Post Sales Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Credit Memo is posted and Value Entry has "Red Storno" = TRUE.
        VerifyValueEntryRedStorno(ItemNo[1], ValueEntry."Document Type"::"Sales Credit Memo", CrMemoNo, true);
        VerifyValueEntryRedStorno(ItemNo[2], ValueEntry."Document Type"::"Sales Credit Memo", CrMemoNo, true);
    end;

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        UpdateGLSetup();
        UpdateInventorySetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure CorrectionForInvtDocuments(DocType: Enum "Invt. Doc. Document Type"; CorrDocType: Enum "Invt. Doc. Document Type"; RedStorno: Boolean)
    var
        ItemNo: Code[20];
        CorrEntryType: Option;
        Quantity: Decimal;
        UnitAmt: Decimal;
        ExpectedSign: Integer;
        Sorting: Boolean;
    begin
        Initialize();

        ItemNo := CreateItemWithStartingData(Quantity, UnitAmt);
        CreateAndPostInvtDocument(DocType, "Invt. Doc. Document Type"::Receipt, ItemNo, WorkDate(), Quantity, UnitAmt, 0, false);

        CreateAndPostInvtDocument(CorrDocType, DocType, ItemNo, WorkDate(), Quantity, 0,
          FindLastItemLedgerEntryNo(ItemNo, WorkDate()), RedStorno);

        CalcTypeAndSignForInvtDoc(CorrEntryType, ExpectedSign, Sorting, DocType, CorrDocType);

        VerifyValueEntries(ItemNo, WorkDate(), ExpectedSign * Round(UnitAmt * Quantity), RedStorno);
        VerifyItemLedgerEntries(ItemNo, WorkDate(), CorrEntryType, ExpectedSign * Quantity);

        VerifyGLEntries('', GetLastCostDocumentNo(), CalcExpectedSign(RedStorno) * Round(UnitAmt * Quantity), Sorting);
    end;

    local procedure CorrectionForItemJournal(EntryType: Enum "Item Ledger Entry Type"; CorrEntryType: Enum "Item Ledger Entry Type"; RedStorno: Boolean)
    var
        ItemNo: Code[20];
        Quantity: Decimal;
        CostAmt: Decimal;
        CorrSign: Integer;
        ExpectedSign: Integer;
        Sorting: Boolean;
    begin
        Initialize();

        ItemNo := CreateItemWithStartingData(Quantity, CostAmt);

        CreateAndPostItemJournalLine(
          EntryType, "Item Ledger Entry Type"::" ", ItemNo, WorkDate(), Quantity, CostAmt, 0, false);

        CalcSign(CorrSign, ExpectedSign, EntryType, RedStorno);

        CreateAndPostItemJournalLine(
          CorrEntryType, EntryType, ItemNo, WorkDate(), CorrSign * Quantity, 0,
          FindLastItemLedgerEntryNo(ItemNo, WorkDate()), RedStorno);

        VerifyValueEntries(ItemNo, WorkDate(), ExpectedSign * CostAmt, RedStorno);
        VerifyItemLedgerEntries(ItemNo, WorkDate(), CorrEntryType.AsInteger(), ExpectedSign * Quantity);

        Sorting := (ExpectedSign = -1) xor RedStorno;
        VerifyGLEntries('', GetLastCostDocumentNo(), CorrSign * CostAmt, Sorting);
    end;

    local procedure CorrectionForSalesDocument(RedStorno: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
        Quantity: Decimal;
        CostAmt: Decimal;
    begin
        Initialize();

        ItemNo := CreateItemWithStartingData(Quantity, CostAmt);
        InvoiceNo := CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, ItemNo, WorkDate(), Quantity);
        CostAmt := -GetCostAmountActual(FindLastItemLedgerEntryNo(ItemNo, WorkDate()));

        CrMemoNo := CreateAndPostCorrSalesCrMemo(InvoiceNo, WorkDate(), FindLastItemLedgerEntryNo(ItemNo, WorkDate()), RedStorno);

        VerifyValueEntries(ItemNo, WorkDate(), CostAmt, RedStorno);
        VerifyGLEntries('', CrMemoNo, CalcExpectedSign(RedStorno) * CostAmt, RedStorno);
    end;

    local procedure CorrectionForPurchDocument(RedStorno: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
        Quantity: Decimal;
        CostAmt: Decimal;
    begin
        Initialize();

        ItemNo := CreateItemWithStartingData(Quantity, CostAmt);
        InvoiceNo := CreateAndPostPurchDocument(PurchaseHeader."Document Type"::Invoice, ItemNo, WorkDate(), Quantity);
        CostAmt := GetCostAmountActual(FindLastItemLedgerEntryNo(ItemNo, WorkDate()));

        CrMemoNo := CreateAndPostCorrPurchCrMemo(InvoiceNo, WorkDate(), FindLastItemLedgerEntryNo(ItemNo, WorkDate()), RedStorno);

        VerifyValueEntries(ItemNo, WorkDate(), -CostAmt, RedStorno);
        VerifyGLEntries('', CrMemoNo, CalcExpectedSign(RedStorno) * CostAmt, not RedStorno);
    end;

    local procedure CorrectionForRevaluation(IncreaseIndex: Integer; RedStorno: Boolean)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        CostAmt: Decimal;
        RevalAmt: Decimal;
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        CostAmt := LibraryRandom.RandDecInRange(100, 200, 2);
        RevalAmt := CostAmt + IncreaseIndex * LibraryRandom.RandDec(100, 2);

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", "Item Ledger Entry Type"::" ", Item."No.", WorkDate(),
          LibraryRandom.RandDec(10, 2), CostAmt, 0, false);

        CreateAndPostRevaluationItemJnlLine(Item."No.", WorkDate(), RevalAmt, RedStorno);

        VerifyValueEntries(Item."No.", WorkDate(), -(CostAmt - RevalAmt), RedStorno);
        VerifyGLEntries('', GetLastCostDocumentNo(), CalcExpectedSign(RedStorno) * (CostAmt - RevalAmt), not RedStorno);
    end;

    local procedure CorrectionForReclassification(RedStorno: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
        Quantity: Decimal;
        CostAmt: Decimal;
    begin
        Initialize();

        ItemNo := CreateItemWithStartingData(Quantity, CostAmt);

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", "Item Ledger Entry Type"::" ", ItemNo, WorkDate(), Quantity, CostAmt, 0, false);

        CreateAndPostReclassItemJnlLine(ItemNo, WorkDate(), Quantity, FindLastItemLedgerEntryNo(ItemNo, WorkDate()), RedStorno);

        VerifyValueEntries(ItemNo, WorkDate(), CostAmt, RedStorno);
        VerifyItemLedgerEntries(ItemNo, WorkDate(), ItemLedgerEntry."Entry Type"::Transfer.AsInteger(), Quantity);

        VerifyGLEntries(GetInventoryAdjAccountNo(ItemNo), GetLastCostDocumentNo(), CalcExpectedSign(RedStorno) * CostAmt, not RedStorno);
        VerifyGLEntries(GetInventoryAccountNoFilter(ItemNo), GetLastCostDocumentNo(), CalcExpectedSign(RedStorno) * CostAmt, RedStorno);
    end;

    local procedure CorrectionForFA(RedStorno: Boolean)
    var
        CorrectionNo: Code[20];
        FANo: Code[20];
        DeprBookCode: Code[10];
        CostAmt: Decimal;
    begin
        Initialize();

        DeprBookCode := SetStornoOnDefaultDeprBook(RedStorno);
        CostAmt := LibraryRandom.RandDecInRange(100, 200, 2);
        FANo := CreateAndPostFAAcquisition(DeprBookCode, CostAmt);
        CancelLastFALedgerEntry(FANo, DeprBookCode);
        CorrectionNo := PostCancelledJournalLine(FANo, DeprBookCode);

        VerifyGLEntries('', CorrectionNo, CalcExpectedSign(RedStorno) * CostAmt, RedStorno);
    end;

    local procedure CreateInvPostingSetup(InvPostingGroupCode: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        if InventoryPostingSetup.Get('', InvPostingGroupCode) then
            exit;
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, '', InvPostingGroupCode);
        LibraryERM.FindGLAccount(GLAccount);
        InventoryPostingSetup.Validate("Inventory Account", GLAccount."No.");
        InventoryPostingSetup.Modify(true);
    end;

    local procedure CreateItemWithStartingData(var Quantity: Decimal; var Amount: Decimal): Code[20]
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateInvPostingSetup(Item."Inventory Posting Group");

        CreateAndPostItemJournalLine(
          ItemJnlLine."Entry Type"::"Positive Adjmt.", "Item Ledger Entry Type"::" ", Item."No.", CalcDate('<-1D>', WorkDate()),
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2), 0, false);

        Quantity := LibraryRandom.RandDec(10, 2);
        Amount := LibraryRandom.RandDec(100, 2);

        exit(Item."No.");
    end;

    local procedure CreateAndPostItemJournalLine(EntryType: Enum "Item Ledger Entry Type"; CorrectedEntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; PostingDate: Date; Quantity: Decimal; CostAmt: Decimal; ApplyEntryNo: Integer; RedStorno: Boolean)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        InitItemJournalLine(ItemJnlLine, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", EntryType, ItemNo, Quantity);

        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Validate(Amount, CostAmt);
        ItemJnlLine.Validate("Red Storno", RedStorno);
        if ApplyEntryNo <> 0 then
            case CorrectedEntryType of
                ItemJnlLine."Entry Type"::"Positive Adjmt.":
                    ItemJnlLine.Validate("Applies-to Entry", ApplyEntryNo);
                ItemJnlLine."Entry Type"::"Negative Adjmt.":
                    ItemJnlLine.Validate("Applies-from Entry", ApplyEntryNo);
            end;
        ItemJnlLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure CreateAndPostInvtDocument(DocumentType: Enum "Invt. Doc. Document Type"; CorrectedDocType: Enum "Invt. Doc. Document Type"; ItemNo: Code[20]; PostingDate: Date; Qty: Decimal; UnitCost: Decimal; ApplyEntryNo: Integer; Correction: Boolean)
    var
        InvtDocumentHeader: Record "Invt. Document Header";
    begin
        CreateInvtDocumentHeader(InvtDocumentHeader, DocumentType, PostingDate, Correction);
        CreateInvtDocumentLine(InvtDocumentHeader, ItemNo, Qty, UnitCost, CorrectedDocType, ApplyEntryNo);

        CODEUNIT.Run(CODEUNIT::"Invt. Doc.-Post (Yes/No)", InvtDocumentHeader);
    end;

    local procedure CreateAndPostSalesDocument(DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; PostingDate: Date; Qty: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesHeader, DocumentType, Customer."No.", PostingDate, false);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchDocument(DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; PostingDate: Date; Qty: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchDocument(PurchaseHeader, DocumentType, PostingDate, Vendor."No.", false);
        CreatePurchLine(PurchaseHeader, ItemNo, Qty);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostRevaluationItemJnlLine(ItemNo: Code[20]; PostingDate: Date; RevalCost: Decimal; RedStorno: Boolean)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        Item: Record Item;
    begin
        InitItemJournalLine(ItemJnlLine, ItemJournalTemplate.Type::Revaluation);
        Item.SetRange("No.", ItemNo);
        LibraryCosting.CalculateInventoryValue(
          ItemJnlLine, Item, PostingDate, LibraryUtility.GenerateGUID(),
          "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", false);

        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Red Storno", RedStorno);
        ItemJnlLine.Validate("Inventory Value (Revalued)", RevalCost);
        ItemJnlLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure CreateAndPostReclassItemJnlLine(ItemNo: Code[20]; PostingDate: Date; Qty: Decimal; ApplyEntryNo: Integer; RedStorno: Boolean)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        InitItemJournalLine(ItemJnlLine, "Item Journal Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name",
          ItemJnlLine."Entry Type"::Transfer, ItemNo, 0);

        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Applies-to Entry", ApplyEntryNo);
        ItemJnlLine.Validate("New Location Code", FindLocationCode());
        ItemJnlLine.Validate("Red Storno", RedStorno);
        ItemJnlLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure InitItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Type, Type);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        ItemJnlLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
        ItemJnlLine."Journal Batch Name" := ItemJournalBatch.Name;
    end;

    local procedure CreateItemNo(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(1000, 2000, 2));
        exit(Item."No.");
    end;

    local procedure CreateInvtDocumentHeader(var InvtDocumentHeader: Record "Invt. Document Header"; DocumentType: Enum "Invt. Doc. Document Type"; PostingDate: Date; NewCorrection: Boolean)
    begin
        InvtDocumentHeader.Init();
        InvtDocumentHeader."Document Type" := DocumentType;
        InvtDocumentHeader.Insert(true);
        InvtDocumentHeader.Validate("Posting Date", PostingDate);
        InvtDocumentHeader.Validate(Correction, NewCorrection);
        InvtDocumentHeader.Modify(true);
    end;

    local procedure CreateInvtDocumentLine(InvtDocumentHeader: Record "Invt. Document Header"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; CorrectedDocType: Enum "Invt. Doc. Document Type"; ApplyEntryNo: Integer)
    var
        InvtDocumentLine: Record "Invt. Document Line";
    begin
        InvtDocumentLine.Init();
        InvtDocumentLine.Validate("Document Type", InvtDocumentHeader."Document Type");
        InvtDocumentLine.Validate("Document No.", InvtDocumentHeader."No.");
        InvtDocumentLine.Validate("Item No.", ItemNo);
        InvtDocumentLine.Validate(Quantity, Qty);
        InvtDocumentLine.Validate("Unit Cost", UnitCost);
        if ApplyEntryNo <> 0 then
            case CorrectedDocType of
                InvtDocumentLine."Document Type"::Receipt:
                    InvtDocumentLine.Validate("Applies-to Entry", ApplyEntryNo);
                InvtDocumentLine."Document Type"::Shipment:
                    InvtDocumentLine.Validate("Applies-from Entry", ApplyEntryNo);
            end;
        InvtDocumentLine.Insert(true);
    end;

    local procedure CreateRevSalesCrMemoAfterInvoice(var SalesHeader: Record "Sales Header"; CorrectedDocNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(CorrectedDocNo);
        CreateRevSalesDoc(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesInvoiceHeader."Sell-to Customer No.",
          SalesHeader."Corrected Doc. Type"::Invoice, CorrectedDocNo);
        GetInvoiceCorrDocLines(SalesHeader, CorrectedDocNo);
        DecreaseQuantityInSalesLine(SalesHeader);
    end;

    local procedure CreateRevSalesDoc(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; CorrectedDocType: Option; CorrectedDocNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate(Correction, true);
        SalesHeader.Validate("Corrective Document", true);
        SalesHeader.Validate("Corrective Doc. Type", SalesHeader."Corrective Doc. Type"::Revision);
        SalesHeader.Validate("Revision No.", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Corrected Doc. Type", CorrectedDocType);
        SalesHeader.Validate("Corrected Doc. No.", CorrectedDocNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PostingDate: Date; NewCorrection: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate(Correction, NewCorrection);
        SalesHeader.Modify(true);
    end;

    local procedure CreateAndPostCorrSalesCrMemo(InvoiceNo: Code[20]; PostingDate: Date; ApplyEntryNo: Integer; Correction: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesInvoiceHeader."Sell-to Customer No.", PostingDate, Correction);

        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", InvoiceNo, false, false);
        UpdateApplyEntryNoForSalesLine(SalesHeader, ApplyEntryNo);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure UpdateApplyEntryNoForSalesLine(SalesHeader: Record "Sales Header"; ApplyEntryNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Appl.-from Item Entry", ApplyEntryNo);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PostingDate: Date; VendorNo: Code[20]; NewCorrection: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate(Correction, NewCorrection);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchLine(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostCorrPurchCrMemo(InvoiceNo: Code[20]; PostingDate: Date; ApplyEntryNo: Integer; Correction: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(InvoiceNo);
        CreatePurchDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PostingDate, PurchInvHeader."Buy-from Vendor No.", Correction);

        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", InvoiceNo, false, false);
        UpdateApplyEntryNoForPurchLine(PurchaseHeader."Document Type", PurchaseHeader."No.", ApplyEntryNo);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateApplyEntryNoForPurchLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ApplyEntryNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Appl.-to Item Entry", ApplyEntryNo);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostFAAcquisition(DeprBookCode: Code[10]; CostAmt: Decimal) FANo: Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        FindFAGenJournalBatch(GenJnlBatch, DeprBookCode, true);

        FANo := LibraryFixedAsset.CreateFixedAssetNo();
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
            GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::"Fixed Asset", FANo,
            GenJnlLine."Bal. Account Type"::"G/L Account", GLAccount."No.", CostAmt);
        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::"Acquisition Cost");
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CancelLastFALedgerEntry(FANo: Code[20]; DeprBookCode: Code[10])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        CancelFAEntries: Report "Cancel FA Entries";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgerEntry.FindLast();

        CancelFAEntries.GetFALedgEntry(FALedgerEntry);
        CancelFAEntries.UseRequestPage(false);
        CancelFAEntries.Run();
    end;

    local procedure PostCancelledJournalLine(FANo: Code[20]; DeprBookCode: Code[10]): Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        FindFAGenJournalBatch(GenJnlBatch, DeprBookCode, false);
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Account No.", FANo);
        GenJnlLine.FindFirst();

        GenJnlLine."Document No." := LibraryUtility.GenerateGUID();
        LibraryERM.FindGLAccount(GLAccount);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        exit(GenJnlLine."Document No.");
    end;

    local procedure FindFAGenJournalBatch(var GenJnlBatch: Record "Gen. Journal Batch"; DeprBookCode: Code[10]; ClearJnl: Boolean)
    var
        FAJnlSetup: Record "FA Journal Setup";
    begin
        FAJnlSetup.Get(DeprBookCode, '');
        GenJnlBatch.Get(FAJnlSetup."Gen. Jnl. Template Name", FAJnlSetup."Gen. Jnl. Batch Name");
        if ClearJnl then
            LibraryERM.ClearGenJournalLines(GenJnlBatch);
    end;

    local procedure UpdateInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := true;
        InventorySetup."Enable Red Storno" := true;
        InventorySetup.Modify();
    end;

    local procedure UpdateGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Mark Cr. Memos as Corrections" := false;
        GLSetup.Modify();
    end;

    local procedure DecreaseQuantityInSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        repeat
            SalesLine.Validate("Quantity (After)", SalesLine."Quantity (Before)" / LibraryRandom.RandIntInRange(3, 5));
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure SetStornoOnDefaultDeprBook(Correction: Boolean): Code[10]
    var
        FASetup: Record "FA Setup";
        DepreciationBook: Record "Depreciation Book";
    begin
        FASetup.Get();
        DepreciationBook.Get(FASetup."Default Depr. Book");
        DepreciationBook."Mark Errors as Corrections" := Correction;
        DepreciationBook.Modify();
        exit(DepreciationBook.Code);
    end;

    local procedure FindLastItemLedgerEntryNo(ItemNo: Code[20]; PostingDate: Date): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Posting Date", PostingDate);
        ItemLedgerEntry.FindLast();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure FindLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        Location.FindFirst();
        exit(Location.Code);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure GetCostAmountActual(EntryNo: Integer): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(EntryNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        exit(ItemLedgerEntry."Cost Amount (Actual)");
    end;

    local procedure GetLastCostDocumentNo(): Code[20]
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.FindLast();
        exit(ValueEntry."Document No.");
    end;

    local procedure GetInventoryAdjAccountNo(ItemNo: Code[20]): Code[20]
    var
        Item: Record Item;
        GenPostingSetup: Record "General Posting Setup";
    begin
        Item.Get(ItemNo);
        GenPostingSetup.Get('', Item."Gen. Prod. Posting Group");
        exit(GenPostingSetup."Inventory Adjmt. Account");
    end;

    local procedure GetInventoryAccountNoFilter(ItemNo: Code[20]) InvAccountNoFilter: Text
    var
        Item: Record Item;
        InvPostingSetup: Record "Inventory Posting Setup";
    begin
        Item.Get(ItemNo);
        InvPostingSetup.Get('', Item."Inventory Posting Group");
        InvAccountNoFilter := InvPostingSetup."Inventory Account";
        InvPostingSetup.Get(FindLocationCode(), Item."Inventory Posting Group");
        InvAccountNoFilter += '|' + InvPostingSetup."Inventory Account";
    end;

    local procedure GetInvoiceCorrDocLines(SalesHeader: Record "Sales Header"; SalesInvoiceNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        CorrectiveDocumentMgt: Codeunit "Corrective Document Mgt.";
        CorrectionType: Option "Original Item","Item Charge";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceNo);
        CorrectiveDocumentMgt.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        CorrectiveDocumentMgt.SetCorrectionType(CorrectionType::"Original Item");
        CorrectiveDocumentMgt.CreateSalesLinesFromPstdInv(SalesInvoiceLine);
    end;

    local procedure VerifyValueEntries(ItemNo: Code[20]; PostingDate: Date; ExpectedAmount: Decimal; RedStorno: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Posting Date", PostingDate);
        ValueEntry.FindLast();
        Assert.AreNearlyEqual(ExpectedAmount, ValueEntry."Cost Amount (Actual)", 0.01,
          StrSubstNo(ValuesAreNotEqualErr, ValueEntry.TableCaption(), ValueEntry.FieldCaption("Cost Amount (Actual)")));
        Assert.AreEqual(RedStorno, ValueEntry."Red Storno",
          StrSubstNo(ValuesAreNotEqualErr, ValueEntry.TableCaption(), ValueEntry.FieldCaption("Red Storno")));
    end;

    local procedure VerifyValueEntryRedStorno(ItemNo: Code[20]; DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; RedStorno: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
        Assert.AreEqual(RedStorno, ValueEntry."Red Storno", ValueEntry.FieldCaption("Red Storno"));
    end;

    local procedure VerifyItemLedgerEntries(ItemNo: Code[20]; PostingDate: Date; ExpectedEntryType: Option; ExpectedQty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Posting Date", PostingDate);
        ItemLedgerEntry.FindLast();
        Assert.AreEqual(ExpectedEntryType, ItemLedgerEntry."Entry Type",
          StrSubstNo(ValuesAreNotEqualErr, ItemLedgerEntry.TableCaption(), ItemLedgerEntry.FieldCaption("Entry Type")));
        Assert.AreEqual(ExpectedQty, ItemLedgerEntry.Quantity,
          StrSubstNo(ValuesAreNotEqualErr, ItemLedgerEntry.TableCaption(), ItemLedgerEntry.FieldCaption(Quantity)));
    end;

    local procedure VerifyGLEntries(AccountNoFilter: Text; DocumentNo: Code[20]; ExpectedAmount: Decimal; Sorting: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Ascending(Sorting);
        GLEntry.SetFilter("G/L Account No.", AccountNoFilter);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.FindSet();
        VerifyGLDebitCredit(GLEntry, 0, ExpectedAmount);
        GLEntry.Next();
        VerifyGLDebitCredit(GLEntry, ExpectedAmount, 0);
    end;

    local procedure VerifyGLDebitCredit(var GLEntry: Record "G/L Entry"; ExpectedDebit: Decimal; ExpectedCredit: Decimal)
    begin
        Assert.AreNearlyEqual(ExpectedDebit, GLEntry."Debit Amount", 0.01,
          StrSubstNo(ValuesAreNotEqualErr, GLEntry.TableCaption(), GLEntry.FieldCaption("Debit Amount")));
        Assert.AreNearlyEqual(ExpectedCredit, GLEntry."Credit Amount", 0.01,
          StrSubstNo(ValuesAreNotEqualErr, GLEntry.TableCaption(), GLEntry.FieldCaption("Credit Amount")));
    end;

    local procedure CalcSign(var CorrSign: Integer; var ExpectedSign: Integer; EntryType: Enum "Item Ledger Entry Type"; RedStorno: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        if RedStorno then
            CorrSign := -1
        else
            CorrSign := 1;
        case EntryType of
            ItemJournalLine."Entry Type"::"Positive Adjmt.":
                ExpectedSign := -1;
            ItemJournalLine."Entry Type"::"Negative Adjmt.":
                ExpectedSign := 1;
        end;
    end;

    local procedure CalcExpectedSign(RedStorno: Boolean): Integer
    begin
        if RedStorno then
            exit(-1);

        exit(1);
    end;

    local procedure CalcTypeAndSignForInvtDoc(var CorrEntryType: Option; var ExpectedSign: Integer; var Sorting: Boolean; DocType: Enum "Invt. Doc. Document Type"; CorrDocType: Enum "Invt. Doc. Document Type")
    var
        InvtDocHeader: Record "Invt. Document Header";
        ItemJournalLine: Record "Item Journal Line";
    begin
        case DocType of
            InvtDocHeader."Document Type"::Receipt:
                ExpectedSign := -1;
            InvtDocHeader."Document Type"::Shipment:
                ExpectedSign := 1;
        end;
        case CorrDocType of
            InvtDocHeader."Document Type"::Receipt:
                CorrEntryType := ItemJournalLine."Entry Type"::"Positive Adjmt.".AsInteger();
            InvtDocHeader."Document Type"::Shipment:
                CorrEntryType := ItemJournalLine."Entry Type"::"Negative Adjmt.".AsInteger();
        end;
        Sorting := CorrEntryType = ItemJournalLine."Entry Type"::"Negative Adjmt.".AsInteger();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

