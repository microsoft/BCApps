// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;

codeunit 99000855 "Planning-Get Parameters"
{

    trigger OnRun()
    begin
    end;

    var
        GlobalSKU: Record "Stockkeeping Unit";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        HasGotInventorySetUp: Boolean;
        LotForLot: Boolean;
        ManualScheduling: Boolean;

    procedure AtSKU(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        GetInventorySetUp();
        if (ItemNo <> GlobalSKU."Item No.") or
            (VariantCode <> GlobalSKU."Variant Code") or
            (LocationCode <> GlobalSKU."Location Code")
        then begin
            Clear(GlobalSKU);
            GlobalSKU.SetRange("Item No.", ItemNo);
            GlobalSKU.SetRange("Variant Code", VariantCode);
            GlobalSKU.SetRange("Location Code", LocationCode);
            if not GlobalSKU.FindFirst() then begin
                GetItem(ItemNo);
                GlobalSKU."Item No." := ItemNo;
                GlobalSKU."Variant Code" := VariantCode;
                GlobalSKU."Location Code" := LocationCode;
                GlobalSKU.CopyFromItem(Item);
                OnAtSKUOnAfterCopyFromItem(GlobalSKU, Item, ItemNo, VariantCode, LocationCode);
                if LotForLot then begin
                    GlobalSKU."Reorder Point" := 0;
                    GlobalSKU."Maximum Inventory" := 0;
                    GlobalSKU."Reorder Quantity" := 0;
                    case Item."Reordering Policy" of
                        GlobalSKU."Reordering Policy"::" ":
                            GlobalSKU."Reordering Policy" := GlobalSKU."Reordering Policy"::" ";
                        GlobalSKU."Reordering Policy"::Order:
                            GlobalSKU."Reordering Policy" := GlobalSKU."Reordering Policy"::Order;
                        GlobalSKU."Reordering Policy"::"Lot-for-Lot":
                            GlobalSKU."Reordering Policy" := GlobalSKU."Reordering Policy"::"Lot-for-Lot";
                        else begin
                            GlobalSKU."Reordering Policy" := GlobalSKU."Reordering Policy"::"Lot-for-Lot";
                            GlobalSKU."Plan Minimal Supply" := true;
                        end;
                    end;
                    if GlobalSKU."Reordering Policy" = GlobalSKU."Reordering Policy"::"Lot-for-Lot" then
                        GlobalSKU."Include Inventory" := true
                    else
                        GlobalSKU."Include Inventory" := Item."Include Inventory";
                    GlobalSKU."Maximum Order Quantity" := 0;
                    GlobalSKU."Safety Stock Quantity" := 0;
                    GlobalSKU."Order Multiple" := 0;
                    GlobalSKU."Overflow Level" := 0;
                end;
            end;
            SetComponentsAtLocation(LocationCode);
        end;

        OnAtSKUOnBeforeSetSafetyLeadTime(GlobalSKU, ManualScheduling);

        if not ManualScheduling then
            if Format(GlobalSKU."Safety Lead Time") = '' then
                if Format(InventorySetup."Default Safety Lead Time") <> '' then
                    GlobalSKU."Safety Lead Time" := InventorySetup."Default Safety Lead Time"
                else
                    Evaluate(GlobalSKU."Safety Lead Time", '<0D>');


        AdjustInvalidSettings(GlobalSKU);
        SKU := GlobalSKU;

        OnAfterAtSKU(SKU, GlobalSKU);
    end;

    procedure SetManualScheduling(NewManualScheduling: Boolean)
    begin
        ManualScheduling := NewManualScheduling;
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." <> ItemNo then
            Item.Get(ItemNo);
    end;

    local procedure GetInventorySetUp()
    begin
        if not HasGotInventorySetUp then
            HasGotInventorySetUp := InventorySetup.Get();
    end;

    local procedure SetComponentsAtLocation(LocationCode: Code[10])
    begin
        if GlobalSKU."Components at Location" = '' then
            if InventorySetup.GetComponentsAtLocation() <> '' then
                GlobalSKU."Components at Location" := InventorySetup.GetComponentsAtLocation()
            else
                GlobalSKU."Components at Location" := LocationCode;
        OnAfterSetComponentsAtLocation(GlobalSKU, Item);
    end;

    procedure SetLotForLot()
    begin
        LotForLot := true;
    end;

    procedure SetPlanningParameters(var PlanningParameters: Record "Planning Parameters")
    var
        xPlanningParameters: Record "Planning Parameters";
    begin
        xPlanningParameters := PlanningParameters;
        Clear(PlanningParameters);
        PlanningParameters."Reordering Policy" := xPlanningParameters."Reordering Policy";
        PlanningParameters."Include Inventory" := xPlanningParameters."Include Inventory";

        case PlanningParameters."Reordering Policy" of
            PlanningParameters."Reordering Policy"::" ":
                PlanningParameters."Safety Lead Time Enabled" := true;
            PlanningParameters."Reordering Policy"::"Fixed Reorder Qty.":
                begin
                    PlanningParameters."Time Bucket Enabled" := true;
                    PlanningParameters."Safety Lead Time Enabled" := true;
                    PlanningParameters."Safety Stock Qty Enabled" := true;
                    PlanningParameters."Reorder Point Enabled" := true;
                    PlanningParameters."Reorder Quantity Enabled" := true;
                    PlanningParameters."Maximum Inventory Enabled" := false;
                    PlanningParameters."Minimum Order Qty Enabled" := true;
                    PlanningParameters."Maximum Order Qty Enabled" := true;
                    PlanningParameters."Order Multiple Enabled" := true;
                    PlanningParameters."Include Inventory Enabled" := false;
                    PlanningParameters."Rescheduling Period Enabled" := false;
                    PlanningParameters."Lot Accum. Period Enabled" := false;
                    PlanningParameters."Dampener Period Enabled" := false;
                    PlanningParameters."Dampener Quantity Enabled" := true;
                    PlanningParameters."Overflow Level Enabled" := true;
                end;
            PlanningParameters."Reordering Policy"::"Maximum Qty.":
                begin
                    PlanningParameters."Time Bucket Enabled" := true;
                    PlanningParameters."Safety Lead Time Enabled" := true;
                    PlanningParameters."Safety Stock Qty Enabled" := true;
                    PlanningParameters."Reorder Point Enabled" := true;
                    PlanningParameters."Reorder Quantity Enabled" := false;
                    PlanningParameters."Maximum Inventory Enabled" := true;
                    PlanningParameters."Minimum Order Qty Enabled" := true;
                    PlanningParameters."Maximum Order Qty Enabled" := true;
                    PlanningParameters."Order Multiple Enabled" := true;
                    PlanningParameters."Include Inventory Enabled" := false;
                    PlanningParameters."Rescheduling Period Enabled" := false;
                    PlanningParameters."Lot Accum. Period Enabled" := false;
                    PlanningParameters."Dampener Period Enabled" := false;
                    PlanningParameters."Dampener Quantity Enabled" := true;
                    PlanningParameters."Overflow Level Enabled" := true;
                end;
            PlanningParameters."Reordering Policy"::Order:
                begin
                    PlanningParameters."Time Bucket Enabled" := false;
                    PlanningParameters."Safety Lead Time Enabled" := true;
                    PlanningParameters."Safety Stock Qty Enabled" := false;
                    PlanningParameters."Reorder Point Enabled" := false;
                    PlanningParameters."Reorder Quantity Enabled" := false;
                    PlanningParameters."Maximum Inventory Enabled" := false;
                    PlanningParameters."Minimum Order Qty Enabled" := false;
                    PlanningParameters."Maximum Order Qty Enabled" := false;
                    PlanningParameters."Order Multiple Enabled" := false;
                    PlanningParameters."Include Inventory Enabled" := false;
                    PlanningParameters."Rescheduling Period Enabled" := false;
                    PlanningParameters."Lot Accum. Period Enabled" := false;
                    PlanningParameters."Dampener Period Enabled" := true;
                    PlanningParameters."Dampener Quantity Enabled" := false;
                    PlanningParameters."Overflow Level Enabled" := false;
                end;
            PlanningParameters."Reordering Policy"::"Lot-for-Lot":
                begin
                    PlanningParameters."Time Bucket Enabled" := false;
                    PlanningParameters."Safety Lead Time Enabled" := true;
                    PlanningParameters."Safety Stock Qty Enabled" := xPlanningParameters."Include Inventory";
                    PlanningParameters."Reorder Point Enabled" := false;
                    PlanningParameters."Reorder Quantity Enabled" := false;
                    PlanningParameters."Maximum Inventory Enabled" := false;
                    PlanningParameters."Minimum Order Qty Enabled" := true;
                    PlanningParameters."Maximum Order Qty Enabled" := true;
                    PlanningParameters."Order Multiple Enabled" := true;
                    PlanningParameters."Include Inventory Enabled" := true;
                    PlanningParameters."Rescheduling Period Enabled" := true;
                    PlanningParameters."Lot Accum. Period Enabled" := true;
                    PlanningParameters."Dampener Period Enabled" := true;
                    PlanningParameters."Dampener Quantity Enabled" := true;
                    PlanningParameters."Overflow Level Enabled" := false;
                end;
            else
                OnSetPlanningParametersOnReorderingPolicyElseCase(PlanningParameters);
        end;

        OnAfterSetPlanningParameters(PlanningParameters, xPlanningParameters);
    end;

    procedure AdjustInvalidSettings(var SKU: Record "Stockkeeping Unit")
    var
        PlanningParameters: Record "Planning Parameters";
    begin
        PlanningParameters."Reordering Policy" := SKU."Reordering Policy";
        PlanningParameters."Include Inventory" := SKU."Include Inventory";

        SetPlanningParameters(PlanningParameters);

        if not PlanningParameters."Time Bucket Enabled" then
            Evaluate(SKU."Time Bucket", '<0D>');
        if not PlanningParameters."Safety Lead Time Enabled" then
            Evaluate(SKU."Safety Lead Time", '<0D>');
        if not PlanningParameters."Safety Stock Qty Enabled" then
            SKU."Safety Stock Quantity" := 0;
        if not PlanningParameters."Reorder Point Enabled" then
            SKU."Reorder Point" := 0;
        if not PlanningParameters."Reorder Quantity Enabled" then
            SKU."Reorder Quantity" := 0;
        if not PlanningParameters."Maximum Inventory Enabled" then
            SKU."Maximum Inventory" := 0;
        if not PlanningParameters."Minimum Order Qty Enabled" then
            SKU."Minimum Order Quantity" := 0;
        if not PlanningParameters."Maximum Order Qty Enabled" then
            SKU."Maximum Order Quantity" := 0;
        if not PlanningParameters."Order Multiple Enabled" then
            SKU."Order Multiple" := 0;
        if not PlanningParameters."Rescheduling Period Enabled" then
            Evaluate(SKU."Rescheduling Period", '<0D>');
        if not PlanningParameters."Lot Accum. Period Enabled" then
            Evaluate(SKU."Lot Accumulation Period", '<0D>');
        if not PlanningParameters."Dampener Period Enabled" then
            Evaluate(SKU."Dampener Period", '<0D>');
        if not PlanningParameters."Dampener Quantity Enabled" then
            SKU."Dampener Quantity" := 0;
        if not PlanningParameters."Overflow Level Enabled" then
            SKU."Overflow Level" := 0;

        AdjustInvalidValues(SKU, PlanningParameters."Reorder Point Enabled");

        OnAfterAdjustInvalidSettings(SKU, PlanningParameters);
    end;

    local procedure AdjustInvalidValues(var SKU: Record "Stockkeeping Unit"; ReorderPointEnabled: Boolean)
    begin
        if SKU."Reorder Point" < 0 then
            SKU."Reorder Point" := 0;

        if SKU."Safety Stock Quantity" < 0 then
            SKU."Safety Stock Quantity" := 0;

        if (SKU."Reorder Point" < SKU."Safety Stock Quantity") and
           ReorderPointEnabled
        then
            SKU."Reorder Point" := SKU."Safety Stock Quantity";

        if SKU."Maximum Order Quantity" < 0 then
            SKU."Maximum Order Quantity" := 0;

        if SKU."Minimum Order Quantity" < 0 then
            SKU."Minimum Order Quantity" := 0;

        if SKU."Maximum Order Quantity" <> 0 then
            if SKU."Maximum Order Quantity" < SKU."Minimum Order Quantity" then
                SKU."Maximum Order Quantity" := SKU."Minimum Order Quantity";

        if (SKU."Maximum Inventory" < SKU."Safety Stock Quantity") or
           (SKU."Maximum Inventory" < SKU."Reorder Point")
        then
            SKU."Maximum Inventory" := 0;

        if SKU."Overflow Level" <> 0 then
            case SKU."Reordering Policy" of
                SKU."Reordering Policy"::"Fixed Reorder Qty.":
                    if SKU."Overflow Level" < (SKU."Reorder Point" + SKU."Reorder Quantity") then
                        SKU."Overflow Level" := SKU."Reorder Point" + SKU."Reorder Quantity";
                SKU."Reordering Policy"::"Maximum Qty.":
                    if SKU."Overflow Level" < SKU."Maximum Inventory" then
                        SKU."Overflow Level" := SKU."Maximum Inventory";
            end;
    end;

    procedure CalcDampenerDays(SKU: Record "Stockkeeping Unit") DampenerDays: Integer
    begin
        if Format(SKU."Dampener Period") = '' then begin
            GetInventorySetUp();
            DampenerDays := CalcDate(InventorySetup."Default Dampener Period") - Today;
        end else
            DampenerDays := CalcDate(SKU."Dampener Period") - Today;

        // The Dampener Period must not be less than the Lot Accumulation Period unless
        // the Reordering Policy is order
        if SKU."Reordering Policy" <> SKU."Reordering Policy"::Order then
            if DampenerDays > CalcDate(SKU."Lot Accumulation Period") - Today then
                DampenerDays := CalcDate(SKU."Lot Accumulation Period") - Today;
    end;

    procedure CalcDampenerQty(SKU: Record "Stockkeeping Unit") DampenerQty: Decimal
    begin
        if SKU."Reordering Policy" <> SKU."Reordering Policy"::Order then
            if SKU."Dampener Quantity" = 0 then begin
                GetInventorySetup();
                DampenerQty := SKU."Lot Size" * InventorySetup."Default Dampener %" / 100;
            end else
                DampenerQty := SKU."Dampener Quantity"
        else
            DampenerQty := 0;
    end;

    procedure CalcOverflowLevel(SKU: Record "Stockkeeping Unit") WarningLevel: Decimal
    begin
        if SKU."Overflow Level" <> 0 then
            WarningLevel := SKU."Overflow Level"
        else begin
            GetInventorySetup();
            if InventorySetup."Blank Overflow Level" = InventorySetup."Blank Overflow Level"::"Allow Default Calculation" then begin
                case SKU."Reordering Policy" of
                    SKU."Reordering Policy"::"Maximum Qty.":
                        WarningLevel := SKU."Maximum Inventory" + SKU."Minimum Order Quantity";
                    SKU."Reordering Policy"::"Fixed Reorder Qty.":
                        begin
                            if SKU."Minimum Order Quantity" > SKU."Reorder Quantity" then
                                WarningLevel := SKU."Minimum Order Quantity"
                            else
                                WarningLevel := SKU."Reorder Quantity";
                            WarningLevel += SKU."Reorder Point";
                        end
                    else
                        WarningLevel := 0;
                end;
                if SKU."Order Multiple" > 0 then
                    WarningLevel := Round(WarningLevel, SKU."Order Multiple", '>');
            end else
                WarningLevel := 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustInvalidSettings(var StockkeepingUnit: Record "Stockkeeping Unit"; var PlanningParameters: Record "Planning Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAtSKU(var SKU: Record "Stockkeeping Unit"; var GlobalSKU: Record "Stockkeeping Unit");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAtSKUOnAfterCopyFromItem(var GlobalSKU: Record "Stockkeeping Unit"; var Item: Record Item; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPlanningParameters(var PlanningParameters: Record "Planning Parameters"; xPlanningParameters: Record "Planning Parameters");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetComponentsAtLocation(var GlobalStockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetPlanningParametersOnReorderingPolicyElseCase(var PlanningParameters: Record "Planning Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAtSKUOnBeforeSetSafetyLeadTime(var GlobalSKU: Record "Stockkeeping Unit"; ManualScheduling: Boolean)
    begin
    end;
}

