// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;

codeunit 5972 "Service Info-Pane Management"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;

    procedure CalcAvailability(var ServLine: Record "Service Line") Result: Decimal
    var
        AvailableToPromise: Codeunit "Available to Promise";
        LookaheadDateformula: DateFormula;
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        PeriodType: Enum "Analysis Period Type";
        AvailabilityDate: Date;
    begin
        if GetItem(ServLine) then begin
            if ServLine."Needed by Date" <> 0D then
                AvailabilityDate := ServLine."Needed by Date"
            else
                AvailabilityDate := WorkDate();

            Item.Reset();
            Item.SetRange("Date Filter", 0D, AvailabilityDate);
            Item.SetRange("Variant Filter", ServLine."Variant Code");
            Item.SetRange("Location Filter", ServLine."Location Code");
            Item.SetRange("Drop Shipment Filter", false);
            OnCalcAvailabilityOnAfterSetItemFilters(Item, ServLine);

            Evaluate(LookaheadDateformula, '<0D>');
            Result :=
              AvailableToPromise.CalcQtyAvailabletoPromise(
                Item,
                GrossRequirement,
                ScheduledReceipt,
                AvailabilityDate,
                PeriodType,
                LookaheadDateformula);
        end;

        OnAfterCalcAvailability(ServLine, Item, GrossRequirement, ScheduledReceipt, AvailabilityDate, PeriodType, LookaheadDateformula, Result);
    end;

    procedure CalcNoOfSubstitutions(var ServLine: Record "Service Line"): Integer
    begin
        if GetItem(ServLine) then begin
            Item.CalcFields("No. of Substitutes");
            exit(Item."No. of Substitutes");
        end;
    end;

    procedure CalcNoOfSalesPrices(var ServLine: Record "Service Line"): Integer
    begin
        exit(ServLine.CountPrice(true));
    end;

    procedure CalcNoOfSalesLineDisc(var ServLine: Record "Service Line"): Integer
    begin
        exit(ServLine.CountDiscount(true));
    end;

    local procedure GetItem(var ServLine: Record "Service Line"): Boolean
    begin
        if (ServLine.Type <> ServLine.Type::Item) or (ServLine."No." = '') then
            exit(false);

        if ServLine."No." <> Item."No." then
            Item.Get(ServLine."No.");
        exit(true);
    end;

    procedure CalcNoOfServItemComponents(var ServItemLine: Record "Service Item Line"): Integer
    var
        ServItem: Record "Service Item";
        ServItemComponent: Record "Service Item Component";
        ResultValue: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcNoOfServItemComponents(ServItemLine, ResultValue, IsHandled);
        if IsHandled then
            exit(ResultValue);

        if ServItem.Get(ServItemLine."Service Item No.") then begin
            ServItemComponent.Reset();
            ServItemComponent.SetRange(Active, true);
            ServItemComponent.SetRange("Parent Service Item No.", ServItemLine."Service Item No.");
            exit(ServItemComponent.Count);
        end;
    end;

    procedure CalcNoOfTroubleshootings(var ServItemLine: Record "Service Item Line"): Integer
    var
        ServItem: Record "Service Item";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        ResultValue: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcNoOfTroubleshootings(ServItemLine, ResultValue, IsHandled);
        if IsHandled then
            exit(ResultValue);

        TroubleshootingSetup.Reset();
        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::"Service Item");
        TroubleshootingSetup.SetRange("No.", ServItemLine."Service Item No.");
        if not TroubleshootingSetup.IsEmpty() then
            exit(TroubleshootingSetup.Count);
        if not ServItem.Get(ServItemLine."Service Item No.") then
            exit(0);
        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::Item);
        TroubleshootingSetup.SetRange("No.", ServItem."Item No.");
        if not TroubleshootingSetup.IsEmpty() then
            exit(TroubleshootingSetup.Count);
        TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::"Service Item Group");
        TroubleshootingSetup.SetRange("No.", ServItem."Service Item Group Code");
        exit(TroubleshootingSetup.Count);
    end;

    procedure CalcNoOfSkilledResources(var ServItemLine: Record "Service Item Line"): Integer
    var
        ServItem: Record "Service Item";
        Res: Record Resource;
        ServOrderAllocMgt: Codeunit ServAllocationManagement;
        NoOfSkilledResources: Integer;
        ResultValue: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcNoOfSkilledResources(ServItemLine, ResultValue, IsHandled);
        if IsHandled then
            exit(0);

        if ServItem.Get(ServItemLine."Service Item No.") then begin
            Res.Reset();
            if Res.Find('-') then
                repeat
                    if ServOrderAllocMgt.ResourceQualified(Res."No.", Enum::"Resource Skill Type"::"Service Item", ServItem."No.") then
                        NoOfSkilledResources += 1;
                until Res.Next() = 0;
            exit(NoOfSkilledResources);
        end;
    end;

    procedure ShowServItemComponents(var ServItemLine: Record "Service Item Line")
    var
        ServItem: Record "Service Item";
        ServItemComponent: Record "Service Item Component";
    begin
        if ServItem.Get(ServItemLine."Service Item No.") then begin
            ServItemComponent.Reset();
            ServItemComponent.SetRange(Active, true);
            ServItemComponent.SetRange("Parent Service Item No.", ServItemLine."Service Item No.");
            PAGE.RunModal(PAGE::"Service Item Component List", ServItemComponent);
        end;
    end;

    procedure ShowTroubleshootings(var ServItemLine: Record "Service Item Line")
    var
        ServItem: Record "Service Item";
        TroubleshootingSetup: Record "Troubleshooting Setup";
    begin
        if ServItem.Get(ServItemLine."Service Item No.") then begin
            TroubleshootingSetup.Reset();
            TroubleshootingSetup.SetRange(Type, TroubleshootingSetup.Type::"Service Item");
            TroubleshootingSetup.SetRange("No.", ServItemLine."Service Item No.");
            PAGE.RunModal(PAGE::"Troubleshooting Setup", TroubleshootingSetup);
        end;
    end;

    procedure ShowSkilledResources(var ServItemLine: Record "Service Item Line")
    var
        ServItem: Record "Service Item";
        ResourceSkill: Record "Resource Skill";
        SkilledResourceList: Page "Skilled Resource List";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSkilledResources(ServItemLine, IsHandled);
        if IsHandled then
            exit;

        if ServItem.Get(ServItemLine."Service Item No.") then begin
            Clear(SkilledResourceList);
            SkilledResourceList.Initialize(ResourceSkill.Type::"Service Item", ServItem."No.", ServItem.Description);
            SkilledResourceList.RunModal();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAvailability(ServLine: Record "Service Line"; var Item: Record Item; GrossRequirement: Decimal; ScheduledReceipt: Decimal; AvailabilityDate: Date; PeriodType: Enum "Analysis Period Type"; LookaheadDateformula: DateFormula; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNoOfTroubleshootings(ServItemLine: Record "Service Item Line"; var ResultValue: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNoOfServItemComponents(ServItemLine: Record "Service Item Line"; var ResultValue: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNoOfSkilledResources(ServItemLine: Record "Service Item Line"; var ResultValue: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSkilledResources(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailabilityOnAfterSetItemFilters(var Item: Record Item; var ServLine: Record "Service Line")
    begin
    end;
}

