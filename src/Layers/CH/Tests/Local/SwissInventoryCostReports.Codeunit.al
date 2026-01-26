codeunit 144022 "Swiss Inventory Cost. Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        EndBalanceCaptionTxt: Label 'End Balance';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Swiss Inventory Cost. Reports");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Swiss Inventory Cost. Reports");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Swiss Inventory Cost. Reports");
    end;

    [Test]
    [HandlerFunctions('SRItemAccSheetNetChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifySRItemAccSheetNetChangeReport()
    var
        ItemNumber: Variant;
        QuantityToBuy: Variant;
    begin
        Initialize();
        RunReport(REPORT::"SR Item Acc Sheet Net Change");

        // Verify that that we had an increase in quantity.
        LibraryVariableStorage.Dequeue(ItemNumber);
        LibraryVariableStorage.Dequeue(QuantityToBuy);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo', ItemNumber);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_ItemLedgerEntry', QuantityToBuy);

        LibraryReportDataset.SetRange('EndBalanceCaption', EndBalanceCaptionTxt);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('IncreaseQty_Integer', QuantityToBuy);
    end;

    [Test]
    [HandlerFunctions('SRItemAccSheetInvValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifySRItemAccSheetInventoryValueReport()
    var
        Quantity: Variant;
        Amount: Variant;
        ItemNumber: Variant;
        QuantityToBuy: Integer;
        AmountToBuy: Decimal;
    begin
        Initialize();
        RunReport(REPORT::"SR Item Acc Sheet Inv. Value");

        // Verify that the amounts match.
        LibraryVariableStorage.Dequeue(ItemNumber);
        LibraryVariableStorage.Dequeue(Quantity);
        LibraryVariableStorage.Dequeue(Amount);
        AmountToBuy := Amount;
        QuantityToBuy := Quantity;
        AmountToBuy := AmountToBuy * QuantityToBuy;

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo', ItemNumber);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CostAmountActual_ItemLedgerEntry', Amount);

        LibraryReportDataset.SetRange('EndBalanceCaption', EndBalanceCaptionTxt);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalValueAdjusted_Integer', Amount);
    end;

    [Test]
    [HandlerFunctions('SRItemRankingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifySRItemRankingReport()
    var
        Quantity: Variant;
        ItemNumber: Variant;
        j: Integer;
        Column1: Integer;
        Column2: Integer;
    begin
        Initialize();

        // There are 14 option values. We want to test them all.
        for j := 0 to 13 do begin
            Column1 := j;
            Column2 := j + 1;

            // These must be dequeued in the request page handler.
            LibraryVariableStorage.Clear();
            LibraryVariableStorage.Enqueue(Column1);
            LibraryVariableStorage.Enqueue(Column2);
            RunReport(REPORT::"SR Item Ranking");

            // Verify that the amounts match.
            LibraryVariableStorage.Dequeue(ItemNumber);
            LibraryVariableStorage.Dequeue(Quantity);
            VerifyItemRankingReportColumns(ItemNumber, Column1, Column2);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SRItemAccSheetNetChangeRequestPageHandler(var RequestPageHandler: TestRequestPage "SR Item Acc Sheet Net Change")
    begin
        RequestPageHandler.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SRItemAccSheetInvValueRequestPageHandler(var RequestPageHandler: TestRequestPage "SR Item Acc Sheet Inv. Value")
    begin
        RequestPageHandler.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SRItemRankingRequestPageHandler(var RequestPageHandler: TestRequestPage "SR Item Ranking")
    var
        Column1: Variant;
        Column2: Variant;
    begin
        LibraryVariableStorage.Dequeue(Column1);
        LibraryVariableStorage.Dequeue(Column2);

        RequestPageHandler."Column[1]".SetValue(Column1);
        RequestPageHandler."Column[2]".SetValue(Column2);
        RequestPageHandler.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Normal]
    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Integer; Amount: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          EntryType, ItemNo, LibraryRandom.RandDec(100, 2) * 100);
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    [Normal]
    local procedure RunReport(ReportId: Integer)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemToFilter: Record Item;
        QuantityToBuy: Integer;
        AmountToBuy: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");

        QuantityToBuy := LibraryRandom.RandInt(20);
        LibraryVariableStorage.Enqueue(QuantityToBuy);

        AmountToBuy := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(AmountToBuy);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.", ItemJournalLine."Entry Type"::Purchase, QuantityToBuy, AmountToBuy);

        Commit();

        // Exercise the report filtered on the item created.
        ItemToFilter.SetRange("No.", Item."No.");
        REPORT.Run(ReportId, true, false, ItemToFilter);
    end;

    [Normal]
    local procedure VerifyItemRankingReportColumns(ItemNumber: Code[20]; Column1: Option; Column2: Option)
    var
        Item: Record Item;
        TmpAmount1: Decimal;
        TmpAmount2: Decimal;
        HasRow: Boolean;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo', ItemNumber);
        HasRow := LibraryReportDataset.GetNextRow();

        // Get the item
        Assert.IsTrue(Item.Get(ItemNumber), 'We should have retrieved the item');

        TmpAmount1 := CalculateAmountForColumn(Item, Column1);
        TmpAmount2 := CalculateAmountForColumn(Item, Column2);
        if (TmpAmount1 <> 0) or (TmpAmount2 <> 0) then begin
            LibraryReportDataset.AssertCurrentRowValueEquals('Col1Amount', TmpAmount1);
            LibraryReportDataset.AssertCurrentRowValueEquals('Col2Amount', TmpAmount2);
        end else
            Assert.IsFalse(HasRow,
              'If the amount in column 1 and column 2 is 0 than the Col1Amount and Col2Amount should not be found in the report');
    end;

    [Normal]
    local procedure CalculateAmountForColumn(var Item: Record Item; Column: Option Stock,"Inv. Stock","Net Change","Purch. Qty","Sales Qty","Pos. Adj.","Neg. Adj.","On Purch. Order","On Sales Order","Purch. Amt.","Sales Amt.",Profit,"Unit Price","Direct Cost","<blank>") Amount: Decimal
    begin
        // Check the amount columns for the various options.
        Amount := 0;

        case Column of
            Column::Stock:
                begin
                    Item.CalcFields(Inventory);
                    Amount := Item.Inventory;
                end;
            Column::"Inv. Stock":
                begin
                    Item.CalcFields("Net Invoiced Qty.");
                    Amount := Item."Net Invoiced Qty.";
                end;
            Column::"Net Change":
                begin
                    Item.CalcFields("Net Change");
                    Amount := Item."Net Change";
                end;
            Column::"Purch. Qty":
                begin
                    Item.CalcFields("Purchases (Qty.)");
                    Amount := Item."Purchases (Qty.)";
                end;
            Column::"Sales Qty":
                begin
                    Item.CalcFields("Sales (Qty.)");
                    Amount := Item."Sales (Qty.)";
                end;
            Column::"Pos. Adj.":
                begin
                    Item.CalcFields("Positive Adjmt. (Qty.)");
                    Amount := Item."Positive Adjmt. (Qty.)";
                end;
            Column::"Neg. Adj.":
                begin
                    Item.CalcFields("Negative Adjmt. (Qty.)");
                    Amount := Item."Negative Adjmt. (Qty.)";
                end;
            Column::"On Purch. Order":
                begin
                    Item.CalcFields("Qty. on Purch. Order");
                    Amount := Item."Qty. on Purch. Order";
                end;
            Column::"On Sales Order":
                begin
                    Item.CalcFields("Qty. on Sales Order");
                    Amount := Item."Qty. on Sales Order";
                end;
            Column::"Purch. Amt.":
                begin
                    Item.CalcFields("Purchases (LCY)");
                    Amount := Item."Purchases (LCY)";
                end;
            Column::"Sales Amt.":
                begin
                    Item.CalcFields("Sales (LCY)");
                    Amount := Item."Sales (LCY)";
                end;
            Column::Profit:
                begin
                    Item.CalcFields("Sales (LCY)", "COGS (LCY)");
                    Amount := Item."Sales (LCY)" - Item."COGS (LCY)";
                end;
            Column::"Unit Price":
                Amount := Item."Unit Price";
            Column::"Direct Cost":
                Amount := Item."Unit Cost";
        end;  // case
    end;
}

