codeunit 137018 "SCM Adjmt. of Expected Cost"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Automatic Cost Adjustment] [Expected Cost] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        GLEntryTotalMismatchErr: Label 'GL Entry total for account %1 is %2, expected %3.', Comment = '%1 = G/L Account No., %2 = Actual Amount, %3 = Expected Amount';

    [Test]
    [Scope('OnPrem')]
    procedure VSTF324950()
    var
        Item: Record Item;
        OldInventorySetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ValueEntry: Record "Value Entry";
        Qty: Decimal;
    begin
        Initialize();
        Qty := 100;
        // Inventory setup for test
        OldInventorySetup.Get();
        SetInventorySetup(
          OldInventorySetup, true, true, true,
          OldInventorySetup."Automatic Cost Adjustment"::Always);

        // make item
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, 0);

        // purchase
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty, WorkDate(), 10, true, false);

        // Sales order - shipment only
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty, WorkDate(), 0, true, false);

        // Now invoice of sales order
        PartialInvoiceOfSales(SalesHeader, Qty / 4);

        PurchaseOrderWithItemCharge(PurchaseHeader, 100);
        PurchaseOrderWithItemCharge(PurchaseHeader, 200);

        // Now invoice of sales order
        PartialInvoiceOfSales(SalesHeader, Qty / 4);

        // verify correct ValueEntries
        VerifyValueEntries(ValueEntry, 75);
        VerifyValueEntries(ValueEntry, 250);

        // restore Inventory Setup
        SetInventorySetup(
          OldInventorySetup, false,
          OldInventorySetup."Automatic Cost Posting",
          OldInventorySetup."Expected Cost Posting to G/L", OldInventorySetup."Automatic Cost Adjustment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThreePartialReceiptsGLEntryTotalIsExact()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Item: Record Item;
        OldInventorySetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ActualTotalAmount: Decimal;
        ExpectedTotalAmount: Decimal;
        Receipt1Qty: Decimal;
        Receipt2Qty: Decimal;
        Receipt3Qty: Decimal;
        TotalQty: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 626698] GL Entry total for interim accounts equals exact line amount after 3 partial receipts.
        Initialize();

        // [GIVEN] Inventory Setup with Automatic Cost Posting and Expected Cost Posting to G/L enabled.
        OldInventorySetup.Get();
        SetInventorySetup(
            OldInventorySetup, true, true, true,
            OldInventorySetup."Automatic Cost Adjustment"::Never);

        // [GIVEN] Item "I" with FIFO costing method
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Cost is Adjusted", false);
        Item.Validate("Allow Online Adjustment", false);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Modify(true);

        // [GIVEN] Create new interim accounts.
        InventoryPostingSetup.Get('', Item."Inventory Posting Group");
        if InventoryPostingSetup."Inventory Account (Interim)" = '' then begin
            LibraryERM.CreateGLAccount(GLAccount);
            InventoryPostingSetup.Validate("Inventory Account (Interim)", GLAccount."No.");
            InventoryPostingSetup.Modify(true);
        end;

        // [GIVEN] Purchase Order "PO" with Quantity = 100 and Direct Unit Cost = 500 (Total = 50000).
        TotalQty := 100;
        UnitCost := 500;
        ExpectedTotalAmount := TotalQty * UnitCost;
        Receipt1Qty := 33.33333;
        Receipt2Qty := 33.33333;
        Receipt3Qty := 33.33334;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", TotalQty);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] Post 3 partial receipts: 33.33333 + 33.33333 + 33.33334 = 100.
        PurchaseLine.Validate("Qty. to Receive", Receipt1Qty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchaseHeader.Find();
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", Receipt2Qty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        PurchaseHeader.Find();
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", Receipt3Qty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Total GL Entry Amount for Inventory (Interim) account = 50000 (not 50000.01).
        GLEntry.Reset();
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."Inventory Account (Interim)");
        GLEntry.SetFilter("Document No.", GetPurchRcptDocNoFilter(PurchaseHeader."No."));
        GLEntry.CalcSums(Amount);
        ActualTotalAmount := GLEntry.Amount;
        Assert.AreEqual(
            ExpectedTotalAmount, ActualTotalAmount,
            StrSubstNo(GLEntryTotalMismatchErr, InventoryPostingSetup."Inventory Account (Interim)", ActualTotalAmount, ExpectedTotalAmount));

        // Teardown
        SetInventorySetup(
            OldInventorySetup, false,
            OldInventorySetup."Automatic Cost Posting",
            OldInventorySetup."Expected Cost Posting to G/L",
            OldInventorySetup."Automatic Cost Adjustment");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Adjmt. of Expected Cost");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Adjmt. of Expected Cost");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Adjmt. of Expected Cost");
    end;

    local procedure SetInventorySetup(InventorySetup: Record "Inventory Setup"; NewSetup: Boolean; AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        SavedInventorySetup: Record "Inventory Setup";
    begin
        if NewSetup then begin
            InventorySetup."Automatic Cost Posting" := AutomaticCostPosting;
            InventorySetup."Expected Cost Posting to G/L" := ExpectedCostPosting;
            InventorySetup."Automatic Cost Adjustment" := AutomaticCostAdjustment;
            InventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type"::Item;
            InventorySetup."Average Cost Period" := InventorySetup."Average Cost Period"::Day;
        end else begin
            SavedInventorySetup.Get();
            SavedInventorySetup."Automatic Cost Posting" := AutomaticCostPosting;
            SavedInventorySetup."Expected Cost Posting to G/L" := ExpectedCostPosting;
            SavedInventorySetup."Automatic Cost Adjustment" := AutomaticCostAdjustment;
            SavedInventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type";
            SavedInventorySetup."Average Cost Period" := InventorySetup."Average Cost Period";
            InventorySetup := SavedInventorySetup;
        end;
        InventorySetup.Modify();
        CODEUNIT.Run(CODEUNIT::"Change Average Cost Setting", InventorySetup);
    end;

    local procedure PartialInvoiceOfSales(var SalesHeader: Record "Sales Header"; QuantityToInv: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Invoice", QuantityToInv);
        SalesLine.Modify();

        SalesHeader.Find('=');
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure PurchaseOrderWithItemCharge(var PurchaseHeader: Record "Purchase Header"; DirectUnitCost: Decimal)
    var
        PurchaseHeaderItemCharge: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");

        PurchRcptLine.SetCurrentKey("Buy-from Vendor No.");
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindFirst();

        // Purchase Order for Item Charge
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderItemCharge, PurchaseHeader."Document Type", Vendor."No.");

        // Line for Item Charge
        LibraryPurchase.ASSIGNPurchChargeToPurchRcptLine(PurchaseHeaderItemCharge, PurchRcptLine, 1, DirectUnitCost);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderItemCharge, true, true);
    end;

    local procedure VerifyValueEntries(var ValueEntry: Record "Value Entry"; EntryCost: Decimal)
    begin
        // last value entry has to have Cost Amount Expected = 75, Cost Amount Actual has to equal -75
        // previous value entry has to have Cost Amount Expected = 250, Cost Amount Actual has to equal -250
        if ValueEntry."Entry No." = 0 then
            ValueEntry.FindLast()
        else
            ValueEntry.Get(ValueEntry."Entry No." - 1);

        Assert.AreEqual(EntryCost, ValueEntry."Cost Amount (Expected)", '');
        Assert.AreEqual(-EntryCost, ValueEntry."Cost Amount (Actual)", '');
    end;

    local procedure GetPurchRcptDocNoFilter(OrderNo: Code[20]): Text
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        DocNoFilter: Text;
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        if PurchRcptHeader.FindSet() then
            repeat
                if DocNoFilter <> '' then
                    DocNoFilter += '|';
                DocNoFilter += PurchRcptHeader."No.";
            until PurchRcptHeader.Next() = 0;
        exit(DocNoFilter);
    end;
}

