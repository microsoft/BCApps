codeunit 137811 "SCM - Costing UT"
{
    Permissions = TableData "Value Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Stockkeeping Unit] [SCM]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF327751()
    begin
        // test negative amount - roots of bug fixed
        UpdateUnitCostOfSKU(-0.00024);

        // test zero amount - this doesn't exist after adjustment but we need to be sure the field Unit Cost is not changed
        UpdateUnitCostOfSKU(0);

        // test positive amount
        UpdateUnitCostOfSKU(0.00024);
    end;

    local procedure UpdateUnitCostOfSKU(NewUnitCost: Decimal)
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ValueEntry: Record "Value Entry";
        InventorySetup: Record "Inventory Setup";
        ItemCostManagement: Codeunit ItemCostManagement;
        OldAvgCostCalcType: Enum "Average Cost Calculation Type";
    begin
        // Initialize of needed records
        SetupItem(Item);
        SetupSKU(SKU, Item);
        SetupValueEntry(ValueEntry, SKU, NewUnitCost);

        InventorySetup.Get();
        OldAvgCostCalcType := InventorySetup."Average Cost Calc. Type";
        InventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant";
        InventorySetup.Modify();

        // Execution of test
        // test of function
        ItemCostManagement.SetProperties(true, 1);
        ItemCostManagement.UpdateUnitCostSKU(Item, SKU, 0, NewUnitCost, false, 0);

        // Verification of results
        VerifyUnitCostOfSKU(SKU."Unit Cost", Item."Unit Cost", NewUnitCost);

        // restore original value of Inventory Setup
        if OldAvgCostCalcType <> InventorySetup."Average Cost Calc. Type" then begin
            InventorySetup."Average Cost Calc. Type" := OldAvgCostCalcType;
            InventorySetup.Modify();
        end;
    end;

    local procedure SetupItem(var Item: Record Item)
    begin
        Item."No." := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);
        Item."Costing Method" := Item."Costing Method"::Average;
        Item."Unit Cost" := 99.99999;
        Item.Insert();  // function which is tested later requires Item in table (GET method is called)
    end;

    local procedure SetupSKU(var SKU: Record "Stockkeeping Unit"; var Item: Record Item)
    begin
        SKU."Location Code" := LibraryUtility.GenerateRandomCode(SKU.FieldNo("Location Code"), DATABASE::"Stockkeeping Unit");
        SKU."Item No." := Item."No.";
        SKU."Variant Code" := '';
        SKU."Unit Cost" := Item."Unit Cost";
        SKU.Insert();  // function which is tested later requires SKU in table due to MODIFY command
    end;

    local procedure SetupValueEntry(var ValueEntry: Record "Value Entry"; var SKU: Record "Stockkeeping Unit"; CostAmountActual: Decimal)
    begin
        if ValueEntry.FindLast() then begin
            ValueEntry.Init();
            ValueEntry."Entry No." += 1;
        end else
            ValueEntry."Entry No." := 1;
        ValueEntry."Item No." := SKU."Item No.";
        ValueEntry."Location Code" := SKU."Location Code";
        ValueEntry."Variant Code" := SKU."Variant Code";
        ValueEntry."Valuation Date" := WorkDate();
        ValueEntry."Item Ledger Entry Quantity" := 1;
        ValueEntry."Cost Amount (Actual)" := CostAmountActual;
        ValueEntry.Insert();  // function which is tested later requires Value Entry in table
    end;

    local procedure VerifyUnitCostOfSKU(UnitCostOfSKU: Decimal; ItemUnitCost: Decimal; NewUnitCost: Decimal)
    begin
        if NewUnitCost <= 0 then
            Assert.AreEqual(ItemUnitCost, UnitCostOfSKU, '')
        else
            Assert.AreEqual(NewUnitCost, UnitCostOfSKU, '');
    end;
}

