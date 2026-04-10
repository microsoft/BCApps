namespace Microsoft.API.Upgrade;

using Microsoft.Inventory.Item;

codeunit 5524 "API Fix Item Cat. Code"
{
    trigger OnRun()
    var
        Item: Record "Item";
        Item2: Record "Item";
        ItemCategory: Record "Item Category";
    begin
        Item.SetLoadFields(Item."Item Category Id", Item."Item Category Code");
        Item.SetRange(Item."Item Category Code", '');
        if Item.FindSet() then
            repeat
                Item2 := Item;
                if ItemCategory.GetBySystemId(Item2."Item Category Id") then begin
                    Item2."Item Category Code" := ItemCategory."Code";
                    Item2.Modify();
                end;
            until Item.Next() = 0;
    end;

}