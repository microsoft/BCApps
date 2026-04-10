codeunit 137013 "SCM Costing Sales Returns-II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Return Order] [Sales] [SCM]
        isInitialized := false;
    end;

    var
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        isInitialized: Boolean;
        ErrAmountsMustBeSame: Label 'Sales Amounts must be same.';
        CostingMethod: array[2] of Enum "Costing Method";
        MsgCorrectedInvoiceNo: Label 'have a Corrected Invoice No. Do you want to continue?';
        CostNotAdjustedErr: Label 'Item cost must be adjusted.';
        ItemLedgCostAmountErr: Label 'Incorrect cost amount in item ledger entry';

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnItemAndCharge()
    begin
        // One Charge Line and one Item Line in Sales Return Order.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        SalesReturnItem(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnSameItemTwice()
    begin
        // No Charge Line and two Item Lines in Sales Return Order of the same item.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        SalesReturnItem(0, 1, true);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnDiffItems()
    begin
        // No Charge Line and two Item Lines in Sales Return Order with different items.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CostingMethod[2] := Item."Costing Method"::Average;
        SalesReturnItem(0, 2, false);
    end;

    [Normal]
    local procedure SalesReturnItem(NoOfCharges: Integer; NoOfItems: Integer; SameItemTwice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempItem: Record Item temporary;
        TempItemCharge: Record "Item Charge" temporary;
        SalesOrderNo: Code[20];
        SalesItemQty: Decimal;
    begin
        // Setup: Create required Setups with only Items, create Item Charge required for Sales Return Order.
        Initialize();
        UpdateSalesReceivablesSetup(false);
        CreateItemsAndCopyToTemp(TempItem, NoOfItems);
        CreateSalesSetup(TempItem, SalesHeader, SalesItemQty);
        SalesOrderNo := SalesHeader."No.";
        CreateItemChargeAndCopyToTemp(TempItemCharge, NoOfCharges);

        // Create Sales Return Order with Lines containing: Item, Charge or additional Item (Same or Different).
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        CreateSalesLines(SalesHeader, TempItem, TempItemCharge, SameItemTwice, SalesItemQty - 1);

        // Update Sales Return Lines with required Unit Price and required Qty.
        SelectSalesLines(SalesLine, SalesHeader."No.", SalesHeader."Document Type"::"Return Order");
        TempItem.FindFirst();
        UpdateSalesLine(SalesLine, TempItem."Unit Price", 1);  // Qty Sign Factor value important for Test.
        SalesLine.Next();
        if NoOfCharges > 0 then begin
            UpdateSalesLine(SalesLine, -LibraryRandom.RandInt(10), 1);  // Qty Sign Factor value important for Test.
            CreateItemChargeAssignment(SalesLine, SalesOrderNo);
        end;
        if (NoOfItems > 0) and (NoOfCharges = 0) then begin
            TempItem.FindLast();
            UpdateSalesLine(SalesLine, -TempItem."Unit Price", -1);  // Qty Sign Factor value important for Test.
        end;
        CopySalesLinesToTemp(TempSalesLine, SalesLine);

        // Exercise: Post Sales Return Order and Run Adjust Cost Item Entries report.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Customer Ledger Entry.
        VerifySalesAmount(TempSalesLine, SalesHeader, SalesOrderNo);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnChargeMoveLineFIFO()
    begin
        // One Charge Line and one Item Line (Costing Method:FIFO) in Sales Return Order. Move -ve line to new Sales Order.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        SalesReturnItemMoveLine(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnChargeMoveLineAvg()
    begin
        // One Charge Line and one Item Line (Costing Method:Avg) in Sales Return Order. Move -ve line to new Sales Order.
        CostingMethod[1] := Item."Costing Method"::Average;
        SalesReturnItemMoveLine(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnItemMoveLineFIFO()
    begin
        // No Charge Line and two Item Lines in Sales Return Order of the same item. Move -ve line to new Sales Order.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        SalesReturnItemMoveLine(0, 1, true);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnDiffItemsMoveLine()
    begin
        // No Charge Line and two Item Lines in Sales Return Order with different items. Move -ve line to new Sales Order.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CostingMethod[2] := Item."Costing Method"::Average;
        SalesReturnItemMoveLine(0, 2, false);
    end;

    [Normal]
    local procedure SalesReturnItemMoveLine(NoOfCharges: Integer; NoOfItems: Integer; SameItemTwice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempItem: Record Item temporary;
        SalesOrderNo: Code[20];
    begin
        // Setup: Create required Setups with only Items, create Item Charge required for Sales Return Order.
        Initialize();
        UpdateSalesReceivablesSetup(false);
        CreateItemsAndCopyToTemp(TempItem, NoOfItems);

        // Create Sales Return Order with Lines containing: Item, Charge or additional Item (Same or Different).
        SalesOrderNo :=
          CreateSalesDoc(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", NoOfCharges, TempItem, SameItemTwice);

        // Move Negative Lines to a new Sales Order.
        MoveNegativeLine(SalesHeader, SalesHeader2, "Sales Document Type From"::"Return Order", "Sales Document Type From"::Order);
        CopySalesLinesToTemp(TempSalesLine, SalesLine);

        // Exercise: Post Sales Return Order and Run Adjust Cost Item Entries report.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Customer Ledger Entry.
        VerifySalesAmount(TempSalesLine, SalesHeader, SalesOrderNo);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnTwicePostCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempItem: Record Item temporary;
        TempItemCharge: Record "Item Charge" temporary;
        SalesOrderNo: Code[20];
        SalesItemQty: Decimal;
    begin
        // Setup: Create required Setups with only Items, create Item Charge required for Credit Memo.
        Initialize();
        UpdateSalesReceivablesSetup(false);
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CostingMethod[2] := Item."Costing Method"::Average;
        CreateItemsAndCopyToTemp(TempItem, 2);  // No of Item = 2
        CreateSalesSetup(TempItem, SalesHeader, SalesItemQty);
        SalesOrderNo := SalesHeader."No.";
        CreateItemChargeAndCopyToTemp(TempItemCharge, 1);

        // Create Sales Return Order for different Items and Item Charge, and Receive only.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        CreateSalesLines(SalesHeader, TempItem, TempItemCharge, false, LibraryRandom.RandInt(5));
        SelectSalesLines(SalesLine, SalesHeader."No.", SalesHeader."Document Type"::"Return Order");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();
        UpdateSalesLine(SalesLine, -LibraryRandom.RandInt(1), 1);  // Qty Sign Factor value important for Test.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        TempItem.FindLast();
        TempItem.Delete();

        // Create Sales Return Order for same Item with postive and negative quantity and Item Charge, and Receive only.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        CreateSalesLines(SalesHeader2, TempItem, TempItemCharge, true, SalesItemQty - 2);
        SelectSalesLines(SalesLine2, SalesHeader2."No.", SalesHeader."Document Type"::"Return Order");
        UpdateSalesLine(SalesLine2, TempItem."Unit Price", -1);  // Qty Sign Factor value important for Test.
        SalesLine2.SetRange(Type, SalesLine2.Type::"Charge (Item)");
        SalesLine2.FindFirst();
        UpdateSalesLine(SalesLine2, LibraryRandom.RandInt(10), 1);  // Qty Sign Factor value important for Test.
        LibrarySales.PostSalesDocument(SalesHeader2, true, false);

        // Make a Credit Memo for both the Sales Return Orders using Get Return Receipt Line and Post.
        LibrarySales.CreateSalesHeader(SalesHeader3, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        CreateCrMemoLines(SalesHeader3, SalesHeader."No.", SalesHeader2."No.");
        SelectSalesLines(SalesLine3, SalesHeader3."No.", SalesHeader."Document Type"::"Credit Memo");
        CopySalesLinesToTemp(TempSalesLine, SalesLine3);
        SalesLine3.SetRange(Type, SalesLine3.Type::"Charge (Item)");
        SalesLine3.FindSet();
        repeat
            CreateItemChargeAssignment(SalesLine3, SalesOrderNo);
        until SalesLine3.Next() = 0;

        // Exercise: Post Credit Memo and Run Adjust Cost Item Entries report.
        LibrarySales.PostSalesDocument(SalesHeader3, true, false);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Customer Ledger Entry.
        VerifyCustLedgerEntry(TempSalesLine, SalesHeader3);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoCharge()
    begin
        // One Charge Line in Sales Credit Memo.
        CostingMethod[1] := Item."Costing Method"::Average;
        SalesCrMemo(1, 0, false, -1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoItemAvg()
    begin
        // One Item Line in Sales Credit Memo.
        CostingMethod[1] := Item."Costing Method"::Average;
        SalesCrMemo(0, 1, false, -1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoItemAvgAndCharge()
    begin
        // One Charge Line and one Item Line (Item Costing Method: Average) in Sales Credit Memo.
        CostingMethod[1] := Item."Costing Method"::Average;
        SalesCrMemo(1, 1, false, -1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoItemFIFOAndCharge()
    begin
        // One Charge Line and one Item Line (Item Costing Method: FIFO) in Sales Credit Memo.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        SalesCrMemo(1, 1, false, -1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoItemNegativeCharge()
    begin
        // One negative Charge Line and one Item Line (Item Costing Method: FIFO) in Sales Credit Memo.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        SalesCrMemo(1, 1, false, 1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoSameItemTwice()
    begin
        // No Charge Line and two Item Lines in Sales Credit Memo of the same Item.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        SalesCrMemo(0, 1, true, -1);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoDiffItems()
    begin
        // No Charge Line and two Item Lines in Sales Credit Memo with different items.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CostingMethod[2] := Item."Costing Method"::Average;
        SalesCrMemo(0, 2, false, -1);
    end;

    [Normal]
    local procedure SalesCrMemo(NoOfCharges: Integer; NoOfItems: Integer; SameItemTwice: Boolean; SignFactor: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempItem: Record Item temporary;
        TempItemCharge: Record "Item Charge" temporary;
        SalesOrderNo: Code[20];
        SalesItemQty: Decimal;
    begin
        // Setup: Create required Setups with only Items, create Item Charge required for Credit Memo.
        Initialize();
        UpdateSalesReceivablesSetup(false);
        CreateItemsAndCopyToTemp(TempItem, NoOfItems);
        CreateSalesSetup(TempItem, SalesHeader, SalesItemQty);
        SalesOrderNo := SalesHeader."No.";
        CreateItemChargeAndCopyToTemp(TempItemCharge, NoOfCharges);
        if NoOfItems = 0 then
            TempItem.Delete();

        // Make a Credit Memo for Item, Charge or both as required.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        CreateSalesLines(SalesHeader, TempItem, TempItemCharge, SameItemTwice, SalesItemQty - 1);

        // Update Credit Memo Lines with required Unit Price and required Qty.
        SelectSalesLines(SalesLine, SalesHeader."No.", SalesHeader."Document Type"::"Credit Memo");
        if SameItemTwice then
            UpdateSalesLine(SalesLine, TempItem."Unit Price", SignFactor);
        if (NoOfItems > 0) and (NoOfCharges > 0) then begin
            TempItem.FindFirst();
            UpdateSalesLine(SalesLine, SignFactor * TempItem."Unit Price", SignFactor);
            SalesLine.Next();
        end;
        if NoOfItems > 1 then begin
            TempItem.FindFirst();
            UpdateSalesLine(SalesLine, SignFactor * TempItem."Unit Price", SignFactor);
        end;
        if NoOfCharges > 0 then begin
            UpdateSalesLine(SalesLine, -SignFactor * LibraryRandom.RandInt(10), 1);  // Qty Sign Factor value important for Test.
            CreateItemChargeAssignment(SalesLine, SalesOrderNo);
        end;
        CopySalesLinesToTemp(TempSalesLine, SalesLine);

        // Exercise: Post Credit Memo and Run Adjust Cost Item Entries report.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        if TempItem.FindSet() then
            AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Customer Ledger Entry.
        VerifySalesAmount(TempSalesLine, SalesHeader, SalesOrderNo);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoChargeMoveLineAvg()
    begin
        // One Charge Line and one Item Line (Item Costing method: Average) in Sales Credit Memo. Move -ve line to new Sales Invoice.
        CostingMethod[1] := Item."Costing Method"::Average;
        SalesCrMemoMoveLine(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoChargeMoveLineFIFO()
    begin
        // One Charge Line and one Item Line (Item Costing method: FIFO) in Sales Credit Memo. Move -ve line to new Sales Invoice.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        SalesCrMemoMoveLine(1, 1, false);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoItemMoveLineFIFO()
    begin
        // No Charge Line and two Item Lines in Sales Credit Memo of the same item. Move -ve line to new Sales Invoice.
        CostingMethod[1] := Item."Costing Method"::FIFO;
        SalesCrMemoMoveLine(0, 1, true);
    end;

    [Normal]
    local procedure SalesCrMemoMoveLine(NoOfCharges: Integer; NoOfItems: Integer; SameItemTwice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempItem: Record Item temporary;
        SalesOrderNo: Code[20];
    begin
        // Setup: Create required Setups with only Items, create Item Charge required for Credit Memo.
        Initialize();
        UpdateSalesReceivablesSetup(false);
        CreateItemsAndCopyToTemp(TempItem, NoOfItems);

        // Make a Credit Memo for Item, Charge or both as required.
        SalesOrderNo :=
          CreateSalesDoc(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", NoOfCharges, TempItem, SameItemTwice);
        // Move Negative Lines to a new Sales Invoice.
        MoveNegativeLine(SalesHeader, SalesHeader2, "Sales Document Type From"::"Credit Memo", "Sales Document Type From"::Invoice);
        CopySalesLinesToTemp(TempSalesLine, SalesLine);

        // Exercise: Post Credit Memo and Run Adjust Cost Item Entries report.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader2, true, false);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Customer Ledger Entry.
        VerifySalesAmount(TempSalesLine, SalesHeader, SalesOrderNo);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; NoOfCharges: Integer; var TempItem: Record Item temporary; SameItemTwice: Boolean) SalesOrderNo: Code[20]
    var
        TempItemCharge: Record "Item Charge" temporary;
        SalesItemQty: Decimal;
    begin
        CreateSalesSetup(TempItem, SalesHeader, SalesItemQty);
        SalesOrderNo := SalesHeader."No.";
        CreateItemChargeAndCopyToTemp(TempItemCharge, NoOfCharges);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SalesHeader."Sell-to Customer No.");
        CreateSalesLines(SalesHeader, TempItem, TempItemCharge, SameItemTwice, SalesItemQty - 1);

        // Update Credit Memo Lines with required Unit Price and required Qty.
        SelectSalesLines(SalesLine, SalesHeader."No.", DocumentType);
        TempItem.FindFirst();
        UpdateSalesLine(SalesLine, TempItem."Unit Price", -1);  // Qty Sign Factor value important for Test.
        if NoOfCharges > 0 then begin
            SalesLine.Next();
            UpdateSalesLine(SalesLine, LibraryRandom.RandInt(10), 1);  // Qty Sign Factor value important for Test.
            CreateItemChargeAssignment(SalesLine, SalesOrderNo);
        end;
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoCopyShipmentDoc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TempSalesLine: Record "Sales Line" temporary;
        TempItem: Record Item temporary;
        SalesItemQty: Decimal;
        SalesOrderNo: Code[20];
    begin
        // Setup: Create required Setups with only Item.
        Initialize();
        UpdateSalesReceivablesSetup(false);
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CreateItemsAndCopyToTemp(TempItem, 1);  // No of Item = 1
        CreateSalesSetup(TempItem, SalesHeader, SalesItemQty);
        SalesOrderNo := SalesHeader."No.";

        // Create Credit Memo using Copy Document of Posted Sales Shipment.
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        CreateCrMemo(SalesHeader);
        SalesHeaderCopySalesDoc(SalesHeader, "Sales Document Type From"::"Posted Shipment", SalesShipmentHeader."No.", true, true);

        // Copy Sales Line to a temporary Sales Line record.
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        SelectSalesLines(SalesLine, SalesHeader."No.", SalesHeader."Document Type"::"Credit Memo");
        CopySalesLinesToTemp(TempSalesLine, SalesLine);

        // Exercise: Post Credit Memo and Run Adjust Cost Item Entries report.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Customer Ledger Entry.
        VerifySalesAmount(TempSalesLine, SalesHeader, SalesOrderNo);
    end;

    [Test]
    [HandlerFunctions('CorrectedInvoiceNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoDeleteWrongMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempItem: Record Item temporary;
        TempItemCharge: Record "Item Charge" temporary;
        SalesOrderNo: Code[20];
        CustomerNo: Code[20];
        SalesItemQty: Decimal;
    begin
        // Setup: Create required Setups with only Item.
        Initialize();
        UpdateSalesReceivablesSetup(true);
        CostingMethod[1] := Item."Costing Method"::FIFO;
        CreateItemsAndCopyToTemp(TempItem, 1);  // No of Item = 1
        CreateSalesSetup(TempItem, SalesHeader, SalesItemQty);
        SalesOrderNo := SalesHeader."No.";

        // Make a Credit Memo for Item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        CreateSalesLines(SalesHeader, TempItem, TempItemCharge, false, SalesItemQty - 1);
        SelectSalesLines(SalesLine, SalesHeader."No.", SalesHeader."Document Type"::"Credit Memo");

        // Exercise: Post Credit Memo without Apply-from Item Entry.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Apply-from Item Entry error message.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Appl.-from Item Entry"), '');

        // Delete incorrect Sales Credit Memo.
        DeleteSalesCreditMemo(SalesHeader."No.");
        CustomerNo := SalesHeader."Sell-to Customer No.";
        Clear(SalesHeader);
        Clear(SalesLine);

        // Make a new Credit Memo for Item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        CreateSalesLines(SalesHeader, TempItem, TempItemCharge, false, SalesItemQty - 1);
        SelectSalesLines(SalesLine, SalesHeader."No.", SalesHeader."Document Type"::"Credit Memo");
        UpdateSalesLine(SalesLine, TempItem."Unit Price", 1);
        CopySalesLinesToTemp(TempSalesLine, SalesLine);

        // Exercise: Post Credit Memo and Run Adjust Cost Item Entries report.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        AdjustCostItemEntries(TempItem);

        // Verify: Verify Item Ledger Entry and Customer Ledger Entry.
        VerifySalesAmount(TempSalesLine, SalesHeader, SalesOrderNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure CostAdjustedWithSalesReturnAppliedToBackdatedShipment()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Undo Shipment] [Adjust Cost Item Entries]
        // [SCENARIO 363792] Item cost is adjusted when a shipment return entry is applied to a backdated outbound entry

        Initialize();

        // [GIVEN] Item with Average costing method
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item, Item."Costing Method"::Average);
        Quantity := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Ship item on the WORKDATE
        CreateSalesOrderPostShipment(SalesHeader, Customer."No.", WorkDate(), Item."No.", Quantity * 2);

        // [GIVEN] Ship and return item on the WorkDate() + 1D, so that the inbount entry is applied to the first outbound posted on the previous day
        CreateSalesOrderPostShipment(SalesHeader, Customer."No.", CalcDate('<1D>', WorkDate()), Item."No.", Quantity);
        UndoSalesShipmentLine(SalesHeader."No.");

        // [GIVEN] Ship item on the WorkDate() + 2 days
        CreateSalesOrderPostShipment(SalesHeader, Customer."No.", CalcDate('<2D>', WorkDate()), Item."No.", Quantity * 2);

        // [WHEN] Run Adjust Cost - Item Entries batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] "Cost is Adjusted" is "Yes" on the Item
        Assert.IsTrue(Item."Cost is Adjusted", CostNotAdjustedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure CostAdjustmentAfterApplyItemChargeForwardToSalesReturnAndUndoSalesReturnFixedAppln()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Undo Receipt] [Cost Application] [Item Charge] [Adjust Cost - Item Entries]
        // [SCENARIO 377809] Item charge assigned to purchase after cost adjustment, then adjusted again - cost forwarded to applied sale, sales return and undo sales return entries

        // [GIVEN] Item "I" with "Average" costing method
        // [GIVEN] Post purchase order for "X" pcs of item "I"
        CreateItemPostPurchase(Item);

        // [GIVEN] Post sales order with fixed cost application to purchase
        PostSalesOrderWithFixedCostApplication(
          Item."No.", Item.Inventory, FindItemLedgerEtry(Item."No.", ItemLedgerEntry."Entry Type"::Purchase));

        // [GIVEN] Post sales return order, undo it and run cost adjustment
        PostAndUndoSalesReturnWithACIE(Item."No.", Item.Inventory);
        // [GIVEN] Apply item charge to purchase receipt
        PostPurchItemChargeApplyToReceipt(Item."No.", Item.Inventory, LibraryRandom.RandInt(20));

        // [WHEN] Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] All item ledger entries receive item charge amount
        Item.Find();
        VerifyItemLedgerEntriesActualCost(Item);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure CostAdjustmentAfterApplyItemChargeForwardToSalesReturnAndUndoSalesReturnNoAppln()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Undo Receipt] [Item Charge] [Adjust Cost - Item Entries]
        // [SCENARIO 377809] Item charge assigned to purchase after cost adjustment, then adjusted again - sale, sales return and undo sales return entries recive cost amount without fixed application

        // [GIVEN] Item "I" with "Average" costing method
        // [GIVEN] Post purchase order for "X" pcs of item "I"
        CreateItemPostPurchase(Item);

        // [GIVEN] Post sales order without fixed cost application
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Item.Inventory);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Post sales return order, undo it and run cost adjustment
        PostAndUndoSalesReturnWithACIE(Item."No.", Item.Inventory);
        // [GIVEN] Apply item charge to purchase receipt
        PostPurchItemChargeApplyToReceipt(Item."No.", Item.Inventory, LibraryRandom.RandInt(20));

        // [WHEN] Adjust cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] All item ledger entries receive item charge amount
        Item.Find();
        VerifyItemLedgerEntriesActualCost(Item);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Sales Returns-II");
        ExecuteConfirmHandler();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Sales Returns-II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        GeneralLedgerSetup.Get();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Sales Returns-II");
    end;

    [Normal]
    local procedure UpdateSalesReceivablesSetup(ExactCostReversingMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Validate("Return Receipt on Credit Memo", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateItemsAndCopyToTemp(var TempItem: Record Item temporary; NoOfItems: Integer)
    var
        Item: Record Item;
        Counter: Integer;
    begin
        if NoOfItems = 0 then
            NoOfItems += 1;
        for Counter := 1 to NoOfItems do begin
            Clear(Item);
            CreateItemWithInventory(Item, CostingMethod[Counter]);
            TempItem := Item;
            TempItem.Insert();
        end;
    end;

    local procedure CreateItemWithInventory(var Item: Record Item; ItemCostingMethod: Enum "Costing Method")
    begin
        CreateItem(Item, ItemCostingMethod);
        UpdateItemInventory(Item."No.", LibraryRandom.RandInt(10) + 50);
    end;

    local procedure CreateItem(var Item: Record Item; ItemCostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", ItemCostingMethod);
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));
        Item.Modify(true);
    end;

    local procedure CreateItemPostPurchase(var Item: Record Item)
    begin
        CreateItem(Item, Item."Costing Method"::Average);
        PostPurchaseOrder(Item."No.", LibraryRandom.RandInt(10), LibraryRandom.RandInt(100));
        Item.CalcFields(Inventory);
    end;

    local procedure PostPurchaseOrder(ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseOrderWithItemCharge(var PurchaseHeader: Record "Purchase Header"; PurchRcptLine: Record "Purch. Rcpt. Line"; Qty: Decimal; UnitCost: Decimal)
    var
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchRcptLine."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", Qty);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt, PurchRcptLine."Document No.", PurchRcptLine."Line No.",
          PurchRcptLine."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateSalesOrderPostShipment(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PostingDate: Date; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Init();
        SalesHeader."No." := '';
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure FindItemLedgerEtry(ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindFirst();

        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnRcptLine: Record "Return Receipt Line"; ItemNo: Code[20])
    begin
        ReturnRcptLine.SetRange("No.", ItemNo);
        ReturnRcptLine.FindLast();
    end;

    [Normal]
    local procedure UpdateItemInventory(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, Qty);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [Normal]
    local procedure CreateSalesSetup(var TempItem: Record Item temporary; var SalesHeader: Record "Sales Header"; var ItemQty: Decimal)
    var
        Customer: Record Customer;
        TempItemCharge: Record "Item Charge" temporary;
    begin
        // Create Sales Order.
        TempItem.CalcFields(Inventory);
        ItemQty := TempItem.Inventory - 10;
        CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLines(SalesHeader, TempItem, TempItemCharge, false, ItemQty);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Normal]
    local procedure CreateItemChargeAndCopyToTemp(var TempItemCharge: Record "Item Charge" temporary; NoOfCharges: Integer)
    var
        ItemCharge: Record "Item Charge";
        Counter: Integer;
    begin
        for Counter := 1 to NoOfCharges do begin
            LibraryInventory.CreateItemCharge(ItemCharge);
            TempItemCharge := ItemCharge;
            TempItemCharge.Insert();
        end;
    end;

    [Normal]
    local procedure CreateSalesLines(var SalesHeader: Record "Sales Header"; var TempItem: Record Item temporary; var TempItemCharge: Record "Item Charge" temporary; SameItemTwice: Boolean; ItemQty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        if TempItem.FindSet() then
            repeat
                LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, TempItem."No.", ItemQty);
                if SameItemTwice then
                    LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, TempItem."No.", ItemQty);
            until TempItem.Next() = 0;

        if TempItemCharge.FindSet() then
            repeat
                LibrarySales.CreateSalesLine(
                  SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", TempItemCharge."No.", LibraryRandom.RandInt(1));
            until TempItemCharge.Next() = 0;
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
    end;

    [Normal]
    local procedure UpdateSalesLine(var SalesLine: Record "Sales Line"; UnitPrice: Decimal; SignFactor: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        SalesLine.Validate(Quantity, SignFactor * SalesLine.Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine.Quantity > 0) then begin
            ItemLedgerEntry.SetRange("Item No.", SalesLine."No.");
            ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
            ItemLedgerEntry.FindFirst();
            SalesLine.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        end;
        SalesLine.Validate("Qty. to Ship", 0);  // Value important for Test.
        SalesLine.Modify(true);
    end;

    local procedure CreateItemChargeAssignment(SalesLine: Record "Sales Line"; SalesOrderNo: Code[20])
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        DocTypeCrMemo: Boolean;
    begin
        ItemChargeAssignmentSales.Validate("Document Type", SalesLine."Document Type");
        ItemChargeAssignmentSales.Validate("Document No.", SalesLine."Document No.");
        ItemChargeAssignmentSales.Validate("Document Line No.", SalesLine."Line No.");
        ItemChargeAssignmentSales.Validate("Item Charge No.", SalesLine."No.");
        ItemChargeAssignmentSales.Validate("Unit Cost", SalesLine."Unit Price");
        AssignItemChargeToShipment(ItemChargeAssignmentSales, SalesOrderNo);
        if SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo" then
            DocTypeCrMemo := true;
        UpdateItemChargeQtyToAssign(
          ItemChargeAssignmentSales."Document No.", SalesLine.Quantity, SalesLine."Line No.", DocTypeCrMemo);
    end;

    local procedure AssignItemChargeToShipment(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; SalesOrderNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        SalesShipmentLine.SetRange("Order No.", SalesOrderNo);
        SalesShipmentLine.FindFirst();
        ItemChargeAssgntSales.CreateShptChargeAssgnt(SalesShipmentLine, ItemChargeAssignmentSales);
    end;

    local procedure PostAndUndoSalesReturnWithACIE(ItemNo: Code[20]; Qty: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(FindItemLedgerEtry(ItemNo, ItemLedgerEntry."Entry Type"::Sale));
        PostSalesReturnOrder(ItemLedgerEntry."Source No.", ItemNo, Qty, ItemLedgerEntry."Entry No.");
        UndoReturnReceiptLine(ItemNo);
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
    end;

    local procedure PostPurchItemChargeApplyToReceipt(ItemNo: Code[20]; ChargeQty: Decimal; ChargeUnitCost: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        FindPurchaseReceiptLine(PurchRcptLine, ItemNo);
        CreatePurchaseOrderWithItemCharge(PurchaseHeader, PurchRcptLine, ChargeQty, ChargeUnitCost);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostSalesOrderWithFixedCostApplication(ItemNo: Code[20]; Qty: Decimal; AppliesToEntryNo: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Qty);
        SalesLine.Validate("Appl.-to Item Entry", AppliesToEntryNo);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostSalesReturnOrder(CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; ApplFromItemEntry: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CustomerNo, ItemNo, Qty);
        SalesLine.Validate("Appl.-from Item Entry", ApplFromItemEntry);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure UndoReturnReceiptLine(ItemNo: Code[20])
    var
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        FindReturnReceiptLine(ReturnRcptLine, ItemNo);
        LibrarySales.UndoReturnReceiptLine(ReturnRcptLine);
    end;

    local procedure UndoSalesShipmentLine(OrderNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentHeader.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateItemChargeQtyToAssign(DocumentNo: Code[20]; QtyToAssign: Decimal; DocLineNo: Integer; DocTypeCrMemo: Boolean)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssignmentSales.SetRange("Document No.", DocumentNo);
        if DocTypeCrMemo then begin
            ItemChargeAssignmentSales.SetRange("Document Type", ItemChargeAssignmentSales."Document Type"::"Credit Memo");
            ItemChargeAssignmentSales.SetRange("Document Line No.", DocLineNo);
        end else
            ItemChargeAssignmentSales.SetRange("Document Type", ItemChargeAssignmentSales."Document Type"::"Return Order");
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssignmentSales.Modify(true);
    end;

    [Normal]
    local procedure SelectSalesLines(var SalesLine: Record "Sales Line"; SalesHeaderNo: Code[20]; DocumentType: Enum "Sales Document Type")
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.FindSet();
    end;

    [Normal]
    local procedure MoveNegativeLine(var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; ToDocType: Enum "Sales Document Type From")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(true, false, true, true, true, false, false);
        SalesHeader2."Document Type" := CopyDocumentMgt.GetSalesDocumentType(ToDocType);
        CopyDocumentMgt.CopySalesDoc(FromDocType, SalesHeader."No.", SalesHeader2);
    end;

    [Normal]
    local procedure CreateCrMemoLines(var SalesHeader: Record "Sales Header"; ReturnOrderNo: Code[20]; ReturnOrderNo2: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        ReturnReceiptLine.SetFilter("Return Order No.", '%1|%2', ReturnOrderNo, ReturnOrderNo2);
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
    end;

    local procedure SalesHeaderCopySalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type From"; DocNo: Code[20]; IncludeHeader: Boolean; RecalcLines: Boolean)
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocType, DocNo, IncludeHeader, RecalcLines);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.RunModal();
    end;

    [Normal]
    local procedure CopySalesLinesToTemp(var TempSalesLine: Record "Sales Line" temporary; var SalesLine: Record "Sales Line")
    begin
        SalesLine.FindSet();
        repeat
            TempSalesLine := SalesLine;
            TempSalesLine.Insert();
        until SalesLine.Next() = 0;
    end;

    [Normal]
    local procedure CreateCrMemo(var SalesHeader: Record "Sales Header")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Validate(
          "External Document No.",
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("External Document No."), DATABASE::"Sales Header"));
        SalesHeader.Insert(true);
    end;

    [Normal]
    local procedure DeleteSalesCreditMemo(SalesCreditMemoNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
    begin
        SalesHeader.Get(DocumentType::"Credit Memo", SalesCreditMemoNo);
        Clear(SalesLine);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Delete();
        SalesHeader.Delete();
    end;

    [Normal]
    local procedure AdjustCostItemEntries(var TempItem: Record Item temporary)
    var
        Counter: Integer;
    begin
        TempItem.FindSet();
        for Counter := 1 to TempItem.Count do begin
            LibraryCosting.AdjustCostItemEntries(TempItem."No.", '');
            TempItem.Next();
        end;
    end;

    [Normal]
    local procedure VerifySalesAmount(var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header"; SalesOrderNo: Code[20])
    begin
        TempSalesLine.FindSet();
        VerifyCustLedgerEntry(TempSalesLine, SalesHeader);

        repeat
            if TempSalesLine.Type = TempSalesLine.Type::Item then
                VerifyItemLedgerReturnReceipt(SalesHeader."External Document No.")
            else
                VerifyItemLedgerShipment(TempSalesLine, SalesOrderNo);  // Verification for Sales Line type - Charge.
        until TempSalesLine.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntriesActualCost(Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            Assert.AreEqual(Item."Unit Cost" * ItemLedgerEntry.Quantity, ItemLedgerEntry."Cost Amount (Actual)", ItemLedgCostAmountErr);
        until ItemLedgerEntry.Next() = 0;
    end;

    [Normal]
    local procedure VerifyItemLedgerShipment(var TempSalesLine: Record "Sales Line" temporary; SalesOrderNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CalcSalesAmountWithCharge: Decimal;
    begin
        // Verify Sales Amount (Actual) from Sales Shipment line after Item Charge has been applied to it.
        SalesShipmentLine.SetRange("Order No.", SalesOrderNo);
        SalesShipmentLine.FindFirst();
        TempSalesLine.SetRange(Type, TempSalesLine.Type::"Charge (Item)");
        TempSalesLine.FindSet();
        CalcSalesAmountWithCharge :=
          SalesShipmentLine.Quantity * SalesShipmentLine."Unit Price" - TempSalesLine.Quantity * TempSalesLine."Unit Price";

        ItemLedgerEntry.SetRange("Document No.", SalesShipmentLine."Document No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)");

        Assert.AreNearlyEqual(CalcSalesAmountWithCharge, ItemLedgerEntry."Sales Amount (Actual)",
          GeneralLedgerSetup."Amount Rounding Precision", ErrAmountsMustBeSame);
    end;

    [Normal]
    local procedure VerifyItemLedgerReturnReceipt(ExternalDocNo: Code[35])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
        CalcSalesAmount: Decimal;
        ActualSalesAmount: Decimal;
    begin
        // Verify Sales Amount (Actual) from Sales Return Receipt lines.
        ReturnReceiptHeader.SetRange("External Document No.", ExternalDocNo);
        ReturnReceiptHeader.FindFirst();
        ReturnReceiptLine.SetRange("Document No.", ReturnReceiptHeader."No.");
        ReturnReceiptLine.SetRange(Type, ReturnReceiptLine.Type::Item);
        ReturnReceiptLine.FindSet();

        repeat
            CalcSalesAmount += ReturnReceiptLine.Quantity * ReturnReceiptLine."Unit Price";
        until ReturnReceiptLine.Next() = 0;
        ItemLedgerEntry.SetRange("Document No.", ReturnReceiptHeader."No.");
        ItemLedgerEntry.FindSet();

        repeat
            ItemLedgerEntry.CalcFields("Sales Amount (Actual)");
            ActualSalesAmount += ItemLedgerEntry."Sales Amount (Actual)";
        until ItemLedgerEntry.Next() = 0;

        Assert.AreNearlyEqual(Abs(CalcSalesAmount), Abs(ActualSalesAmount), GeneralLedgerSetup."Amount Rounding Precision",
          ErrAmountsMustBeSame);
    end;

    [Normal]
    local procedure VerifyCustLedgerEntry(var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Verify Amount from Customer Ledger Entry.
        SalesCrMemoHeader.SetRange("External Document No.", SalesHeader."External Document No.");
        SalesCrMemoHeader.FindFirst();
        CustLedgerEntry.SetRange("Document No.", SalesCrMemoHeader."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(-CalcCustCrMemoAmount(TempSalesLine), CustLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          ErrAmountsMustBeSame);
    end;

    [Normal]
    local procedure CalcCustCrMemoAmount(var TempSalesLine: Record "Sales Line" temporary) TotalAmountIncVAT: Decimal
    begin
        TempSalesLine.FindSet();
        repeat
            TotalAmountIncVAT +=
              TempSalesLine.Quantity * TempSalesLine."Unit Price" +
              (TempSalesLine.Quantity * TempSalesLine."Unit Price" * (TempSalesLine."VAT %" / 100));
        until TempSalesLine.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CorrectedInvoiceNoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MsgCorrectedInvoiceNo) > 0, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure ExecuteConfirmHandler()
    begin
        if Confirm(MsgCorrectedInvoiceNo) then;
    end;
}

