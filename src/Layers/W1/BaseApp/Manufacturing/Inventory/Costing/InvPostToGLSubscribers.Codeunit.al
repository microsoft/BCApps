// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;

codeunit 99000763 "Inv. Post. To G/L Subscribers"
{
    var
        ManufacturingSetup: Record "Manufacturing Setup";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Posting To G/L", OnBeforeAdjustWIPForProduction, '', false, false)]
    local procedure OnBeforeAdjustWIPForProduction(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
        IsHandled := SkipAdjustWIPForProduction(ValueEntry);
    end;

    local procedure SkipAdjustWIPForProduction(var ValueEntry: Record "Value Entry"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ManufacturingSetup.GetRecordOnce();
        if not (ManufacturingSetup."Finish Order Without Output") then
            exit(true);

        if ValueEntry."Expected Cost" then
            exit(true);

        ProdOrderLine.SetLoadFields(Status, "Prod. Order No.", "Line No.", "Finished Qty. (Base)");
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Finished);
        ProdOrderLine.SetRange("Prod. Order No.", ValueEntry."Order No.");
        ProdOrderLine.SetRange("Line No.", ValueEntry."Order Line No.");
        ProdOrderLine.SetRange("Finished Qty. (Base)", 0);
        if ProdOrderLine.IsEmpty() then
            exit(true);
    end;
}