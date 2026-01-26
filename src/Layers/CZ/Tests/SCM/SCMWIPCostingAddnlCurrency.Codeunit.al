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
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('AdjustAddnlCurrConfirmHandler,AdjustAddnlCurrReportHandler')]
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
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // Set Residual Gains Account and Residual Losses Account for Currency.
        UpdateResidualAccountsCurrency(CurrencyExchangeRate, Currency);
        Commit();

        // Update Additional Reporting Currency on G/L setup to execute Adjust Additional Reporting Currency report.
        GeneralLedgerSetup.OpenEdit();
        GeneralLedgerSetup."Additional Reporting Currency".SetValue(Currency.Code);
        GeneralLedgerSetup.OK().Invoke();
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

