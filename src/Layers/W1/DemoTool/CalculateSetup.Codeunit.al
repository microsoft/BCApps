codeunit 119029 "Calculate Setup"
{

    trigger OnRun()
    var
        Item: Record Item;
        TempItem: Record Item temporary;
    begin
        CalcStdCost.SetProperties(WorkDate(), true, false, false, '', true);
        CalcStdCost.CalcItems(Item, TempItem);

        if TempItem.Find('-') then
            repeat
                ItemCostMgt.UpdateStdCostShares(TempItem);
            until TempItem.Next() = 0;
    end;

    var
        CalcStdCost: Codeunit "Calculate Standard Cost";
        ItemCostMgt: Codeunit ItemCostManagement;
}

