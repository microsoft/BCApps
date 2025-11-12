// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Worksheet;

report 7304 "Get Outbound Source Documents"
{
    Caption = 'Get Outbound Source Documents';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Whse. Pick Request"; "Whse. Pick Request")
        {
            DataItemTableView = sorting("Document Type", "Document Subtype", "Document No.", "Location Code") where(Status = const(Released), "Completely Picked" = const(false));
            RequestFilterFields = "Document Type", "Document No.";
            dataitem("Warehouse Shipment Header"; "Warehouse Shipment Header")
            {
                DataItemLink = "No." = field("Document No.");
                DataItemTableView = sorting("No.");
                dataitem("Warehouse Shipment Line"; "Warehouse Shipment Line")
                {
                    DataItemLink = "No." = field("No.");
                    DataItemTableView = sorting("No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        ATOLink: Record "Assemble-to-Order Link";
                        ATOAsmLine: Record "Assembly Line";
                        IsHandled: Boolean;
                        ShouldPickLineFromShipmentLine: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeWhseShipmentLineOnAfterGetRecord("Warehouse Shipment Line", "Whse. Pick Request", IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        if not "Assemble to Order" then begin
                            CalcFields("Pick Qty.", "Pick Qty. (Base)");
                            ShouldPickLineFromShipmentLine := "Qty. (Base)" > "Qty. Picked (Base)" + "Pick Qty. (Base)";
                            OnWarehouseShipmentLineOnAfterGetRecordOnAfterCalcShouldPickLineFromShipmentLine("Whse. Pick Request", "Warehouse Shipment Header", "Warehouse Shipment Line", ShouldPickLineFromShipmentLine);
                            if ShouldPickLineFromShipmentLine then begin
                                if "Destination Type" = "Destination Type"::Customer then begin
                                    TestField("Destination No.");
                                    Cust.Get("Destination No.");
                                    Cust.CheckBlockedCustOnDocs(Cust, "Source Document", false, false);
                                end;

                                if WhsePickWkshCreate.FromWhseShptLine(PickWkshTemplate, PickWkshName, "Warehouse Shipment Line") then
                                    LineCreated := true;
                            end;
                        end else
                            if ATOLink.AsmExistsForWhseShptLine("Warehouse Shipment Line") then begin
                                ATOAsmLine.SetRange("Document Type", ATOLink."Assembly Document Type");
                                ATOAsmLine.SetRange("Document No.", ATOLink."Assembly Document No.");
                                if ATOAsmLine.FindSet() then
                                    repeat
                                        ProcessAsmLineFromWhseShpt(ATOAsmLine, "Warehouse Shipment Line");
                                    until ATOAsmLine.Next() = 0;
                            end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Qty. Outstanding", '>0');
                        OnAfterWarehouseShipmentLineOnPreDataItem("Warehouse Shipment Line");
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Pick Request"."Document Type" <>
                       "Whse. Pick Request"."Document Type"::Shipment
                    then
                        CurrReport.Break();

                    OnWhseShipHeaderOnPreDataItem("Warehouse Shipment Header");
                end;
            }
            dataitem("Whse. Internal Pick Header"; "Whse. Internal Pick Header")
            {
                DataItemLink = "No." = field("Document No.");
                DataItemTableView = sorting("No.");
                dataitem("Whse. Internal Pick Line"; "Whse. Internal Pick Line")
                {
                    DataItemLink = "No." = field("No.");
                    DataItemTableView = sorting("No.", "Line No.");

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Pick Qty.", "Pick Qty. (Base)");
                        if "Qty. (Base)" > "Qty. Picked (Base)" + "Pick Qty. (Base)" then
                            if WhsePickWkshCreate.FromWhseInternalPickLine(
                                 PickWkshTemplate, PickWkshName, LocationCode, "Whse. Internal Pick Line")
                            then
                                LineCreated := true;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Qty. Outstanding", '>0');
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Pick Request"."Document Type" <> "Whse. Pick Request"."Document Type"::"Internal Pick" then
                        CurrReport.Break();
                end;
            }
            dataitem("Assembly Header"; "Assembly Header")
            {
                DataItemLink = "Document Type" = field("Document Subtype"), "No." = field("Document No.");
                DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
                dataitem("Assembly Line"; "Assembly Line")
                {
                    DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    DataItemTableView = sorting("Document Type", "Document No.", Type, "Location Code") where(Type = const(Item));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessAsmLineFromAsmLine("Assembly Line");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Location Code", "Whse. Pick Request"."Location Code");
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Pick Request"."Document Type" <> "Whse. Pick Request"."Document Type"::Assembly then
                        CurrReport.Break();
                end;
            }
            dataitem(Job; Job)
            {
                DataItemLink = "No." = field("Document No.");
                DataItemTableView = sorting("No.") where(Status = const(Open));
                dataitem("Job Planning Line"; "Job Planning Line")
                {
                    DataItemLink = "Job No." = field("No.");
                    DataItemTableView = sorting("Job No.", "Job Task No.", "Line No.") where(Type = const(Item), "Line Type" = filter(Budget | "Both Budget and Billable"));

                    trigger OnAfterGetRecord()
                    begin
                        ProcessJobPlanningLine("Job Planning Line");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Location Code", "Whse. Pick Request"."Location Code");
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Pick Request"."Document Type" <> "Whse. Pick Request"."Document Type"::Job then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            var
                SkipRecord: Boolean;
            begin
                OnBeforeWhsePickRequestOnAfterGetRecord("Whse. Pick Request", PickWkshTemplate, PickWkshName, LocationCode, LineCreated, SkipRecord);
                if SkipRecord then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                OnBeforePreDataItemWhsePickRequest("Whse. Pick Request");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not HideDialog then
            if not LineCreated then
                Error(NoWorksheetLinesCreatedErr);

        Completed := true;

        OnAfterPostReport();
    end;

    trigger OnPreReport()
    begin
        OnBeforePreReport();

        LineCreated := false;
    end;

    var
        Cust: Record Customer;
        WhsePickWkshCreate: Codeunit "Whse. Worksheet-Create";
        LocationCode: Code[10];
        Completed: Boolean;
        HideDialog: Boolean;
        NoWorksheetLinesCreatedErr: Label 'There are no Warehouse Worksheet Lines created.';

    protected var
        Location: Record Location;
        PickWkshTemplate: Code[10];
        PickWkshName: Code[10];
        LineCreated: Boolean;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure NotCancelled(): Boolean
    begin
        exit(Completed);
    end;

    procedure SetPickWkshName(PickWkshTemplate2: Code[10]; PickWkshName2: Code[10]; LocationCode2: Code[10])
    begin
        PickWkshTemplate := PickWkshTemplate2;
        PickWkshName := PickWkshName2;
        LocationCode := LocationCode2;
    end;

    protected procedure GetLocation(LocationCode2: Code[10])
    begin
        if LocationCode2 = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode2 then
                Location.Get(LocationCode2);
    end;

    local procedure IsPickToBeMadeForAsmLine(AsmLine: Record "Assembly Line"): Boolean
    begin
        if not AsmLine.IsInventoriableItem() then
            exit(false);

        GetLocation(AsmLine."Location Code");

        AsmLine.CalcFields("Pick Qty.");
        if Location."Asm. Consump. Whse. Handling" = Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)" then
            exit(AsmLine.Quantity > AsmLine."Qty. Picked" + AsmLine."Pick Qty.");

        exit(AsmLine."Quantity to Consume" > AsmLine."Qty. Picked" + AsmLine."Pick Qty.");
    end;

    local procedure ProcessAsmLineFromAsmLine(AsmLine: Record "Assembly Line")
    begin
        if IsPickToBeMadeForAsmLine(AsmLine) then
            if WhsePickWkshCreate.FromAssemblyLine(PickWkshTemplate, PickWkshName, AsmLine) then
                LineCreated := true;
    end;

    local procedure ProcessAsmLineFromWhseShpt(AsmLine: Record "Assembly Line"; WhseShptLine: Record "Warehouse Shipment Line")
    begin
        if IsPickToBeMadeForAsmLine(AsmLine) then
            if WhsePickWkshCreate.FromAssemblyLineInATOWhseShpt(PickWkshTemplate, PickWkshName, AsmLine, WhseShptLine) then
                LineCreated := true;
    end;

    local procedure ProcessJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    var
        Item: Record Item;
    begin
        GetLocation(JobPlanningLine."Location Code");
        if (Location."Job Consump. Whse. Handling" = Location."Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)") and not JobPlanningLine."Completely Picked" then begin
            Item.Get(JobPlanningLine."No.");
            if Item.IsInventoriableType() then
                if WhsePickWkshCreate.FromJobPlanningLine(PickWkshTemplate, PickWkshName, JobPlanningLine) then
                    LineCreated := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWarehouseShipmentLineOnPreDataItem(var WhseShipmentLine: record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhsePickRequestOnAfterGetRecord(var WhsePickRequest: Record "Whse. Pick Request"; PickWkshTemplate: Code[10]; PickWkshName: Code[10]; LocationCode: Code[10]; var LineCreated: Boolean; var SkipRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseShipHeaderOnPreDataItem(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreDataItemWhsePickRequest(var WhsePickRequest: Record "Whse. Pick Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShipmentLineOnAfterGetRecord(var WhseShipmentLine: Record "Warehouse Shipment Line"; var WhsePickRequest: Record "Whse. Pick Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWarehouseShipmentLineOnAfterGetRecordOnAfterCalcShouldPickLineFromShipmentLine(var WhsePickRequest: Record "Whse. Pick Request"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var ShouldPickLineFromShipmentLine: Boolean)
    begin
    end;
}

