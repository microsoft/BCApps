// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using System.Reflection;

codeunit 7311 "Whse. Worksheet-Create"
{

    trigger OnRun()
    begin
    end;

    var
        WhseMgt: Codeunit "Whse. Management";

    procedure FromWhseShptLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseShptLine: Record "Warehouse Shipment Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        TransferFromWhseShptLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseShptLine);
        AdjustQtyToHandle(WhseWkshLine);
        if CreateWhseWkshLine(WhseWkshLine, WhseShptLine) then
            exit(true);
    end;

    local procedure TransferFromWhseShptLine(var WhseWkshLine: Record "Whse. Worksheet Line"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseShptLine: Record "Warehouse Shipment Line")
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferFromWhseShptLine(WhseWkshLine, WhseShptLine, WhseWkshTemplateName, WhseWkshName, IsHandled);
        if IsHandled then
            exit;

        WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        WhseWkshLine.SetRange("Whse. Document Type", WhseWkshLine."Whse. Document Type"::Shipment);
        WhseWkshLine.SetRange("Whse. Document No.", WhseShptLine."No.");
        WhseWkshLine.SetRange("Whse. Document Line No.", WhseShptLine."Line No.");
        if WhseWkshLine.Find('-') then
            exit;

        FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseShptLine."Location Code");
        WhseShptHeader.Get(WhseShptLine."No.");

        WhseWkshLine.Init();
        WhseWkshLine.SetHideValidationDialog(true);
        WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
        WhseWkshLine."Source Type" := WhseShptLine."Source Type";
        WhseWkshLine."Source Subtype" := WhseShptLine."Source Subtype";
        WhseWkshLine."Source No." := WhseShptLine."Source No.";
        WhseWkshLine."Source Line No." := WhseShptLine."Source Line No.";
        WhseWkshLine."Source Document" := WhseMgt.GetWhseActivSourceDocument(WhseShptLine."Source Type", WhseShptLine."Source Subtype");
        WhseWkshLine."Location Code" := WhseShptLine."Location Code";
        WhseWkshLine."Item No." := WhseShptLine."Item No.";
        WhseWkshLine."Variant Code" := WhseShptLine."Variant Code";
        WhseWkshLine."Unit of Measure Code" := WhseShptLine."Unit of Measure Code";
        WhseWkshLine."Qty. per Unit of Measure" := WhseShptLine."Qty. per Unit of Measure";
        WhseWkshLine."Qty. Rounding Precision" := WhseShptLine."Qty. Rounding Precision";
        WhseWkshLine."Qty. Rounding Precision (Base)" := WhseShptLine."Qty. Rounding Precision (Base)";
        WhseWkshLine.Description := WhseShptLine.Description;
        WhseWkshLine."Description 2" := WhseShptLine."Description 2";
        WhseWkshLine."Due Date" := WhseShptLine."Due Date";
        WhseWkshLine."Qty. Handled" := WhseShptLine."Qty. Picked" + WhseShptLine."Pick Qty.";
        WhseWkshLine."Qty. Handled (Base)" := WhseShptLine."Qty. Picked (Base)" + WhseShptLine."Pick Qty. (Base)";
        WhseWkshLine.Validate(Quantity, WhseShptLine.Quantity);
        WhseWkshLine."To Zone Code" := WhseShptLine."Zone Code";
        WhseWkshLine."To Bin Code" := WhseShptLine."Bin Code";
        WhseWkshLine."Shelf No." := WhseShptLine."Shelf No.";
        WhseWkshLine."Destination Type" := WhseShptLine."Destination Type";
        WhseWkshLine."Destination No." := WhseShptLine."Destination No.";
        if WhseShptHeader."Shipment Date" = 0D then
            WhseWkshLine."Shipment Date" := WhseShptLine."Shipment Date"
        else
            WhseWkshLine."Shipment Date" := WhseShptHeader."Shipment Date";
        WhseWkshLine."Shipping Advice" := WhseShptLine."Shipping Advice";
        WhseWkshLine."Shipping Agent Code" := WhseShptHeader."Shipping Agent Code";
        WhseWkshLine."Shipping Agent Service Code" := WhseShptHeader."Shipping Agent Service Code";
        WhseWkshLine."Shipment Method Code" := WhseShptHeader."Shipment Method Code";
        WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Shipment;
        WhseWkshLine."Whse. Document No." := WhseShptLine."No.";
        WhseWkshLine."Whse. Document Line No." := WhseShptLine."Line No.";

        OnAfterTransferFromWhseShptLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseShptLine);
    end;

    procedure FromWhseInternalPickLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; WhseInternalPickLine: Record "Whse. Internal Pick Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        WhseWkshLine.SetRange("Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Pick");
        WhseWkshLine.SetRange("Whse. Document No.", WhseInternalPickLine."No.");
        WhseWkshLine.SetRange("Whse. Document Line No.", WhseInternalPickLine."Line No.");
        if not WhseWkshLine.IsEmpty() then
            exit;

        FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, LocationCode);

        WhseWkshLine.Init();
        WhseWkshLine.SetHideValidationDialog(true);
        WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
        WhseWkshLine."Location Code" := WhseInternalPickLine."Location Code";
        WhseWkshLine."Item No." := WhseInternalPickLine."Item No.";
        WhseWkshLine."Variant Code" := WhseInternalPickLine."Variant Code";
        WhseWkshLine."Unit of Measure Code" := WhseInternalPickLine."Unit of Measure Code";
        WhseWkshLine."Qty. per Unit of Measure" := WhseInternalPickLine."Qty. per Unit of Measure";
        WhseWkshLine.Description := WhseInternalPickLine.Description;
        WhseWkshLine."Description 2" := WhseInternalPickLine."Description 2";
        WhseWkshLine."Due Date" := WhseInternalPickLine."Due Date";
        WhseWkshLine."Qty. Handled" := WhseInternalPickLine."Qty. Picked" + WhseInternalPickLine."Pick Qty.";
        WhseWkshLine."Qty. Handled (Base)" := WhseInternalPickLine."Qty. Picked (Base)" + WhseInternalPickLine."Pick Qty. (Base)";
        WhseWkshLine.Validate(Quantity, WhseInternalPickLine.Quantity);
        WhseWkshLine."To Zone Code" := WhseInternalPickLine."To Zone Code";
        WhseWkshLine."To Bin Code" := WhseInternalPickLine."To Bin Code";
        WhseWkshLine."Shelf No." := WhseInternalPickLine."Shelf No.";
        WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::"Internal Pick";
        WhseWkshLine."Whse. Document No." := WhseInternalPickLine."No.";
        WhseWkshLine."Whse. Document Line No." := WhseInternalPickLine."Line No.";

        OnFromWhseInternalPickLineOnAfterTransferFields(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseInternalPickLine);

        if CreateWhseWkshLine(WhseWkshLine, WhseInternalPickLine) then
            exit(true);
    end;

#if not CLEAN26
    [Obsolete('Moved to codeunit ProdOrderWarehouseMgt', '26.0')]
    procedure FromProdOrderCompLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; ToBinCode: Code[20]; ProdOrderCompLine: Record Microsoft.Manufacturing.Document."Prod. Order Component"): Boolean
    var
        ProdOrderWarehouseMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Warehouse Mgt.";
    begin
        exit(ProdOrderWarehouseMgt.FromProdOrderCompLine(WhseWkshTemplateName, WhseWkshName, LocationCode, ToBinCode, ProdOrderCompLine));
    end;
#endif

    procedure FromAssemblyLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; AssemblyLine: Record "Assembly Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        if WhseWkshLineForAsmLineExists(AssemblyLine) then
            exit;

        FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, AssemblyLine."Location Code");

        WhseWkshLine.Init();
        TransferAllButWhseDocDetailsFromAssemblyLine(WhseWkshLine, AssemblyLine);
        WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Assembly;
        WhseWkshLine."Whse. Document No." := AssemblyLine."Document No.";
        WhseWkshLine."Whse. Document Line No." := AssemblyLine."Line No.";
        if CreateWhseWkshLine(WhseWkshLine, AssemblyLine) then
            exit(true);
    end;

    internal procedure FromJobPlanningLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; var JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        Bin: Record Bin;
        WhseWkshLine: Record "Whse. Worksheet Line";
        Job: Record Job;
    begin
        if WhseWkshLineForJobPlanLineExists(WhseWkshLine, JobPlanningLine) then
            exit;

        FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, JobPlanningLine."Location Code");

        WhseWkshLine.Init();
        WhseWkshLine.SetHideValidationDialog(true);
        WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
        WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Job;
        WhseWkshLine."Whse. Document No." := JobPlanningLine."Job No.";
        WhseWkshLine."Whse. Document Line No." := JobPlanningLine."Job Contract Entry No.";
        WhseWkshLine."Source Type" := Database::Job;
        WhseWkshLine."Source Subtype" := 0;
        WhseWkshLine."Source No." := JobPlanningLine."Job No.";
        WhseWkshLine."Source Line No." := JobPlanningLine."Job Contract Entry No.";
        WhseWkshLine."Source Subline No." := JobPlanningLine."Line No.";
        WhseWkshLine."Source Document" := WhseMgt.GetWhseActivSourceDocument(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype");
        WhseWkshLine."Location Code" := JobPlanningLine."Location Code";
        WhseWkshLine."Item No." := JobPlanningLine."No.";
        WhseWkshLine."Variant Code" := JobPlanningLine."Variant Code";
        WhseWkshLine."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        WhseWkshLine."Qty. per Unit of Measure" := JobPlanningLine."Qty. per Unit of Measure";
        WhseWkshLine.Description := JobPlanningLine.Description;
        WhseWkshLine."Due Date" := JobPlanningLine."Planning Due Date";

        Job.SetLoadFields("Sell-to Customer No.");
        Job.Get(JobPlanningLine."Job No.");
        WhseWkshLine."Destination No." := Job."Sell-to Customer No.";
        WhseWkshLine."Destination Type" := WhseWkshLine."Destination Type"::Customer;

        JobPlanningLine.CalcFields("Pick Qty.", "Pick Qty. (Base)");
        WhseWkshLine."Qty. Handled" := JobPlanningLine."Qty. Picked" + JobPlanningLine."Pick Qty.";
        WhseWkshLine."Qty. Handled (Base)" := JobPlanningLine."Qty. Picked (Base)" + JobPlanningLine."Pick Qty. (Base)";
        WhseWkshLine.Validate(Quantity, JobPlanningLine.Quantity);

        WhseWkshLine."To Bin Code" := JobPlanningLine."Bin Code";
        if (JobPlanningLine."Location Code" <> '') and (JobPlanningLine."Bin Code" <> '') then begin
            Bin.Get(JobPlanningLine."Location Code", JobPlanningLine."Bin Code");
            WhseWkshLine."To Zone Code" := Bin."Zone Code";
        end;

        OnFromJobPlanningLineOnBeforeCreateWhseWkshLine(WhseWkshLine, JobPlanningLine);
        if CreateWhseWkshLine(WhseWkshLine, JobPlanningLine) then
            exit(true);
    end;

    procedure FromAssemblyLineInATOWhseShpt(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; AssemblyLine: Record "Assembly Line"; WhseShptLine: Record "Warehouse Shipment Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        WhseShptLine.TestField("Assemble to Order", true);

        if WhseWkshLineForAsmLineExists(AssemblyLine) then
            exit;

        TransferFromWhseShptLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseShptLine);
        TransferAllButWhseDocDetailsFromAssemblyLine(WhseWkshLine, AssemblyLine);
        if CreateWhseWkshLine(WhseWkshLine, AssemblyLine) then
            exit(true);
    end;

    local procedure WhseWkshLineForAsmLineExists(AssemblyLine: Record "Assembly Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        WhseWkshLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
        WhseWkshLine.SetRange("Source Type", Database::"Assembly Line");
        WhseWkshLine.SetRange("Source Subtype", AssemblyLine."Document Type");
        WhseWkshLine.SetRange("Source No.", AssemblyLine."Document No.");
        WhseWkshLine.SetRange("Source Line No.", AssemblyLine."Line No.");
        WhseWkshLine.SetRange("Source Subline No.", 0);
        exit(not WhseWkshLine.IsEmpty);
    end;

    local procedure WhseWkshLineForJobPlanLineExists(var WhseWkshLine: Record "Whse. Worksheet Line"; var JobPlanningLine: Record "Job Planning Line"): Boolean
    begin
        WhseWkshLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
        WhseWkshLine.SetRange("Source Type", Database::Job);
        WhseWkshLine.SetRange("Source Subtype", 0);
        WhseWkshLine.SetRange("Source No.", JobPlanningLine."Job No.");
        WhseWkshLine.SetRange("Source Line No.", JobPlanningLine."Job Contract Entry No.");
        WhseWkshLine.SetRange("Source Subline No.", JobPlanningLine."Line No.");
        exit(not WhseWkshLine.IsEmpty());
    end;

    local procedure TransferAllButWhseDocDetailsFromAssemblyLine(var WhseWkshLine: Record "Whse. Worksheet Line"; AssemblyLine: Record "Assembly Line")
    var
        WhseWkshLine1: Record "Whse. Worksheet Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        WhseWkshLine.SetHideValidationDialog(true);
        FindLastWhseWkshLine(WhseWkshLine1, WhseWkshLine."Worksheet Template Name", WhseWkshLine.Name, WhseWkshLine."Location Code");
        WhseWkshLine."Line No." := WhseWkshLine1."Line No." + 10000;
        WhseWkshLine."Source Type" := Database::"Assembly Line";
        WhseWkshLine."Source Subtype" := AssemblyLine."Document Type".AsInteger();
        WhseWkshLine."Source No." := AssemblyLine."Document No.";
        WhseWkshLine."Source Line No." := AssemblyLine."Line No.";
        WhseWkshLine."Source Subline No." := 0;
        WhseWkshLine."Source Document" := WhseMgt.GetWhseActivSourceDocument(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype");
        WhseWkshLine."Location Code" := AssemblyLine."Location Code";
        AssemblyLine.TestField(AssemblyLine.Type, AssemblyLine.Type::Item);
        WhseWkshLine."Item No." := AssemblyLine."No.";
        WhseWkshLine."Variant Code" := AssemblyLine."Variant Code";
        WhseWkshLine."Unit of Measure Code" := AssemblyLine."Unit of Measure Code";
        WhseWkshLine."Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
        WhseWkshLine.Description := AssemblyLine.Description;
        WhseWkshLine."Description 2" := AssemblyLine."Description 2";
        WhseWkshLine."Due Date" := AssemblyLine."Due Date";
        AssemblyLine.CalcFields(AssemblyLine."Pick Qty.", AssemblyLine."Pick Qty. (Base)");
        WhseWkshLine."Qty. Handled" := AssemblyLine."Qty. Picked" + AssemblyLine."Pick Qty.";
        WhseWkshLine."Qty. Handled (Base)" := AssemblyLine."Qty. Picked (Base)" + AssemblyLine."Pick Qty. (Base)";
        Location.Get(AssemblyLine."Location Code");
        if Location."Require Shipment" then
            WhseWkshLine.Validate(Quantity, AssemblyLine.Quantity)
        else
            WhseWkshLine.Validate(Quantity, AssemblyLine."Quantity to Consume");
        WhseWkshLine."To Bin Code" := AssemblyLine."Bin Code";
        if (AssemblyLine."Location Code" <> '') and (AssemblyLine."Bin Code" <> '') then begin
            Bin.Get(AssemblyLine."Location Code", AssemblyLine."Bin Code");
            WhseWkshLine."To Zone Code" := Bin."Zone Code";
        end;
        OnAfterTransferAllButWhseDocDetailsFromAssemblyLine(WhseWkshLine, AssemblyLine);
    end;

    procedure FromWhseRcptLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; PostedWhseRcptLine: Record "Posted Whse. Receipt Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        if PostedWhseRcptLine."Qty. Put Away" = PostedWhseRcptLine.Quantity then
            exit;

        WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        WhseWkshLine.SetRange("Whse. Document Type", WhseWkshLine."Whse. Document Type"::Receipt);
        WhseWkshLine.SetRange("Whse. Document No.", PostedWhseRcptLine."No.");
        WhseWkshLine.SetRange("Whse. Document Line No.", PostedWhseRcptLine."Line No.");
        if not WhseWkshLine.IsEmpty() then
            exit;

        FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, LocationCode);

        WhseWkshLine.Init();
        WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
        WhseWkshLine."Source Type" := PostedWhseRcptLine."Source Type";
        WhseWkshLine."Source Subtype" := PostedWhseRcptLine."Source Subtype";
        WhseWkshLine."Source No." := PostedWhseRcptLine."Source No.";
        WhseWkshLine."Source Line No." := PostedWhseRcptLine."Source Line No.";
        WhseWkshLine."Source Document" := WhseMgt.GetWhseActivSourceDocument(PostedWhseRcptLine."Source Type", PostedWhseRcptLine."Source Subtype");
        WhseWkshLine."Location Code" := PostedWhseRcptLine."Location Code";
        WhseWkshLine."Item No." := PostedWhseRcptLine."Item No.";
        WhseWkshLine."Variant Code" := PostedWhseRcptLine."Variant Code";
        WhseWkshLine."Unit of Measure Code" := PostedWhseRcptLine."Unit of Measure Code";
        WhseWkshLine."Qty. per Unit of Measure" := PostedWhseRcptLine."Qty. per Unit of Measure";
        WhseWkshLine.Description := PostedWhseRcptLine.Description;
        WhseWkshLine."Description 2" := PostedWhseRcptLine."Description 2";
        WhseWkshLine."Due Date" := PostedWhseRcptLine."Due Date";
        WhseWkshLine.Validate(Quantity, PostedWhseRcptLine.Quantity);
        WhseWkshLine.Validate("Qty. Handled", PostedWhseRcptLine."Qty. Put Away" + PostedWhseRcptLine."Put-away Qty.");
        WhseWkshLine."From Zone Code" := PostedWhseRcptLine."Zone Code";
        WhseWkshLine."From Bin Code" := PostedWhseRcptLine."Bin Code";
        WhseWkshLine."Shelf No." := PostedWhseRcptLine."Shelf No.";
        WhseWkshLine."From Unit of Measure Code" := PostedWhseRcptLine."Unit of Measure Code";
        WhseWkshLine."Qty. per From Unit of Measure" := PostedWhseRcptLine."Qty. per Unit of Measure";
        WhseWkshLine."Qty. Rounding Precision" := PostedWhseRcptLine."Qty. Rounding Precision";
        WhseWkshLine."Qty. Rounding Precision (Base)" := PostedWhseRcptLine."Qty. Rounding Precision (Base)";
        WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Receipt;
        WhseWkshLine."Whse. Document No." := PostedWhseRcptLine."No.";
        WhseWkshLine."Whse. Document Line No." := PostedWhseRcptLine."Line No.";

        OnAfterFromWhseRcptLineCreateWhseWkshLine(WhseWkshLine, PostedWhseRcptLine);
        if CreateWhseWkshLine(WhseWkshLine, PostedWhseRcptLine) then
            exit(true);
    end;

    procedure FromWhseInternalPutawayLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; WhseInternalPutawayLine: Record "Whse. Internal Put-away Line"): Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        if WhseInternalPutawayLine."Qty. Put Away" = WhseInternalPutawayLine.Quantity then
            exit;

        WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        WhseWkshLine.SetRange("Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Put-away");
        WhseWkshLine.SetRange("Whse. Document No.", WhseInternalPutawayLine."No.");
        WhseWkshLine.SetRange("Whse. Document Line No.", WhseInternalPutawayLine."Line No.");
        if not WhseWkshLine.IsEmpty() then
            exit;

        FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, LocationCode);

        WhseWkshLine.Init();
        WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
        WhseWkshLine."Location Code" := WhseInternalPutawayLine."Location Code";
        WhseWkshLine."Item No." := WhseInternalPutawayLine."Item No.";
        WhseWkshLine."Variant Code" := WhseInternalPutawayLine."Variant Code";
        WhseWkshLine."Unit of Measure Code" := WhseInternalPutawayLine."Unit of Measure Code";
        WhseWkshLine."Qty. per Unit of Measure" := WhseInternalPutawayLine."Qty. per Unit of Measure";
        WhseWkshLine.Description := WhseInternalPutawayLine.Description;
        WhseWkshLine."Description 2" := WhseInternalPutawayLine."Description 2";
        WhseWkshLine."Due Date" := WhseInternalPutawayLine."Due Date";
        WhseWkshLine.Validate(Quantity, WhseInternalPutawayLine.Quantity);
        WhseWkshLine.Validate("Qty. Handled", WhseInternalPutawayLine."Qty. Put Away" + WhseInternalPutawayLine."Put-away Qty.");
        WhseWkshLine."From Zone Code" := WhseInternalPutawayLine."From Zone Code";
        WhseWkshLine."From Bin Code" := WhseInternalPutawayLine."From Bin Code";
        WhseWkshLine."Shelf No." := WhseInternalPutawayLine."Shelf No.";
        WhseWkshLine."From Unit of Measure Code" := WhseInternalPutawayLine."Unit of Measure Code";
        WhseWkshLine."Qty. per From Unit of Measure" := WhseInternalPutawayLine."Qty. per Unit of Measure";
        WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::"Internal Put-away";
        WhseWkshLine."Whse. Document No." := WhseInternalPutawayLine."No.";
        WhseWkshLine."Whse. Document Line No." := WhseInternalPutawayLine."Line No.";

        OnFromWhseInternalPutawayLineOnAfterTransferFields(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, WhseInternalPutawayLine);

        if CreateWhseWkshLine(WhseWkshLine, WhseInternalPutawayLine) then
            exit(true);
    end;

    procedure CreateWhseWkshLine(var WhseWkshLine: Record "Whse. Worksheet Line"; SourceRecord: Variant) Created: Boolean
    var
        Item: Record Item;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseWkshLine(WhseWkshLine, Created, IsHandled, SourceRecord);
        if IsHandled then
            exit(Created);

        if WhseWkshLine."Shelf No." = '' then begin
            Item."No." := WhseWkshLine."Item No.";
            Item.ItemSKUGet(Item, WhseWkshLine."Location Code", WhseWkshLine."Variant Code");
            WhseWkshLine."Shelf No." := Item."Shelf No.";
        end;
        OnCreateWhseWkshLineOnBeforeInsert(WhseWkshLine, SourceRecord);
        if WhseWkshLine.Insert() then begin
            Created := true;

            IsHandled := false;
            OnCreateWhseWkshLineOnBeforeGetWhseItemTrkgSetup(WhseWkshLine, IsHandled, SourceRecord);
            if not IsHandled then
                if ItemTrackingMgt.GetWhseItemTrkgSetup(WhseWkshLine."Item No.") then
                    ItemTrackingMgt.InitTrackingSpecification(WhseWkshLine);

            OnCreateWhseWkshLineOnAfterInsert(WhseWkshLine, SourceRecord);
        end;
    end;

    procedure FindLastWhseWkshLine(var WhseWkshLine: Record "Whse. Worksheet Line"; WkshTemplateName: Code[10]; WkshName: Code[10]; LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindLastWhseWkshLine(WhseWkshLine, WkshTemplateName, WkshName, LocationCode, IsHandled);
        if IsHandled then
            exit;

        WhseWkshLine.Reset();
        WhseWkshLine."Worksheet Template Name" := WkshTemplateName;
        WhseWkshLine.Name := WkshName;
        WhseWkshLine."Location Code" := LocationCode;
        WhseWkshLine.SetRange("Worksheet Template Name", WkshTemplateName);
        WhseWkshLine.SetRange(Name, WkshName);
        WhseWkshLine.SetRange("Location Code", LocationCode);
        WhseWkshLine.LockTable();
        if WhseWkshLine.FindLast() then;
    end;

    local procedure AdjustQtyToHandle(var WhseWkshLine: Record "Whse. Worksheet Line")
    var
        Location: Record Location;
        TypeHelper: Codeunit "Type Helper";
        AvailQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        AvailQtyToPickBase := AvailableQtyToPickBase(WhseWkshLine, WhseWkshLine."Qty. to Handle (Base)"); // When "Always Create Pick Line" is false, then "Qty. to Handle (Base)" is set to maximum available quantity for the item in the location
        if Location.Get(WhseWkshLine."Location Code") then
            if Location."Always Create Pick Line" then
                AvailQtyToPickBase := AvailableQtyToPickBase(WhseWkshLine, WhseWkshLine.CalcAvailableQtyBase()); // Set the Qty. to handle to the available quantity for "Always Create Pick Line" when transferring warehouse shipment lines to warehouse worksheet lines

        IsHandled := false;
        OnAdjustQtyToHandleOnBeforeAssignQtyToHandle(WhseWkshLine, AvailQtyToPickBase, IsHandled);
        if IsHandled then
            exit;

        WhseWkshLine."Qty. to Handle" := TypeHelper.Minimum(AvailQtyToPickBase, WhseWkshLine."Qty. Outstanding");
        WhseWkshLine."Qty. to Handle (Base)" := WhseWkshLine.CalcBaseQty(WhseWkshLine."Qty. to Handle");
        WhseWkshLine.CalcReservedNotFromILEQty(AvailQtyToPickBase, WhseWkshLine."Qty. to Handle", WhseWkshLine."Qty. to Handle (Base)");
    end;

    procedure AvailableQtyToPickBase(WhseWkshLine: Record "Whse. Worksheet Line"; QtyBase: Decimal): Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if WhseWkshLine."Qty. per Unit of Measure" <> 0 then
            exit(Round(QtyBase / WhseWkshLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromWhseShptLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

#if not CLEAN26
    internal procedure RunOnAfterFromProdOrderCompLineCreateWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; LocationCode: Code[10]; ToBinCode: Code[20])
    begin
        OnAfterFromProdOrderCompLineCreateWhseWkshLine(WhseWorksheetLine, ProdOrderComponent, LocationCode, ToBinCode);
    end;

    [Obsolete('Moved to codeunit ProdOrderWarehouseMgt', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFromProdOrderCompLineCreateWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; LocationCode: Code[10]; ToBinCode: Code[20])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromWhseRcptLineCreateWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAllButWhseDocDetailsFromAssemblyLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromWhseShptLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseWkshLine(var WhseWkshLine: Record "Whse. Worksheet Line"; var Created: Boolean; var IsHandled: Boolean; var SourceRecord: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseWkshLineOnBeforeInsert(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceRecord: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseWkshLineOnAfterInsert(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceRecord: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromWhseInternalPickLineOnAfterTransferFields(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromWhseInternalPutawayLineOnAfterTransferFields(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseWkshLineOnBeforeGetWhseItemTrkgSetup(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean; var SourceRecord: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromJobPlanningLineOnBeforeCreateWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustQtyToHandleOnBeforeAssignQtyToHandle(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var AvailQtyToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLastWhseWkshLine(var WhseWksheetLine: Record "Whse. Worksheet Line"; WorksheetTemplateName: Code[10]; WorksheetName: Code[10]; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

