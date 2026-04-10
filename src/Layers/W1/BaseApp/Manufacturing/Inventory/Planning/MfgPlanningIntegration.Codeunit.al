// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000861 "Mfg. Planning Integration"
{
    [EventSubscriber(ObjectType::Table, Database::"Planning Assignment", 'OnItemChange', '', true, false)]
    local procedure PlanningAssignmentOnItemChange(var NewItem: Record Item; var OldItem: Record Item; var PlanningAssignment: Record "Planning Assignment")
    var
        InventorySetup: Record "Inventory Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if PlanningAssignment.PlanningParametersChanged(NewItem, OldItem) then begin
            InventorySetup.Get();
            ManufacturingSetup.Get();
            if (ManufacturingSetup."Components at Location" <> '') or not InventorySetup."Location Mandatory" then
                PlanningAssignment.AssignOne(NewItem."No.", '', ManufacturingSetup."Components at Location", WorkDate());
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Planning Component", 'OnAfterGetUpdateFromSKU', '', true, false)]
    local procedure OnAfterGetUpdateFromSKU(var PlanningComponent: Record "Planning Component"; StockeepingUnit: Record "Stockkeeping Unit")
    begin
        PlanningComponent.Validate("Flushing Method", StockeepingUnit."Flushing Method");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Planning Component", 'OnAfterValidateCalculationFormula', '', true, false)]
    local procedure PlanningCompomentOnAfterValidateCalculationFormula(var PlanningComponent: Record "Planning Component")
    begin
        if PlanningComponent."Calculation Formula" <> PlanningComponent."Calculation Formula"::"Fixed Quantity" then
            PlanningComponent.UpdateExpectedQuantityForPlanningNeeds();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Planning Component", 'OnGetToBinOnBeforeGetWMSDefaultCode', '', true, false)]
    local procedure OnGetToBinOnBeforeGetWMSDefaultCode(var PlanningComponent: Record "Planning Component"; var BinCode: Code[20])
    begin
        BinCode := PlanningComponent.GetRefOrderTypeBin();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Planning Error Log", 'OnShowError', '', true, false)]
    local procedure PlanningErrorLogOnShowError(RecRef: RecordRef; TableID: Integer)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        RtngHeader: Record "Routing Header";
        RtngVersion: Record "Routing Version";
        WorkCenter: Record "Work Center";
        MachCenter: Record "Machine Center";
        MfgSetup: Record "Manufacturing Setup";
    begin
        case TableID of
            DATABASE::"Production BOM Header":
                begin
                    RecRef.SetTable(ProdBOMHeader);
                    ProdBOMHeader.SetRecFilter();
                    PAGE.RunModal(PAGE::"Production BOM", ProdBOMHeader);
                end;
            DATABASE::"Routing Header":
                begin
                    RecRef.SetTable(RtngHeader);
                    RtngHeader.SetRecFilter();
                    PAGE.RunModal(PAGE::Routing, RtngHeader);
                end;
            DATABASE::"Production BOM Version":
                begin
                    RecRef.SetTable(ProdBOMVersion);
                    ProdBOMVersion.SetRecFilter();
                    PAGE.RunModal(PAGE::"Production BOM Version", ProdBOMVersion);
                end;
            DATABASE::"Routing Version":
                begin
                    RecRef.SetTable(RtngVersion);
                    RtngVersion.SetRecFilter();
                    PAGE.RunModal(PAGE::"Routing Version", RtngVersion);
                end;
            DATABASE::"Machine Center":
                begin
                    RecRef.SetTable(MachCenter);
                    MachCenter.SetRecFilter();
                    PAGE.RunModal(PAGE::"Machine Center Card", MachCenter);
                end;
            DATABASE::"Work Center":
                begin
                    RecRef.SetTable(WorkCenter);
                    WorkCenter.SetRecFilter();
                    PAGE.RunModal(PAGE::"Work Center Card", WorkCenter);
                end;
            DATABASE::"Manufacturing Setup":
                begin
                    RecRef.SetTable(MfgSetup);
                    PAGE.RunModal(0, MfgSetup);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning Transparency", 'OnSurplusQtyOnSetReservEntryFilters', '', true, false)]
    local procedure OnSurplusQtyOnSetReservEntryFilters(var ReservEntry: Record "Reservation Entry"; var RequisitionLine: Record "Requisition Line")
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::"Prod. Order":
                begin
                    ReservEntry.SetRange("Source ID", RequisitionLine."Ref. Order No.");
                    ReservEntry.SetRange("Source Type", Database::"Prod. Order Line");
                    ReservEntry.SetRange("Source Subtype", RequisitionLine."Ref. Order Status");
                    ReservEntry.SetRange("Source Prod. Order Line", RequisitionLine."Ref. Line No.");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning Transparency", 'OnFindReasonOnAfterSetSurplusType', '', true, false)]
    local procedure OnFindReasonOnAfterSetSurplusType(var DemandInventoryProfile: Record "Inventory Profile"; var SurplusType: Enum "Planning Surplus Type")
    begin
        case DemandInventoryProfile."Source Type" of
            Database::"Production Forecast Entry":
                SurplusType := SurplusType::Forecast;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning-Get Parameters", 'OnAtSKUOnBeforeSetSafetyLeadTime', '', true, false)]
    local procedure OnAtSKUOnBeforeSetSafetyLeadTime(var GlobalSKU: Record "Stockkeeping Unit"; ManualScheduling: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if ManualScheduling then begin
            ManufacturingSetup.Get();
            if ManufacturingSetup."Manual Scheduling" then
                GlobalSKU."Safety Lead Time" := ManufacturingSetup."Safety Lead Time for Man. Sch.";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Setup", 'OnGetComponentsAtLocation', '', true, false)]
    local procedure OnGetComponentsAtLocation(var LocationCode: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if ManufacturingSetup.Get() then
            LocationCode := ManufacturingSetup."Components at Location";
    end;
}
