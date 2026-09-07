codeunit 137002 "SCM WIP Costing Addnl Currency"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [ACY] [SCM]
        isInitialized := false;
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('AdjustAddnlCurrReportHandler')]
    [Scope('OnPrem')]
    procedure WIPAddnlReportingCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        ItemJournalBatch: Record "Item Journal Batch";
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Verify correct conversion for additional reporting currency when adjusting Item.

        // [GIVEN] Posted Purchase Order with Item having costing method Standard, Released Production Order created and refreshed.
        Initialize();

        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(false);
        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAverageCostSetup("Average Cost Calculation Type"::Item, "Average Cost Period Type"::Day);

        LibraryERM.SetAddReportingCurrency('');

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, CreateItem(Item."Costing Method"::Standard));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ProductionOrderNo := CreateRelProductionOrder(PurchaseLine);
        RefreshRelProductionOrder(ProductionOrderNo, false);

        // [GIVEN] Consumption and Output Journals posted.
        CreateItemJournal(ItemJournalBatch, PurchaseLine, ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        CreateItemJournal(ItemJournalBatch, PurchaseLine, ItemJournalBatch."Template Type"::Output, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [WHEN] Adjust Addnl. Reporting Currency report executed after update of Addnl. Reporting Currency on G/L Setup.
        // [WHEN] Adjust Cost Item Entries report is run.
        UpdateAddnlReportingCurrency(CurrencyExchangeRate, Currency);
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // [THEN] Amount & Additional-Currency Amount in G/L Entry for Inventory & WIP Accounts are correct.
        VerifyInvtWIPAmntGLEntry(CurrencyExchangeRate, Currency."Amount Rounding Precision", PurchaseLine."No.");
    end;

    [Test]
    procedure PurchaseInACYUsesDocumentAmountForValueEntryACY()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        AddReportingCurrencyCode: Code[10];
        DocumentNo: Code[20];
        ExpectedCostAmountACY: Decimal;
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [ACY] [Purchase] [AI test 0.4]
        // [SCENARIO] Value Entry ACY cost uses the document Additional Reporting Currency amount directly instead of reconverting it from LCY when the purchase currency equals the Additional Reporting Currency, so it reconciles with the G/L Entry Additional-Currency Amount.
        Initialize();

        // [GIVEN] Automatic cost posting to the inventory account is enabled and expected cost posting is disabled.
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(false);

        // [GIVEN] Currency "C" is the Additional Reporting Currency. Exchange rate 3 is used because 1/3 is non-terminating, so a naive ACY -> LCY -> ACY round-trip drops a cent.
        ExchangeRate := LibraryRandom.RandIntInRange(3, 3);
        AddReportingCurrencyCode := CreateAddReportingCurrency(ExchangeRate);

        // [GIVEN] An Average costing Item and a Vendor invoicing in the Additional Reporting Currency "C".
        CreateAverageCostItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", AddReportingCurrencyCode);
        Vendor.Modify(true);

        // [GIVEN] A purchase invoice whose Quantity and Direct Unit Cost are each one above a multiple of the exchange rate, so the ACY line amount is never divisible by it and ACY -> LCY rounding always leaves a remainder.
        Quantity := LibraryRandom.RandInt(5) * ExchangeRate + 1;
        DirectUnitCost := LibraryRandom.RandInt(20) * ExchangeRate + 1;
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] The purchase invoice is posted.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The Value Entry "Cost Amount (Actual) (ACY)" equals the exact document ACY amount, not the value obtained by reconverting the rounded LCY amount back to "C".
        ExpectedCostAmountACY := DirectUnitCost * Quantity;
        VerifyValueEntryCostAmountACY(Item."No.", DocumentNo, ExpectedCostAmountACY);

        // [THEN] The Inventory Account G/L Entry "Additional-Currency Amount" matches the Value Entry ACY amount, so Value Entries and G/L Entries reconcile.
        FindInventoryAccount(InventoryPostingSetup, Item);
        VerifyGLEntryAddnlCurrencyAmount(InventoryPostingSetup."Inventory Account", DocumentNo, ExpectedCostAmountACY);
    end;

    [Test]
    procedure PurchaseReceiptInACYUsesDocumentAmountForExpectedValueEntryACY()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        AddReportingCurrencyCode: Code[10];
        DocumentNo: Code[20];
        ExpectedCostAmountACY: Decimal;
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [ACY] [Purchase] [Expected Cost] [AI test 0.4]
        // [SCENARIO] Value Entry expected ACY cost uses the document Additional Reporting Currency amount directly instead of reconverting it from LCY when a purchase receipt is posted with expected cost posting enabled and the purchase currency equals the Additional Reporting Currency, so it reconciles with the interim G/L Entry Additional-Currency Amount before invoicing.
        Initialize();

        // [GIVEN] Automatic cost posting and expected cost posting to the interim inventory account are both enabled.
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(true);

        // [GIVEN] Currency "C" is the Additional Reporting Currency. Exchange rate 3 is used because 1/3 is non-terminating, so a naive ACY -> LCY -> ACY round-trip drops a cent.
        ExchangeRate := LibraryRandom.RandIntInRange(3, 3);
        AddReportingCurrencyCode := CreateAddReportingCurrency(ExchangeRate);

        // [GIVEN] An Average costing Item and a Vendor invoicing in the Additional Reporting Currency "C".
        CreateAverageCostItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", AddReportingCurrencyCode);
        Vendor.Modify(true);

        // [GIVEN] A purchase order whose Quantity and Direct Unit Cost are each one above a multiple of the exchange rate, so the ACY line amount is never divisible by it and ACY -> LCY rounding always leaves a remainder.
        Quantity := LibraryRandom.RandInt(5) * ExchangeRate + 1;
        DirectUnitCost := LibraryRandom.RandInt(20) * ExchangeRate + 1;
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] The purchase order is received but not invoiced, so only the expected cost is posted.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The Value Entry "Cost Amount (Expected) (ACY)" equals the exact document ACY amount, not the value obtained by reconverting the rounded LCY amount back to "C".
        ExpectedCostAmountACY := DirectUnitCost * Quantity;
        VerifyValueEntryExpectedCostAmountACY(Item."No.", DocumentNo, ExpectedCostAmountACY);

        // [THEN] The interim Inventory Account G/L Entry "Additional-Currency Amount" matches the Value Entry expected ACY amount, so Value Entries and G/L Entries reconcile before invoicing.
        FindInventoryAccount(InventoryPostingSetup, Item);
        VerifyGLEntryAddnlCurrencyAmount(InventoryPostingSetup."Inventory Account (Interim)", DocumentNo, ExpectedCostAmountACY);
    end;

    [Test]
    procedure ItemChargeInACYReconcilesValueEntryAndGLEntryACY()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        ItemPurchaseLine: Record "Purchase Line";
        ChargePurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
        AddReportingCurrencyCode: Code[10];
        DocumentNo: Code[20];
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        ChargeUnitCost: Decimal;
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [ACY] [Purchase] [Item Charge]
        // [SCENARIO] An item charge is excluded from the document-amount ACY shortcut (guard requires an empty Item Charge No.), so its Value Entry ACY is still derived from LCY. This verifies that item charges purchased in the Additional Reporting Currency continue to reconcile: the summed Value Entry "Cost Amount (Actual) (ACY)" equals the summed Inventory Account G/L Entry "Additional-Currency Amount".
        Initialize();

        // [GIVEN] Automatic cost posting to the inventory account is enabled and expected cost posting is disabled.
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(false);

        // [GIVEN] Currency "C" is the Additional Reporting Currency. Exchange rate 3 is used because 1/3 is non-terminating, so a naive ACY -> LCY -> ACY round-trip drops a cent.
        ExchangeRate := LibraryRandom.RandIntInRange(3, 3);
        AddReportingCurrencyCode := CreateAddReportingCurrency(ExchangeRate);

        // [GIVEN] An Average costing Item and a Vendor invoicing in the Additional Reporting Currency "C".
        CreateAverageCostItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", AddReportingCurrencyCode);
        Vendor.Modify(true);

        // [GIVEN] A purchase order in "C" with an item line and an item charge line assigned to that item line, each amount one above a multiple of the exchange rate so ACY -> LCY rounding always leaves a remainder.
        Quantity := LibraryRandom.RandInt(5) * ExchangeRate + 1;
        DirectUnitCost := LibraryRandom.RandInt(20) * ExchangeRate + 1;
        ChargeUnitCost := LibraryRandom.RandInt(20) * ExchangeRate + 1;
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(ItemPurchaseLine, PurchaseHeader, ItemPurchaseLine.Type::Item, Item."No.", Quantity);
        ItemPurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        ItemPurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          ChargePurchaseLine, PurchaseHeader, ChargePurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        ChargePurchaseLine.Validate("Direct Unit Cost", ChargeUnitCost);
        ChargePurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, ChargePurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.",
          ItemPurchaseLine."Line No.", Item."No.");

        // [WHEN] The purchase order is received and invoiced.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The summed Value Entry "Cost Amount (Actual) (ACY)" (item plus charge) reconciles with the summed Inventory Account G/L Entry "Additional-Currency Amount", so excluding item charges from the shortcut does not break reconciliation.
        FindInventoryAccount(InventoryPostingSetup, Item);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.CalcSums("Cost Amount (Actual) (ACY)");
        VerifyGLEntryAddnlCurrencyAmount(
          InventoryPostingSetup."Inventory Account", DocumentNo, ValueEntry."Cost Amount (Actual) (ACY)");
    end;

    [Test]
    procedure PurchaseInACYWithNonBaseUoMKeepsUnitCostRoundingResidualOnBothLegs()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AddReportingCurrencyCode: Code[10];
        ReceiptDocumentNo: Code[20];
        InvoiceDocumentNo: Code[20];
        ExpectedCostAmountACY: Decimal;
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        QtyPerUnitOfMeasure: Decimal;
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [ACY] [Purchase] [Expected Cost] [Unit of Measure] [AI test 0.4]
        // [SCENARIO] When the purchase currency equals the Additional Reporting Currency and the purchase unit of measure holds more than one base unit, the per-base-unit ACY unit cost must be rounded, which drops a residual. Both the expected (receipt) and the actual (invoice) Value Entry ACY amounts must still equal the exact document ACY amount, so neither leg drifts by the dropped residual.
        Initialize();

        // [GIVEN] Automatic cost posting and expected cost posting are both enabled, so the receipt posts an expected ACY cost that is later reversed and replaced by the actual ACY cost on invoicing.
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(true);

        // [GIVEN] Currency "C" is the Additional Reporting Currency with a coarse 0.01 Unit-Amount Rounding Precision, so rounding the per-base-unit ACY cost drops a residual larger than the 0.01 Amount Rounding Precision and a dropped residual is visible on the Value Entry. The exchange rate only affects LCY conversion, not the ACY amount, so it can be random.
        ExchangeRate := LibraryRandom.RandIntInRange(2, 10);
        AddReportingCurrencyCode := CreateAddReportingCurrencyWithUnitAmountPrecision(ExchangeRate, 0.01);

        // [GIVEN] An Average costing Item and a Vendor invoicing in the Additional Reporting Currency "C".
        CreateAverageCostItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", AddReportingCurrencyCode);
        Vendor.Modify(true);

        // [GIVEN] A purchase unit of measure holding a random multiple of 3 base units, so 1/(base-unit count) stays a non-terminating decimal (a factor of 3 never clears against the 2s and 5s of the rounding precision).
        QtyPerUnitOfMeasure := 3 * LibraryRandom.RandIntInRange(1, 5);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUnitOfMeasure);

        // [GIVEN] A purchase order for a random number of that unit of measure at a random unit cost that is never divisible by the base-unit count, so the per-base-unit ACY cost is a repeating decimal that rounds and drops a residual on each base unit.
        Quantity := LibraryRandom.RandIntInRange(2, 10);
        DirectUnitCost := QtyPerUnitOfMeasure * LibraryRandom.RandIntInRange(2, 10) + 1;
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] The purchase order is received but not invoiced, so only the expected cost is posted.
        ReceiptDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The Value Entry "Cost Amount (Expected) (ACY)" equals the exact document ACY amount, with the residual folded back in.
        ExpectedCostAmountACY := DirectUnitCost * Quantity;
        VerifyValueEntryExpectedCostAmountACY(Item."No.", ReceiptDocumentNo, ExpectedCostAmountACY);

        // [WHEN] The same purchase order is invoiced separately.
        PurchaseHeader.Find();
        InvoiceDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] The Value Entry "Cost Amount (Actual) (ACY)" also equals the exact document ACY amount, so the actual leg reconstructs the residual exactly as the expected leg does instead of dropping it.
        VerifyValueEntryCostAmountACY(Item."No.", InvoiceDocumentNo, ExpectedCostAmountACY);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM WIP Costing Addnl Currency");
        // Initialize setup.
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM WIP Costing Addnl Currency");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateInventoryPostingSetup(); // NAVCZ
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM WIP Costing Addnl Currency");
    end;

    [Normal]
    local procedure CreateItem(ItemCostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandInt(10), Item."Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", '', '');
        exit(Item."No.");
    end;

    [Normal]
    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]): Code[20]
    begin
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo);
    end;

    [Normal]
    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        // Create Purchase Header with a selected Vendor No. and a random Vendor Invoice No.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
    end;

    [Normal]
    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        // Create Purchase Line with a random Item Quantity.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    [Normal]
    local procedure CreateRelProductionOrder(PurchaseLine: Record "Purchase Line"): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, PurchaseLine."No.", PurchaseLine.Quantity);
        ProductionOrder.Validate("Starting Time", Time);
        ProductionOrder.Validate("Due Date", WorkDate());
        ProductionOrder.Modify(true);
        exit(ProductionOrder."No.");
    end;

    [Normal]
    local procedure RefreshRelProductionOrder(ProductionOrderNo: Code[20]; Direction: Boolean)
    var
        ProductionOrder: Record "Production Order";
    begin
        // Refresh Released Production Order with False for Direction Backward.
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("No.", ProductionOrderNo);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, Direction, true, true, true, false);
    end;

    [Normal]
    local procedure CreateItemJournal(var ItemJournalBatch: Record "Item Journal Batch"; PurchaseLine: Record "Purchase Line"; ItemJournalTemplateType: Enum "Item Journal Template Type"; ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Create Journals for Consumption and Output.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        CreateConsumptionOutputJournal(ItemJournalLine, PurchaseLine, ItemJournalTemplate, ItemJournalBatch, ProductionOrderNo);
    end;

    [Normal]
    local procedure CreateConsumptionOutputJournal(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch"; ProductionOrderNo: Code[20])
    begin
        // Create Consumption Journal or Output Journal depending on the Entry type.
        if ItemJournalTemplate.Type = ItemJournalTemplate.Type::Consumption then
            ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Consumption
        else
            ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Output;

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type",
          PurchaseLine."No.", PurchaseLine.Quantity);

        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProductionOrderNo);
        if ItemJournalTemplate.Type = ItemJournalTemplate.Type::Output then begin
            ItemJournalLine.Validate("Output Quantity", PurchaseLine.Quantity);
            ItemJournalLine.Validate("Source No.", ProductionOrderNo);
            ItemJournalLine.Validate("Order Line No.", ItemJournalLine."Line No.");
        end;
        ItemJournalLine.Modify(true);
    end;

    [Normal]
    local procedure UpdateAddnlReportingCurrency(var CurrencyExchangeRate: Record "Currency Exchange Rate"; var Currency: Record Currency)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        // Set Residual Gains Account and Residual Losses Account for Currency.
        UpdateResidualAccountsCurrency(CurrencyExchangeRate, Currency);
        Commit();

        // Update Additional Reporting Currency on G/L setup to execute Adjust Additional Reporting Currency report.
        GLSetup.Get();
        GLSetup.Validate("Journal Templ. Name Mandatory", false);
        GLSetup.Modify();
        Commit();
        GLSetup.Validate("Additional Reporting Currency", Currency.code);
        GLSetup.Modify();
    end;

    [Normal]
    local procedure UpdateResidualAccountsCurrency(var CurrencyExchangeRate: Record "Currency Exchange Rate"; var Currency: Record Currency)
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();
        // Update Residual Gains Account and Residual Losses Account for the selected Currency.
        Currency.Validate("Residual Gains Account", SelectGLAccountNo());
        Currency.Validate("Residual Losses Account", SelectGLAccountNo());
        Currency.Modify(true);
    end;

    local procedure SelectGLAccountNo(): Code[10]
    var
        GLAccount: Record "G/L Account";
    begin
        // Select Account from General Ledger Account of type Posting.
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.FindFirst();
        exit(GLAccount."No.");
    end;

    [Normal]
    local procedure VerifyInvtWIPAmntGLEntry(CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyAmntRoundingPrecision: Decimal; ItemNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();

        // Select Quantity posted from Consumption Journal.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindLast();

        // Select Inventory Account and Check Amounts for Inventory Account.
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."Inventory Account");
        GLEntry.FindLast();
        CheckGLEntryAmnt(GLEntry, ItemNo, ItemLedgerEntry.Quantity);
        CheckGLEntryAddnlCurrencyAmnt(CurrencyAmntRoundingPrecision, CurrencyExchangeRate, GLEntry);

        // Select WIP Account Check Amounts for WIP Account.
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."WIP Account");
        GLEntry.FindLast();
        CheckGLEntryAmnt(GLEntry, ItemNo, Abs(ItemLedgerEntry.Quantity));
        CheckGLEntryAddnlCurrencyAmnt(CurrencyAmntRoundingPrecision, CurrencyExchangeRate, GLEntry);
    end;

    [Normal]
    local procedure CheckGLEntryAmnt(GLEntry: Record "G/L Entry"; ItemNo: Code[20]; ItemLedgerEntryQuantity: Integer)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);

        // Check the generated amount and calculated Amount are equal.
        GLEntry.TestField(Amount, Item."Standard Cost" * ItemLedgerEntryQuantity);
    end;

    [Normal]
    local procedure CheckGLEntryAddnlCurrencyAmnt(CurrencyAmntRoundingPrecision: Decimal; CurrencyExchangeRate: Record "Currency Exchange Rate"; GLEntry: Record "G/L Entry")
    begin
        // Check the generated Additional Currency Amount and calculated Additional-Currency Amount are equal.
        GLEntry.TestField(
          "Additional-Currency Amount",
          Round(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount" *
            GLEntry.Amount,
            CurrencyAmntRoundingPrecision));
    end;

    local procedure CreateAddReportingCurrency(ExchangeRate: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), ExchangeRate, ExchangeRate);
        Currency.Validate("Amount Rounding Precision", 0.01);
        Currency.Validate("Unit-Amount Rounding Precision", 0.00001);
        Currency.Modify(true);
        LibraryERM.SetAddReportingCurrency(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAddReportingCurrencyWithUnitAmountPrecision(ExchangeRate: Decimal; UnitAmountRoundingPrecision: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), ExchangeRate, ExchangeRate);
        Currency.Validate("Amount Rounding Precision", 0.01);
        Currency.Validate("Unit-Amount Rounding Precision", UnitAmountRoundingPrecision);
        Currency.Modify(true);
        LibraryERM.SetAddReportingCurrency(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAverageCostItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);
    end;

    local procedure FindInventoryAccount(var InventoryPostingSetup: Record "Inventory Posting Setup"; Item: Record Item)
    begin
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();
    end;

    local procedure VerifyValueEntryCostAmountACY(ItemNo: Code[20]; DocumentNo: Code[20]; ExpectedCostAmountACY: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.CalcSums("Cost Amount (Actual) (ACY)");
        Assert.AreEqual(
          ExpectedCostAmountACY, ValueEntry."Cost Amount (Actual) (ACY)",
          ValueEntry.FieldCaption("Cost Amount (Actual) (ACY)"));
    end;

    local procedure VerifyValueEntryExpectedCostAmountACY(ItemNo: Code[20]; DocumentNo: Code[20]; ExpectedCostAmountACY: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.CalcSums("Cost Amount (Expected) (ACY)");
        Assert.AreEqual(
          ExpectedCostAmountACY, ValueEntry."Cost Amount (Expected) (ACY)",
          ValueEntry.FieldCaption("Cost Amount (Expected) (ACY)"));
    end;

    local procedure VerifyGLEntryAddnlCurrencyAmount(GLAccountNo: Code[20]; DocumentNo: Code[20]; ExpectedAddnlCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        ActualAddnlCurrencyAmount: Decimal;
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            ActualAddnlCurrencyAmount += GLEntry."Additional-Currency Amount";
        until GLEntry.Next() = 0;
        Assert.AreEqual(
          ExpectedAddnlCurrencyAmount, ActualAddnlCurrencyAmount,
          GLEntry.FieldCaption("Additional-Currency Amount"));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AdjustAddnlCurrConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm Handler: Set Reply to True to select the Yes button.
        Reply := true;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure AdjustAddnlCurrReportHandler(var AdjustAddReportingCurrency: Report "Adjust Add. Reporting Currency")
    begin
        // Report Handler: Update request form with random Document No, Retained Earnings Account and run the
        // Adjust Additional Reporting Currency report.
        AdjustAddReportingCurrency.InitializeRequest(Format(LibraryRandom.RandInt(100)), SelectGLAccountNo());
        AdjustAddReportingCurrency.UseRequestPage(false);
        AdjustAddReportingCurrency.Run();
    end;
}

