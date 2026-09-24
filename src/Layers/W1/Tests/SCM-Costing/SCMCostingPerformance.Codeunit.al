codeunit 133504 "SCM Costing Performance"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Performance]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        LibraryCalcComplexity: Codeunit "Library - Calc. Complexity";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        NotLinearCCErr: Label 'Computational cost is not linear.';
        NotConstantCCErr: Label 'Computational cost must be constant.';
        OrderSelectionSubscriberFilter: Code[20];
        SelectionItemsForSubscriber: List of [Code[20]];
        SelectionReplacementItemNo: Code[20];
        SharedInboundItemNo: Code[20];
        SharedInboundVisits: Integer;
        SharedInboundEntryNos: Dictionary of [Integer, Boolean];

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Costing Performance");

        LibraryVariableStorage.Clear();
        Clear(OrderSelectionSubscriberFilter);
        Clear(SelectionItemsForSubscriber);
        Clear(SelectionReplacementItemNo);
        Clear(SharedInboundItemNo);
        Clear(SharedInboundVisits);
        Clear(SharedInboundEntryNos);
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SharedInboundCostInputsStayFresh()
    var
        Item: Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ValueEntry: Record "Value Entry";
        EntryCount: Integer;
        Measurement: Text;
    begin
        // [SCENARIO] Sales sharing a receipt receive later item charges, and another adjustment is idempotent.
        Initialize();
        Measurement := MeasureSharedInboundCostInputs(Item, PurchRcptLine, 5, 2);
        Assert.IsTrue(SharedInboundVisits > SharedInboundEntryNos.Count(),
            'The fixture must exercise repeated inbound cost inputs. ' + Measurement);

        PostSharedInboundItemCharge(PurchRcptLine, 1);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        VerifySharedInboundCosts(Item, 5, 5);

        ValueEntry.SetRange("Item No.", Item."No.");
        EntryCount := ValueEntry.Count();
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        Assert.AreEqual(EntryCount, ValueEntry.Count(), 'An unchanged adjustment must not add value entries.');
        VerifySharedInboundCosts(Item, 5, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SharedInboundCostInputsAcrossFanOut()
    var
        Item: Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        Initialize();
        MeasureSharedInboundCostInputs(Item, PurchRcptLine, 5, 1);
        MeasureSharedInboundCostInputs(Item, PurchRcptLine, 20, 1);
        MeasureSharedInboundCostInputs(Item, PurchRcptLine, 20, 10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SharedInboundCostInputsIncludeNegativeCorrection()
    var
        Item: Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        Initialize();
        MeasureSharedInboundCostInputs(Item, PurchRcptLine, 5, 2);

        PostSharedInboundItemCharge(PurchRcptLine, -1);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        VerifySharedInboundCosts(Item, 5, 3);
    end;

    local procedure MeasureSharedInboundCostInputs(var Item: Record Item; var PurchRcptLine: Record "Purch. Rcpt. Line"; SaleCount: Integer; ChargeCount: Integer): Text
    var
        PurchaseHeader: Record "Purchase Header";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        InventorySetup: Record "Inventory Setup";
        EntryIndex: Integer;
        StatementsBefore: BigInteger;
        RowsBefore: BigInteger;
        StatementCount: BigInteger;
        RowCount: BigInteger;
        StartedAt: DateTime;
        Elapsed: Duration;
    begin
        LibraryInventory.SetAutomaticCostAdjmtNever();
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", false);
        InventorySetup.Modify(true);
        CreateItem(Item, Item."Costing Method"::FIFO);
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', SaleCount + 1, WorkDate(), 2, true, true);
        PurchRcptLine.Reset();
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindLast();
        for EntryIndex := 1 to SaleCount do
            LibraryInventory.PostItemJournalLine(
                ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Sale, Item, '', '', '', 1, WorkDate(), 10);
        for EntryIndex := 1 to ChargeCount do
            PostSharedInboundItemCharge(PurchRcptLine, 1);

        SharedInboundItemNo := Item."No.";
        Clear(SharedInboundVisits);
        Clear(SharedInboundEntryNos);
        BindSubscription(this);
        SelectLatestVersion();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
        StartedAt := CurrentDateTime();
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        Elapsed := CurrentDateTime() - StartedAt;
        RowCount := SessionInformation.SqlRowsRead() - RowsBefore;
        StatementCount := SessionInformation.SqlStatementsExecuted() - StatementsBefore;
        UnbindSubscription(this);

        VerifySharedInboundCosts(Item, SaleCount, 2 + ChargeCount);
        Assert.IsTrue(SharedInboundEntryNos.Count() >= ChargeCount + 1, 'Receipt and charge inputs must be observed.');
        Assert.AreEqual(SaleCount * (ChargeCount + 1), SharedInboundVisits,
            'The per-entry extension hook must observe every applicable receipt and charge input for every sale.');
        exit(StrSubstNo('Sales=%1, charges=%2, SQL statements=%3, SQL rows=%4, source visits=%5, distinct inputs=%6, ms=%7; ',
            SaleCount, ChargeCount, StatementCount, RowCount, SharedInboundVisits, SharedInboundEntryNos.Count(), Elapsed / 1));
    end;

    local procedure PostSharedInboundItemCharge(PurchRcptLine: Record "Purch. Rcpt. Line"; DirectUnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentType: Enum "Purchase Document Type";
    begin
        if DirectUnitCost < 0 then
            DocumentType := PurchaseHeader."Document Type"::"Credit Memo"
        else
            DocumentType := PurchaseHeader."Document Type"::Invoice;
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, DocumentType, PurchRcptLine."Buy-from Vendor No.");
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(PurchaseHeader, PurchRcptLine, PurchRcptLine.Quantity, Abs(DirectUnitCost));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure VerifySharedInboundCosts(var Item: Record Item; SaleCount: Integer; ExpectedUnitCost: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        Assert.AreEqual(SaleCount, ItemLedgerEntry.Count(), 'Sale entries');
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
            Assert.AreEqual(-ExpectedUnitCost, ItemLedgerEntry."Cost Amount (Actual)", 'Adjusted sale cost');
            Assert.AreEqual(0, ItemLedgerEntry."Cost Amount (Expected)", 'Invoiced sale expected cost');
        until ItemLedgerEntry.Next() = 0;
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        Assert.AreEqual(ExpectedUnitCost, ValueEntry."Cost Amount (Actual)", 'Remaining one-unit inventory value');
        Assert.AreEqual(0, ValueEntry."Cost Amount (Expected)", 'Remaining expected inventory value');
        LibraryCosting.CheckAdjustment(Item);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", 'OnCalcInbndEntryAdjustedCostOnBeforeAddCost', '', false, false)]
    local procedure CountSharedInboundCostInputs(var Item: Record Item; var InbndValueEntry: Record "Value Entry")
    begin
        if Item."No." <> SharedInboundItemNo then
            exit;
        SharedInboundVisits += 1;
        if not SharedInboundEntryNos.ContainsKey(InbndValueEntry."Entry No.") then
            SharedInboundEntryNos.Add(InbndValueEntry."Entry No.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityCostCalculationPreservesCostShares()
    var
        SourceInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CalcInventoryAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
    begin
        // [SCENARIO] Shared routing costs retain subcontracting, overhead, corrections and ACY amounts.
        Initialize();
        CreateCapacityCostFixture(SourceInventoryAdjmtEntryOrder, 4);

        CalcInventoryAdjmtOrder.CalcActualUsageCosts(SourceInventoryAdjmtEntryOrder, 1, InventoryAdjmtEntryOrder);

        VerifyCapacityCostShares(InventoryAdjmtEntryOrder, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityCostCalculationWithoutEntries()
    var
        SourceInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CalcInventoryAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
    begin
        // [SCENARIO] An order without capacity entries has zero capacity cost.
        Initialize();
        CreateCapacityCostFixture(SourceInventoryAdjmtEntryOrder, 0);

        CalcInventoryAdjmtOrder.CalcActualUsageCosts(SourceInventoryAdjmtEntryOrder, 1, InventoryAdjmtEntryOrder);

        VerifyCapacityCostShares(InventoryAdjmtEntryOrder, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityCostCalculationSqlGrowthIsBounded()
    var
        SmallStatementCount: BigInteger;
        MediumStatementCount: BigInteger;
        LargeStatementCount: BigInteger;
    begin
        // [SCENARIO] Reading more capacity entries must not issue FlowField queries for every entry.
        Initialize();
        SmallStatementCount := MeasureCapacityCostCalculation(10);
        MediumStatementCount := MeasureCapacityCostCalculation(50);
        LargeStatementCount := MeasureCapacityCostCalculation(100);

        Assert.IsTrue(
            (MediumStatementCount <= SmallStatementCount + 10) and
            (LargeStatementCount <= SmallStatementCount + 10),
            StrSubstNo('Capacity SQL statements for 10/50/100 entries: %1/%2/%3. Growth must not exceed 10 statements.',
                SmallStatementCount, MediumStatementCount, LargeStatementCount));
    end;

    local procedure MeasureCapacityCostCalculation(EntryCount: Integer): BigInteger
    var
        SourceInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CalcInventoryAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
        StatementCountBefore: BigInteger;
        StatementCount: BigInteger;
    begin
        CreateCapacityCostFixture(SourceInventoryAdjmtEntryOrder, EntryCount);
        SelectLatestVersion();
        StatementCountBefore := SessionInformation.SqlStatementsExecuted();
        CalcInventoryAdjmtOrder.CalcActualUsageCosts(SourceInventoryAdjmtEntryOrder, 1, InventoryAdjmtEntryOrder);
        StatementCount := SessionInformation.SqlStatementsExecuted() - StatementCountBefore;
        VerifyCapacityCostShares(InventoryAdjmtEntryOrder, EntryCount);
        exit(StatementCount);
    end;

    local procedure CreateCapacityCostFixture(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; EntryCount: Integer)
    var
        Item: Record Item;
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ValueEntry: Record "Value Entry";
        CapacityEntryNo: Integer;
        ValueEntryNo: Integer;
        EntryIndex: Integer;
    begin
        LibraryInventory.CreateItem(Item);
        InventoryAdjmtEntryOrder.Init();
        InventoryAdjmtEntryOrder."Order Type" := InventoryAdjmtEntryOrder."Order Type"::Production;
        InventoryAdjmtEntryOrder."Order No." := Item."No.";
        InventoryAdjmtEntryOrder."Order Line No." := 10000;
        InventoryAdjmtEntryOrder."Item No." := Item."No.";
        InventoryAdjmtEntryOrder."Routing No." := 'COST-PERF';
        InventoryAdjmtEntryOrder."Routing Reference No." := 10000;

        CapacityLedgerEntry.LockTable();
        if CapacityLedgerEntry.FindLast() then
            CapacityEntryNo := CapacityLedgerEntry."Entry No.";
        ValueEntry.LockTable();
        if ValueEntry.FindLast() then
            ValueEntryNo := ValueEntry."Entry No.";

        for EntryIndex := 1 to EntryCount do begin
            CapacityEntryNo += 1;
            CapacityLedgerEntry.Init();
            CapacityLedgerEntry."Entry No." := CapacityEntryNo;
            CapacityLedgerEntry."Order Type" := InventoryAdjmtEntryOrder."Order Type";
            CapacityLedgerEntry."Order No." := InventoryAdjmtEntryOrder."Order No.";
            CapacityLedgerEntry."Item No." := InventoryAdjmtEntryOrder."Item No.";
            CapacityLedgerEntry."Routing No." := InventoryAdjmtEntryOrder."Routing No.";
            CapacityLedgerEntry."Routing Reference No." := InventoryAdjmtEntryOrder."Routing Reference No.";
            CapacityLedgerEntry.Subcontracting := EntryIndex mod 2 = 0;
            if CapacityLedgerEntry.Subcontracting then begin
                CapacityLedgerEntry."Order Line No." := 20000;
                CapacityLedgerEntry."Output Quantity" := 3;
            end else begin
                CapacityLedgerEntry."Order Line No." := 10000;
                CapacityLedgerEntry."Output Quantity" := 1;
            end;
            CapacityLedgerEntry.Insert();
            InsertCapacityValueEntry(ValueEntryNo, CapacityEntryNo, ValueEntry."Entry Type"::"Direct Cost", 10);
            InsertCapacityValueEntry(ValueEntryNo, CapacityEntryNo, ValueEntry."Entry Type"::"Direct Cost", -2);
            InsertCapacityValueEntry(ValueEntryNo, CapacityEntryNo, ValueEntry."Entry Type"::"Indirect Cost", 2);
        end;
    end;

    local procedure InsertCapacityValueEntry(var EntryNo: Integer; CapacityEntryNo: Integer; EntryType: Enum "Cost Entry Type"; Amount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        EntryNo += 1;
        ValueEntry.Init();
        ValueEntry."Entry No." := EntryNo;
        ValueEntry."Capacity Ledger Entry No." := CapacityEntryNo;
        ValueEntry."Entry Type" := EntryType;
        ValueEntry."Cost Amount (Actual)" := Amount;
        ValueEntry."Cost Amount (Actual) (ACY)" := Amount * 3;
        ValueEntry.Insert();
    end;

    local procedure VerifyCapacityCostShares(InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; EntryCount: Integer)
    begin
        Assert.AreEqual(EntryCount, InventoryAdjmtEntryOrder."Single-Level Capacity Cost", 'Capacity cost');
        Assert.AreEqual(EntryCount * 3, InventoryAdjmtEntryOrder."Single-Lvl Capacity Cost (ACY)", 'Capacity cost (ACY)');
        Assert.AreEqual(EntryCount, InventoryAdjmtEntryOrder."Single-Level Subcontrd. Cost", 'Subcontracting cost');
        Assert.AreEqual(EntryCount * 3, InventoryAdjmtEntryOrder."Single-Lvl Subcontrd Cost(ACY)", 'Subcontracting cost (ACY)');
        Assert.AreEqual(EntryCount / 2, InventoryAdjmtEntryOrder."Single-Level Cap. Ovhd Cost", 'Capacity overhead cost');
        Assert.AreEqual(EntryCount * 3 / 2, InventoryAdjmtEntryOrder."Single-Lvl Cap. Ovhd Cost(ACY)", 'Capacity overhead cost (ACY)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LedgerCostCalculationPreservesTotalsAndState()
    var
        ValueEntry: Record "Value Entry";
        LastValueEntry: Record "Value Entry";
        TempInventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer" temporary;
        ItemLedgerEntryNo: Integer;
    begin
        // [SCENARIO] Mixed entry types and corrections retain totals, ACY and the last record's identity.
        Initialize();
        CreateLedgerCostFixture(ValueEntry, 12, ItemLedgerEntryNo, LastValueEntry);

        VerifyLedgerCostCalculation(ValueEntry, LastValueEntry, ItemLedgerEntryNo, false, 6);
        VerifyLedgerCostCalculation(ValueEntry, LastValueEntry, ItemLedgerEntryNo, true, 42);

        TempInventoryAdjustmentBuffer."Cost Amount (Actual)" := -3;
        TempInventoryAdjustmentBuffer."Cost Amount (Actual) (ACY)" := -5;
        TempInventoryAdjustmentBuffer."Cost Amount (Expected)" := 7;
        TempInventoryAdjustmentBuffer."Cost Amount (Expected) (ACY)" := 9;
        ValueEntry.AddCost(TempInventoryAdjustmentBuffer);
        Assert.AreEqual(42 * 11 - 3, ValueEntry."Cost Amount (Actual)", 'Buffered actual cost');
        Assert.AreEqual(42 * 13 - 5, ValueEntry."Cost Amount (Actual) (ACY)", 'Buffered actual ACY cost');
        Assert.AreEqual(42 * 17 + 7, ValueEntry."Cost Amount (Expected)", 'Buffered expected cost');
        Assert.AreEqual(42 * 19 + 9, ValueEntry."Cost Amount (Expected) (ACY)", 'Buffered expected ACY cost');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LedgerCostCalculationUsesTemporaryEntries()
    var
        ValueEntry: Record "Value Entry";
        TempValueEntry: Record "Value Entry" temporary;
        LastValueEntry: Record "Value Entry";
        ItemLedgerEntryNo: Integer;
    begin
        // [SCENARIO] Temporary entries are summed without reading persistent entries for the same ledger entry.
        Initialize();
        CreateLedgerCostFixture(ValueEntry, 24, ItemLedgerEntryNo, LastValueEntry);
        CreateLedgerCostFixture(TempValueEntry, 12, ItemLedgerEntryNo, LastValueEntry);

        VerifyLedgerCostCalculation(TempValueEntry, LastValueEntry, ItemLedgerEntryNo, false, 6);
        VerifyLedgerCostCalculation(TempValueEntry, LastValueEntry, ItemLedgerEntryNo, true, 42);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LedgerCostCalculationWithoutMatchingExpectedCost()
    var
        ValueEntry: Record "Value Entry";
        LastValueEntry: Record "Value Entry";
        ItemLedgerEntryNo: Integer;
    begin
        // [SCENARIO] An empty expected-cost subset retains the last entry's other fields and returns zero totals.
        Initialize();
        CreateLedgerCostFixture(ValueEntry, 1, ItemLedgerEntryNo, LastValueEntry);

        VerifyLedgerCostCalculation(ValueEntry, LastValueEntry, ItemLedgerEntryNo, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LedgerCostCalculationWithoutEntries()
    var
        ValueEntry: Record "Value Entry";
        LastValueEntry: Record "Value Entry";
        ItemLedgerEntryNo: Integer;
    begin
        // [SCENARIO] An empty ledger scope zeroes sums without clearing unrelated record fields.
        Initialize();
        CreateLedgerCostFixture(ValueEntry, 0, ItemLedgerEntryNo, LastValueEntry);
        ValueEntry."Entry No." := 123;
        ValueEntry."Document No." := 'PRESERVE';
        ValueEntry."Item Ledger Entry Quantity" := 1;
        ValueEntry."Cost Amount (Actual)" := 2;
        ValueEntry."Cost Amount (Actual) (ACY)" := 3;
        ValueEntry."Cost Amount (Expected)" := 4;
        ValueEntry."Cost Amount (Expected) (ACY)" := 5;
        LastValueEntry := ValueEntry;

        VerifyLedgerCostCalculation(ValueEntry, LastValueEntry, ItemLedgerEntryNo, false, 0);
        VerifyLedgerCostCalculation(ValueEntry, LastValueEntry, ItemLedgerEntryNo, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LedgerCostCalculationSqlRowsAreBounded()
    var
        SmallRows: BigInteger;
        MediumRows: BigInteger;
        LargeRows: BigInteger;
        SmallStatements: BigInteger;
        MediumStatements: BigInteger;
        LargeStatements: BigInteger;
    begin
        // [SCENARIO] Aggregating longer ledger histories transfers bounded rows with bounded statement overhead.
        Initialize();
        MeasureLedgerCostCalculation(12, SmallRows, SmallStatements);
        MeasureLedgerCostCalculation(120, MediumRows, MediumStatements);
        MeasureLedgerCostCalculation(1200, LargeRows, LargeStatements);

        Assert.IsTrue(
            (SmallRows <= 5) and (MediumRows <= 5) and (LargeRows <= 5) and
            (SmallStatements <= 3) and (MediumStatements <= 3) and (LargeStatements <= 3),
            StrSubstNo('Ledger SQL rows for 12/120/1200 entries: %1/%2/%3; statements: %4/%5/%6. Budgets: 5 rows, 3 statements.',
                SmallRows, MediumRows, LargeRows, SmallStatements, MediumStatements, LargeStatements));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LedgerCostCalculationSmallHistorySqlIsBounded()
    var
        RowsRead: BigInteger;
        StatementsExecuted: BigInteger;
        EntryCount: Integer;
    begin
        // [SCENARIO] One- and two-entry histories need at most two statements.
        Initialize();
        for EntryCount := 1 to 2 do begin
            MeasureLedgerCostCalculation(EntryCount, RowsRead, StatementsExecuted);
            Assert.IsTrue(
                (RowsRead <= 3) and (StatementsExecuted <= 2),
                StrSubstNo('Ledger SQL for %1 entries: %2 rows, %3 statements. Budgets: 3 rows, 2 statements.',
                    EntryCount, RowsRead, StatementsExecuted));
        end;
    end;

    local procedure MeasureLedgerCostCalculation(EntryCount: Integer; var RowsRead: BigInteger; var StatementsExecuted: BigInteger)
    var
        ValueEntry: Record "Value Entry";
        LastValueEntry: Record "Value Entry";
        ItemLedgerEntryNo: Integer;
        EntryIndex: Integer;
        ExpectedQuantity: Decimal;
        RowsBefore: BigInteger;
        StatementsBefore: BigInteger;
    begin
        CreateLedgerCostFixture(ValueEntry, EntryCount, ItemLedgerEntryNo, LastValueEntry);
        SelectLatestVersion();
        RowsBefore := SessionInformation.SqlRowsRead();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        ValueEntry.CalcItemLedgEntryCost(ItemLedgerEntryNo, false);
        RowsRead := SessionInformation.SqlRowsRead() - RowsBefore;
        StatementsExecuted := SessionInformation.SqlStatementsExecuted() - StatementsBefore;
        for EntryIndex := 1 to EntryCount do
            case EntryIndex mod 4 of
                1:
                    ExpectedQuantity -= EntryIndex;
                3:
                    ExpectedQuantity += EntryIndex;
            end;
        VerifyLedgerCostAmounts(ValueEntry, ExpectedQuantity);
    end;

    local procedure CreateLedgerCostFixture(var ValueEntry: Record "Value Entry"; EntryCount: Integer; var ItemLedgerEntryNo: Integer; var LastValueEntry: Record "Value Entry")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
        EntryIndex: Integer;
        EntryType: Integer;
        Quantity: Decimal;
    begin
        if ItemLedgerEntryNo = 0 then begin
            ItemLedgerEntry.LockTable();
            if ItemLedgerEntry.FindLast() then
                ItemLedgerEntryNo := ItemLedgerEntry."Entry No.";
            ItemLedgerEntryNo += 1;
            ItemLedgerEntry.Init();
            ItemLedgerEntry."Entry No." := ItemLedgerEntryNo;
            ItemLedgerEntry.Insert();
        end;

        ValueEntry.Reset();
        ValueEntry.LockTable();
        if ValueEntry.FindLast() then
            EntryNo := ValueEntry."Entry No.";
        for EntryIndex := 1 to EntryCount do begin
            Quantity := EntryIndex;
            if EntryIndex mod 4 = 1 then
                Quantity := -Quantity;
            EntryType := EntryIndex mod 7;
            if EntryType = 6 then
                EntryType := 10;
            ValueEntry.Init();
            ValueEntry."Entry No." := EntryNo + EntryIndex;
            ValueEntry."Item Ledger Entry No." := ItemLedgerEntryNo;
            ValueEntry."Entry Type" := Enum::"Cost Entry Type".FromInteger(EntryType);
            ValueEntry."Document No." := Format(EntryIndex);
            ValueEntry."Expected Cost" := EntryIndex mod 2 = 0;
            ValueEntry."Item Ledger Entry Quantity" := Quantity;
            ValueEntry."Cost Amount (Actual)" := Quantity * 11;
            ValueEntry."Cost Amount (Actual) (ACY)" := Quantity * 13;
            ValueEntry."Cost Amount (Expected)" := Quantity * 17;
            ValueEntry."Cost Amount (Expected) (ACY)" := Quantity * 19;
            ValueEntry.Insert();
        end;
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        if ValueEntry.FindLast() then
            LastValueEntry := ValueEntry;
    end;

    local procedure VerifyLedgerCostCalculation(var ValueEntry: Record "Value Entry"; LastValueEntry: Record "Value Entry"; ItemLedgerEntryNo: Integer; Expected: Boolean; ExpectedQuantity: Decimal)
    var
        ExpectedView: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Entry No.");
        ValueEntry.SetRange("Item No.", 'NO-MATCH');
        ValueEntry.CalcItemLedgEntryCost(ItemLedgerEntryNo, Expected);

        VerifyLedgerCostAmounts(ValueEntry, ExpectedQuantity);
        Assert.AreEqual(LastValueEntry."Entry No.", ValueEntry."Entry No.", 'Last entry number');
        Assert.AreEqual(LastValueEntry."Entry Type", ValueEntry."Entry Type", 'Last entry type');
        Assert.AreEqual(LastValueEntry."Expected Cost", ValueEntry."Expected Cost", 'Last entry expected-cost flag');
        Assert.AreEqual(LastValueEntry."Document No.", ValueEntry."Document No.", 'Last entry document number');
        ExpectedView.SetCurrentKey("Item Ledger Entry No.");
        ExpectedView.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        Assert.AreEqual(ExpectedView.GetView(false), ValueEntry.GetView(false), 'Result key and filters');
    end;

    local procedure VerifyLedgerCostAmounts(ValueEntry: Record "Value Entry"; ExpectedQuantity: Decimal)
    begin
        Assert.AreEqual(ExpectedQuantity, ValueEntry."Item Ledger Entry Quantity", 'Ledger quantity');
        Assert.AreEqual(ExpectedQuantity * 11, ValueEntry."Cost Amount (Actual)", 'Ledger actual cost');
        Assert.AreEqual(ExpectedQuantity * 13, ValueEntry."Cost Amount (Actual) (ACY)", 'Ledger actual ACY cost');
        Assert.AreEqual(ExpectedQuantity * 17, ValueEntry."Cost Amount (Expected)", 'Ledger expected cost');
        Assert.AreEqual(ExpectedQuantity * 19, ValueEntry."Cost Amount (Expected) (ACY)", 'Ledger expected ACY cost');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectedItemsRefreshBetweenAdjustmentRuns()
    var
        Item: array[3] of Record Item;
        FilterItem: Record Item;
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
        CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";
        InventoryAdjustment: Codeunit "Inventory Adjustment";
        ItemsToAdjust: List of [Code[20]];
        ItemIndex: Integer;
    begin
        Initialize();
        for ItemIndex := 1 to ArrayLen(Item) do begin
            CreateOrderSelectionItem(Item[ItemIndex]);
            Item[ItemIndex]."Cost is Adjusted" := false;
            Item[ItemIndex].Modify();
        end;
        FilterItem.SetFilter("No.", '%1|%2|%3', Item[1]."No.", Item[2]."No.", Item[3]."No.");
        InventoryAdjustment.SetFilterItem(FilterItem);
        CostAdjustmentParameter."Online Adjustment" := true;
        CostAdjustmentParameter."Skip Job Item Cost Update" := true;
        CostAdjustmentParamsMgt.SetParameters(CostAdjustmentParameter);
        ItemsToAdjust.Add(Item[1]."No.");
        ItemsToAdjust.Add(Item[1]."No.");
        CostAdjustmentParamsMgt.SetItemsToAdjust(ItemsToAdjust);

        InventoryAdjustment.MakeMultiLevelAdjmt(CostAdjustmentParamsMgt);
        VerifySelectedItemAdjusted(Item[1], true);
        VerifySelectedItemAdjusted(Item[2], false);
        VerifySelectedItemAdjusted(Item[3], false);

        ItemsToAdjust.Set(1, Item[2]."No.");
        ItemsToAdjust.Set(2, Item[2]."No.");
        InventoryAdjustment.MakeMultiLevelAdjmt(CostAdjustmentParamsMgt);
        VerifySelectedItemAdjusted(Item[2], true);
        VerifySelectedItemAdjusted(Item[3], false);

        Clear(ItemsToAdjust);
        CostAdjustmentParamsMgt.SetItemsToAdjust(ItemsToAdjust);
        InventoryAdjustment.MakeMultiLevelAdjmt(CostAdjustmentParamsMgt);
        VerifySelectedItemAdjusted(Item[3], true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectedItemsReflectChangesBetweenDiscoveryPasses()
    var
        Item: Record Item;
        OtherItem: Record Item;
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ItemsToAdjust: List of [Code[20]];
    begin
        Initialize();
        CreateOrderSelectionItem(Item);
        CreateOrderSelectionItem(OtherItem);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Assembly, 10000);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, OtherItem."No.", "Inventory Order Type"::Assembly, 10000);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Production, 10000);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, OtherItem."No.", "Inventory Order Type"::Production, 10000);
        ItemsToAdjust.Add(Item."No.");
        ItemsToAdjust.Add(Item."No.");
        SelectionItemsForSubscriber := ItemsToAdjust;
        SelectionReplacementItemNo := OtherItem."No.";
        BindSubscription(this);
        Item.SetFilter("No.", '%1|%2', Item."No.", OtherItem."No.");
        InventoryAdjmtEntryOrder.Reset();

        RunOrderSelection(Item, InventoryAdjmtEntryOrder, ItemsToAdjust);

        UnbindSubscription(this);
        Assert.AreEqual(OtherItem."No.", ItemsToAdjust.Get(1), 'Subscriber must replace the shared selection.');
        VerifyOrderSelectionEntry(Item."No.", "Inventory Order Type"::Assembly, 10000, true);
        VerifyOrderSelectionEntry(OtherItem."No.", "Inventory Order Type"::Assembly, 10000, false);
        VerifyOrderSelectionEntry(Item."No.", "Inventory Order Type"::Production, 10000, false);
        VerifyOrderSelectionEntry(OtherItem."No.", "Inventory Order Type"::Production, 10000, true);
    end;

    local procedure VerifySelectedItemAdjusted(var Item: Record Item; ExpectedAdjusted: Boolean)
    begin
        Item.Get(Item."No.");
        Assert.AreEqual(ExpectedAdjusted, Item."Cost is Adjusted", 'Selected item adjustment state');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSelectionRespectsItemAndOrderFilters()
    begin
        Initialize();
        VerifyOrderSelectionFilters("Inventory Order Type"::Assembly);
        VerifyOrderSelectionFilters("Inventory Order Type"::Production);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSelectionEmptyItemListAllowsMatchingOrders()
    var
        Item: Record Item;
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ItemsToAdjust: List of [Code[20]];
    begin
        Initialize();
        CreateOrderSelectionItem(Item);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Assembly, 10000);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Production, 10000);
        Item.SetRecFilter();
        InventoryAdjmtEntryOrder.Reset();
        InventoryAdjmtEntryOrder.SetRange("Item No.", Item."No.");

        RunOrderSelection(Item, InventoryAdjmtEntryOrder, ItemsToAdjust);

        InventoryAdjmtEntryOrder.SetRange("Cost is Adjusted", true);
        Assert.AreEqual(2, InventoryAdjmtEntryOrder.Count(), 'An empty selection must not exclude matching orders.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSelectionPreservesProductionSubscriberFilter()
    var
        Item: Record Item;
        OtherItem: Record Item;
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ItemsToAdjust: List of [Code[20]];
    begin
        Initialize();
        CreateOrderSelectionItem(Item);
        CreateOrderSelectionItem(OtherItem);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Production, 10000);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, OtherItem."No.", "Inventory Order Type"::Production, 10000);
        ItemsToAdjust.Add(Item."No.");
        ItemsToAdjust.Add(OtherItem."No.");
        OrderSelectionSubscriberFilter := Item."No.";
        BindSubscription(this);
        Item.SetFilter("No.", '%1|%2', Item."No.", OtherItem."No.");
        InventoryAdjmtEntryOrder.Reset();

        RunOrderSelection(Item, InventoryAdjmtEntryOrder, ItemsToAdjust);

        UnbindSubscription(this);
        VerifyOrderSelectionEntry(Item."No.", "Inventory Order Type"::Production, 10000, true);
        VerifyOrderSelectionEntry(OtherItem."No.", "Inventory Order Type"::Production, 10000, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSelectionPreservesOnlineAndFinishedRestrictions()
    var
        Item: Record Item;
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ItemsToAdjust: List of [Code[20]];
    begin
        Initialize();
        CreateOrderSelectionItem(Item);
        ItemsToAdjust.Add(Item."No.");
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Assembly, 10000);
        InventoryAdjmtEntryOrder."Allow Online Adjustment" := false;
        InventoryAdjmtEntryOrder.Modify();
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Production, 10000);
        InventoryAdjmtEntryOrder."Is Finished" := false;
        InventoryAdjmtEntryOrder.Modify();
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Production, 20000);
        InventoryAdjmtEntryOrder."Allow Online Adjustment" := false;
        InventoryAdjmtEntryOrder.Modify();
        Item.SetRecFilter();
        InventoryAdjmtEntryOrder.Reset();

        RunOrderSelection(Item, InventoryAdjmtEntryOrder, ItemsToAdjust);

        VerifyOrderSelectionEntry(Item."No.", "Inventory Order Type"::Assembly, 10000, false);
        VerifyOrderSelectionEntry(Item."No.", "Inventory Order Type"::Production, 10000, false);
        VerifyOrderSelectionEntry(Item."No.", "Inventory Order Type"::Production, 20000, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSelectionSkipsMissingSelectedItem()
    var
        Item: Record Item;
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ItemsToAdjust: List of [Code[20]];
    begin
        Initialize();
        CreateOrderSelectionItem(Item);
        ItemsToAdjust.Add(Item."No.");
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Assembly, 10000);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Production, 10000);
        Item.Delete();
        Item.SetRecFilter();
        InventoryAdjmtEntryOrder.Reset();

        RunOrderSelection(Item, InventoryAdjmtEntryOrder, ItemsToAdjust);

        VerifyOrderSelectionEntry(Item."No.", "Inventory Order Type"::Assembly, 10000, false);
        VerifyOrderSelectionEntry(Item."No.", "Inventory Order Type"::Production, 10000, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSelectionRejectedItemsSqlGrowthIsBounded()
    var
        Item: Record Item;
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ItemsToAdjust: List of [Code[20]];
        ItemIndex: Integer;
        SmallStatementCount: BigInteger;
        LargeStatementCount: BigInteger;
    begin
        // [SCENARIO] Orders outside an explicit item selection do not cause per-item SQL reads.
        Initialize();
        CreateOrderSelectionItem(Item);
        ItemsToAdjust.Add(Item."No.");
        for ItemIndex := 1 to 100 do begin
            CreateOrderSelectionItem(Item);
            CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Assembly, 10000);
            CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", "Inventory Order Type"::Production, 10000);
            InventoryAdjmtEntryOrder.Reset();
            if ItemIndex = 10 then
                SmallStatementCount := MeasureOrderSelection(Item, InventoryAdjmtEntryOrder, ItemsToAdjust);
        end;
        LargeStatementCount := MeasureOrderSelection(Item, InventoryAdjmtEntryOrder, ItemsToAdjust);

        Assert.IsTrue(LargeStatementCount <= SmallStatementCount + 10,
            StrSubstNo('Order selection SQL statements for 10/100 rejected items: %1/%2. Growth must not exceed 10 statements.',
                SmallStatementCount, LargeStatementCount));
    end;

    local procedure VerifyOrderSelectionFilters(OrderType: Enum "Inventory Order Type")
    var
        Item: Record Item;
        FilteredItem: Record Item;
        UnselectedItem: Record Item;
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ItemsToAdjust: List of [Code[20]];
    begin
        CreateOrderSelectionItem(Item);
        CreateOrderSelectionItem(FilteredItem);
        CreateOrderSelectionItem(UnselectedItem);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", OrderType, 10000);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, Item."No.", OrderType, 20000);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, FilteredItem."No.", OrderType, 10000);
        CreateOrderSelectionEntry(InventoryAdjmtEntryOrder, UnselectedItem."No.", OrderType, 10000);
        ItemsToAdjust.Add(Item."No.");
        ItemsToAdjust.Add(Item."No.");
        ItemsToAdjust.Add(FilteredItem."No.");
        Item.SetFilter("No.", '%1|%2', Item."No.", UnselectedItem."No.");
        InventoryAdjmtEntryOrder.Reset();
        InventoryAdjmtEntryOrder.SetRange("Order Type", OrderType);
        InventoryAdjmtEntryOrder.SetRange("Order Line No.", 10000);

        RunOrderSelection(Item, InventoryAdjmtEntryOrder, ItemsToAdjust);

        VerifyOrderSelectionEntry(Item."No.", OrderType, 10000, true);
        VerifyOrderSelectionEntry(Item."No.", OrderType, 20000, false);
        VerifyOrderSelectionEntry(FilteredItem."No.", OrderType, 10000, false);
        VerifyOrderSelectionEntry(UnselectedItem."No.", OrderType, 10000, false);
    end;

    local procedure CreateOrderSelectionItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Cost is Adjusted" := true;
        Item."Inventory Value Zero" := true;
        Item.Modify();
    end;

    local procedure CreateOrderSelectionEntry(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemNo: Code[20]; OrderType: Enum "Inventory Order Type"; LineNo: Integer)
    begin
        InventoryAdjmtEntryOrder.Init();
        InventoryAdjmtEntryOrder."Order Type" := OrderType;
        InventoryAdjmtEntryOrder."Order No." := ItemNo;
        InventoryAdjmtEntryOrder."Order Line No." := LineNo;
        InventoryAdjmtEntryOrder."Item No." := ItemNo;
        InventoryAdjmtEntryOrder."Cost is Adjusted" := false;
        InventoryAdjmtEntryOrder."Completely Invoiced" := true;
        InventoryAdjmtEntryOrder."Is Finished" := true;
        InventoryAdjmtEntryOrder.Insert();
    end;

    local procedure VerifyOrderSelectionEntry(ItemNo: Code[20]; OrderType: Enum "Inventory Order Type"; LineNo: Integer; ExpectedAdjusted: Boolean)
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        InventoryAdjmtEntryOrder.Get(OrderType, ItemNo, LineNo);
        Assert.AreEqual(ExpectedAdjusted, InventoryAdjmtEntryOrder."Cost is Adjusted", 'Order selection');
    end;

    local procedure MeasureOrderSelection(var Item: Record Item; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ItemsToAdjust: List of [Code[20]]): BigInteger
    var
        StatementsBefore: BigInteger;
    begin
        SelectLatestVersion();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        RunOrderSelection(Item, InventoryAdjmtEntryOrder, ItemsToAdjust);
        exit(SessionInformation.SqlStatementsExecuted() - StatementsBefore);
    end;

    local procedure RunOrderSelection(var Item: Record Item; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ItemsToAdjust: List of [Code[20]])
    var
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
        CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";
        InventoryAdjustment: Codeunit "Inventory Adjustment";
    begin
        CostAdjustmentParameter."Online Adjustment" := true;
        CostAdjustmentParameter."Skip Job Item Cost Update" := true;
        CostAdjustmentParamsMgt.SetParameters(CostAdjustmentParameter);
        CostAdjustmentParamsMgt.SetItemsToAdjust(ItemsToAdjust);
        CostAdjustmentParamsMgt.SetInventoryAdjmtEntryOrder(InventoryAdjmtEntryOrder);
        InventoryAdjustment.SetFilterItem(Item);
        InventoryAdjustment.MakeMultiLevelAdjmt(CostAdjustmentParamsMgt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Adjustment", 'OnWIPToAdjustExistOnAfterInventoryAdjmtEntryOrderSetFilters', '', false, false)]
    local procedure FilterProductionOrderSelection(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
        if OrderSelectionSubscriberFilter <> '' then
            InventoryAdjmtEntryOrder.SetRange("Order No.", OrderSelectionSubscriberFilter);
        if SelectionReplacementItemNo <> '' then begin
            SelectionItemsForSubscriber.Set(1, SelectionReplacementItemNo);
            SelectionItemsForSubscriber.Set(2, SelectionReplacementItemNo);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplicationTraceEntryLookupPreservesMembership()
    var
        ItemApplicationTrace: Record "Item Application Trace";
    begin
        // [SCENARIO] Entry membership spans roots and includes parents, duplicate children and negative entries.
        InsertApplicationTraceEntry(ItemApplicationTrace, 100, 100, 0);
        InsertApplicationTraceEntry(ItemApplicationTrace, 100, 200, 1);
        InsertApplicationTraceEntry(ItemApplicationTrace, 101, 101, 0);
        InsertApplicationTraceEntry(ItemApplicationTrace, 101, 200, 1);
        InsertApplicationTraceEntry(ItemApplicationTrace, 102, -5, 1);
        ItemApplicationTrace.SetRange("From Entry No.", 999);

        Assert.IsTrue(ApplicationTraceContainsEntry(ItemApplicationTrace, 100), 'Parent entry must be found.');
        Assert.IsTrue(ApplicationTraceContainsEntry(ItemApplicationTrace, 200), 'Shared child must be found.');
        Assert.AreEqual(2, ItemApplicationTrace.Count(), 'Both roots must retain their shared child.');
        Assert.IsTrue(ApplicationTraceContainsEntry(ItemApplicationTrace, -5), 'Negative entry must be found.');
        Assert.IsFalse(ApplicationTraceContainsEntry(ItemApplicationTrace, 0), 'Missing zero entry must not be found.');
        Assert.IsFalse(ApplicationTraceContainsEntry(ItemApplicationTrace, 500), 'Unrelated entry must not be found.');

        ItemApplicationTrace.Reset();
        ItemApplicationTrace.SetRange("From Entry No.", 100);
        ItemApplicationTrace.SetFilter(Level, '>0');
        Assert.AreEqual(1, ItemApplicationTrace.Count(), 'Chain traversal must still exclude the parent.');
        ItemApplicationTrace.FindFirst();
        Assert.AreEqual(200, ItemApplicationTrace."Entry No.", 'Chain child');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplicationTraceEntryLookupFollowsMutations()
    var
        ItemApplicationTrace: Record "Item Application Trace";
    begin
        // [SCENARIO] Membership remains current after deleting one root, deleting all copies and rebuilding a chain.
        InsertApplicationTraceEntry(ItemApplicationTrace, 100, 200, 1);
        InsertApplicationTraceEntry(ItemApplicationTrace, 101, 200, 1);
        Assert.IsTrue(ApplicationTraceContainsEntry(ItemApplicationTrace, 200), 'Initial child');
        ItemApplicationTrace.Get(100, 200);
        ItemApplicationTrace.Delete();
        Assert.IsTrue(ApplicationTraceContainsEntry(ItemApplicationTrace, 200), 'Child under the other root');
        ItemApplicationTrace.Get(101, 200);
        ItemApplicationTrace.Delete();
        Assert.IsFalse(ApplicationTraceContainsEntry(ItemApplicationTrace, 200), 'Deleted child');
        InsertApplicationTraceEntry(ItemApplicationTrace, 100, 200, 1);
        Assert.IsTrue(ApplicationTraceContainsEntry(ItemApplicationTrace, 200), 'Rebuilt child');
        ItemApplicationTrace.Reset();
        ItemApplicationTrace.DeleteAll();
        Assert.IsFalse(ApplicationTraceContainsEntry(ItemApplicationTrace, 200), 'Cleared trace');
    end;

    local procedure InsertApplicationTraceEntry(var ItemApplicationTrace: Record "Item Application Trace"; FromEntryNo: Integer; EntryNo: Integer; EntryLevel: Integer)
    begin
        ItemApplicationTrace.Init();
        ItemApplicationTrace."From Entry No." := FromEntryNo;
        ItemApplicationTrace."Entry No." := EntryNo;
        ItemApplicationTrace.Level := EntryLevel;
        ItemApplicationTrace.Insert();
    end;

    local procedure ApplicationTraceContainsEntry(var ItemApplicationTrace: Record "Item Application Trace"; EntryNo: Integer): Boolean
    begin
        ItemApplicationTrace.Reset();
        ItemApplicationTrace.SetCurrentKey("Entry No.");
        ItemApplicationTrace.SetRange("Entry No.", EntryNo);
        exit(not ItemApplicationTrace.IsEmpty());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOAdjustingOptimisationForPurchaseOnceManySales()
    var
        DurationSmallNo: Integer;
        DurationLargeNo: Integer;
        SmallNoOfSales: Integer;
    begin
        // Workitem VSTF-301226
        if not CodeCoverageMgt.Running() then
            CodeCoverageMgt.StartApplicationCoverage();

        Initialize();
        LibraryInventory.SetAutomaticCostAdjmtNever();
        // Both fixtures must adjust an earlier sale before measuring the final adjustment.
        SmallNoOfSales := 3;
        DurationSmallNo := PurchaseOnceManySales(SmallNoOfSales);
        DurationLargeNo := PurchaseOnceManySales(SmallNoOfSales * 4);

        if CodeCoverageMgt.Running() then
            CodeCoverageMgt.StopApplicationCoverage();

        // The adjusting should have the same duration.
        Assert.AreNearlyEqual(DurationSmallNo, DurationLargeNo, 0.2 * DurationSmallNo,
          StrSubstNo('Costing optimization of one purchase many sales broken (DurationSmallNo (%1) * 1.2  > DurationLargeNo (%2))',
            DurationSmallNo, DurationLargeNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalePurchSale_FIFO()
    begin
        Initialize();
        SalePurchSale("Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalePurchSale_Avg()
    begin
        Initialize();
        SalePurchSale("Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_PurchReturnShptAnd2Sales_FIFO()
    begin
        Initialize();
        PurchReturnShptAnd2Sales("Costing Method"::FIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_PurchReturnShptAnd2Sales_AvgFixedAppln()
    begin
        Initialize();
        PurchReturnShptAnd2Sales("Costing Method"::Average, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_PurchReturnShptAnd2Sales_AvgNoAppln()
    begin
        Initialize();
        PurchReturnShptAnd2Sales("Costing Method"::Average, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_UndoReturnReceiptAnd2Sales_FIFO()
    begin
        Initialize();
        UndoReturnReceiptAnd2Sales("Costing Method"::FIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_UndoReturnReceiptAnd2Sales_AvgFixedAppln()
    begin
        Initialize();
        UndoReturnReceiptAnd2Sales("Costing Method"::Average, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_UndoReturnReceiptAnd2Sales_AvgNoAppln()
    begin
        Initialize();
        UndoReturnReceiptAnd2Sales("Costing Method"::Average, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF268387()
    var
        Item: Record Item;
        LinesWithOneSKU: Integer;
        LinesWithTwoSKU: Integer;
        LinesWithThreeSKU: Integer;
    begin
        // Workitem VSTF-268387
        Initialize();
        LibraryInventory.SetAutomaticCostAdjmtNever();
        LibraryInventory.SetAverageCostSetup("Average Cost Calculation Type"::Item, "Average Cost Period Type"::Day);
        if not CodeCoverageMgt.Running() then
            CodeCoverageMgt.StartApplicationCoverage();

        CreateItem(Item, "Costing Method"::FIFO);
        LinesWithOneSKU := PostItemJournalLineWithSKU(Item);
        LinesWithTwoSKU := PostItemJournalLineWithSKU(Item);
        LinesWithThreeSKU := PostItemJournalLineWithSKU(Item);

        if CodeCoverageMgt.Running() then
            CodeCoverageMgt.StopApplicationCoverage();

        // There should be the same code covered with and without SKU.
        Assert.AreEqual(2, LinesWithOneSKU, 'GetInvtSetup should only be hit twice.');
        Assert.AreEqual(1, LinesWithTwoSKU - LinesWithOneSKU, 'There should be the a difference of 1 hit per SKU. See bug 268387.');
        Assert.AreEqual(1, LinesWithThreeSKU - LinesWithTwoSKU, 'There should be the a difference of 1 hit per SKU. See bug 268387.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS94483_ManyConsumptionsAppliedToOneInbound()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemQty: Integer;
        NoOfConsumtionsSmall: Integer;
        NoOfConsumtionsMedium: Integer;
        NoOfConsumtionsLarge: Integer;
        NoOfHitsSmall: Integer;
        NoOfHitsMedium: Integer;
        NoOfHitsLarge: Integer;
    begin
        ItemQty := 1000;
        NoOfConsumtionsSmall := 10;
        NoOfConsumtionsMedium := 20;
        NoOfConsumtionsLarge := 50;

        CreateProductionOrder(ProdOrderLine, ItemQty);

        if not CodeCoverageMgt.Running() then
            CodeCoverageMgt.StartApplicationCoverage();
        NoOfHitsSmall := PostPurchWithConsumptionAndAdjust(ProdOrderLine, ItemQty, NoOfConsumtionsSmall);
        NoOfHitsMedium := PostPurchWithConsumptionAndAdjust(ProdOrderLine, ItemQty, NoOfConsumtionsMedium);
        NoOfHitsLarge := PostPurchWithConsumptionAndAdjust(ProdOrderLine, ItemQty, NoOfConsumtionsLarge);
        if CodeCoverageMgt.Running() then
            CodeCoverageMgt.StopApplicationCoverage();

        VerifyLinearComputationalComplexity(NoOfConsumtionsSmall, NoOfConsumtionsMedium, NoOfConsumtionsLarge,
          NoOfHitsSmall, NoOfHitsMedium, NoOfHitsLarge);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateUnitCostSKUNotCalledWhenNotAdjustmentPosted()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        Location: array[3] of Record Location;
        SKU: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        I: Integer;
        NoOfHitsSmall: Integer;
        NoOfHitsLarge: Integer;
    begin
        // [FEATURE] [Stockkeeping Unit]
        // [SCENARIO 263791] "Adjust Cost - Item Entries" job does not recalculate SKU unit cost when no adjustment entries were posted

        Initialize();

        // [GIVEN] "Average Cost Calc. Type" is set to "Item & Location & Variant" to track cost by SKU
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Day);

        // [GIVEN] Item "I" with a stockkeeping unit "SKU1" on location "L1"
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location[1].Code, Item."No.", '');

        // [GIVEN] Post purcashe entry for SKU1 and run cost adjustment
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location[1].Code, '', 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CodeCoverageMgt.StartApplicationCoverage();
        NoOfHitsSmall := CodeCoverageMgt.ApplicationHits();
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        NoOfHitsSmall := CodeCoverageMgt.ApplicationHits() - NoOfHitsSmall;

        // [GIVEN] Create two more SKU's for item "I"
        LibraryWarehouse.CreateLocation(Location[2]);
        LibraryWarehouse.CreateLocation(Location[3]);
        for I := 2 to ArrayLen(Location) do
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location[I].Code, Item."No.", '');

        // [GIVEN] Post purchase entry for SKU1
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location[1].Code, '', 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Run cost adjustment
        NoOfHitsLarge := CodeCoverageMgt.ApplicationHits();
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        NoOfHitsLarge := CodeCoverageMgt.ApplicationHits() - NoOfHitsLarge;
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] Cost adjustment routine demonstrates the same performance for 1 SKU and 3 SKUs
        Assert.IsTrue(LibraryCalcComplexity.IsConstant(NoOfHitsSmall, NoOfHitsLarge), NotConstantCCErr);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
    end;

    local procedure PurchaseOnceManySales(PurchaseQty: Integer) NoOfLinesHIt: Integer
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemApplnEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        Loc: Code[10];
        Variant: Code[10];
        jj: Decimal;
        Day1: Date;
    begin
        CreateItem(Item, Item."Costing Method"::FIFO);
        Day1 := WorkDate();
        Loc := '';
        Variant := '';
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Purchase, Item, '', '', '', PurchaseQty, Day1, 2);

        ItemLedgEntry.FindLast();

        for jj := 1 to PurchaseQty - 1 do begin
            LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);

            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch, Item, Loc, Variant, Day1, ItemJournalLine."Entry Type"::Sale, 1, 0.007);
            ItemJournalLine.Modify(true);

            LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

            if jj = PurchaseQty - 1 then
                NoOfLinesHIt := CodeCoverageMgt.ApplicationHits();
            LibraryCosting.AdjustCostItemEntries(Item."No.", '');
            if jj = PurchaseQty - 1 then
                NoOfLinesHIt := CodeCoverageMgt.ApplicationHits() - NoOfLinesHIt;

            ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemLedgEntry."Entry No.");
            ItemApplnEntry.SetFilter("Outbound Item Entry No.", '<> %1', 0);
            ItemApplnEntry.SetRange("Outbound Entry is Updated", false);
            Assert.IsTrue(not ItemApplnEntry.FindFirst(),
              StrSubstNo('Item Application Entries with inbound %1 and "Outbound Entry is Updated" == FALSE NOT EMPTY',
                ItemLedgEntry."Entry No."));
        end;
    end;

    local procedure PostItemJournalLineWithSKU(Item: Record Item) NoOfHits: Integer
    var
        CodeCover: Record "Code Coverage";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryWarehouse.CreateStockkeepingUnit(StockkeepingUnit, Item);
        NoOfHits := GetCodeCoverageForObject(CodeCover."Object Type"::Codeunit, 5804, 'GetInvtSetup');
        LibraryInventory.PostItemJournalLine(
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::Purchase, Item, '', '', '',
          LibraryRandom.RandDec(100, 2), WorkDate(), LibraryRandom.RandDec(100, 2));
        NoOfHits := GetCodeCoverageForObject(CodeCover."Object Type"::Codeunit, 5804, 'GetInvtSetup') - NoOfHits;
    end;

    local procedure PostPurchWithConsumptionAndAdjust(ProdOrderLine: Record "Prod. Order Line"; Quantity: Decimal; NoOfConsumptions: Integer): Integer
    var
        Item: Record Item;
        NoOfHits: Integer;
        I: Integer;
    begin
        Item.Get(ProdOrderLine."Item No.");
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', Quantity, WorkDate(), Item."Unit Cost");
        for I := 1 to NoOfConsumptions do
            LibraryManufacturing.POSTConsumption(
              ProdOrderLine, Item, '', '', Quantity / NoOfConsumptions, WorkDate(), Item."Unit Cost" + LibraryRandom.RandDecInRange(20, 30, 2));

        NoOfHits := CodeCoverageMgt.ApplicationHits();
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        exit(CodeCoverageMgt.ApplicationHits() - NoOfHits);
    end;

    local procedure CreateProductionOrder(var ProdOrderLine: Record "Prod. Order Line"; Quantity: Decimal)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        CreateItem(Item, Item."Costing Method"::Average);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity);
        ProdOrderLine.Status := ProdOrderLine.Status::Released;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 1;
        ProdOrderLine."Item No." := Item."No.";
        ProdOrderLine.Insert(true);
    end;

    local procedure SalePurchSale(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalesHeader: Record "Sales Header";
        FirstSaleItemApplnEntry: Record "Item Application Entry";
        SecondSaleItemApplnEntry: Record "Item Application Entry";
        Qty1: Decimal;
        Qty2: Decimal;
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        SetupItemQtyCost(Item, Qty1, Qty2, UnitCost, UnitPrice, CostingMethod);

        // Create and Post Sales
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty1, WorkDate(), UnitPrice, true, true);

        // Create and Post Purchase
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty1 + Qty2, WorkDate(), UnitCost, true, true);
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindLast();
        FirstSaleItemApplnEntry.Find('+');
        FirstSaleItemApplnEntry.Next(-1);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, CostingMethod = Item."Costing Method"::Average);

        // Create and post item charge
        CreateandPostItemCharge(PurchRcptLine);
        // Verify
        VerifyApplnEntry(FirstSaleItemApplnEntry, false, CostingMethod = Item."Costing Method"::Average);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, CostingMethod = Item."Costing Method"::Average);

        // Create and Post Second Sales
        LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty2, WorkDate(), UnitPrice, true, true);
        SecondSaleItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, CostingMethod = Item."Costing Method"::Average);
        VerifyApplnEntry(SecondSaleItemApplnEntry, true, CostingMethod = Item."Costing Method"::Average);
    end;

    local procedure PurchReturnShptAnd2Sales(CostingMethod: Enum "Costing Method"; AvgCostNoApplication: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ReturnPurchaseHeader: Record "Purchase Header";
        ReturnPurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchReturnItemApplnEntry: Record "Item Application Entry";
        FirstSaleItemApplnEntry: Record "Item Application Entry";
        SecondSaleItemApplnEntry: Record "Item Application Entry";
        Qty1: Decimal;
        Qty2: Decimal;
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        SetupItemQtyCost(Item, Qty1, Qty2, UnitCost, UnitPrice, CostingMethod);

        // Create and Post Purchase
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty1 + Qty2, WorkDate(), UnitCost, true, true);
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindLast();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast();

        // Create and Post Return Order
        LibraryPurchase.CreatePurchaseReturnOrder(ReturnPurchaseHeader, ReturnPurchaseLine, Item, '', '', Qty1, WorkDate(), UnitCost);
        ReturnPurchaseLine.SetRange("Document Type", ReturnPurchaseLine."Document Type");
        ReturnPurchaseLine.SetRange("Document No.", ReturnPurchaseLine."Document No.");
        ReturnPurchaseLine.FindFirst();
        ReturnPurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReturnPurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(ReturnPurchaseHeader, true, true);
        PurchReturnItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);

        // Create and Post Sales
        PostSalesOrder(Item, Qty2 / 2, UnitPrice, not AvgCostNoApplication, ItemLedgerEntry."Entry No.");
        FirstSaleItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, AvgCostNoApplication);

        // Create and post item charge
        CreateandPostItemCharge(PurchRcptLine);
        // Verify
        VerifyApplnEntry(PurchReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, false, AvgCostNoApplication);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, AvgCostNoApplication);

        // Create and Post Second Sales
        PostSalesOrder(Item, Qty2 / 2, UnitPrice, not AvgCostNoApplication, ItemLedgerEntry."Entry No.");
        SecondSaleItemApplnEntry.FindLast();
        // Verify
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(SecondSaleItemApplnEntry, false, AvgCostNoApplication);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(PurchReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(FirstSaleItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(SecondSaleItemApplnEntry, true, AvgCostNoApplication);
    end;

    local procedure UndoReturnReceiptAnd2Sales(CostingMethod: Enum "Costing Method"; AvgCostNoApplication: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnSalesHeader: Record "Sales Header";
        ReturnSalesLine: Record "Sales Line";
        PurchItemLedgerEntry: Record "Item Ledger Entry";
        SalesItemLedgerEntry: Record "Item Ledger Entry";
        ReturnRcptLine: Record "Return Receipt Line";
        SalesReturnItemApplnEntry: Record "Item Application Entry";
        UndoSalesReturnItemApplnEntry: Record "Item Application Entry";
        SecondSaleItemApplnEntry: Record "Item Application Entry";
        UndoReturnReceiptLine: Codeunit "Undo Return Receipt Line";
        Qty1: Decimal;
        Qty2: Decimal;
        UnitCost: Decimal;
        UnitPrice: Decimal;
    begin
        SetupItemQtyCost(Item, Qty1, Qty2, UnitCost, UnitPrice, CostingMethod);

        // Create and Post Purchase
        LibraryPurchase.POSTPurchaseOrder(PurchaseHeader, Item, '', '', Qty1 + Qty2, WorkDate(), UnitCost, true, true);
        PurchItemLedgerEntry.SetRange("Item No.", Item."No.");
        PurchItemLedgerEntry.FindLast();
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindLast();

        // Create and Post Sales
        PostSalesOrder(Item, Qty1, UnitPrice, not AvgCostNoApplication, PurchItemLedgerEntry."Entry No.");
        SalesItemLedgerEntry.SetRange("Item No.", Item."No.");
        SalesItemLedgerEntry.FindLast();

        // Create and Ship Sales Return Order
        LibrarySales.CreateSalesReturnOrder(ReturnSalesHeader, ReturnSalesLine, Item, '', '', Qty1, WorkDate(), UnitCost, UnitPrice);
        ReturnSalesLine.SetRange("Document Type", ReturnSalesLine."Document Type");
        ReturnSalesLine.SetRange("Document No.", ReturnSalesLine."Document No.");
        ReturnSalesLine.FindFirst();
        ReturnSalesLine.Validate("Appl.-from Item Entry", SalesItemLedgerEntry."Entry No.");
        ReturnSalesLine.Modify(true);
        LibrarySales.PostSalesDocument(ReturnSalesHeader, true, false);
        SalesReturnItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);

        // Undo Return Receipt
        ReturnRcptLine.SetRange("No.", Item."No.");
        ReturnRcptLine.FindLast();
        UndoReturnReceiptLine.SetHideDialog(true);
        UndoReturnReceiptLine.Run(ReturnRcptLine);
        UndoSalesReturnItemApplnEntry.FindLast();

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(UndoSalesReturnItemApplnEntry, true, AvgCostNoApplication);

        // Create and post item charge
        CreateandPostItemCharge(PurchRcptLine);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(UndoSalesReturnItemApplnEntry, true, AvgCostNoApplication);

        // Create and Post Second Sales
        PostSalesOrder(Item, Qty2, UnitPrice, not AvgCostNoApplication, PurchItemLedgerEntry."Entry No.");
        SecondSaleItemApplnEntry.FindLast();
        // Verify
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(UndoSalesReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(SecondSaleItemApplnEntry, false, AvgCostNoApplication);

        // Adjust Cost
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        // Verify
        LibraryCosting.CheckAdjustment(Item);
        VerifyApplnEntry(SalesReturnItemApplnEntry, false, AvgCostNoApplication);
        VerifyApplnEntry(UndoSalesReturnItemApplnEntry, true, AvgCostNoApplication);
        VerifyApplnEntry(SecondSaleItemApplnEntry, true, AvgCostNoApplication);
    end;

    local procedure SetupItemQtyCost(var Item: Record Item; var Qty1: Decimal; var Qty2: Decimal; var UnitCost: Decimal; var UnitPrice: Decimal; CostingMethod: Enum "Costing Method")
    begin
        Qty1 := LibraryRandom.RandDecInRange(1, 100, 2);
        Qty2 := LibraryRandom.RandDecInRange(1, 100, 2);
        UnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        UnitPrice := LibraryRandom.RandDecInRange(1, 100, 2);

        LibraryInventory.CreateItemSimple(Item, CostingMethod, UnitCost);
    end;

    local procedure CreateandPostItemCharge(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.");
        LibraryPurchase.AssignPurchChargeToPurchRcptLine(
          PurchHeader, PurchRcptLine, PurchRcptLine.Quantity, LibraryRandom.RandDecInRange(1, 10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure PostSalesOrder(var Item: Record Item; Qty: Decimal; UnitPrice: Decimal; PostWithApplyTo: Boolean; ApplToEntry: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        if PostWithApplyTo then begin
            LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', 0D);
            SalesLine.Validate("Unit Price", UnitPrice);
            SalesLine.Validate("Appl.-to Item Entry", ApplToEntry);
            SalesLine.Modify();
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end else
            LibrarySales.PostSalesOrder(SalesHeader, Item, '', '', Qty, WorkDate(), UnitPrice, true, true);
    end;

    local procedure VerifyApplnEntry(var ItemApplnEntry: Record "Item Application Entry"; ExpectedOutbndUpdatedValue: Boolean; AvgCostNoApplication: Boolean)
    begin
        if AvgCostNoApplication then
            exit;

        ItemApplnEntry.Find('=');
        ItemApplnEntry.TestField("Outbound Entry is Updated", ExpectedOutbndUpdatedValue);
    end;

    local procedure VerifyLinearComputationalComplexity(x1: Decimal; x2: Decimal; x3: Integer; fx1: Decimal; fx2: Decimal; fx3: Decimal)
    begin
        Assert.IsTrue(LibraryCalcComplexity.IsLinear(x1, x2, x3, fx1, fx2, fx3), NotLinearCCErr);
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; Line: Text) NoOfHits: Integer
    var
        CodeCover: Record "Code Coverage";
    begin
        CodeCoverageMgt.Refresh();
        CodeCover.SetRange("Line Type", CodeCover."Line Type"::Code);
        CodeCover.SetRange("Object Type", ObjectType);
        CodeCover.SetRange("Object ID", ObjectID);
        CodeCover.SetFilter("No. of Hits", '>%1', 0);
        CodeCover.SetFilter(Line, '@*' + Line + '*');
        if CodeCover.FindSet() then
            repeat
                NoOfHits += CodeCover."No. of Hits";
            until CodeCover.Next() = 0;
    end;
}
