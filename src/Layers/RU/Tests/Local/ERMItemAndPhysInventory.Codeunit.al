codeunit 144709 "ERM Item And Phys. Inventory"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        isInitialized: Boolean;
        ValueNotExistErr: Label 'Value %1 does not exist on worksheet %2';
        ValueNotExistInColErr: Label 'Value %1 does not exist in column %2', Comment = '%1:Function GetItemJnlLineNewAmount, %2:ColumnID in Excel Buffer';

    [Test]
    [Scope('OnPrem')]
    procedure M17_CheckItem()
    var
        Item: Record Item;
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        Item.Modify(true);

        PrintM17ItemCard(Item."No.");

        LibraryReportValidation.VerifyCellValue(5, 77, Item."No.");
        LibraryReportValidation.VerifyCellValue(14, 92, Item."Base Unit of Measure");
        LibraryReportValidation.VerifyCellValue(14, 107, Format(Item."Unit Price"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M17_CheckItemLedgerEntries()
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        i: Integer;
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);

        InitItemJournalLine(ItemJnlLine, ItemJournalBatch."Template Type"::Item);
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do
            CreateAndPostItemJournalLine(ItemJnlLine, Item."No.");

        PrintM17ItemCard(Item."No.");

        VerifyRemainingQuantity(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure INV3_CalculatedQuantity()
    var
        ItemJnlLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        PrintINV3PhysInvForm(ItemJnlLine, 1);

        Qty := GetItemJnlLineQtyCalc(ItemJnlLine);
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, Format(Qty)),
          StrSubstNo(ValueNotExistErr, Qty, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure INV3_FactQuantity()
    var
        ItemJnlLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        PrintINV3PhysInvForm(ItemJnlLine, 1);

        Qty := GetItemJnlLineQtyFact(ItemJnlLine);
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, Format(Qty)),
          StrSubstNo(ValueNotExistErr, Qty, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure INV3_SurplusAmount()
    var
        ItemJnlLine: Record "Item Journal Line";
        Item: Record Item;
        LocalReportManagement: Codeunit "Local Report Management";
        Amt: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Phys. Inventory]
        // [SCENARIO 379022] Reports Phys. Inventory Form INV-3 in case of surplus should show already posted actual cost plus surplus amount from an inventory line.

        Initialize();
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, 0, LibraryRandom.RandDecInRange(10, 100, 2));

        // [GIVEN] Post positive item entries (e.g. Qty1 = 258, Cost1 = 170.58; Qty2 = 10, Cost2 = 150.45).
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do
            CreateAndPostPositiveItemJnlLine(ItemJnlLine, Item."No.",
              LibraryRandom.RandDecInRange(50, 500, 2), LibraryRandom.RandInt(50));

        // [GIVEN] Calculate inventory, set surplus quantity (e.g. "Qty. (Phys. Inventory)" = 750).
        CalculateInventoryAndSetNewQuantity(ItemJnlLine, Item."No.", LibraryRandom.RandDecInRange(501, 1000, 2));

        // [GIVEN] Posted actual cost plus surplus amount from journal line (t.g. 258*170.58 + 10*150.45 + (750-268)*"unit cost").
        Amt := Round(GetItemJnlLineNewAmount(ItemJnlLine));

        // [WHEN] Phys. Inventory Form INV-3 Report is shown.
        PrintINV3PhysInvFormForExistingJournal(ItemJnlLine);

        // [THEN] INV-3 form Phys. Inventory amount cell contains full cost of the item.
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('R', LocalReportManagement.FormatReportValue(Amt, 2)),
          StrSubstNo(ValueNotExistInColErr, Amt, 'R'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure INV3_LackAmount()
    var
        ItemJnlLine: Record "Item Journal Line";
        Item: Record Item;
        LocalReportManagement: Codeunit "Local Report Management";
        Amt: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Phys. Inventory]
        // [SCENARIO 379022] Reports Phys. Inventory Form INV-3 should show average cost of remaining quantity in case of lack.

        Initialize();
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, 0, LibraryRandom.RandDecInRange(10, 100, 2));

        // [GIVEN] Post positive item entries (e.g. Qty1 = 258, Cost1 = 170.58; Qty2 = 10, Cost2 = 150.45).
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do
            CreateAndPostPositiveItemJnlLine(ItemJnlLine, Item."No.",
              LibraryRandom.RandDecInRange(50, 500, 2), LibraryRandom.RandInt(50));

        // [GIVEN] Calculate inventory, set lacking quantity (e.g. "Qty. (Phys. Inventory)" = 5).
        CalculateInventoryAndSetNewQuantity(ItemJnlLine, Item."No.", LibraryRandom.RandDec(10, 2));

        // [GIVEN] Average cost of "Qty. (Phys. Inventory)" (5 * "average cost" = 5 * (258*170.58 + 10*150.45)/(258 + 10)).
        Amt := Round(GetItemJnlLineNewAmount(ItemJnlLine));

        // [WHEN] Phys. Inventory Form INV-3 Report is shown.
        PrintINV3PhysInvFormForExistingJournal(ItemJnlLine);

        // [THEN] INV-3 form Phys. Inventory amount cell contains 5 * "average cost".
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('R', LocalReportManagement.FormatReportValue(Amt, 2)),
          StrSubstNo(ValueNotExistInColErr, Amt, 'R'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure INV19_SurplusQty()
    var
        ItemJnlLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        PrintINV19PhysInvForm(ItemJnlLine, 1);

        Qty := Abs(GetItemJnlLineQtySurplus(ItemJnlLine, true));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, Format(Qty)),
          StrSubstNo(ValueNotExistErr, Qty, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure INV19_LackQty()
    var
        ItemJnlLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        PrintINV19PhysInvForm(ItemJnlLine, -1);

        Qty := Abs(GetItemJnlLineQtySurplus(ItemJnlLine, false));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, Format(Qty)),
          StrSubstNo(ValueNotExistErr, Qty, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AverageUnitCost()
    var
        ItemJnlLine: Record "Item Journal Line";
        Item: Record Item;
        ItemCostManagement: Codeunit ItemCostManagement;
        Qtys: array[2] of Decimal;
        UnitCosts: array[2] of Decimal;
        ActualResult: Decimal;
        ExpectedResult: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Unit Cost] [UT]
        // [SCENARIO 379022] Testing auxiliary function calculating average unit cost.

        Initialize();
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, 0, LibraryRandom.RandDecInRange(10, 100, 2));

        // [GIVEN] Post two positive item journal lines (i.e. Qty[1] = 50, Cost[1] = 10 and Qty[2] = 10, Cost[2] = 1)
        Qtys[1] := LibraryRandom.RandInt(100);
        UnitCosts[1] := LibraryRandom.RandInt(100);
        Qtys[2] := LibraryRandom.RandInt(100);
        UnitCosts[2] := LibraryRandom.RandInt(100);

        for i := 1 to 2 do
            CreateAndPostPositiveItemJnlLine(ItemJnlLine, Item."No.", Qtys[i], UnitCosts[i]);

        // [GIVEN] Average unit cost "AC" is (50*10 + 5*1) / (50 + 5) = 9.1818...
        ExpectedResult := (Qtys[1] * UnitCosts[1] + Qtys[2] * UnitCosts[2]) / (Qtys[1] + Qtys[2]);

        // [WHEN] Run function CalcAvgUnitActualCost of ItemCostManagement Codeunit.
        ActualResult := ItemCostManagement.CalcAvgUnitActualCost(Item."No.", '', WorkDate());

        // [THEN] Calculated average unit cost is equal to "AC".
        Assert.AreEqual(ExpectedResult, ActualResult, 'Wrong average unit cost calculation');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure PrintM17ItemCard(ItemNo: Code[20])
    var
        Item: Record Item;
        ItemCardM17: Report "Item Card M-17";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        Item.SetRange("No.", ItemNo);
        ItemCardM17.SetTableView(Item);
        ItemCardM17.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ItemCardM17.UseRequestPage(false);
        ItemCardM17.Run();
    end;

    local procedure PrintINV3PhysInvForm(var ItemJnlLine: Record "Item Journal Line"; Sign: Integer)
    begin
        Initialize();

        InitPhysInvJournal(ItemJnlLine, Sign);

        PrintINV3PhysInvFormForExistingJournal(ItemJnlLine);
    end;

    local procedure PrintINV3PhysInvFormForExistingJournal(var ItemJnlLine: Record "Item Journal Line")
    var
        PhysInventoryFormINV3: Report "Phys. Inventory Form INV-3";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        PhysInventoryFormINV3.SetTableView(ItemJnlLine);
        PhysInventoryFormINV3.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PhysInventoryFormINV3.UseRequestPage(false);
        PhysInventoryFormINV3.Run();
    end;

    local procedure PrintINV19PhysInvForm(var ItemJnlLine: Record "Item Journal Line"; Sign: Integer)
    var
        PhysInvFormINV19: Report "Phys. Inventory Form INV-19";
    begin
        Initialize();

        InitPhysInvJournal(ItemJnlLine, Sign);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        PhysInvFormINV19.SetTableView(ItemJnlLine);
        PhysInvFormINV19.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PhysInvFormINV19.UseRequestPage(false);
        PhysInvFormINV19.Run();
    end;

    local procedure InitPhysInvJournal(var ItemJnlLine: Record "Item Journal Line"; Sign: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemFilter: Text;
        i: Integer;
    begin
        InitItemJournalLine(ItemJnlLine, ItemJournalBatch."Template Type"::Item);
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            CreateAndPostItemJournalLine(ItemJnlLine, LibraryInventory.CreateItemNo());
            ItemFilter += ItemJnlLine."Item No." + '|';
        end;
        ItemFilter := DelChr(ItemFilter, '>', '|');

        InitItemJournalLine(ItemJnlLine, ItemJournalBatch."Template Type"::"Phys. Inventory");
        CalcInventory(ItemJnlLine, ItemFilter);
        UpdateInvFactQuantity(ItemJnlLine, Sign);
    end;

    local procedure InitItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        ItemJnlLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
        ItemJnlLine."Journal Batch Name" := ItemJournalBatch.Name;
    end;

    local procedure CreateItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name",
          "Item Ledger Entry Type".FromInteger(
            GetRandomType(
                ItemJnlLine."Entry Type"::"Positive Adjmt.".AsInteger(), ItemJnlLine."Entry Type"::"Negative Adjmt.".AsInteger())),
          ItemNo, LibraryRandom.RandDecInRange(5, 10, 2));
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20])
    begin
        CreateItemJournalLine(ItemJnlLine, ItemNo);

        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure FindItemJnlLines(var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        ItemJnlLine.FindSet();
    end;

    local procedure CreateAndPostPositiveItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        InitItemJournalLine(ItemJnlLine, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name",
          ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        ItemJnlLine.Validate("Posting Date", CalcDate('<-1M>', WorkDate()));
        ItemJnlLine.Validate("Unit Cost", UnitCost);
        ItemJnlLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure CalculateInventoryAndSetNewQuantity(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; InventoryQty: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        InitItemJournalLine(ItemJnlLine, ItemJournalBatch."Template Type"::"Phys. Inventory");
        CalcInventory(ItemJnlLine, ItemNo);

        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        ItemJnlLine.FindSet(true);
        repeat
            ItemJnlLine.Validate("Qty. (Phys. Inventory)", InventoryQty);
            ItemJnlLine.Modify(true);
        until ItemJnlLine.Next() = 0;
    end;

    local procedure GetItemJnlLineQtyCalc(ItemJnlLine: Record "Item Journal Line") QtyCalc: Decimal
    begin
        FindItemJnlLines(ItemJnlLine);
        repeat
            QtyCalc += ItemJnlLine."Qty. (Calculated)";
        until ItemJnlLine.Next() = 0;
    end;

    local procedure GetItemJnlLineQtyFact(ItemJnlLine: Record "Item Journal Line") QtyFact: Decimal
    begin
        FindItemJnlLines(ItemJnlLine);
        repeat
            QtyFact += ItemJnlLine."Qty. (Phys. Inventory)";
        until ItemJnlLine.Next() = 0;
    end;

    local procedure GetItemJnlLineNewAmount(ItemJnlLine: Record "Item Journal Line") RemAmt: Decimal
    var
        ValueEntry: Record "Value Entry";
        ItemCostManagement: Codeunit ItemCostManagement;
    begin
        RemAmt := 0;

        FindItemJnlLines(ItemJnlLine);
        repeat
            ValueEntry.Reset();
            ValueEntry.SetCurrentKey("Item No.", "Location Code", "Expected Cost", Inventoriable, "Posting Date");
            ValueEntry.SetRange("Item No.", ItemJnlLine."Item No.");
            ValueEntry.SetRange("Location Code", ItemJnlLine."Location Code");
            ValueEntry.SetRange(Inventoriable, true);
            ValueEntry.SetRange("Expected Cost", false);
            ValueEntry.SetFilter("Posting Date", '<%1', ItemJnlLine."Posting Date");
            ValueEntry.CalcSums("Cost Amount (Actual)");

            if ItemJnlLine."Qty. (Phys. Inventory)" >= ItemJnlLine."Qty. (Calculated)" then
                RemAmt += ValueEntry."Cost Amount (Actual)" + ItemJnlLine.Amount
            else
                RemAmt += ValueEntry."Cost Amount (Actual)" -
                  ItemJnlLine."Quantity (Base)" *
                  ItemCostManagement.CalcAvgUnitActualCost(
                    ItemJnlLine."Item No.", ItemJnlLine."Location Code", ItemJnlLine."Posting Date");
        until ItemJnlLine.Next() = 0;
    end;

    local procedure GetItemJnlLineQtySurplus(ItemJnlLine: Record "Item Journal Line"; Surplus: Boolean) Qty: Decimal
    var
        QtyDiff: Decimal;
    begin
        FindItemJnlLines(ItemJnlLine);
        repeat
            QtyDiff := ItemJnlLine."Qty. (Phys. Inventory)" - ItemJnlLine."Qty. (Calculated)";
            if Surplus xor (QtyDiff < 0) then
                Qty += QtyDiff;
        until ItemJnlLine.Next() = 0;
    end;

    local procedure GetRandomType(FromInt: Integer; ToInt: Integer): Integer
    begin
        exit(LibraryRandom.RandIntInRange(FromInt, ToInt));
    end;

    local procedure CalcInventory(var ItemJournalLine: Record "Item Journal Line"; ItemFilter: Text)
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilter);
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate() + 1, false, false);
    end;

    local procedure UpdateInvFactQuantity(ItemJnlLine: Record "Item Journal Line"; Sign: Integer)
    begin
        FindItemJnlLines(ItemJnlLine);
        repeat
            ItemJnlLine.Validate("Qty. (Phys. Inventory)", Sign * LibraryRandom.RandDec(100, 2));
            ItemJnlLine.Modify(true);
        until ItemJnlLine.Next() = 0;
    end;

    local procedure VerifyRemainingQuantity(ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        RemQty: Decimal;
        i: Integer;
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.FindSet();
        repeat
            RemQty += ItemLedgEntry.Quantity;
            LibraryReportValidation.VerifyCellValue(25 + i, 22, Format(ItemLedgEntry."Entry No."));
            LibraryReportValidation.VerifyCellValue(25 + i, 127, Format(RemQty));
            i += 1;
        until ItemLedgEntry.Next() = 0;
    end;
}

