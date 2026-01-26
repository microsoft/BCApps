codeunit 144099 "UT Fiscal LIFO"
{
    // 1. Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"Fiscal Cost" for report 12135 - Fiscal Inventory Valuation.
    // 2. Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"Average Cost" for report 12135 - Fiscal Inventory Valuation.
    // 3. Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"Weighted Average Cost" for report 12135 - Fiscal Inventory Valuation.
    // 4. Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"FIFO Cost" for report 12135 - Fiscal Inventory Valuation.
    // 5. Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"LIFO Cost" for report 12135 - Fiscal Inventory Valuation.
    // 6. Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"Discrete LIFO Cost" for report 12135 - Fiscal Inventory Valuation.
    // 
    // Covers Test Cases for WI - 345139.
    // --------------------------------------------------------------------------------------
    // Test Function Name                                         TFS ID
    // --------------------------------------------------------------------------------------
    // OnAfterGetRecordFiscalCostFiscalInvValuation               156426
    // OnAfterGetRecordAverageCostFiscalInvValuation              156427
    // OnAfterGetRecordWeightedAvCostFiscalInvValuation           156428
    // OnAfterGetRecordFIFOCostFiscalInvValuation                 156429
    // OnAfterGetRecordLIFOCostFiscalInvValuation                 156430
    // OnAfterGetRecordDiscreteLIFOCostFiscalInvValuation         156431

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ItemNoCap: Label 'Item__No__';
        UnitCostCap: Label 'UnitCost';
        ItemInvtTxt: Label 'Item__Net_Change_';
        InvValueTxt: Label 'InvValue';
        CostType: Option "Fiscal Cost","Average Cost","Weighted Average Cost","FIFO Cost","LIFO Cost","Discrete LIFO Cost";

    [Test]
    [HandlerFunctions('FiscalInventoryValuationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordFiscalCostFiscalInvValuation()
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"Fiscal Cost" for report 12135 - Fiscal Inventory Valuation.
        // Setup and Exercise.
        CostTypeFiscalInventoryValuation(ItemCostHistory, CostType::"Fiscal Cost");

        // Verify.
        VerifyValuesOnReport(ItemCostHistory."Item No.", ItemCostHistory."Year Average Cost");
    end;

    [Test]
    [HandlerFunctions('FiscalInventoryValuationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAverageCostFiscalInvValuation()
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"Average Cost" for report 12135 - Fiscal Inventory Valuation.
        // Setup and Exercise.
        CostTypeFiscalInventoryValuation(ItemCostHistory, CostType::"Average Cost");

        // Verify.
        VerifyValuesOnReport(ItemCostHistory."Item No.", ItemCostHistory."Year Average Cost");
    end;

    [Test]
    [HandlerFunctions('FiscalInventoryValuationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWeightedAvCostFiscalInvValuation()
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"Weighted Average Cost" for report 12135 - Fiscal Inventory Valuation.
        // Setup and Exercise.
        CostTypeFiscalInventoryValuation(ItemCostHistory, CostType::"Weighted Average Cost");

        // Verify.
        VerifyValuesOnReport(ItemCostHistory."Item No.", ItemCostHistory."Weighted Average Cost");
    end;

    [Test]
    [HandlerFunctions('FiscalInventoryValuationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordFIFOCostFiscalInvValuation()
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"FIFO Cost" for report 12135 - Fiscal Inventory Valuation.
        // Setup and Exercise.
        CostTypeFiscalInventoryValuation(ItemCostHistory, CostType::"FIFO Cost");

        // Verify.
        VerifyValuesOnReport(ItemCostHistory."Item No.", ItemCostHistory."FIFO Cost");
    end;

    [Test]
    [HandlerFunctions('FiscalInventoryValuationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLIFOCostFiscalInvValuation()
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"LIFO Cost" for report 12135 - Fiscal Inventory Valuation.
        // Setup and Exercise.
        CostTypeFiscalInventoryValuation(ItemCostHistory, CostType::"LIFO Cost");

        // Verify.
        VerifyValuesOnReport(ItemCostHistory."Item No.", ItemCostHistory."LIFO Cost");
    end;

    [Test]
    [HandlerFunctions('FiscalInventoryValuationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDiscreteLIFOCostFiscalInvValuation()
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Item trigger for CostType::"Discrete LIFO Cost" for report 12135 - Fiscal Inventory Valuation.
        // Setup and Exercise.
        CostTypeFiscalInventoryValuation(ItemCostHistory, CostType::"Discrete LIFO Cost");

        // Verify.
        VerifyValuesOnReport(ItemCostHistory."Item No.", ItemCostHistory."Discrete LIFO Cost");
    end;

    local procedure CostTypeFiscalInventoryValuation(var ItemCostHistory: Record "Item Cost History"; ItemCostType: Option)
    begin
        // Setup.
        Initialize();
        CreateItemCostHistory(ItemCostHistory);
        // Enqueue for FiscalInventoryValuationRequestPageHandler.
        LibraryVariableStorage.Enqueue(ItemCostHistory."Item No.");
        LibraryVariableStorage.Enqueue(ItemCostType);

        // Exercise.
        REPORT.Run(REPORT::"Fiscal Inventory Valuation");  // Opens FiscalInventoryValuationRequestPageHandler.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        MockItemInventory(Item."No.");
        exit(Item."No.");
    end;

    local procedure CreateItemCostHistory(var ItemCostHistory: Record "Item Cost History")
    begin
        ItemCostHistory."Item No." := CreateItem();
        ItemCostHistory."Competence Year" := WorkDate();
        ItemCostHistory."Year Average Cost" := LibraryRandom.RandDec(10, 2);
        ItemCostHistory."Weighted Average Cost" := ItemCostHistory."Year Average Cost";
        ItemCostHistory."FIFO Cost" := ItemCostHistory."Year Average Cost";
        ItemCostHistory."LIFO Cost" := ItemCostHistory."Year Average Cost";
        ItemCostHistory."Discrete LIFO Cost" := ItemCostHistory."Year Average Cost";
        ItemCostHistory.Insert();
    end;

    local procedure MockItemInventory(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Posting Date" := WorkDate() - LibraryRandom.RandInt(10);
        ItemLedgerEntry.Quantity := LibraryRandom.RandInt(20);
        ItemLedgerEntry.Insert();
    end;

    local procedure VerifyValuesOnReport(ItemNo: Code[20]; UnitCost: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.CalcFields("Net Change");

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNoCap, ItemNo);
        LibraryReportDataset.AssertElementWithValueExists(UnitCostCap, UnitCost);
        LibraryReportDataset.AssertElementWithValueExists(ItemInvtTxt, Item."Net Change");
        LibraryReportDataset.AssertElementWithValueExists(InvValueTxt, Item."Net Change" * UnitCost);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FiscalInventoryValuationRequestPageHandler(var FiscalInventoryValuation: TestRequestPage "Fiscal Inventory Valuation")
    var
        No: Variant;
        ItemCostType: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ItemCostType);
        FiscalInventoryValuation.CompetenceDate.SetValue(WorkDate());
        FiscalInventoryValuation.CostType.SetValue(ItemCostType);
        FiscalInventoryValuation.Item.SetFilter("No.", No);
        FiscalInventoryValuation.Item.SetFilter("Date Filter", Format(WorkDate()));
        FiscalInventoryValuation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

