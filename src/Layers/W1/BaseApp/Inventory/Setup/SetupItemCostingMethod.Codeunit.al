// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Inventory.Item;

codeunit 8625 "Setup Item Costing Method"
{
    TableNo = Item;

    trigger OnRun()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Rec."Costing Method" := InventorySetup."Default Costing Method"::FIFO;
        if Rec.Type = Rec.Type::Inventory then
            if InventorySetup.Get() then
                Rec."Costing Method" := InventorySetup."Default Costing Method";
        Rec.Modify();
    end;
}

